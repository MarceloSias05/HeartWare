//
//  PhoneLink.swift
//  HearthwareWatch Watch App
//
//  The Watch side of WatchConnectivity: reads today's step and which step to start,
//  hears "cancel", and sends the result of an iPhone-started step back.
//

import Foundation
import WatchConnectivity

final class PhoneLink: NSObject, WCSessionDelegate {
    private weak var workout: StepWorkout?
    private weak var store: WatchStore?

    func activate(workout: StepWorkout, store: WatchStore) {
        self.workout = workout
        self.store = store
        workout.onFinish = { [weak store] step, result in
            // A step started on the Watch keeps its result here for the "after" question.
            if let store, step == store.localStep {
                store.localResult = result
                return
            }
            let payload = WatchMessage.resultPayload(step: step, result: result)
            let session = WCSession.default
            if session.isReachable {
                // If the live message fails, queue it so the result is never lost.
                session.sendMessage(payload, replyHandler: nil) { _ in session.transferUserInfo(payload) }
            } else {
                session.transferUserInfo(payload)
            }
        }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func pendingStep() -> (step: String, title: String)? {
        WatchMessage.start(from: WCSession.default.receivedApplicationContext)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        updateToday(session.receivedApplicationContext)
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        updateToday(applicationContext)
    }

    private nonisolated func updateToday(_ context: [String: Any]) {
        let today = WatchMessage.today(from: context)
        Task { @MainActor in store?.today = today }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleCancel(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleCancel(userInfo)
    }

    private nonisolated func handleCancel(_ message: [String: Any]) {
        guard message[WatchMessage.kind] as? String == WatchMessage.cancel,
              let step = message[WatchMessage.step] as? String else { return }
        Task { @MainActor in workout?.cancel(step: step) }
    }
}

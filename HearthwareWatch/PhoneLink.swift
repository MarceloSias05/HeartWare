//
//  PhoneLink.swift
//  HearthwareWatch
//
//  The Watch side of WatchConnectivity: reads which step to start, hears "cancel",
//  and sends the result back to the iPhone.
//

import Foundation
import WatchConnectivity

final class PhoneLink: NSObject, WCSessionDelegate {
    private weak var workout: StepWorkout?

    func activate(workout: StepWorkout) {
        self.workout = workout
        workout.onFinish = { step, result in
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

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

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

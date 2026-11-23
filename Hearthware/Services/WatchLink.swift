//
//  WatchLink.swift
//  Hearthware
//
//  The iPhone side of the Watch: opens the Watch app for a step and hands back what
//  it measured. Without a paired Watch with the app installed, `canUseWatch` is false
//  and the step runs on the iPhone alone.
//

import Foundation
import HealthKit
import Observation
import WatchConnectivity

@MainActor @Observable
final class WatchLink: NSObject {
    private(set) var canUseWatch = false
    /// Called with the result of the step that is currently running.
    var onResult: ((WatchResult) -> Void)?

    private var currentStep: String?
    private let healthStore = HKHealthStore()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Opens the Watch app for this step. Returns false if the Watch can't take it,
    /// so the caller falls back to the iPhone-only step.
    func start(title: String) async -> Bool {
        guard canUseWatch else { return false }
        let step = UUID().uuidString
        do {
            try WCSession.default.updateApplicationContext(WatchMessage.startContext(step: step, title: title))
            let config = HKWorkoutConfiguration()
            config.activityType = .walking
            try await healthStore.startWatchApp(toHandle: config)
            currentStep = step
            return true
        } catch {
            return false
        }
    }

    func cancel() {
        guard let step = currentStep else { return }
        currentStep = nil
        let message = WatchMessage.cancelMessage(step: step)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(message)
        }
    }

    private func refresh(_ session: WCSession) {
        canUseWatch = session.activationState == .activated && session.isPaired && session.isWatchAppInstalled
    }

    private func receive(step: String, result: WatchResult) {
        // Ignore results from a step that was cancelled or already finished.
        guard step == currentStep else { return }
        currentStep = nil
        onResult?(result)
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in refresh(session) }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in refresh(session) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // The person switched Watches: activate again for the new one.
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let (step, result) = WatchMessage.result(from: message) else { return }
        Task { @MainActor in receive(step: step, result: result) }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let (step, result) = WatchMessage.result(from: userInfo) else { return }
        Task { @MainActor in receive(step: step, result: result) }
    }
}

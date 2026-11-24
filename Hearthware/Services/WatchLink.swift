//
//  WatchLink.swift
//  Hearthware
//
//  The iPhone side of the Watch: opens the Watch app for a step and hands back what
//  it measured, tells the Watch today's step, and saves steps and symptoms reported
//  on the Watch. Without a paired Watch with the app installed, `canUseWatch` is false
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
    private weak var model: AppModel?
    /// The application context is one dictionary: today's step and a step start live in it together.
    private var context: [String: Any] = [:]

    func activate(model: AppModel) {
        self.model = model
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
            context.merge(WatchMessage.startContext(step: step, title: title)) { $1 }
            try WCSession.default.updateApplicationContext(context)
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

    /// Keeps the Watch's "today" in sync. Nil before onboarding.
    func share(today: WatchToday?) {
        context[WatchMessage.today] = nil
        if let today { context.merge(WatchMessage.todayContext(today)) { $1 } }
        guard WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext(context)
    }

    /// A step or symptom reported on the Watch. Kept with the Watch's own date.
    private func receiveReport(_ message: [String: Any]) {
        guard let model else { return }
        if let log = WatchMessage.decode(WatchStepLog.self, kind: WatchMessage.stepLog, from: message) {
            model.log(title: log.title, before: log.before, after: log.after, watch: log.result,
                      noteBefore: log.noteBefore, noteAfter: log.noteAfter, date: log.date)
        } else if let symptom = WatchMessage.decode(WatchSymptom.self, kind: WatchMessage.symptom, from: message) {
            model.logSymptom(symptom.symptom, urgent: symptom.urgent, date: symptom.date)
            if !symptom.urgent { Task { await CheckIn.schedule(after: symptom.symptom) } }
        }
    }

    private func refresh(_ session: WCSession) {
        canUseWatch = session.activationState == .activated && session.isPaired && session.isWatchAppInstalled
        if let today = model?.watchToday { share(today: today) }
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
        handle(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handle(userInfo)
    }

    private nonisolated func handle(_ message: [String: Any]) {
        if let (step, result) = WatchMessage.result(from: message) {
            Task { @MainActor in receive(step: step, result: result) }
        } else {
            // [String: Any] isn't Sendable: pass the raw bytes of what we need.
            let kind = message[WatchMessage.kind] as? String, data = message[WatchMessage.data] as? Data
            Task { @MainActor in
                var copy: [String: Any] = [:]
                copy[WatchMessage.kind] = kind
                copy[WatchMessage.data] = data
                receiveReport(copy)
            }
        }
    }
}

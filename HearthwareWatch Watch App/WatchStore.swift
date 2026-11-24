//
//  WatchStore.swift
//  HearthwareWatch Watch App
//
//  What the Watch knows (today's step, from the iPhone) and how it reports back.
//  Reports go with transferUserInfo: queued and delivered even if the iPhone is far
//  away or the app is closed, so nothing reported on the wrist is lost.
//

import Foundation
import Observation
import WatchConnectivity

@MainActor @Observable
final class WatchStore {
    /// Nil until the iPhone has shared it (before onboarding, or never opened).
    var today: WatchToday?
    /// The step running from the Watch itself, and its result once the rest is over.
    var localStep: String?
    var localResult: WatchResult?

    func send(_ log: WatchStepLog) { transfer(WatchMessage.payload(WatchMessage.stepLog, log)) }
    func send(_ symptom: WatchSymptom) { transfer(WatchMessage.payload(WatchMessage.symptom, symptom)) }

    private func transfer(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        WCSession.default.transferUserInfo(payload)
    }
}

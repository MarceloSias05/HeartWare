//
//  WatchResult.swift
//  Hearthware
//
//  What the Watch measured during a step. Shared by the iPhone and Watch targets,
//  so it uses Foundation only. Numbers here only ever reach the doctor summary.
//

import Foundation

nonisolated struct WatchResult: Codable, Equatable, Sendable {
    var peakHeartRate: Int?
    var recoverySeconds: Int?
}

nonisolated enum Recovery {
    /// How long the Watch keeps listening after "End step".
    static let window: TimeInterval = 120
    /// "Back to rest" means within this many bpm of the first reading of the step.
    static let margin: Double = 10

    /// Seconds from the end of the step to the first reading back near the baseline,
    /// or nil if the heart did not settle within the window.
    static func seconds(baseline: Double, endedAt: Date, samples: [(date: Date, bpm: Double)]) -> Int? {
        samples
            .filter { $0.date >= endedAt && $0.date.timeIntervalSince(endedAt) <= window }
            .sorted { $0.date < $1.date }
            .first { $0.bpm <= baseline + margin }
            .map { Int($0.date.timeIntervalSince(endedAt).rounded()) }
    }
}

/// The few messages the iPhone and Watch exchange. Every step has an id so a late
/// result from a cancelled step is never saved on the wrong step.
nonisolated enum WatchMessage {
    static let kind = "kind", step = "step", title = "title", result = "result", cancel = "cancel"

    /// iPhone → Watch, sent as application context before launching the Watch app.
    static func startContext(step: String, title: String) -> [String: Any] {
        [self.step: step, self.title: title]
    }

    static func start(from context: [String: Any]) -> (step: String, title: String)? {
        guard let step = context[self.step] as? String, let title = context[self.title] as? String else { return nil }
        return (step, title)
    }

    /// iPhone → Watch: stop the step without saving.
    static func cancelMessage(step: String) -> [String: Any] { [kind: cancel, self.step: step] }

    /// Watch → iPhone, when the rest after the step is over.
    static func resultPayload(step: String, result: WatchResult) -> [String: Any] {
        [kind: self.result, self.step: step, self.result: (try? JSONEncoder().encode(result)) ?? Data()]
    }

    static func result(from message: [String: Any]) -> (step: String, result: WatchResult)? {
        guard message[kind] as? String == self.result,
              let step = message[self.step] as? String,
              let data = message[self.result] as? Data,
              let result = try? JSONDecoder().decode(WatchResult.self, from: data) else { return nil }
        return (step, result)
    }
}

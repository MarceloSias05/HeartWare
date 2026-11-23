//
//  WatchResult.swift
//  Hearthware
//
//  What the Watch measured during a step. Shared by the iPhone and Watch targets,
//  so it uses Foundation only. Numbers here only ever reach the doctor summary.
//

import Foundation

struct WatchResult: Codable, Equatable, Sendable {
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

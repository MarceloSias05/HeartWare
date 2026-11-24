//
//  Trends.swift
//  Hearthware
//
//  Day-by-day values for the charts in the doctor summary. Pure: the HealthKit
//  queries live in Services/HealthHistory.swift.
//

import Foundation

nonisolated struct TrendPoint: Sendable {
    var date: Date
    var value: Double
}

nonisolated struct TrendSeries: Sendable {
    var metric: HealthMetric
    var points: [TrendPoint]
}

nonisolated enum TrendCharts {
    /// One chart per group; blood pressure draws systolic and diastolic together.
    static let groups: [[HealthMetric]] = [
        [.steps], [.restingHeartRate], [.systolic, .diastolic],
        [.heartRateVariability], [.walkingSpeed], [.bloodOxygen], [.weight],
    ]
    static var metrics: [HealthMetric] { groups.flatMap { $0 } }

    /// Charts worth drawing: the group's first series needs at least two days to show a line.
    static func cards(_ series: [TrendSeries]) -> [[TrendSeries]] {
        groups.compactMap { group in
            let found = group.compactMap { metric in series.first { $0.metric == metric } }
            guard let lead = found.first, lead.metric == group[0], lead.points.count >= 2 else { return nil }
            return found
        }
    }
}

extension HealthMetric {
    /// Percentages are stored as fractions by Health; charts show 0–100.
    nonisolated func chartValue(_ value: Double) -> Double {
        switch self {
        case .bloodOxygen, .afibBurden, .walkingAsymmetry, .doubleSupport, .walkingSteadiness: value * 100
        default: value
        }
    }

    nonisolated var chartUnit: String {
        switch self {
        case .heartRate, .restingHeartRate, .walkingHeartRate, .heartRateRecovery: "bpm"
        case .heartRateVariability: "ms"
        case .bloodOxygen, .afibBurden, .walkingAsymmetry, .doubleSupport, .walkingSteadiness: "%"
        case .systolic, .diastolic, .meanArterialPressure: "mmHg"
        case .respiratoryRate: "/min"
        case .vo2Max: "mL/kg/min"
        case .steps: "steps/day"
        case .exerciseMinutes: "min/day"
        case .flightsClimbed: "flights/day"
        case .walkingSpeed: "km/h"
        case .stepLength: "cm"
        case .sixMinuteWalk: "m"
        case .weight: "kg"
        case .irregularRhythmAlerts, .highHeartRateAlerts, .lowHeartRateAlerts, .ecgRecordings: ""
        }
    }
}

extension Feeling {
    /// Calm at the top of the fear chart, very scared at the bottom.
    var chartLevel: Int { Feeling.veryScared.rawValue - rawValue }
}

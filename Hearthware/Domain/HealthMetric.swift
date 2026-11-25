//
//  HealthMetric.swift
//  Hearthware
//
//  What the doctor summary reads from Apple Health, and how each value is shown.
//  Pure: the HealthKit queries live in Services/HealthHistory.swift.
//  Numbers only ever reach the doctor summary, never the patient's screens.
//

import Foundation

nonisolated enum HealthMetric: String, CaseIterable, Sendable {
    // Heart
    case heartRate, restingHeartRate, walkingHeartRate, heartRateVariability, heartRateRecovery
    case bloodOxygen, systolic, diastolic, meanArterialPressure, respiratoryRate, vo2Max, afibBurden
    case irregularRhythmAlerts, highHeartRateAlerts, lowHeartRateAlerts
    // Movement and tiredness
    case steps, exerciseMinutes, flightsClimbed, walkingSpeed, stepLength
    case walkingAsymmetry, doubleSupport, walkingSteadiness, sixMinuteWalk
    // Body
    case weight

    enum Section: Sendable { case heart, movement, body }

    var section: Section {
        switch self {
        case .steps, .exerciseMinutes, .flightsClimbed, .walkingSpeed, .stepLength,
             .walkingAsymmetry, .doubleSupport, .walkingSteadiness, .sixMinuteWalk: .movement
        case .weight: .body
        default: .heart
        }
    }

    var title: String {
        switch self {
        case .heartRate: "Heart rate (average)"
        case .restingHeartRate: "Resting heart rate"
        case .walkingHeartRate: "Walking heart rate"
        case .heartRateVariability: "Heart rate variability (SDNN)"
        case .heartRateRecovery: "Heart rate recovery (1 min)"
        case .bloodOxygen: "Blood oxygen"
        case .systolic: "Blood pressure, systolic"
        case .diastolic: "Blood pressure, diastolic"
        case .meanArterialPressure: "Mean arterial pressure"
        case .respiratoryRate: "Respiratory rate"
        case .vo2Max: "Cardio fitness (VO₂ max)"
        case .afibBurden: "AFib history (time in AFib)"
        case .irregularRhythmAlerts: "Irregular rhythm alerts"
        case .highHeartRateAlerts: "High heart rate alerts"
        case .lowHeartRateAlerts: "Low heart rate alerts"
        case .steps: "Steps"
        case .exerciseMinutes: "Exercise"
        case .flightsClimbed: "Flights climbed"
        case .walkingSpeed: "Walking speed"
        case .stepLength: "Step length"
        case .walkingAsymmetry: "Walking asymmetry"
        case .doubleSupport: "Double support time"
        case .walkingSteadiness: "Walking steadiness"
        case .sixMinuteWalk: "Six-minute walk (estimated)"
        case .weight: "Weight"
        }
    }

    /// Alerts are counts in the window; everything else is a value.
    var isCount: Bool {
        switch self {
        case .irregularRhythmAlerts, .highHeartRateAlerts, .lowHeartRateAlerts: true
        default: false
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .heartRate, .restingHeartRate, .walkingHeartRate, .heartRateRecovery: "\(Int(value.rounded())) bpm"
        case .heartRateVariability: "\(Int(value.rounded())) ms"
        // Usually a few percent: whole numbers would show 1.2% and 0.9% both as "1%".
        case .afibBurden, .walkingAsymmetry: String(format: "%.1f%%", value * 100)
        case .bloodOxygen, .doubleSupport, .walkingSteadiness: "\(Int((value * 100).rounded()))%"
        case .systolic, .diastolic, .meanArterialPressure: "\(Int(value.rounded())) mmHg"
        case .respiratoryRate: "\(Int(value.rounded())) /min"
        case .vo2Max: String(format: "%.1f mL/kg/min", value)
        case .irregularRhythmAlerts, .highHeartRateAlerts, .lowHeartRateAlerts:
            value == 0 ? "None" : "\(Int(value))"
        // The summary is in English, so numbers use en_US separators whatever the phone locale.
        case .steps: "\(Int(value.rounded()).formatted(.number.locale(Locale(identifier: "en_US")))) /day"
        case .exerciseMinutes: "\(Int(value.rounded())) min/day"
        case .flightsClimbed: String(format: "%.1f /day", value)
        case .walkingSpeed: String(format: "%.1f km/h", value)
        case .stepLength: "\(Int(value.rounded())) cm"
        case .sixMinuteWalk: "\(Int(value.rounded())) m"
        case .weight: String(format: "%.1f kg", value)
        }
    }

    /// MAP ≈ (systolic + 2 × diastolic) / 3.
    static func meanArterialPressure(systolic: Double, diastolic: Double) -> Double {
        (systolic + 2 * diastolic) / 3
    }
}

/// One measure in two windows: before the person joined, and recently.
nonisolated struct MetricReading: Sendable {
    var metric: HealthMetric
    var before: Double?
    var recent: Double?

    var hasData: Bool { before != nil || recent != nil }

    /// Direction and size of the change. No "better/worse": the doctor interprets.
    var change: String {
        guard let before, let recent else { return "–" }
        if metric.isCount {
            let diff = Int(recent - before)
            return diff == 0 ? "≈" : diff > 0 ? "↑ \(diff)" : "↓ \(-diff)"
        }
        // A few kilos matter for a heart (fluid retention), so weight changes are shown in kg.
        if metric == .weight {
            let diff = recent - before
            return abs(diff) < 0.5 ? "≈" : String(format: "%@ %.1f kg", diff > 0 ? "↑" : "↓", abs(diff))
        }
        guard before != 0 else { return "–" }
        let percent = (recent - before) / before * 100
        if abs(percent) < 5 { return "≈" }
        return "\(percent > 0 ? "↑" : "↓") \(Int(abs(percent).rounded()))%"
    }
}

nonisolated struct HealthReport: Sendable {
    var readings: [MetricReading]
    /// Age, sex, height, weight and BMI, latest values.
    var body: BodyProfile? = nil
    /// Day-by-day values from 30 days before joining until today, for the charts.
    var trends: [TrendSeries] = []
    /// What each ECG taken on the Watch showed, per window. Nil when ECGs aren't shared.
    var ecg: (before: [ECGResult], recent: [ECGResult])? = nil

    static let beforeDays = 30
    static let recentDays = 7

    /// The 30 days before the person joined, and the last 7 days.
    static func windows(joined: Date, now: Date) -> (before: DateInterval, recent: DateInterval) {
        let day: TimeInterval = 86_400
        return (DateInterval(start: joined.addingTimeInterval(-Double(beforeDays) * day), end: joined),
                DateInterval(start: now.addingTimeInterval(-Double(recentDays) * day), end: now))
    }

    /// Rows with data in at least one window, in the metric's declared order.
    func shown(in section: HealthMetric.Section) -> [MetricReading] {
        readings.filter { $0.metric.section == section && $0.hasData }
    }
}

/// What an Apple Watch ECG recording showed, as the Health app words it.
nonisolated enum ECGResult: String, CaseIterable, Sendable {
    case sinusRhythm = "sinus rhythm", afib = "AFib", highHeartRate = "inconclusive, high heart rate"
    case lowHeartRate = "inconclusive, low heart rate", inconclusive = "inconclusive"

    /// "2 sinus rhythm, 1 AFib", most worrying first so it is not missed; "None" without recordings.
    static func line(_ results: [ECGResult]) -> String {
        let order: [ECGResult] = [.afib, .highHeartRate, .lowHeartRate, .inconclusive, .sinusRhythm]
        let parts = order.compactMap { kind -> String? in
            let n = results.filter { $0 == kind }.count
            return n == 0 ? nil : "\(n) \(kind.rawValue)"
        }
        return parts.isEmpty ? "None" : parts.joined(separator: ", ")
    }
}

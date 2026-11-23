//
//  HealthHistory.swift
//  Hearthware
//
//  Reads the heart and walking history from Apple Health for the doctor summary:
//  the 30 days before the person joined Hearthware against the last 7 days, so the
//  doctor can see the change. Read-only. Anything not shared or not recorded is nil
//  and the row is left out of the summary.
//

import Foundation
import HealthKit

enum HealthHistory {
    static let beforeDays = 30
    static let recentDays = 7

    private static let store = HKHealthStore()
    private static let bpm = HKUnit.count().unitDivided(by: .minute())

    private enum Source {
        case average(HKQuantityTypeIdentifier, HKUnit)
        /// Total in the window divided by its days.
        case perDay(HKQuantityTypeIdentifier, HKUnit)
        case events(HKCategoryTypeIdentifier)
        case ecg
        /// Calculated from systolic and diastolic, not read.
        case derived
    }

    private static func source(_ metric: HealthMetric) -> Source {
        switch metric {
        case .heartRate: .average(.heartRate, bpm)
        case .restingHeartRate: .average(.restingHeartRate, bpm)
        case .walkingHeartRate: .average(.walkingHeartRateAverage, bpm)
        case .heartRateVariability: .average(.heartRateVariabilitySDNN, .secondUnit(with: .milli))
        case .heartRateRecovery: .average(.heartRateRecoveryOneMinute, bpm)
        case .bloodOxygen: .average(.oxygenSaturation, .percent())
        case .systolic: .average(.bloodPressureSystolic, .millimeterOfMercury())
        case .diastolic: .average(.bloodPressureDiastolic, .millimeterOfMercury())
        case .meanArterialPressure: .derived
        case .respiratoryRate: .average(.respiratoryRate, bpm)
        case .vo2Max: .average(.vo2Max, HKUnit(from: "ml/kg*min"))
        case .afibBurden: .average(.atrialFibrillationBurden, .percent())
        case .irregularRhythmAlerts: .events(.irregularHeartRhythmEvent)
        case .highHeartRateAlerts: .events(.highHeartRateEvent)
        case .lowHeartRateAlerts: .events(.lowHeartRateEvent)
        case .ecgRecordings: .ecg
        case .steps: .perDay(.stepCount, .count())
        case .exerciseMinutes: .perDay(.appleExerciseTime, .minute())
        case .flightsClimbed: .perDay(.flightsClimbed, .count())
        case .walkingSpeed: .average(.walkingSpeed, HKUnit.meterUnit(with: .kilo).unitDivided(by: .hour()))
        case .stepLength: .average(.walkingStepLength, .meterUnit(with: .centi))
        case .walkingAsymmetry: .average(.walkingAsymmetryPercentage, .percent())
        case .doubleSupport: .average(.walkingDoubleSupportPercentage, .percent())
        case .walkingSteadiness: .average(.appleWalkingSteadiness, .percent())
        case .sixMinuteWalk: .average(.sixMinuteWalkTestDistance, .meter())
        }
    }

    private static var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.electrocardiogramType()]
        for metric in HealthMetric.allCases {
            switch source(metric) {
            case .average(let id, _), .perDay(let id, _): types.insert(HKQuantityType(id))
            case .events(let id): types.insert(HKCategoryType(id))
            case .ecg, .derived: break
            }
        }
        return types
    }

    /// Asks once for read access (iOS shows the Health sheet only the first time),
    /// then reads both windows. Nil when Health is not available on this device.
    static func report(joined: Date, now: Date = .now) async -> HealthReport? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        try? await store.requestAuthorization(toShare: [], read: readTypes)

        let day: TimeInterval = 86_400
        let before = DateInterval(start: joined.addingTimeInterval(-Double(beforeDays) * day), end: joined)
        let recent = DateInterval(start: now.addingTimeInterval(-Double(recentDays) * day), end: now)

        var values: [HealthMetric: (before: Double?, recent: Double?)] = [:]
        for metric in HealthMetric.allCases where metric != .meanArterialPressure {
            values[metric] = (await value(metric, in: before), await value(metric, in: recent))
        }
        func map(_ s: Double?, _ d: Double?) -> Double? {
            guard let s, let d else { return nil }
            return HealthMetric.meanArterialPressure(systolic: s, diastolic: d)
        }
        values[.meanArterialPressure] = (map(values[.systolic]?.before, values[.diastolic]?.before),
                                         map(values[.systolic]?.recent, values[.diastolic]?.recent))

        return HealthReport(readings: HealthMetric.allCases.map {
            MetricReading(metric: $0, before: values[$0]?.before, recent: values[$0]?.recent)
        })
    }

    private static func value(_ metric: HealthMetric, in window: DateInterval) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end)
        switch source(metric) {
        case .average(let id, let unit):
            let query = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: HKQuantityType(id), predicate: predicate),
                                                    options: .discreteAverage)
            return try? await query.result(for: store)?.averageQuantity()?.doubleValue(for: unit)
        case .perDay(let id, let unit):
            let query = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: HKQuantityType(id), predicate: predicate),
                                                    options: .cumulativeSum)
            guard let total = try? await query.result(for: store)?.sumQuantity()?.doubleValue(for: unit) else { return nil }
            // shortcut: divides by every day in the window, so days without the Watch pull the average down; average only days with data if doctors ask.
            return total / max(window.duration / 86_400, 1)
        case .events(let id):
            let query = HKSampleQueryDescriptor(predicates: [.categorySample(type: HKCategoryType(id), predicate: predicate)],
                                                sortDescriptors: [])
            // Health can't tell "not shared" from "none": with no access this reads as no alerts.
            return (try? await query.result(for: store)).map { Double($0.count) }
        case .ecg:
            let query = HKSampleQueryDescriptor(predicates: [.electrocardiogram(predicate)], sortDescriptors: [])
            return (try? await query.result(for: store)).map { Double($0.count) }
        case .derived:
            return nil
        }
    }
}

//
//  SampleData.swift
//  Hearthware
//
//  Marco's sample story for previews and the demo.
//

import Foundation

extension SavedState {
    static var sample: SavedState {
        let cal = Calendar.current
        let pairs: [(Int, String, Feeling, Feeling, Int, Int)] = [
            (-16, "Climb one floor, slowly", .veryScared, .nervous, 118, 130),
            (-13, "Climb one floor, slowly", .nervous, .littleNervous, 112, 100),
            (-10, "Climb your stairs, slowly", .nervous, .littleNervous, 116, 90),
            (-7, "Climb your stairs, slowly", .littleNervous, .calm, 110, 80),
            (-4, "Climb your stairs, slowly", .littleNervous, .calm, 108, 70),
            (-1, "Climb your stairs twice", .calm, .calm, 104, 65)
        ]
        let records = pairs.map { days, title, before, after, hr, recovery in
            StepRecord(date: cal.date(byAdding: .day, value: days, to: .now) ?? .now,
                       title: title, before: before, after: after, peakHeartRate: hr, recoverySeconds: recovery)
        }
        return SavedState(goal: .stairs, condition: .heartAttack, records: records, hasOnboarded: true)
    }
}

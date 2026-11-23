//
//  StepRecord.swift
//  Hearthware
//
//  One step the person took: how they felt before and after. Stored with SwiftData.
//

import Foundation
import SwiftData

@Model
final class StepRecord {
    var id = UUID()
    var date: Date
    var title: String
    var before: Feeling
    var after: Feeling
    /// Filled by Apple Watch. Only shown in the doctor summary.
    var peakHeartRate: Int?
    var recoverySeconds: Int?

    init(date: Date, title: String, before: Feeling, after: Feeling, peakHeartRate: Int? = nil, recoverySeconds: Int? = nil) {
        self.date = date
        self.title = title
        self.before = before
        self.after = after
        self.peakHeartRate = peakHeartRate
        self.recoverySeconds = recoverySeconds
    }
}

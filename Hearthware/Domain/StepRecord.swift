//
//  StepRecord.swift
//  Hearthware
//
//  One step the person took: how they felt before and after.
//

import Foundation

struct StepRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var title: String
    var before: Feeling
    var after: Feeling
    /// Filled by Apple Watch later. Only shown in the doctor summary.
    var peakHeartRate: Int?
    var recoverySeconds: Int?
}

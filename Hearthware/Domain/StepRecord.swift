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
    /// Optional words the person added to their answer before and after the step.
    var noteBefore: String?
    var noteAfter: String?

    init(date: Date, title: String, before: Feeling, after: Feeling, peakHeartRate: Int? = nil, recoverySeconds: Int? = nil,
         noteBefore: String? = nil, noteAfter: String? = nil) {
        self.date = date
        self.title = title
        self.before = before
        self.after = after
        self.peakHeartRate = peakHeartRate
        self.recoverySeconds = recoverySeconds
        self.noteBefore = noteBefore
        self.noteAfter = noteAfter
    }

    /// Room a row takes in the doctor summary: one line, plus up to two per note.
    static func noteWeight(before: String?, after: String?) -> Int {
        1 + 2 * [before, after].compactMap { $0 }.count
    }
}

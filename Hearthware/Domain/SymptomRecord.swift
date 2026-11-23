//
//  SymptomRecord.swift
//  Hearthware
//
//  Something the person reported from "Not feeling well". Shown only in the doctor summary.
//

import Foundation
import SwiftData

@Model
final class SymptomRecord {
    var date: Date
    var symptom: String
    /// Chest pain or strong breathlessness: the person was sent to call 112.
    var urgent: Bool

    init(date: Date = .now, symptom: String, urgent: Bool) {
        self.date = date
        self.symptom = symptom
        self.urgent = urgent
    }
}

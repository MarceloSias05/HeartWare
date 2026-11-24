//
//  SymptomList.swift
//  Hearthware
//
//  "Not feeling well" choices, the same on the iPhone and the Watch.
//

import Foundation

nonisolated enum SymptomList {
    /// Straight to the emergency number.
    static let urgent = ["Chest pain or pressure", "Very short of breath"]
    /// Noted for the doctor, with a check-in an hour later.
    static let other = ["Dizzy", "More tired than usual", "Something else"]
}

//
//  HeartCondition.swift
//  Hearthware
//
//  What happened to the person's heart.
//

import Foundation

enum HeartCondition: String, CaseIterable, Codable, Identifiable {
    case heartAttack, heartFailure, irregular, surgery, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .heartAttack: "Heart attack"
        case .heartFailure: "Heart failure"
        case .irregular: "Irregular heartbeat"
        case .surgery: "Heart surgery"
        case .other: "Something else"
        }
    }
}

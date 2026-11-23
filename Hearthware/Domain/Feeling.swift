//
//  Feeling.swift
//  Hearthware
//
//  How scared the person feels.
//

import Foundation

/// How scared the person feels. Words only, never a score on screen.
enum Feeling: Int, CaseIterable, Codable, Identifiable {
    case calm = 0, littleNervous, nervous, veryScared

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .calm: "Calm"
        case .littleNervous: "A little nervous"
        case .nervous: "Nervous"
        case .veryScared: "Very scared"
        }
    }
}

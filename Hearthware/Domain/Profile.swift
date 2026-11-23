//
//  Profile.swift
//  Hearthware
//
//  Who the person is, from onboarding. There is only ever one.
//

import Foundation
import SwiftData

@Model
final class Profile {
    var name: String
    var goal: Goal
    /// What the person wrote when the goal is "Something else".
    var customGoal: String?
    var condition: HeartCondition
    var createdAt: Date

    init(name: String, goal: Goal, customGoal: String?, condition: HeartCondition, createdAt: Date = .now) {
        self.name = name
        self.goal = goal
        self.customGoal = customGoal
        self.condition = condition
        self.createdAt = createdAt
    }
}

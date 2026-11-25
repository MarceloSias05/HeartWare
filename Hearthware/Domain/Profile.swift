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
    /// What the person wrote when the condition is "Something else".
    var customCondition: String?
    var createdAt: Date
    /// How they felt about the goal when they joined. Nil for profiles made before this was asked.
    var baselineFear: Feeling?
    /// Beats per minute the doctor said not to pass. Nil when they gave none.
    var heartRateLimit: Int?

    init(name: String, goal: Goal, customGoal: String?, condition: HeartCondition, customCondition: String? = nil,
         baselineFear: Feeling? = nil,
         createdAt: Date = .now) {
        self.name = name
        self.goal = goal
        self.customGoal = customGoal
        self.condition = condition
        self.customCondition = customCondition
        self.baselineFear = baselineFear
        self.createdAt = createdAt
    }

    /// The goal in the person's own words when they chose "Something else".
    var goalTitle: String {
        goal == .other ? (customGoal ?? goal.title) : goal.title
    }

    /// The condition in the person's own words when they chose "Something else".
    var conditionTitle: String {
        condition == .other ? (customCondition ?? condition.title) : condition.title
    }
}

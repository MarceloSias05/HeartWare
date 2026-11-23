//
//  OnboardingInput.swift
//  Hearthware
//
//  What the person types and picks during onboarding, and whether it is enough to continue.
//

import Foundation

struct OnboardingInput {
    var name = ""
    var goal: Goal = .stairs
    var customGoal = ""
    var condition: HeartCondition = .heartAttack

    static let maxNameLength = 40

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var nameIsValid: Bool { (1...Self.maxNameLength).contains(trimmedName.count) }

    /// Only kept when the goal is "Something else"; nil when it is blank.
    var trimmedCustomGoal: String? {
        guard goal == .other else { return nil }
        let text = customGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
    var goalIsValid: Bool { goal != .other || trimmedCustomGoal != nil }
}

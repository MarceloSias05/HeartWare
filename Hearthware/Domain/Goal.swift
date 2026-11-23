//
//  Goal.swift
//  Hearthware
//
//  The part of life the person wants back, and its ladder of small steps.
//

import Foundation

/// The part of life the person wants back.
enum Goal: String, CaseIterable, Codable, Identifiable {
    case stairs, market, grandkids, driving, travelling, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stairs: "Climbing my stairs"
        case .market: "Walking to the market"
        case .grandkids: "Playing with my grandkids"
        case .driving: "Driving again"
        case .travelling: "Travelling"
        case .other: "Something else"
        }
    }

    /// Small steps that grow over time. The first ones are gentle on purpose.
    var steps: [StepIdea] {
        switch self {
        case .stairs:
            [StepIdea(title: "Climb one floor, slowly", hint: "Stop on the landing whenever you want."),
             StepIdea(title: "Climb your stairs, slowly", hint: "Rest at the top before you come down."),
             StepIdea(title: "Climb your stairs twice", hint: "Take a short break in between.")]
        case .market:
            [StepIdea(title: "Walk to the corner and back", hint: "Go at a pace where you can still talk."),
             StepIdea(title: "Walk halfway to the market", hint: "Sit down on a bench if you need to."),
             StepIdea(title: "Walk to the market", hint: "Carry only something light today.")]
        case .grandkids:
            [StepIdea(title: "Sit and play on the floor", hint: "Stand up slowly when you finish."),
             StepIdea(title: "A short walk in the park", hint: "Let them run, you walk."),
             StepIdea(title: "Play in the park for a while", hint: "Rest on a bench whenever you want.")]
        case .driving:
            [StepIdea(title: "Sit in the car for a few minutes", hint: "Just get used to it again.", bigStep: true),
             StepIdea(title: "A short drive around the block", hint: "Bring someone with you.", bigStep: true)]
        case .travelling:
            [StepIdea(title: "Plan a short trip", hint: "Somewhere close and easy to come back from.", bigStep: true),
             StepIdea(title: "Take a flight", hint: "Walk the aisle now and then.", bigStep: true)]
        case .other:
            // Generic ladder for a goal the person wrote themselves.
            [StepIdea(title: "Try it for a few minutes", hint: "Stop whenever you want."),
             StepIdea(title: "Do it a little longer", hint: "Rest whenever you need to."),
             StepIdea(title: "Do it like before", hint: "Take someone with you the first time.")]
        }
    }
}

struct StepIdea: Hashable, Codable {
    var title: String
    var hint: String
    /// Big steps ask the person to check with their doctor first.
    var bigStep: Bool = false
}

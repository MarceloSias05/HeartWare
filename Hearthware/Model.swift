//
//  Model.swift
//  Hearthware
//
//  App state: the goal, the heart condition, and every step the person takes.
//  The patient never sees numbers. Numbers only exist in the doctor summary.
//

import SwiftUI
import Observation

// MARK: - Feeling

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

// MARK: - Goal

/// The part of life the person wants back.
enum Goal: String, CaseIterable, Codable, Identifiable {
    case stairs, market, grandkids, driving, travelling

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stairs: "Climbing my stairs"
        case .market: "Walking to the market"
        case .grandkids: "Playing with my grandkids"
        case .driving: "Driving again"
        case .travelling: "Travelling"
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
        }
    }
}

struct StepIdea: Hashable, Codable {
    var title: String
    var hint: String
    /// Big steps ask the person to check with their doctor first.
    var bigStep: Bool = false
}

// MARK: - Condition

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

// MARK: - Step record

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

// MARK: - App model

@Observable
final class AppModel {
    var name: String = "Marco"
    var goal: Goal? { didSet { save() } }
    var condition: HeartCondition? { didSet { save() } }
    var records: [StepRecord] = [] { didSet { save() } }
    var hasOnboarded: Bool = false { didSet { save() } }

    init(preview: Bool = false) {
        if preview { loadSample(); return }
        load()
    }

    // MARK: Today

    /// Today's suggested step: the next one in the goal's ladder.
    var todayStep: StepIdea {
        let ladder = (goal ?? .stairs).steps
        let done = records.filter { $0.after.rawValue <= Feeling.littleNervous.rawValue }.count
        return ladder[min(done, ladder.count - 1)]
    }

    /// How the body is today, in plain words. Never a number.
    var todayState: (title: String, detail: String, calm: Bool) {
        guard let last = records.last else {
            return ("Ready when you are", "Your first step is a small one. You can stop anytime.", true)
        }
        if last.after.rawValue >= Feeling.nervous.rawValue {
            return ("Taking it easy", "The last step felt hard. Today we keep it gentle.", false)
        }
        return ("Calm today", "Your body is doing well. A little tiredness is normal in the first weeks.", true)
    }

    /// True when fear is lower now than at the start.
    var fearIsShrinking: Bool {
        guard let first = records.first, let last = records.last, records.count > 1 else { return false }
        return last.before.rawValue < first.before.rawValue
    }

    func explanation(for record: StepRecord) -> String {
        let drop = record.before.rawValue - record.after.rawValue
        if drop >= 2 {
            return "Your heart beat faster on the way, like anyone's would, and calmed down quickly when you stopped. It went much better than you expected. That's a good sign."
        } else if drop >= 1 {
            return "Your heart did what a healthy heart does: it worked a bit harder, then settled. It felt easier than you thought."
        } else if record.after.rawValue >= Feeling.nervous.rawValue {
            return "It still felt hard, and that's okay. Fear takes a few tries to get smaller. Next time we'll make the step a bit gentler."
        }
        return "Your heart worked and then settled, just as it should. Every calm step makes the next one easier."
    }

    func log(title: String, before: Feeling, after: Feeling) -> StepRecord {
        let record = StepRecord(date: .now, title: title, before: before, after: after)
        records.append(record)
        return record
    }

    // MARK: Persistence (simple, local only)

    private let key = "hearthware.state.v1"

    private struct Saved: Codable {
        var goal: Goal?
        var condition: HeartCondition?
        var records: [StepRecord]
        var hasOnboarded: Bool
    }

    private func save() {
        let saved = Saved(goal: goal, condition: condition, records: records, hasOnboarded: hasOnboarded)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return }
        goal = saved.goal
        condition = saved.condition
        records = saved.records
        hasOnboarded = saved.hasOnboarded
    }

    /// Sample story for previews and the demo.
    func loadSample() {
        goal = .stairs
        condition = .heartAttack
        hasOnboarded = true
        let cal = Calendar.current
        let pairs: [(Int, String, Feeling, Feeling, Int, Int)] = [
            (-16, "Climb one floor, slowly", .veryScared, .nervous, 118, 130),
            (-13, "Climb one floor, slowly", .nervous, .littleNervous, 112, 100),
            (-10, "Climb your stairs, slowly", .nervous, .littleNervous, 116, 90),
            (-7, "Climb your stairs, slowly", .littleNervous, .calm, 110, 80),
            (-4, "Climb your stairs, slowly", .littleNervous, .calm, 108, 70),
            (-1, "Climb your stairs twice", .calm, .calm, 104, 65)
        ]
        records = pairs.map { days, title, b, a, hr, rec in
            StepRecord(date: cal.date(byAdding: .day, value: days, to: .now) ?? .now,
                       title: title, before: b, after: a, peakHeartRate: hr, recoverySeconds: rec)
        }
    }

    func reset() {
        goal = nil; condition = nil; records = []; hasOnboarded = false
    }
}

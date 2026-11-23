//
//  Coach.swift
//  Hearthware
//
//  The app's rules, as pure functions over the person's records. No UI, no storage,
//  so they can be checked on their own. Words only: numbers never reach the patient.
//

import Foundation

/// How the body is today, in plain words.
struct DayState: Equatable {
    var title: String
    var detail: String
    var calm: Bool
}

enum Coach {
    /// The next step in the goal's ladder: one rung per step that ended calm.
    static func nextStep(goal: Goal?, records: [StepRecord]) -> StepIdea {
        let ladder = (goal ?? .stairs).steps
        let done = records.filter { $0.after.isCalm }.count
        return ladder[min(done, ladder.count - 1)]
    }

    static func dayState(records: [StepRecord]) -> DayState {
        guard let last = records.last else {
            return DayState(title: "Ready when you are", detail: "Your first step is a small one. You can stop anytime.", calm: true)
        }
        if !last.after.isCalm {
            return DayState(title: "Taking it easy", detail: "The last step felt hard. Today we keep it gentle.", calm: false)
        }
        return DayState(title: "Calm today", detail: "Your body is doing well. A little tiredness is normal in the first weeks.", calm: true)
    }

    /// True when fear before a step is lower now than at the start.
    static func fearIsShrinking(records: [StepRecord]) -> Bool {
        guard let first = records.first, let last = records.last, records.count > 1 else { return false }
        return last.before.rawValue < first.before.rawValue
    }

    static func explanation(for record: StepRecord) -> String {
        let drop = record.before.rawValue - record.after.rawValue
        if drop >= 2 {
            return "Your heart beat faster on the way, like anyone's would, and calmed down quickly when you stopped. It went much better than you expected. That's a good sign."
        } else if drop >= 1 {
            return "Your heart did what a healthy heart does: it worked a bit harder, then settled. It felt easier than you thought."
        } else if !record.after.isCalm {
            return "It still felt hard, and that's okay. Fear takes a few tries to get smaller. Next time we'll make the step a bit gentler."
        }
        return "Your heart worked and then settled, just as it should. Every calm step makes the next one easier."
    }
}

extension Feeling {
    /// Calm or a little nervous: the step went well enough to move up the ladder.
    var isCalm: Bool { rawValue <= Feeling.littleNervous.rawValue }
}

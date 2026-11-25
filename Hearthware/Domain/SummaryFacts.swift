//
//  SummaryFacts.swift
//  Hearthware
//
//  The short, plain lines at the top of the doctor summary, and how the pages split.
//  Pure, so it can be checked without the UI.
//

import Foundation

enum SummaryFacts {
    /// How scared the person felt at the start (when they joined, or before their first step)
    /// and before their latest step. Needs two answers.
    static func fearTrend(_ records: [StepRecord], baseline: Feeling? = nil) -> (first: Feeling, last: Feeling)? {
        let answers = (baseline.map { [$0] } ?? []) + records.map(\.before)
        guard answers.count > 1, let first = answers.first, let last = answers.last else { return nil }
        return (first, last)
    }

    /// Which rung of the goal's ladder the next step is on (1-based), out of how many.
    static func ladderPosition(goal: Goal?, records: [StepRecord]) -> (rung: Int, total: Int) {
        let ladder = (goal ?? .stairs).steps
        let next = Coach.nextStep(goal: goal, records: records)
        return ((ladder.firstIndex(of: next) ?? 0) + 1, ladder.count)
    }

    /// Up to three clear Health changes, then fear, then symptoms. Flat changes are left out.
    static func glance(report: HealthReport?, records: [StepRecord], baseline: Feeling? = nil,
                       symptoms: Int, urgentSymptoms: Int) -> [String] {
        let priority: [HealthMetric] = [.steps, .restingHeartRate, .sixMinuteWalk, .walkingSpeed,
                                        .heartRateRecovery, .irregularRhythmAlerts]
        let readings = report?.readings ?? []
        var lines = priority.compactMap { metric -> String? in
            guard let r = readings.first(where: { $0.metric == metric }),
                  let before = r.before, let recent = r.recent,
                  r.change != "≈", r.change != "–" else { return nil }
            return "\(metric.title): \(metric.format(before)) → \(metric.format(recent)) (\(r.change))"
        }
        lines = Array(lines.prefix(3))
        if let fear = fearTrend(records, baseline: baseline) {
            lines.append("Fear before a step: \(fear.first.title) → \(fear.last.title)")
        }
        lines.append(symptoms == 0 ? "No symptoms reported"
                     : "Symptoms reported: \(symptoms)" + (urgentSymptoms > 0 ? " (\(urgentSymptoms) urgent)" : ""))
        return lines
    }

    /// Index ranges of the steps table per page: `first` rows on the first page that has it, `rest` after.
    /// Splits rows into pages by the room each takes (a row with notes takes more). Always one page.
    static func stepPages(weights: [Int], capacity: Int) -> [Range<Int>] {
        var pages: [Range<Int>] = []
        var start = 0, used = 0
        for (i, w) in weights.enumerated() {
            if used + w > capacity && i > start {
                pages.append(start..<i)
                start = i
                used = 0
            }
            used += w
        }
        pages.append(start..<weights.count)
        return pages
    }

    /// The facts handed to the on-device model. Only what the PDF already shows, so nothing new can appear.
    static func narrativePrompt(name: String, condition: String, goal: String, daysInApp: Int,
                                ladder: (rung: Int, total: Int), stepsLogged: Int,
                                facts: [String], symptoms: [String], body: String? = nil) -> String {
        var lines = [
            "Patient: \(name). Condition: \(condition). Personal goal: \(goal).",
            body.map { "From Apple Health: \($0)." } ?? "Age and sex: unknown.",
            "Using Steady for \(daysInApp) days. \(stepsLogged) small exposure steps logged; now at step \(ladder.rung) of \(ladder.total) towards the goal.",
        ]
        lines += facts.map { "- \($0)" }
        lines.append(symptoms.isEmpty ? "Symptoms reported: none." : "Symptoms reported:\n" + symptoms.map { "- \($0)" }.joined(separator: "\n"))
        return lines.joined(separator: "\n")
    }

    /// True when every number in the model's text also appears in the facts it was given.
    /// Catches invented values, like an age the app never asked for.
    static func isGrounded(_ text: String, in prompt: String) -> Bool {
        func numbers(_ s: String) -> Set<String> {
            let number = try! Regex(#"\d[\d,]*(?:\.\d+)?"#)
            return Set(s.matches(of: number).map { s[$0.range].replacingOccurrences(of: ",", with: "") })
        }
        return numbers(text).isSubset(of: numbers(prompt))
    }
}

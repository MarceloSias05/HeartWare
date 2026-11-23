//
//  SummaryFacts.swift
//  Hearthware
//
//  The short, plain lines at the top of the doctor summary, and how the pages split.
//  Pure, so it can be checked without the UI.
//

import Foundation

enum SummaryFacts {
    /// How scared the person felt before their first step, and before their latest one.
    static func fearTrend(_ records: [StepRecord]) -> (first: Feeling, last: Feeling)? {
        guard records.count > 1, let first = records.first, let last = records.last else { return nil }
        return (first.before, last.before)
    }

    /// Which rung of the goal's ladder the next step is on (1-based), out of how many.
    static func ladderPosition(goal: Goal?, records: [StepRecord]) -> (rung: Int, total: Int) {
        let ladder = (goal ?? .stairs).steps
        let next = Coach.nextStep(goal: goal, records: records)
        return ((ladder.firstIndex(of: next) ?? 0) + 1, ladder.count)
    }

    /// Up to three clear Health changes, then fear, then symptoms. Flat changes are left out.
    static func glance(report: HealthReport?, records: [StepRecord], symptoms: Int, urgentSymptoms: Int) -> [String] {
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
        if let fear = fearTrend(records) {
            lines.append("Fear before a step: \(fear.first.title) → \(fear.last.title)")
        }
        lines.append(symptoms == 0 ? "No symptoms reported"
                     : "Symptoms reported: \(symptoms)" + (urgentSymptoms > 0 ? " (\(urgentSymptoms) urgent)" : ""))
        return lines
    }

    /// Index ranges of the steps table per page: `first` rows on the first page that has it, `rest` after.
    static func stepPages(count: Int, first: Int, rest: Int) -> [Range<Int>] {
        var pages = [0..<min(count, first)]
        var start = pages[0].upperBound
        while start < count {
            pages.append(start..<min(count, start + rest))
            start += rest
        }
        return pages
    }
}

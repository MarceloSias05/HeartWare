//
//  AppModel.swift
//  Hearthware
//
//  The single source of truth the views observe. Reads the profile and steps from
//  SwiftData, exposes the Coach's answers, and is the only place that writes.
//

import Foundation
import Observation
import SwiftData

@MainActor @Observable
final class AppModel {
    /// Kept so the container outlives the context (a context does not retain it).
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private(set) var profile: Profile?
    private(set) var records: [StepRecord] = []
    private(set) var symptoms: [SymptomRecord] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    // MARK: Read

    var hasOnboarded: Bool { profile != nil }
    var name: String { profile?.name ?? "" }
    var goal: Goal? { profile?.goal }
    var goalTitle: String? { profile?.goalTitle }
    var condition: HeartCondition? { profile?.condition }
    var conditionTitle: String? { profile?.conditionTitle }

    var todayStep: StepIdea { Coach.nextStep(goal: goal, records: records) }
    var todayState: DayState { Coach.dayState(records: records) }
    var fearIsShrinking: Bool { Coach.fearIsShrinking(records: records) }
    func explanation(for record: StepRecord) -> String { Coach.explanation(for: record) }

    // MARK: Intents

    func completeOnboarding(name: String, goal: Goal, customGoal: String?, condition: HeartCondition,
                            customCondition: String? = nil, baselineFear: Feeling? = nil) {
        context.insert(Profile(name: name, goal: goal, customGoal: customGoal, condition: condition,
                               customCondition: customCondition, baselineFear: baselineFear))
        save()
    }

    @discardableResult
    func log(title: String, before: Feeling, after: Feeling, watch: WatchResult? = nil,
             noteBefore: String? = nil, noteAfter: String? = nil) -> StepRecord {
        func clean(_ note: String?) -> String? {
            let text = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return text.isEmpty ? nil : text
        }
        let record = StepRecord(date: .now, title: title, before: before, after: after,
                                peakHeartRate: watch?.peakHeartRate, recoverySeconds: watch?.recoverySeconds,
                                noteBefore: clean(noteBefore), noteAfter: clean(noteAfter))
        context.insert(record)
        save()
        return record
    }

    func logSymptom(_ symptom: String, urgent: Bool) {
        context.insert(SymptomRecord(symptom: symptom, urgent: urgent))
        save()
    }

    // MARK: Storage

    private func save() {
        do { try context.save() } catch { assertionFailure("Could not save: \(error)") }
        reload()
    }

    private func reload() {
        profile = (try? context.fetch(FetchDescriptor<Profile>(sortBy: [SortDescriptor(\.createdAt)])))?.last
        records = (try? context.fetch(FetchDescriptor<StepRecord>(sortBy: [SortDescriptor(\.date)]))) ?? []
        symptoms = (try? context.fetch(FetchDescriptor<SymptomRecord>(sortBy: [SortDescriptor(\.date)]))) ?? []
    }
}

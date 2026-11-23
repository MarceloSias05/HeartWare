//
//  AppModel.swift
//  Hearthware
//
//  The single source of truth the views observe. Holds the state, exposes the
//  Coach's answers, and is the only place that changes or saves anything.
//

import Observation
import Foundation

@Observable
final class AppModel {
    var name: String = "Marco"
    private(set) var state: SavedState { didSet { store?.save(state) } }

    /// nil = nothing is saved (previews, demo).
    private let store: StateStore?

    init(store: StateStore? = StateStore()) {
        self.store = store
        self.state = store?.load() ?? SavedState()
    }

    /// In-memory model for previews: never touches the real saved story.
    static func preview(sample: Bool = true) -> AppModel {
        let model = AppModel(store: nil)
        if sample { model.state = .sample }
        return model
    }

    // MARK: Read

    var goal: Goal? { state.goal }
    var condition: HeartCondition? { state.condition }
    var records: [StepRecord] { state.records }
    var hasOnboarded: Bool { state.hasOnboarded }

    var todayStep: StepIdea { Coach.nextStep(goal: state.goal, records: state.records) }
    var todayState: DayState { Coach.dayState(records: state.records) }
    var fearIsShrinking: Bool { Coach.fearIsShrinking(records: state.records) }
    func explanation(for record: StepRecord) -> String { Coach.explanation(for: record) }

    // MARK: Intents

    func completeOnboarding(goal: Goal, condition: HeartCondition) {
        state.goal = goal
        state.condition = condition
        state.hasOnboarded = true
    }

    @discardableResult
    func log(title: String, before: Feeling, after: Feeling) -> StepRecord {
        let record = StepRecord(date: .now, title: title, before: before, after: after)
        state.records.append(record)
        return record
    }
}

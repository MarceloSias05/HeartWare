// Self-check for the Coach rules and saved-state compatibility. Run: Checks/run.sh
import Foundation
func r(_ b: Feeling, _ a: Feeling) -> StepRecord { StepRecord(date: .now, title: "t", before: b, after: a) }
precondition(Coach.nextStep(goal: .stairs, records: []) == Goal.stairs.steps[0])
precondition(Coach.nextStep(goal: .stairs, records: [r(.nervous, .calm), r(.nervous, .veryScared)]) == Goal.stairs.steps[1])
precondition(Coach.nextStep(goal: .driving, records: Array(repeating: r(.calm, .calm), count: 9)) == Goal.driving.steps.last!) // ladder caps
precondition(Coach.dayState(records: []).title == "Ready when you are")
precondition(!Coach.dayState(records: [r(.calm, .nervous)]).calm)
precondition(Coach.fearIsShrinking(records: SavedState.sample.records))
precondition(!Coach.fearIsShrinking(records: [r(.calm, .calm)]))
// old v1 JSON still decodes
let v1 = #"{"goal":"market","condition":"surgery","records":[],"hasOnboarded":true}"#.data(using: .utf8)!
let s = try! JSONDecoder().decode(SavedState.self, from: v1); precondition(s.goal == .market && s.hasOnboarded)
print("coach checks OK")

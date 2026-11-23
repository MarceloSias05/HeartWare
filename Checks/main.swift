// Checks for Domain + Data (Coach rules, SwiftData model, onboarding input). Run: Checks/run.sh
// shortcut: plain asserts instead of Swift Testing, move to a HearthwareTests target (plan B1) when it exists.
import Foundation
import SwiftData

var failures = 0
func check(_ ok: Bool, _ name: String) { if !ok { failures += 1; print("FAIL", name) } }
func r(_ b: Feeling, _ a: Feeling) -> StepRecord { StepRecord(date: .now, title: "t", before: b, after: a) }

// Coach
check(Coach.nextStep(goal: .stairs, records: []) == Goal.stairs.steps[0], "nextStepStartsAtFirstRung")
check(Coach.nextStep(goal: .stairs, records: [r(.nervous, .calm), r(.nervous, .veryScared)]) == Goal.stairs.steps[1], "nextStepClimbsOnlyOnCalmSteps")
check(Coach.nextStep(goal: .driving, records: (0..<9).map { _ in r(.calm, .calm) }) == Goal.driving.steps.last!, "nextStepCapsAtLastRung")
check(Coach.dayState(records: []).title == "Ready when you are", "dayStateWithoutRecords")
check(!Coach.dayState(records: [r(.calm, .nervous)]).calm, "dayStateAfterHardStep")
check(Coach.fearIsShrinking(records: [r(.veryScared, .nervous), r(.calm, .calm)]), "fearShrinksWhenLastBeforeIsLower")
check(!Coach.fearIsShrinking(records: [r(.calm, .calm)]), "fearNotShrinkingWithOneRecord")

// AppModel + SwiftData
MainActor.assumeIsolated {
    let m = AppModel(container: .empty)
    check(!m.hasOnboarded && m.records.isEmpty && m.name == "", "startsEmpty")

    let o = AppModel(container: .empty)
    o.completeOnboarding(name: "Ana", goal: .market, customGoal: nil, condition: .surgery)
    check(o.hasOnboarded && o.name == "Ana" && o.condition == .surgery && o.goal == .market, "onboardingCreatesProfile")

    let c = ModelContainer.empty
    AppModel(container: c).log(title: "Walk", before: .nervous, after: .calm)
    check((try? ModelContext(c).fetch(FetchDescriptor<StepRecord>()))?.map(\.title) == ["Walk"], "stepIsSavedToStore")

    let s = AppModel(container: .empty)
    s.log(title: "a", before: .calm, after: .calm); s.log(title: "b", before: .calm, after: .calm)
    check(s.records.map(\.title) == ["a", "b"], "recordsAreOldestFirst")
}

print(failures == 0 ? "all checks OK" : "\(failures) check(s) failed")
exit(failures == 0 ? 0 : 1)

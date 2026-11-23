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

// Onboarding input
check(!OnboardingInput(name: "   ").nameIsValid, "blankNameIsInvalid")
check(OnboardingInput(name: "  Ana \n").trimmedName == "Ana", "nameIsTrimmed")
check(!OnboardingInput(name: String(repeating: "a", count: 41)).nameIsValid, "longNameIsInvalid")
check(OnboardingInput(name: "Ana").nameIsValid, "normalNameIsValid")
check(!OnboardingInput(goal: .other, customGoal: "  ").goalIsValid, "otherGoalNeedsText")
check(OnboardingInput(goal: .other, customGoal: " Gardening ").trimmedCustomGoal == "Gardening", "otherGoalKeepsTrimmedText")
check(OnboardingInput(goal: .market, customGoal: "x").trimmedCustomGoal == nil, "listedGoalIgnoresText")
check(Goal.other.steps.first?.title == "Try it for a few minutes", "otherGoalHasGenericLadder")
check(Profile(name: "A", goal: .other, customGoal: "Gardening", condition: .other).goalTitle == "Gardening", "goalTitleUsesCustomText")
check(Profile(name: "A", goal: .market, customGoal: nil, condition: .other).goalTitle == Goal.market.title, "goalTitleForListedGoal")

// Watch result + recovery
let end0 = Date(timeIntervalSince1970: 0)
check(Recovery.seconds(baseline: 80, endedAt: end0, samples: [(end0 + 30, 120), (end0 + 65, 88), (end0 + 90, 80)]) == 65, "recoveryFirstSampleBackNearBaseline")
check(Recovery.seconds(baseline: 80, endedAt: end0, samples: [(end0 + 60, 110), (end0 + 130, 82)]) == nil, "recoveryNilWhenNeverBackInWindow")
let end100 = Date(timeIntervalSince1970: 100)
check(Recovery.seconds(baseline: 80, endedAt: end100, samples: [(end100 - 5, 81), (end100 + 40, 85)]) == 40, "recoveryIgnoresSamplesBeforeEnd")
check(Recovery.seconds(baseline: 80, endedAt: end0, samples: []) == nil, "recoveryNilWithoutSamples")
let wr = WatchResult(peakHeartRate: 112, recoverySeconds: 65)
check((try? JSONDecoder().decode(WatchResult.self, from: JSONEncoder().encode(wr))) == wr, "watchResultRoundTripsJSON")

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

    let wm = AppModel(container: .empty)  // keep the model (and its container) alive while reading the record
    let w = wm.log(title: "t", before: .nervous, after: .calm, watch: WatchResult(peakHeartRate: 112, recoverySeconds: 65))
    check(w.peakHeartRate == 112 && w.recoverySeconds == 65, "logStoresWatchValues")
    let nwm = AppModel(container: .empty)
    let nw = nwm.log(title: "t", before: .nervous, after: .calm)
    check(nw.peakHeartRate == nil && nw.recoverySeconds == nil, "logWithoutWatchLeavesNil")
}

print(failures == 0 ? "all checks OK" : "\(failures) check(s) failed")
exit(failures == 0 ? 0 : 1)

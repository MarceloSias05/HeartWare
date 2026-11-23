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
check(WatchMessage.result(from: WatchMessage.resultPayload(step: "s1", result: wr))?.step == "s1", "resultPayloadKeepsStep")
check(WatchMessage.result(from: WatchMessage.resultPayload(step: "s1", result: wr))?.result == wr, "resultPayloadKeepsValues")
check(WatchMessage.result(from: ["kind": "cancel"]) == nil, "cancelIsNotAResult")
check(WatchMessage.result(from: ["kind": "result", "step": "s1", "result": Data("x".utf8)]) == nil, "garbageResultIsIgnored")
check(WatchMessage.start(from: WatchMessage.startContext(step: "s2", title: "Walk")).map { "\($0.step)|\($0.title)" } == "s2|Walk", "startContextRoundTrips")

// Health history (pure part)
check(HealthMetric.restingHeartRate.format(61.4) == "61 bpm", "formatBpm")
check(HealthMetric.bloodOxygen.format(0.972) == "97%", "formatPercentFromFraction")
check(HealthMetric.walkingSpeed.format(4.53) == "4.5 km/h", "formatSpeedOneDecimal")
check(HealthMetric.steps.format(4512.6) == "4,513 /day", "formatStepsPerDay")
check(HealthMetric.irregularRhythmAlerts.format(0) == "None", "formatZeroAlerts")
check(abs(HealthMetric.meanArterialPressure(systolic: 120, diastolic: 80) - 93.33) < 0.01, "meanArterialPressure")
check(MetricReading(metric: .steps, before: 2000, recent: 4500).change == "↑ 125%", "changeUp")
check(MetricReading(metric: .restingHeartRate, before: 80, recent: 70).change == "↓ 13%", "changeDown")
check(MetricReading(metric: .restingHeartRate, before: 80, recent: 81).change == "≈", "changeSmallIsFlat")
check(MetricReading(metric: .steps, before: nil, recent: 4500).change == "–", "changeNeedsBoth")
check(MetricReading(metric: .irregularRhythmAlerts, before: 0, recent: 2).change == "↑ 2", "alertChangeIsCount")
check(MetricReading(metric: .steps, before: nil, recent: nil).hasData == false, "noDataBothWindows")
let rep = HealthReport(readings: [MetricReading(metric: .steps, before: 1, recent: 2), MetricReading(metric: .walkingSpeed, before: nil, recent: nil), MetricReading(metric: .restingHeartRate, before: 70, recent: nil)])
check(rep.shown(in: .heart).map(\.metric) == [.restingHeartRate] && rep.shown(in: .movement).map(\.metric) == [.steps], "reportHidesEmptyRowsAndSplitsSections")
check(HealthMetric.allCases.filter { $0.section == .heart }.first == .heartRate, "heartSectionFirst")

// Summary facts
let rs = [r(.veryScared, .nervous), r(.nervous, .calm), r(.calm, .calm)]
check(SummaryFacts.fearTrend(rs).map { "\($0.first)|\($0.last)" } == "veryScared|calm", "fearTrendFirstAndLastBefore")
check(SummaryFacts.fearTrend([r(.calm, .calm)]) == nil, "fearTrendNeedsTwoSteps")
check(SummaryFacts.ladderPosition(goal: .stairs, records: []) == (1, 3), "ladderStartsAtOne")
check(SummaryFacts.ladderPosition(goal: .stairs, records: rs) == (3, 3), "ladderCountsCalmSteps")
check(SummaryFacts.ladderPosition(goal: .driving, records: rs + rs) == (2, 2), "ladderCapsAtTop")
let gl = SummaryFacts.glance(report: HealthReport(readings: [
    MetricReading(metric: .restingHeartRate, before: 74, recent: 66),
    MetricReading(metric: .steps, before: 2100, recent: 4520),
    MetricReading(metric: .walkingSpeed, before: 4.0, recent: 4.1),
    MetricReading(metric: .irregularRhythmAlerts, before: 2, recent: 0)]), records: rs, symptoms: 3, urgentSymptoms: 1)
check(gl.first == "Steps: 2,100 /day → 4,520 /day (↑ 115%)", "glanceStepsFirst")
check(gl.contains("Resting heart rate: 74 bpm → 66 bpm (↓ 11%)"), "glanceRestingHR")
check(!gl.contains { $0.hasPrefix("Walking speed") }, "glanceSkipsFlatChanges")
check(gl.contains("Irregular rhythm alerts: 2 → None (↓ 2)"), "glanceAlerts")
check(gl.contains("Fear before a step: Very scared → Calm"), "glanceFear")
check(gl.last == "Symptoms reported: 3 (1 urgent)", "glanceSymptoms")
check(SummaryFacts.glance(report: nil, records: [], symptoms: 0, urgentSymptoms: 0) == ["No symptoms reported"], "glanceEmpty")
let joined = Date(timeIntervalSince1970: 1_000_000_000), nowD = joined.addingTimeInterval(20 * 86_400)
let win = HealthReport.windows(joined: joined, now: nowD)
check(win.before.end == joined && win.before.duration == 30 * 86_400, "beforeWindowEndsAtJoin")
check(win.recent.end == nowD && win.recent.duration == 7 * 86_400, "recentWindowIsLastWeek")
check(SummaryFacts.stepPages(count: 0, first: 25, rest: 40) == [0..<0], "stepPagesEmptyStillOnePage")
check(SummaryFacts.stepPages(count: 30, first: 25, rest: 40) == [0..<25, 25..<30], "stepPagesSplit")
check(SummaryFacts.stepPages(count: 90, first: 25, rest: 40) == [0..<25, 25..<65, 65..<90], "stepPagesMany")

// Trends for charts
check(HealthMetric.bloodOxygen.chartValue(0.97) == 97, "chartPercentIsTimes100")
check(HealthMetric.steps.chartValue(4512) == 4512, "chartValueOtherwiseSame")
check(HealthMetric.bloodOxygen.chartUnit == "%" && HealthMetric.restingHeartRate.chartUnit == "bpm", "chartUnits")
check(Feeling.calm.chartLevel == 3 && Feeling.veryScared.chartLevel == 0, "calmIsTopOfFearChart")
let d0 = Date(timeIntervalSince1970: 0)
let series = [TrendSeries(metric: .steps, points: [TrendPoint(date: d0, value: 1), TrendPoint(date: d0 + 86_400, value: 2)]),
              TrendSeries(metric: .restingHeartRate, points: [TrendPoint(date: d0, value: 70)]),
              TrendSeries(metric: .systolic, points: [TrendPoint(date: d0, value: 120), TrendPoint(date: d0 + 86_400, value: 118)]),
              TrendSeries(metric: .diastolic, points: [TrendPoint(date: d0, value: 80), TrendPoint(date: d0 + 86_400, value: 79)])]
let cards = TrendCharts.cards(series)
check(cards.map { $0.map(\.metric) } == [[.steps], [.systolic, .diastolic]], "cardsNeedTwoPointsAndKeepGroups")
check(TrendCharts.metrics.contains(.systolic) && TrendCharts.metrics.contains(.diastolic), "chartMetricsIncludeBloodPressure")

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

    let sm = AppModel(container: .empty)
    sm.logSymptom("Dizzy", urgent: false); sm.logSymptom("Chest pain or pressure", urgent: true)
    check(sm.symptoms.map(\.symptom) == ["Dizzy", "Chest pain or pressure"] && sm.symptoms.last?.urgent == true, "symptomsAreSavedOldestFirst")
}

print(failures == 0 ? "all checks OK" : "\(failures) check(s) failed")
exit(failures == 0 ? 0 : 1)

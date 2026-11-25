//
//  StepWorkout.swift
//  HearthwareWatch Watch App
//
//  One step as a HealthKit workout: keeps the person company with a soft tap every
//  minute, tracks the peak heart rate, then listens during the rest to measure how
//  long the heart takes to settle. Without HealthKit permission it still keeps
//  company and sends an empty result.
//

import Foundation
import HealthKit
import Observation
import WatchKit

@MainActor @Observable
final class StepWorkout: NSObject {
    enum Phase { case idle, moving, resting }

    private(set) var phase: Phase = .idle
    private(set) var title = ""
    /// Past the doctor's limit right now. Always false without a limit.
    private(set) var overLimit = false
    /// Called once per finished step with its id and what was measured.
    var onFinish: ((_ step: String, _ result: WatchResult) -> Void)?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var step: String?
    private var limit: Int?
    private var samples: [(date: Date, bpm: Double)] = []
    private var endedAt: Date?
    private var timers: [Task<Void, Never>] = []

    func start(step: String, title: String, limit: Int?) async {
        guard phase == .idle else { return }
        self.step = step
        self.title = title
        self.limit = limit
        samples = []
        endedAt = nil
        phase = .moving
        await authorize()
        await beginWorkout()
        timers.append(Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                if phase == .moving, !Task.isCancelled { WKInterfaceDevice.current().play(.click) }
            }
        })
    }

    func endStep() {
        guard phase == .moving else { return }
        endedAt = .now
        phase = .resting
        overLimit = false
        stopTimers()
        WKInterfaceDevice.current().play(.success)
        timers.append(Task {
            try? await Task.sleep(for: .seconds(Recovery.window))
            if !Task.isCancelled { doneResting() }
        })
    }

    func doneResting() {
        guard phase == .resting, let step else { return }
        let result = makeResult()
        finishWorkout(save: true)
        reset()
        onFinish?(step, result)
    }

    /// The iPhone closed the step: stop without saving or sending anything.
    func cancel(step: String) {
        guard step == self.step else { return }
        finishWorkout(save: false)
        reset()
    }

    /// If the app was killed mid-step, HealthKit keeps the session alive. End it.
    func endOrphanedSession() async {
        if let orphan = try? await store.recoverActiveWorkoutSession() { orphan.end() }
    }

    // MARK: Result

    private func makeResult() -> WatchResult {
        guard let endedAt, let baseline = samples.first?.bpm else { return WatchResult() }
        let peak = samples.filter { $0.date <= endedAt }.map(\.bpm).max()
        return WatchResult(peakHeartRate: peak.map { Int($0.rounded()) },
                           recoverySeconds: Recovery.seconds(baseline: baseline, endedAt: endedAt, samples: samples))
    }

    // MARK: HealthKit

    private func authorize() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await store.requestAuthorization(toShare: [HKObjectType.workoutType()],
                                              read: [HKQuantityType(.heartRate)])
    }

    private func beginWorkout() async {
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        guard let session = try? HKWorkoutSession(healthStore: store, configuration: config) else { return }
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
        builder.delegate = self
        self.session = session
        self.builder = builder
        session.startActivity(with: .now)
        try? await builder.beginCollection(at: .now)
    }

    private func finishWorkout(save: Bool) {
        guard let session, let builder else { return }
        session.end()
        Task {
            try? await builder.endCollection(at: .now)
            if save { _ = try? await builder.finishWorkout() } else { builder.discardWorkout() }
        }
    }

    private func stopTimers() {
        timers.forEach { $0.cancel() }
        timers = []
    }

    private func reset() {
        stopTimers()
        session = nil
        builder = nil
        step = nil
        limit = nil
        overLimit = false
        phase = .idle
    }

    fileprivate func add(bpm: Double, at date: Date) {
        samples.append((date, bpm))
        guard phase == .moving else { return }
        let over = HeartLimit.isOver(bpm: bpm, limit: limit, wasOver: overLimit)
        if over && !overLimit { WKInterfaceDevice.current().play(.notification) }
        overLimit = over
    }
}

extension StepWorkout: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRate = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRate),
              let stats = workoutBuilder.statistics(for: heartRate),
              let quantity = stats.mostRecentQuantity(),
              let date = stats.mostRecentQuantityDateInterval()?.end else { return }
        let bpm = quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        Task { @MainActor in add(bpm: bpm, at: date) }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

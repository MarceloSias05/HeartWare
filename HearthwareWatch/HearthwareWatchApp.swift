//
//  HearthwareWatchApp.swift
//  HearthwareWatch
//
//  The Watch keeps the person company during a step and measures how the heart
//  responded. The iPhone owns all data; the Watch only sends back one WatchResult.
//

import HealthKit
import SwiftUI
import WatchKit

@main
struct HearthwareWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchAppDelegate

    var body: some Scene {
        WindowGroup {
            WatchStepView()
                .environment(delegate.workout)
        }
    }
}

/// The iPhone opens the Watch app through HealthKit (`startWatchApp`), which lands here.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    let workout = StepWorkout()
    private let phone = PhoneLink()

    func applicationDidFinishLaunching() {
        phone.activate(workout: workout)
        Task { await workout.endOrphanedSession() }
    }

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task {
            // The title arrives as application context just before the launch.
            guard let (step, title) = phone.pendingStep() else { return }
            await workout.start(step: step, title: title)
        }
    }
}

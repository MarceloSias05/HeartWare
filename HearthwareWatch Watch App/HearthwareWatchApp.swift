//
//  HearthwareWatchApp.swift
//  HearthwareWatch Watch App
//
//  The whole app on the wrist: today's step with how you feel before and after
//  (Digital Crown), "Not feeling well", and company during a step started from the
//  iPhone. The iPhone owns all data; the Watch sends it what happened.
//

import HealthKit
import SwiftUI
import WatchKit

@main
struct HearthwareWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchAppDelegate

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(delegate.workout)
                .environment(delegate.store)
        }
    }
}

/// The iPhone opens the Watch app through HealthKit (`startWatchApp`), which lands here.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    let workout = StepWorkout()
    let store = WatchStore()
    private let phone = PhoneLink()

    func applicationDidFinishLaunching() {
        phone.activate(workout: workout, store: store)
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

//
//  RootView.swift
//  Hearthware
//
//  Two tabs only: Today and Your story. Help is always one tap away from Today.
//  The tab bar and toolbar buttons get Liquid Glass from the system.
//

import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.hasOnboarded {
            TabView {
                Tab("Today", systemImage: "sun.max") {
                    TodayView()
                }
                Tab("Your story", systemImage: "book.closed") {
                    NavigationStack { StoryView() }
                }
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview("App") {
    RootView()
        .environment(AppModel.preview())
}

#Preview("Onboarding") {
    RootView()
        .environment(AppModel.preview(sample: false))
}

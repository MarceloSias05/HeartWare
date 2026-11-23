//
//  ContentView.swift
//  Hearthware
//
//  Two tabs only: Today and Your story. Help is always one tap away from Today.
//  The tab bar and toolbar buttons get Liquid Glass from the system.
//

import SwiftUI

struct ContentView: View {
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
    ContentView()
        .environment(AppModel(preview: true))
}

#Preview("Onboarding") {
    ContentView()
        .environment(AppModel(preview: false))
}

//
//  HearthwareApp.swift
//  Hearthware
//
//  Created by Guillermo Lira on 23/11/2026.
//

import SwiftUI
import SwiftData

@main
struct HearthwareApp: App {
    @State private var model: AppModel
    @State private var watchLink = WatchLink()

    init() {
        // try! on purpose: without its store the app cannot do anything useful.
        let container = try! ModelContainer(for: Profile.self, StepRecord.self)
        _model = State(initialValue: AppModel(container: container))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(watchLink)
                .task { watchLink.activate() }
        }
    }
}

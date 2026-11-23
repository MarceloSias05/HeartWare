//
//  HearthwareApp.swift
//  Hearthware
//
//  Created by Guillermo Lira on 23/11/2026.
//

import SwiftUI

@main
struct HearthwareApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}

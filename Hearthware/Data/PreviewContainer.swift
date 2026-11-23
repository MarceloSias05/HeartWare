//
//  PreviewContainer.swift
//  Hearthware
//
//  An empty in-memory store for previews and checks. Never touches the real data.
//

import SwiftData

extension ModelContainer {
    @MainActor static var empty: ModelContainer {
        // try! is fine: an in-memory container with these two models cannot fail to open.
        try! ModelContainer(for: Profile.self, StepRecord.self,
                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}

//
//  StateStore.swift
//  Hearthware
//
//  Saves the person's progress on the device. Local only, nothing leaves the phone.
//

import Foundation

/// Everything the app needs to remember between launches.
struct SavedState: Codable {
    var goal: Goal?
    var condition: HeartCondition?
    var records: [StepRecord] = []
    var hasOnboarded = false
}

struct StateStore {
    var defaults: UserDefaults = .standard
    // Same key as v1 so existing installs keep their story.
    var key = "hearthware.state.v1"

    func load() -> SavedState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedState.self, from: data)
    }

    func save(_ state: SavedState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}

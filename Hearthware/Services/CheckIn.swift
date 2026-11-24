//
//  CheckIn.swift
//  Hearthware
//
//  The gentle check-in an hour after the person reports a symptom.
//  If notifications are off, nothing is scheduled; the symptom is still saved.
//

import UserNotifications

enum CheckIn {
    static let delay: TimeInterval = 3600

    static func schedule(after symptom: String) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling now?"
        content.body = "An hour ago you said: \(symptom.lowercased()). If it hasn't gone away, open Heartware."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "checkin-\(UUID().uuidString)", content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false))
        try? await center.add(request)
    }
}

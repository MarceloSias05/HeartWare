//
//  BodyProfile.swift
//  Hearthware
//
//  Age, sex, height and weight from Apple Health, for the top of the doctor summary.
//  Pure: Services/HealthHistory.swift reads them. Anything missing is nil and left out.
//

import Foundation

nonisolated struct BodyProfile: Sendable, Equatable {
    var age: Int?
    var sex: String?
    var heightCm: Double?
    var weightKg: Double?

    /// kg / m², from the latest weight and height.
    var bmi: Double? {
        guard let weightKg, let heightCm, heightCm > 0 else { return nil }
        return weightKg / pow(heightCm / 100, 2)
    }

    /// "52 years · Male · 175 cm · 82 kg · BMI 26.8", only with what exists; nil when nothing does.
    var line: String? {
        let parts = [
            age.map { "\($0) years" },
            sex,
            heightCm.map { "\(Int($0.rounded())) cm" },
            weightKg.map { "\(Int($0.rounded())) kg" },
            bmi.map { String(format: "BMI %.1f", $0) },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func age(birth: DateComponents, now: Date, calendar: Calendar = .current) -> Int? {
        guard birth.year != nil, let born = calendar.date(from: birth) else { return nil }
        return calendar.dateComponents([.year], from: born, to: now).year
    }
}

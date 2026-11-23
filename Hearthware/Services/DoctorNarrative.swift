//
//  DoctorNarrative.swift
//  Hearthware
//
//  The opening paragraph of the doctor summary, written on device by Apple
//  Intelligence (Foundation Models) from the facts the PDF already shows.
//  Nil when the model isn't available (older device, Apple Intelligence off);
//  the PDF then simply has no paragraph.
//

import Foundation
import FoundationModels

enum DoctorNarrative {
    private static let instructions = """
        You write the opening paragraph of a patient summary for a cardiologist.
        Use only the facts given. Never invent numbers, dates or symptoms.
        Do not diagnose, do not recommend treatment, do not say whether a change is good or bad.
        Third person, plain clinical English, 3 or 4 sentences, under 90 words. No headings, no lists.
        """

    static func write(_ prompt: String) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let session = LanguageModelSession(instructions: instructions)
        let response = try? await session.respond(to: prompt, options: GenerationOptions(temperature: 0.2))
        return response?.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

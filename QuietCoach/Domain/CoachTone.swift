// CoachTone.swift
// QuietCoach
//
// Defines the coaching voice used for feedback and emphasis.

import Foundation

enum CoachTone: String, CaseIterable, Identifiable, Codable, Sendable {
    case gentle
    case direct
    case executive

    static let `default` = CoachTone.gentle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: return "Gentle"
        case .direct: return "Direct"
        case .executive: return "Executive"
        }
    }

    var description: String {
        switch self {
        case .gentle:
            return "Supportive, calm phrasing with softer prompts."
        case .direct:
            return "Concise coaching with clear, actionable direction."
        case .executive:
            return "Crisp, professional language focused on authority."
        }
    }

    var weightBias: ScoringProfile.ScoreWeights {
        switch self {
        case .gentle:
            return .init(clarity: 1.05, pacing: 0.95, tone: 1.1, confidence: 0.95)
        case .direct:
            return .init(clarity: 1.0, pacing: 1.1, tone: 0.9, confidence: 1.1)
        case .executive:
            return .init(clarity: 1.15, pacing: 1.0, tone: 0.95, confidence: 1.15)
        }
    }
}

enum CoachToneSettings {
    static var current: CoachTone {
        let rawValue = UserDefaults.standard.string(forKey: Constants.SettingsKeys.coachTone)
        return CoachTone(rawValue: rawValue ?? CoachTone.default.rawValue) ?? .default
    }
}

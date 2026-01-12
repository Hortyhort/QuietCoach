// FeedbackScores.swift
// QuietCoach
//
// The four dimensions of delivery feedback.
// Each score is 0-100, computed from audio metrics.

import Foundation

struct FeedbackScores: Codable, Hashable {

    // MARK: - Scores

    /// How clearly ideas are separated (pause patterns)
    let clarity: Int

    /// Speaking rhythm (segments per minute)
    let pacing: Int

    /// Volume consistency (stability, spike control)
    let tone: Int

    /// Overall presence (volume level, consistency)
    let confidence: Int

    // MARK: - Computed Properties

    /// Average of all four scores
    var overall: Int {
        (clarity + pacing + tone + confidence) / 4
    }

    /// The highest scoring dimension
    var primaryStrength: ScoreType {
        let scores: [(ScoreType, Int)] = [
            (.clarity, clarity),
            (.pacing, pacing),
            (.tone, tone),
            (.confidence, confidence)
        ]
        return scores.max(by: { $0.1 < $1.1 })?.0 ?? .clarity
    }

    /// The lowest scoring dimension
    var primaryWeakness: ScoreType {
        let scores: [(ScoreType, Int)] = [
            (.clarity, clarity),
            (.pacing, pacing),
            (.tone, tone),
            (.confidence, confidence)
        ]
        return scores.min(by: { $0.1 < $1.1 })?.0 ?? .clarity
    }

    /// Weighted strength used for scenario emphasis
    func weightedStrength(using weights: ScoringProfile.ScoreWeights) -> ScoreType {
        let weighted: [(ScoreType, Double)] = [
            (.clarity, Double(clarity) * weights.clarity),
            (.pacing, Double(pacing) * weights.pacing),
            (.tone, Double(tone) * weights.tone),
            (.confidence, Double(confidence) * weights.confidence)
        ]
        return weighted.max(by: { $0.1 < $1.1 })?.0 ?? .clarity
    }

    /// Weighted weakness used for scenario emphasis
    func weightedWeakness(using weights: ScoringProfile.ScoreWeights) -> ScoreType {
        let weighted: [(ScoreType, Double)] = [
            (.clarity, Double(clarity) * weights.clarity),
            (.pacing, Double(pacing) * weights.pacing),
            (.tone, Double(tone) * weights.tone),
            (.confidence, Double(confidence) * weights.confidence)
        ]
        return weighted.min(by: { $0.1 < $1.1 })?.0 ?? .clarity
    }

    /// Quality tier based on overall score
    var tier: Tier {
        switch overall {
        case 85...100: return .excellent
        case 70..<85: return .good
        case 55..<70: return .developing
        default: return .needsWork
        }
    }

    // MARK: - Types

    enum ScoreType: String, CaseIterable, Codable {
        case clarity = "Clarity"
        case pacing = "Pacing"
        case tone = "Tone"
        case confidence = "Confidence"

        var icon: String {
            switch self {
            case .clarity: return "text.alignleft"
            case .pacing: return "metronome"
            case .tone: return "waveform"
            case .confidence: return "bolt.fill"
            }
        }

        var explanation: String {
            switch self {
            case .clarity:
                return "Based on pause patterns and silence. Clear speakers pause intentionally."
            case .pacing:
                return "Based on rhythm—phrases per minute. Too fast or slow affects your score."
            case .tone:
                return "Based on volume stability. Consistent volume sounds calm and controlled."
            case .confidence:
                return "Based on volume level and consistency. Steady delivery sounds assured."
            }
        }
    }

    enum Tier: String {
        case excellent = "Excellent"
        case good = "Good"
        case developing = "Developing"
        case needsWork = "Needs Work"

        var emoji: String {
            switch self {
            case .excellent: return "✨"
            case .good: return "👍"
            case .developing: return "📈"
            case .needsWork: return "💪"
            }
        }
    }

    // MARK: - Comparison

    /// Calculate change from a previous score
    func delta(from previous: FeedbackScores?) -> ScoreDelta? {
        guard let previous else { return nil }
        return ScoreDelta(
            clarity: clarity - previous.clarity,
            pacing: pacing - previous.pacing,
            tone: tone - previous.tone,
            confidence: confidence - previous.confidence
        )
    }

    // MARK: - Factories

    static let empty = FeedbackScores(
        clarity: 0,
        pacing: 0,
        tone: 0,
        confidence: 0
    )

    #if DEBUG
    /// Create mock scores for testing
    static func mock(overall targetOverall: Int = 75) -> FeedbackScores {
        let variance = 10
        return FeedbackScores(
            clarity: clamp(targetOverall + Int.random(in: -variance...variance)),
            pacing: clamp(targetOverall + Int.random(in: -variance...variance)),
            tone: clamp(targetOverall + Int.random(in: -variance...variance)),
            confidence: clamp(targetOverall + Int.random(in: -variance...variance))
        )
    }

    private static func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }
    #endif
}

// MARK: - Score Delta

struct ScoreDelta: Codable {
    let clarity: Int
    let pacing: Int
    let tone: Int
    let confidence: Int

    var overall: Int {
        (clarity + pacing + tone + confidence) / 4
    }

    var hasImprovement: Bool {
        clarity > 0 || pacing > 0 || tone > 0 || confidence > 0
    }

    var hasDecline: Bool {
        clarity < 0 || pacing < 0 || tone < 0 || confidence < 0
    }

    /// Formatted string for display (e.g., "+5" or "-3")
    func formatted(_ value: Int) -> String {
        if value > 0 {
            return "+\(value)"
        } else {
            return "\(value)"
        }
    }
}

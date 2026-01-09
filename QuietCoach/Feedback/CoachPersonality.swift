// CoachPersonality.swift
// QuietCoach
//
// The coach has a voice — warm, direct, encouraging.
// Not metrics. Insights. Not data. Wisdom.

import Foundation

// MARK: - Coach Personality

/// Transforms raw metrics into human, encouraging feedback
enum CoachPersonality {

    // MARK: - Score Interpretations

    /// Human interpretation of overall score
    static func interpret(score: Int) -> String {
        switch score {
        case 95...100:
            return "That was exceptional. You found your voice."
        case 90..<95:
            return "Powerful delivery. You meant every word."
        case 85..<90:
            return "Strong and clear. You're ready."
        case 80..<85:
            return "Confident and grounded. This is progress."
        case 75..<80:
            return "You're finding your rhythm."
        case 70..<75:
            return "Solid foundation. Let's build on it."
        case 65..<70:
            return "Good start. The clarity is coming."
        case 60..<65:
            return "You showed up. That matters."
        case 50..<60:
            return "Every practice counts. Keep going."
        default:
            return "This is where growth begins."
        }
    }

    /// Emoji for score (tasteful, not childish)
    static func emoji(for score: Int) -> String {
        switch score {
        case 90...100: return "✦"
        case 80..<90: return "◆"
        case 70..<80: return "●"
        case 60..<70: return "○"
        default: return "·"
        }
    }

    // MARK: - Metric-Specific Feedback

    /// Clarity feedback
    static func clarityFeedback(score: Int, metrics: ClarityMetrics?) -> String {
        switch score {
        case 85...100:
            return "Crystal clear. Every word landed."
        case 75..<85:
            return "Good clarity. Your message came through."
        case 65..<75:
            if let metrics = metrics, metrics.fillerWordCount > 5 {
                return "Some filler words crept in. That's normal when we're thinking out loud."
            }
            return "Mostly clear. A bit of polish will sharpen it."
        case 50..<65:
            return "The core message is there. Let's uncover it together."
        default:
            return "Finding the right words takes practice. You're doing it."
        }
    }

    /// Pacing feedback
    static func pacingFeedback(score: Int, metrics: PacingMetrics?) -> String {
        switch score {
        case 85...100:
            return "Perfect rhythm. You let your words breathe."
        case 75..<85:
            return "Good pacing. Your pauses had purpose."
        case 65..<75:
            if let metrics = metrics, metrics.averageWordsPerMinute > 160 {
                return "You rushed through some key moments. Those deserve more space."
            } else if let metrics = metrics, metrics.averageWordsPerMinute < 100 {
                return "A bit slow in places. Trust your words — they're ready."
            }
            return "Finding your natural rhythm. It's getting there."
        case 50..<65:
            return "Pacing takes practice. Notice where you want to slow down."
        default:
            return "Speed isn't the goal. Presence is."
        }
    }

    /// Tone feedback
    static func toneFeedback(score: Int, scenario: Scenario?) -> String {
        let scenarioContext = scenario?.toneGuidance ?? "this conversation"

        switch score {
        case 85...100:
            return "Your tone matched your message perfectly."
        case 75..<85:
            return "Good tonal balance. You sounded like yourself."
        case 65..<75:
            return "Your tone is developing. For \(scenarioContext), a touch more steadiness helps."
        case 50..<65:
            return "Finding the right tone takes time. You're learning what works."
        default:
            return "Your authentic voice is in there. Let's find it."
        }
    }

    /// Confidence feedback
    static func confidenceFeedback(score: Int, metrics: ConfidenceMetrics?) -> String {
        switch score {
        case 85...100:
            return "You sounded like you believed every word. Because you did."
        case 75..<85:
            return "Confident delivery. You showed up fully."
        case 65..<75:
            if let metrics = metrics, metrics.hesitationCount > 3 {
                return "Some hesitation is natural. But you know what you want to say."
            }
            return "Growing confidence. It's building with each practice."
        case 50..<65:
            return "Confidence is a skill, not a feeling. You're training it."
        default:
            return "Even showing up to practice takes courage. You did that."
        }
    }

    // MARK: - Coaching Notes

    /// Generate a primary coaching note based on the session
    static func primaryNote(
        scores: FeedbackScores,
        scenario: Scenario?,
        metrics: AudioMetrics?
    ) -> CoachingNote {
        // Find the area with most room for improvement
        let lowestScore = min(scores.clarity, scores.pacing, scores.tone, scores.confidence)

        if lowestScore == scores.pacing {
            return CoachingNote(
                title: "On pacing",
                body: pacingAdvice(score: scores.pacing),
                type: .pacing,
                priority: lowestScore < 70 ? .high : .medium
            )
        } else if lowestScore == scores.clarity {
            return CoachingNote(
                title: "On clarity",
                body: clarityAdvice(score: scores.clarity),
                type: .clarity,
                priority: lowestScore < 70 ? .high : .medium
            )
        } else if lowestScore == scores.confidence {
            return CoachingNote(
                title: "On confidence",
                body: confidenceAdvice(score: scores.confidence),
                type: .confidence,
                priority: lowestScore < 70 ? .high : .medium
            )
        } else {
            return CoachingNote(
                title: "On tone",
                body: toneAdvice(score: scores.tone, scenario: scenario),
                type: .tone,
                priority: lowestScore < 70 ? .high : .medium
            )
        }
    }

    /// Generate scenario-specific advice
    static func scenarioNote(scenario: Scenario, scores: FeedbackScores) -> CoachingNote {
        CoachingNote(
            title: "For this conversation",
            body: scenario.coachingAdvice(for: scores),
            type: .scenario,
            priority: .high
        )
    }

    // MARK: - Specific Advice

    private static func pacingAdvice(score: Int) -> String {
        switch score {
        case 85...100:
            return "Your pacing was excellent. Keep trusting those pauses."
        case 75..<85:
            return "Try adding a pause after your key point. Let it land before moving on."
        case 65..<75:
            return "Slow down at the important moments. Rush the rest if you need to, but own your main point."
        case 50..<65:
            return "Take a breath before your main message. That pause isn't empty — it's powerful."
        default:
            return "Start slower than feels natural. You'll find your rhythm."
        }
    }

    private static func clarityAdvice(score: Int) -> String {
        switch score {
        case 85...100:
            return "Every word counted. That's the goal."
        case 75..<85:
            return "Cut your first sentence. Start with the second one — that's usually the real message."
        case 65..<75:
            return "Ask yourself: what's the one thing they need to hear? Lead with that."
        case 50..<65:
            return "Simplify. If you can say it in fewer words, do."
        default:
            return "What do you actually want? Start there. The words will follow."
        }
    }

    private static func confidenceAdvice(score: Int) -> String {
        switch score {
        case 85...100:
            return "That conviction was real. You've earned it."
        case 75..<85:
            return "Stand behind your words. You said them for a reason."
        case 65..<75:
            return "Drop the qualifiers. 'I think' and 'maybe' dilute your message."
        case 50..<65:
            return "Your needs are valid. Practice saying them like you believe that."
        default:
            return "Confidence isn't about being certain. It's about being present. You were here."
        }
    }

    private static func toneAdvice(score: Int, scenario: Scenario?) -> String {
        let context = scenario?.toneGuidance ?? "being direct while staying warm"

        switch score {
        case 85...100:
            return "Your tone was spot-on. Authentic and appropriate."
        case 75..<85:
            return "Good balance. For \(context), you found the right register."
        case 65..<75:
            return "Tone is tricky. Aim for \(context) — firm but not hard."
        case 50..<65:
            return "Think about how you want them to feel. Your tone carries that."
        default:
            return "Your natural voice is your best tool. Let it come through."
        }
    }

    // MARK: - Try Again Focus

    /// Generate a focused goal for the next attempt
    static func tryAgainFocus(scores: FeedbackScores, scenario: Scenario?) -> TryAgainPrompt {
        let lowestScore = min(scores.clarity, scores.pacing, scores.tone, scores.confidence)

        if lowestScore == scores.pacing && scores.pacing < 80 {
            return TryAgainPrompt(
                goal: "Pause after your main point this time.",
                reason: "That moment of silence gives your words weight."
            )
        } else if lowestScore == scores.clarity && scores.clarity < 80 {
            return TryAgainPrompt(
                goal: "State your main point in the first sentence.",
                reason: "Opening with clarity sets up everything that follows."
            )
        } else if lowestScore == scores.confidence && scores.confidence < 80 {
            return TryAgainPrompt(
                goal: "Say it like you mean it. Because you do.",
                reason: "You've already practiced the words. Now own them."
            )
        } else if lowestScore == scores.tone && scores.tone < 80 {
            return TryAgainPrompt(
                goal: "Match your tone to your intention.",
                reason: "How you say it shapes how they hear it."
            )
        } else if scores.overall >= 85 {
            return TryAgainPrompt(
                goal: "See if you can make it feel even more natural.",
                reason: "You're ready. This is about refinement now."
            )
        } else {
            return TryAgainPrompt(
                goal: "Focus on one thing: saying what you need.",
                reason: "Everything else will follow from that."
            )
        }
    }

    // MARK: - Celebration Messages

    /// Messages for achievements and milestones
    static func celebrationMessage(for milestone: Milestone) -> String {
        switch milestone {
        case .firstRecording:
            return "Your first practice. You showed up. That's everything."
        case .weekStreak:
            return "Seven days. A habit is forming. You're changing."
        case .improved20Points:
            return "20 points higher. That's not luck — that's work."
        case .hundredSessions:
            return "100 sessions. You've built something real."
        case .personalBest:
            return "New personal best. You just surprised yourself."
        case .consistentPractice:
            return "Consistency beats intensity. You're proof."
        }
    }

    enum Milestone {
        case firstRecording
        case weekStreak
        case improved20Points
        case hundredSessions
        case personalBest
        case consistentPractice
    }
}

// MARK: - Supporting Types

struct CoachingNote {
    let title: String
    let body: String
    let type: NoteType
    let priority: Priority

    enum NoteType {
        case scenario
        case clarity
        case pacing
        case tone
        case confidence
        case general
    }

    enum Priority {
        case high
        case medium
        case low
    }
}

struct TryAgainPrompt {
    let goal: String
    let reason: String
}

struct ClarityMetrics {
    let fillerWordCount: Int
    let averageSentenceLength: Double
}

struct PacingMetrics {
    let averageWordsPerMinute: Double
    let pauseCount: Int
    let longestPause: TimeInterval
}

struct ConfidenceMetrics {
    let hesitationCount: Int
    let volumeConsistency: Float
    let uptalkInstances: Int
}

// MARK: - Scenario Extensions

extension Scenario {
    var toneGuidance: String {
        switch id {
        case "set-boundary", "say-no":
            return "being firm but not aggressive"
        case "give-feedback":
            return "being honest but kind"
        case "ask-raise", "negotiate":
            return "being confident but collaborative"
        case "apologize":
            return "being sincere without over-explaining"
        case "difficult-news":
            return "being direct but compassionate"
        default:
            return "being authentic"
        }
    }

    func coachingAdvice(for scores: FeedbackScores) -> String {
        switch id {
        case "set-boundary":
            if scores.confidence < 75 {
                return "Boundaries aren't requests. State yours like a fact."
            } else if scores.clarity < 75 {
                return "Be specific about what you need. Vague boundaries get ignored."
            }
            return "Good boundary-setting. Clear, firm, respectful."

        case "say-no":
            if scores.clarity < 75 {
                return "'No' is a complete sentence. You don't owe an explanation."
            } else if scores.tone < 75 {
                return "You can be warm and still say no. They're not opposites."
            }
            return "Clean 'no'. No apology, no justification. Just the truth."

        case "give-feedback":
            if scores.tone < 75 {
                return "Feedback lands better when you sound like you're on their side."
            } else if scores.clarity < 75 {
                return "Be specific. 'You did X, and the impact was Y.' That's the formula."
            }
            return "Honest and kind. That's hard to do. You did it."

        case "ask-raise":
            if scores.confidence < 75 {
                return "You're not asking for a favor. You're stating your value."
            } else if scores.pacing < 75 {
                return "Don't rush to fill silence. Let them respond."
            }
            return "You made your case clearly. That's what matters."

        default:
            return "You practiced what you needed to say. That's the hard part."
        }
    }
}

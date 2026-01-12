// CoachNotesEngine.swift
// QuietCoach
//
// Generates concise coaching notes and the Try Again focus.
// Output is intentionally minimal: one win, one change, one next step.

import Foundation

struct CoachNotesEngine {

    // MARK: - Note Generation

    static func generateNotes(
        metrics: AudioMetrics,
        scores: FeedbackScores,
        scenario: Scenario,
        profile: ScoringProfile = .default,
        baseline: BaselineMetrics? = nil,
        coachTone: CoachTone = .default
    ) -> [CoachNote] {
        let analyzed = AudioMetricsAnalyzer.analyze(metrics, profile: profile)
        let strength = scores.weightedStrength(using: profile.weights)
        let weakness = scores.weightedWeakness(using: profile.weights)

        let winNote = generateWinNote(
            strength: strength,
            metrics: analyzed,
            scenario: scenario,
            baseline: baseline,
            profile: profile,
            coachTone: coachTone
        )

        let changeNote = generateChangeNote(
            weakness: weakness,
            metrics: analyzed,
            scores: scores,
            profile: profile,
            coachTone: coachTone
        )

        return [winNote, changeNote]
    }

    static func generateNotes(
        metrics: AudioMetrics,
        scores: FeedbackScores,
        scenario: Scenario,
        speechAnalysis: SpeechAnalysisResult,
        profile: ScoringProfile = .default,
        baseline: BaselineMetrics? = nil,
        coachTone: CoachTone = .default
    ) -> [CoachNote] {
        let analyzed = AudioMetricsAnalyzer.analyze(metrics, profile: profile)
        let strength = scores.weightedStrength(using: profile.weights)
        let weakness = scores.weightedWeakness(using: profile.weights)

        let winNote = generateWinNote(
            strength: strength,
            metrics: analyzed,
            scenario: scenario,
            baseline: baseline,
            profile: profile,
            coachTone: coachTone
        )

        let changeNote = generateChangeNote(
            weakness: weakness,
            metrics: analyzed,
            scores: scores,
            profile: profile,
            speechAnalysis: speechAnalysis,
            coachTone: coachTone
        )

        return [winNote, changeNote]
    }

    // MARK: - Try Again Focus

    static func generateTryAgainFocus(
        scores: FeedbackScores,
        scenario: Scenario,
        insights: [String],
        profile: ScoringProfile = .default,
        coachTone: CoachTone = .default
    ) -> TryAgainFocus {
        if let firstInsight = insights.first, !firstInsight.contains("Great job") {
            let focus = TryAgainFocus(
                goal: firstInsight,
                reason: "This was identified from your speech patterns."
            )
            return adjustedFocus(focus, coachTone: coachTone)
        }

        return generateTryAgainFocus(
            scores: scores,
            scenario: scenario,
            profile: profile,
            coachTone: coachTone
        )
    }

    static func generateTryAgainFocus(
        scores: FeedbackScores,
        scenario: Scenario,
        profile: ScoringProfile = .default,
        coachTone: CoachTone = .default
    ) -> TryAgainFocus {
        let weakness = scores.weightedWeakness(using: profile.weights)

        switch weakness {
        case .clarity:
            let focus = TryAgainFocus(
                goal: "State your main point in the first sentence.",
                reason: "Opening with clarity sets up everything that follows."
            )
            return adjustedFocus(focus, coachTone: coachTone)

        case .pacing:
            if scores.pacing < 60 {
                let focus = TryAgainFocus(
                    goal: "Add a deliberate pause after your key ask.",
                    reason: "Pauses give weight to what you just said."
                )
                return adjustedFocus(focus, coachTone: coachTone)
            } else {
                let focus = TryAgainFocus(
                    goal: "Try speaking at 80% of your natural speed.",
                    reason: "Slightly slower sounds more confident and controlled."
                )
                return adjustedFocus(focus, coachTone: coachTone)
            }

        case .tone:
            let focus = TryAgainFocus(
                goal: "Keep your volume steady throughout.",
                reason: "Consistent tone signals calm control."
            )
            return adjustedFocus(focus, coachTone: coachTone)

        case .confidence:
            let focus = TryAgainFocus(
                goal: "Start louder than feels natural.",
                reason: "We often underestimate how quiet we sound to others."
            )
            return adjustedFocus(focus, coachTone: coachTone)
        }
    }

    // MARK: - Win Notes

    private static func generateWinNote(
        strength: FeedbackScores.ScoreType,
        metrics: AnalyzedMetrics,
        scenario: Scenario,
        baseline: BaselineMetrics?,
        profile: ScoringProfile,
        coachTone: CoachTone
    ) -> CoachNote {
        let baselineText = baselineWinNote(
            strength: strength,
            metrics: metrics,
            baseline: baseline,
            profile: profile
        )

        let body: String
        switch strength {
        case .clarity:
            body = adjustedWin(
                baselineText ?? "Your pauses felt intentional and clear.",
                coachTone: coachTone
            )
        case .pacing:
            body = adjustedWin(
                baselineText ?? "Your pacing stayed steady and easy to follow.",
                coachTone: coachTone
            )
        case .tone:
            body = adjustedWin(
                baselineText ?? "Your tone sounded calm and controlled.",
                coachTone: coachTone
            )
        case .confidence:
            body = adjustedWin(
                baselineText ?? "You projected with confidence.",
                coachTone: coachTone
            )
        }

        return CoachNote(
            title: "What worked",
            body: body,
            type: .general,
            priority: .high
        )
    }

    private static func baselineWinNote(
        strength: FeedbackScores.ScoreType,
        metrics: AnalyzedMetrics,
        baseline: BaselineMetrics?,
        profile: ScoringProfile
    ) -> String? {
        guard let baseline else { return nil }

        switch strength {
        case .clarity:
            if let silenceBaseline = baseline.silenceRatio,
               metrics.silenceRatio < silenceBaseline - 0.05 {
                return "You left less empty space than your recent sessions."
            }
        case .pacing:
            if let baselineSegments = baseline.segmentsPerMinute {
                let currentDistance = distanceToRange(metrics.segmentsPerMinute, range: profile.audio.pacingOptimalRange)
                let baselineDistance = distanceToRange(baselineSegments, range: profile.audio.pacingOptimalRange)
                if currentDistance + 1 < baselineDistance {
                    return "Your pacing moved closer to an ideal rhythm."
                }
            }
        case .tone:
            if let baselineStability = baseline.volumeStability,
               metrics.volumeStability > baselineStability + 0.05 {
                return "Your volume felt steadier than your recent sessions."
            }
        case .confidence:
            if let baselineLevel = baseline.averageLevel,
               metrics.averageLevel > baselineLevel + 0.05 {
                return "You projected more than your recent sessions."
            }
        }

        return nil
    }

    // MARK: - Change Notes

    private static func generateChangeNote(
        weakness: FeedbackScores.ScoreType,
        metrics: AnalyzedMetrics,
        scores: FeedbackScores,
        profile: ScoringProfile,
        speechAnalysis: SpeechAnalysisResult? = nil,
        coachTone: CoachTone
    ) -> CoachNote {
        if let speechAnalysis {
            if speechAnalysis.clarity.fillerWordCount > profile.nlp.insightFillerWordCountThreshold {
                let topFillers = speechAnalysis.clarity.fillerWords.prefix(2).joined(separator: ", ")
                return CoachNote(
                    title: "What to change",
                    body: adjustedChange(
                        "Replace fillers like '\(topFillers)' with a short pause.",
                        coachTone: coachTone
                    ),
                    type: .general,
                    priority: .high
                )
            }

            if speechAnalysis.confidence.hedgingPhraseCount > profile.nlp.insightHedgingPhraseCountThreshold {
                return CoachNote(
                    title: "What to change",
                    body: adjustedChange(
                        "Drop hedging phrases. Say the ask directly.",
                        coachTone: coachTone
                    ),
                    type: .general,
                    priority: .high
                )
            }
        }

        switch weakness {
        case .clarity:
            return CoachNote(
                title: "What to change",
                body: toneCopy(
                    gentle: "Try leading with your main point before the context.",
                    direct: "Lead with your main point before context.",
                    executive: "Lead with the main point before context.",
                    coachTone: coachTone
                ),
                type: .general,
                priority: .high
            )
        case .pacing:
            if metrics.isPacingTooFast {
                return CoachNote(
                    title: "What to change",
                    body: toneCopy(
                        gentle: "Try slowing down right at the ask so it can land.",
                        direct: "Slow down right at the ask. Give it room to land.",
                        executive: "Slow down at the ask; let it land.",
                        coachTone: coachTone
                    ),
                    type: .pacing,
                    priority: .high
                )
            }
            if metrics.isPacingTooSlow {
                return CoachNote(
                    title: "What to change",
                    body: toneCopy(
                        gentle: "Add a bit of pace between thoughts to keep momentum.",
                        direct: "Pick up the pace between thoughts to keep momentum.",
                        executive: "Increase pace between thoughts to keep momentum.",
                        coachTone: coachTone
                    ),
                    type: .pacing,
                    priority: .high
                )
            }
            return CoachNote(
                title: "What to change",
                body: toneCopy(
                    gentle: "Try adding a deliberate pause after your key line.",
                    direct: "Add a deliberate pause after your key line.",
                    executive: "Add a deliberate pause after the key line.",
                    coachTone: coachTone
                ),
                type: .pacing,
                priority: .high
            )
        case .tone:
            if metrics.hasTooManySpikes {
                return CoachNote(
                    title: "What to change",
                    body: toneCopy(
                        gentle: "Try keeping your volume even on the most important line.",
                        direct: "Keep your volume even on the most important line.",
                        executive: "Keep volume even on the key line.",
                        coachTone: coachTone
                    ),
                    type: .intensity,
                    priority: .high
                )
            }
            return CoachNote(
                title: "What to change",
                body: toneCopy(
                    gentle: "Aim for a steadier volume from start to finish.",
                    direct: "Aim for a steadier volume from start to finish.",
                    executive: "Keep volume steady from start to finish.",
                    coachTone: coachTone
                ),
                type: .intensity,
                priority: .high
            )
        case .confidence:
            if metrics.isTooQuiet {
                return CoachNote(
                    title: "What to change",
                    body: toneCopy(
                        gentle: "Start a touch louder than feels natural.",
                        direct: "Start louder than feels natural.",
                        executive: "Start louder than feels natural.",
                        coachTone: coachTone
                    ),
                    type: .general,
                    priority: .high
                )
            }
            return CoachNote(
                title: "What to change",
                body: toneCopy(
                    gentle: "Hold your volume steady through the end.",
                    direct: "Hold your volume steady through the end.",
                    executive: "Hold volume steady through the end.",
                    coachTone: coachTone
                ),
                type: .general,
                priority: .high
            )
        }
    }

    private static func adjustedWin(_ text: String, coachTone: CoachTone) -> String {
        switch coachTone {
        case .gentle:
            return "Nice work. \(text)"
        case .direct:
            return text
        case .executive:
            return "Outcome: \(text)"
        }
    }

    private static func adjustedChange(_ text: String, coachTone: CoachTone) -> String {
        switch coachTone {
        case .gentle:
            if text.lowercased().hasPrefix("try") {
                return text
            }
            return "Try to \(lowercasedFirst(text))"
        case .direct:
            return text
        case .executive:
            return "Recommendation: \(text)"
        }
    }

    private static func adjustedFocus(_ focus: TryAgainFocus, coachTone: CoachTone) -> TryAgainFocus {
        switch coachTone {
        case .gentle:
            return TryAgainFocus(
                goal: "Try: \(focus.goal)",
                reason: focus.reason
            )
        case .direct:
            return focus
        case .executive:
            return TryAgainFocus(
                goal: "Next: \(focus.goal)",
                reason: focus.reason
            )
        }
    }

    private static func toneCopy(
        gentle: String,
        direct: String,
        executive: String,
        coachTone: CoachTone
    ) -> String {
        switch coachTone {
        case .gentle:
            return gentle
        case .direct:
            return direct
        case .executive:
            return executive
        }
    }

    private static func lowercasedFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return String(first).lowercased() + text.dropFirst()
    }

    private static func distanceToRange(_ value: Float, range: ClosedRange<Float>) -> Float {
        if range.contains(value) {
            return 0
        }
        if value < range.lowerBound {
            return range.lowerBound - value
        }
        return value - range.upperBound
    }
}

// MARK: - Scenario-Specific Coaching

extension CoachNotesEngine {

    static func categoryTips(for category: Scenario.Category) -> [String] {
        switch category {
        case .boundaries:
            return [
                "State your boundary clearly, without apologizing.",
                "Use 'I need' instead of 'I think' or 'Maybe'.",
                "Silence after your boundary is okay. Let it land."
            ]

        case .career:
            return [
                "Lead with your contributions, not your needs.",
                "Use specific numbers and examples when possible.",
                "End with a clear ask and wait for a response."
            ]

        case .relationships:
            return [
                "Share how you feel, not what they did wrong.",
                "Use 'I' statements throughout.",
                "Leave space for their response."
            ]

        case .difficult:
            return [
                "Say the hard part first. Don't bury the lede.",
                "Be direct but not harsh.",
                "Acknowledge that this is difficult."
            ]
        }
    }
}

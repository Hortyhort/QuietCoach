// CoachNotesEngine.swift
// QuietCoach
//
// Generates actionable coaching notes from metrics and scores.
// We limit to 2-3 notes to avoid overwhelming. Each note is specific and brief.

import Foundation

struct CoachNotesEngine {

    // MARK: - Note Generation

    /// Generate coaching notes from metrics, scores, and scenario
    static func generateNotes(
        metrics: AudioMetrics,
        scores: FeedbackScores,
        scenario: Scenario
    ) -> [CoachNote] {
        var notes: [CoachNote] = []
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // 1. Always include scenario-specific coaching hint
        notes.append(CoachNote(
            title: "For this conversation",
            body: scenario.coachingHint,
            type: .scenario,
            priority: .high
        ))

        // 2. Add pacing note if needed
        if let pacingNote = generatePacingNote(analyzed, score: scores.pacing) {
            notes.append(pacingNote)
        }

        // 3. Add tone/intensity note if needed
        if let toneNote = generateToneNote(analyzed, score: scores.tone) {
            notes.append(toneNote)
        }

        // 4. Add confidence note if needed
        if let confidenceNote = generateConfidenceNote(analyzed, score: scores.confidence) {
            notes.append(confidenceNote)
        }

        // Sort by priority (high first) and limit to 3
        notes.sort { $0.priority > $1.priority }
        return Array(notes.prefix(3))
    }

    // MARK: - Try Again Focus

    /// Generate a single focus goal for the next attempt
    static func generateTryAgainFocus(
        scores: FeedbackScores,
        scenario: Scenario
    ) -> TryAgainFocus {
        // Focus on the weakest area
        switch scores.primaryWeakness {
        case .clarity:
            return TryAgainFocus(
                goal: "State your main point in the first sentence.",
                reason: "Opening with clarity sets up everything that follows."
            )

        case .pacing:
            if scores.pacing < 60 {
                return TryAgainFocus(
                    goal: "Add a deliberate pause after your key ask.",
                    reason: "Pauses give weight to what you just said."
                )
            } else {
                return TryAgainFocus(
                    goal: "Try speaking at 80% of your natural speed.",
                    reason: "Slightly slower sounds more confident and controlled."
                )
            }

        case .tone:
            return TryAgainFocus(
                goal: "Keep your volume steady throughout.",
                reason: "Consistent tone signals calm control."
            )

        case .confidence:
            return TryAgainFocus(
                goal: "Start louder than feels natural.",
                reason: "We often underestimate how quiet we sound to others."
            )
        }
    }

    // MARK: - Pacing Notes

    private static func generatePacingNote(
        _ metrics: AnalyzedMetrics,
        score: Int
    ) -> CoachNote? {
        guard score < 80 else { return nil }

        let priority: CoachNote.Priority = score < 60 ? .high : .medium

        if metrics.isPacingTooFast {
            return CoachNote(
                title: "Slow down slightly",
                body: "Try adding a breath between thoughts. Let your words land before moving on.",
                type: .pacing,
                priority: priority
            )
        }

        if metrics.isPacingTooSlow {
            return CoachNote(
                title: "Pick up the pace",
                body: "Keep the momentum going while being deliberate. Silence is okay, but don't lose your listener.",
                type: .pacing,
                priority: priority
            )
        }

        if metrics.pauseCount < 2 && metrics.duration > 30 {
            return CoachNote(
                title: "Add strategic pauses",
                body: "Pauses after key points give them impact. Try pausing right after your main ask.",
                type: .pacing,
                priority: .medium
            )
        }

        return nil
    }

    // MARK: - Tone Notes

    private static func generateToneNote(
        _ metrics: AnalyzedMetrics,
        score: Int
    ) -> CoachNote? {
        guard score < 80 else { return nil }

        let priority: CoachNote.Priority = score < 60 ? .high : .medium

        if metrics.hasTooManySpikes {
            return CoachNote(
                title: "Smooth out intensity spikes",
                body: "Try to stay even, especially on key points. Calm is powerful.",
                type: .intensity,
                priority: priority
            )
        }

        if metrics.hasInconsistentVolume {
            return CoachNote(
                title: "Aim for consistency",
                body: "Steady volume throughout sounds more assured. Pick a level and hold it.",
                type: .intensity,
                priority: .medium
            )
        }

        return nil
    }

    // MARK: - Confidence Notes

    private static func generateConfidenceNote(
        _ metrics: AnalyzedMetrics,
        score: Int
    ) -> CoachNote? {
        guard score < 75 else { return nil }

        if metrics.isTooQuiet {
            return CoachNote(
                title: "Project more",
                body: "Imagine you're speaking to someone across a table. A bit louder sounds more confident.",
                type: .general,
                priority: .high
            )
        }

        if metrics.hasTooMuchSilence {
            return CoachNote(
                title: "Fill the space",
                body: "It's okay to pause and think, but keep moving forward. Own the conversation.",
                type: .general,
                priority: .medium
            )
        }

        return nil
    }
}

// MARK: - Scenario-Specific Coaching

extension CoachNotesEngine {

    /// Get additional coaching tips specific to a scenario category
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

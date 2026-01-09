// FeedbackEngine.swift
// QuietCoach
//
// Transforms audio metrics into meaningful scores.
// Each score maps to one measurable behavior. Every score is actionable.

import Foundation

struct FeedbackEngine {

    // MARK: - Score Generation

    /// Generate feedback scores from audio metrics
    static func generateScores(from metrics: AudioMetrics, scenario: Scenario) -> FeedbackScores {
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        return FeedbackScores(
            clarity: clamp(calculateClarity(analyzed)),
            pacing: clamp(calculatePacing(analyzed)),
            tone: clamp(calculateTone(analyzed)),
            confidence: clamp(calculateConfidence(analyzed))
        )
    }

    // MARK: - Clarity Score

    /// Clarity: Based on pause patterns and silence usage
    /// Clear speakers pause intentionally, don't trail off
    private static func calculateClarity(_ metrics: AnalyzedMetrics) -> Int {
        var score = 75 // Base score

        // Ideal pauses based on duration (roughly 1 every 20 seconds)
        let idealPauses = metrics.idealPauseCount
        let pauseDelta = abs(metrics.pauseCount - idealPauses)

        // Penalize for being far from ideal pause count
        score -= pauseDelta * 5

        // Penalize for too much silence (trailing off, hesitation)
        if metrics.silenceRatio > 0.4 {
            score -= Int((metrics.silenceRatio - 0.4) * 50)
        }

        // Bonus for sustained engagement
        if metrics.duration > 30 {
            score += 5
        }
        if metrics.duration > 60 {
            score += 5
        }

        // Bonus for good pause pattern
        if metrics.hasGoodPausePattern {
            score += 5
        }

        return score
    }

    // MARK: - Pacing Score

    /// Pacing: Based on rhythm (speaking segments per minute)
    /// Too fast feels rushed, too slow loses engagement
    private static func calculatePacing(_ metrics: AnalyzedMetrics) -> Int {
        var score = 75 // Base score

        let segmentsPerMinute = metrics.segmentsPerMinute

        // Optimal range: 15-30 segments per minute
        if segmentsPerMinute < 10 {
            // Too slow
            score -= Int((10 - segmentsPerMinute) * 3)
        } else if segmentsPerMinute > 40 {
            // Too fast
            score -= Int((segmentsPerMinute - 40) * 2)
        } else if segmentsPerMinute >= 15 && segmentsPerMinute <= 30 {
            // Optimal range bonus
            score += 10
        }

        // Penalize very short recordings (didn't engage)
        if metrics.duration < 15 {
            score -= 15
        }

        // Bonus for sustained delivery
        if metrics.effectiveDuration > 30 {
            score += 5
        }

        return score
    }

    // MARK: - Tone Score

    /// Tone: Based on volume consistency and spike control
    /// Consistent volume sounds calm and controlled
    private static func calculateTone(_ metrics: AnalyzedMetrics) -> Int {
        var score = 75 // Base score

        // Reward volume stability (0-1 scale, higher is better)
        score += Int(metrics.volumeStability * 20)

        // Penalize intensity spikes
        let spikesPerMinute = Float(metrics.spikeCount) / max(0.1, Float(metrics.duration / 60))
        if spikesPerMinute > 5 {
            score -= Int((spikesPerMinute - 5) * 3)
        }

        // Small penalty for very inconsistent volume
        if metrics.hasInconsistentVolume {
            score -= 10
        }

        return score
    }

    // MARK: - Confidence Score

    /// Confidence: Based on volume level and consistency
    /// Speaking clearly and steadily sounds assured
    private static func calculateConfidence(_ metrics: AnalyzedMetrics) -> Int {
        var score = 75 // Base score

        // Penalize low volume (sounds timid)
        if metrics.averageLevel < 0.1 {
            score -= 15
        } else if metrics.averageLevel > 0.3 {
            // Good projection
            score += 10
        }

        // Reward stability (consistency = confidence)
        score += Int(metrics.volumeStability * 15)

        // Penalize excessive silence (sounds hesitant)
        if metrics.silenceRatio > 0.5 {
            score -= 10
        }

        // Penalize very short recordings
        if metrics.duration < 10 {
            score -= 10
        }

        // Bonus for filling the space
        if metrics.effectiveDuration / metrics.duration > 0.7 {
            score += 5
        }

        return score
    }

    // MARK: - Helpers

    /// Clamp score to valid range
    private static func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }
}

// MARK: - Score Interpretation

extension FeedbackEngine {

    /// Get a brief interpretation of an overall score
    static func interpretation(for score: Int) -> String {
        switch score {
        case 90...100:
            return "Excellent delivery. You sound ready."
        case 80..<90:
            return "Strong performance. Minor refinements possible."
        case 70..<80:
            return "Good foundation. Focus on consistency."
        case 60..<70:
            return "Developing well. Keep practicing."
        case 50..<60:
            return "Room to grow. Try again with the focus below."
        default:
            return "Let's work on the basics. One thing at a time."
        }
    }

    /// Get emoji for score tier (used sparingly)
    static func emoji(for score: Int) -> String {
        switch score {
        case 85...100: return "✨"
        case 70..<85: return "👍"
        case 55..<70: return "📈"
        default: return "💪"
        }
    }
}

// FeedbackEngine.swift
// QuietCoach
//
// Transforms audio metrics and speech analysis into meaningful scores.
// Each score maps to one measurable behavior. Every score is actionable.

import Foundation
import OSLog

struct FeedbackEngine {

    private static let logger = Logger(subsystem: "com.quietcoach", category: "FeedbackEngine")

    // MARK: - Score Generation (Async - Full Analysis)

    /// Generate feedback scores using full speech analysis (transcription + NLP)
    /// This is the primary method for production use
    static func generateScores(
        from metrics: AudioMetrics,
        audioURL: URL,
        scenario: Scenario
    ) async throws -> FeedbackResult {
        // Track feedback generation performance
        let feedbackSpan = await MainActor.run {
            PerformanceMonitor.shared.startSpan("feedback_generation", category: .analysis)
        }
        defer {
            Task { @MainActor in
                feedbackSpan.finish()
                PerformanceMonitor.shared.endSpan("feedback_generation")
            }
        }

        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Attempt speech analysis for real NLP-based scoring
        do {
            let speechAnalysis = try await SpeechAnalysisEngine.shared.analyze(
                audioURL: audioURL,
                duration: metrics.duration
            )

            logger.info("Speech analysis complete: \(speechAnalysis.transcription.wordCount) words")

            // Blend audio metrics with NLP analysis for comprehensive scoring
            let scores = blendScores(audioMetrics: analyzed, speechAnalysis: speechAnalysis)

            return FeedbackResult(
                scores: scores,
                transcription: speechAnalysis.transcription.text,
                speechAnalysis: speechAnalysis,
                usedSpeechAnalysis: true
            )
        } catch {
            logger.warning("Speech analysis failed, using audio-only: \(error.localizedDescription)")

            // Fallback to audio-only scoring
            let scores = generateScoresFromAudioOnly(analyzed)
            return FeedbackResult(
                scores: scores,
                transcription: nil,
                speechAnalysis: nil,
                usedSpeechAnalysis: false
            )
        }
    }

    /// Blend audio metrics with NLP analysis for comprehensive scoring
    private static func blendScores(audioMetrics: AnalyzedMetrics, speechAnalysis: SpeechAnalysisResult) -> FeedbackScores {
        // Use NLP scores as primary, audio metrics as modifiers
        var clarityScore = speechAnalysis.clarity.score
        var pacingScore = speechAnalysis.pacing.score
        var toneScore = speechAnalysis.tone.score
        var confidenceScore = speechAnalysis.confidence.score

        // Adjust based on audio metrics
        // If audio shows good pause patterns, boost clarity
        if audioMetrics.hasGoodPausePattern {
            clarityScore += 5
        }

        // If audio shows high volume stability, boost tone
        if audioMetrics.volumeStability > 0.7 {
            toneScore += 5
        }

        // If audio shows good projection, boost confidence
        if audioMetrics.averageLevel > 0.3 {
            confidenceScore += 5
        }

        // If audio pacing matches NLP pacing assessment, boost pacing score
        let audioOptimalPacing = audioMetrics.segmentsPerMinute >= 15 && audioMetrics.segmentsPerMinute <= 30
        if audioOptimalPacing && speechAnalysis.pacing.isOptimalPace {
            pacingScore += 5
        }

        return FeedbackScores(
            clarity: clamp(clarityScore),
            pacing: clamp(pacingScore),
            tone: clamp(toneScore),
            confidence: clamp(confidenceScore)
        )
    }

    /// Generate scores from audio metrics only (fallback)
    private static func generateScoresFromAudioOnly(_ metrics: AnalyzedMetrics) -> FeedbackScores {
        FeedbackScores(
            clarity: clamp(calculateClarity(metrics)),
            pacing: clamp(calculatePacing(metrics)),
            tone: clamp(calculateTone(metrics)),
            confidence: clamp(calculateConfidence(metrics))
        )
    }

    // MARK: - Score Generation (Sync - Audio Only)

    /// Generate feedback scores from audio metrics only
    /// Use this when speech analysis is not available or not needed
    static func generateScores(from metrics: AudioMetrics, scenario: Scenario) -> FeedbackScores {
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)
        return generateScoresFromAudioOnly(analyzed)
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

// MARK: - Feedback Result

/// Complete feedback result including scores, transcription, and analysis details
struct FeedbackResult: Sendable {
    /// The calculated scores
    let scores: FeedbackScores

    /// The transcription of the recording (nil if speech analysis failed)
    let transcription: String?

    /// The detailed speech analysis (nil if speech analysis failed)
    let speechAnalysis: SpeechAnalysisResult?

    /// Whether speech analysis was successfully used
    let usedSpeechAnalysis: Bool

    /// Insights derived from the analysis
    var insights: [String] {
        guard let analysis = speechAnalysis else {
            return ["Audio analysis only - enable speech recognition for detailed feedback"]
        }

        var insights: [String] = []

        // Filler word insight
        if analysis.clarity.fillerWordCount > 3 {
            let topFillers = analysis.clarity.fillerWords.prefix(3).joined(separator: ", ")
            insights.append("Reduce filler words like: \(topFillers)")
        }

        // Pacing insight
        if !analysis.pacing.isOptimalPace {
            if analysis.pacing.wordsPerMinute < 120 {
                insights.append("Try speaking slightly faster for better engagement")
            } else if analysis.pacing.wordsPerMinute > 160 {
                insights.append("Slow down a bit to improve clarity")
            }
        }

        // Confidence insight
        if analysis.confidence.hedgingPhraseCount > 2 {
            insights.append("Replace hedging phrases with more direct statements")
        }

        // Tone insight
        if analysis.tone.isNegative {
            insights.append("Try using more positive language")
        }

        if insights.isEmpty {
            insights.append("Great job! Keep practicing to maintain consistency")
        }

        return insights
    }
}

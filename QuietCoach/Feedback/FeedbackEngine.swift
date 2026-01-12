// FeedbackEngine.swift
// QuietCoach
//
// Transforms audio metrics and speech analysis into meaningful scores.
// Each score maps to one measurable behavior. Every score is actionable.
//
// ## Scoring Philosophy
//
// All scores start at 75 (competent baseline) and adjust based on:
// - Positive behaviors → add points (max 100)
// - Concerning patterns → subtract points (min 0)
//
// ## Score Dimensions
//
// - **Clarity** (0-100): Are you easy to follow?
//   Based on pause patterns, silence ratio, sustained engagement
//
// - **Pacing** (0-100): Is your rhythm engaging?
//   Based on segments per minute, effective speaking duration
//
// - **Tone** (0-100): Do you sound calm and controlled?
//   Based on volume stability, spike frequency
//
// - **Confidence** (0-100): Do you sound assured?
//   Based on projection (average level), consistency, silence ratio
//
// ## Blending Strategy
//
// When speech analysis is available, NLP scores are primary and
// audio metrics serve as modifiers (+5 for positive patterns).
// When only audio is available, audio metrics drive scoring directly.

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
        scenario: Scenario,
        baseline: BaselineMetrics? = nil,
        coachTone: CoachTone = CoachToneSettings.current
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

        let profile = ScoringProfile.forScenario(
            scenario,
            baseline: baseline,
            coachTone: coachTone
        )
        let analyzed = AudioMetricsAnalyzer.analyze(metrics, profile: profile)

        let transcriptionEnabled = await MainActor.run { PrivacySettings.shared.transcriptionEnabled }
        let isAuthorized = await SpeechAnalysisEngine.shared.isAuthorized
        let canTranscribe: Bool

        if transcriptionEnabled {
            if isAuthorized {
                canTranscribe = true
            } else {
                canTranscribe = await SpeechAnalysisEngine.shared.requestAuthorization()
            }
        } else {
            canTranscribe = false
        }

        if canTranscribe {
            do {
                let speechAnalysis = try await SpeechAnalysisEngine.shared.analyze(
                    audioURL: audioURL,
                    duration: metrics.duration,
                    profile: profile
                )

                logger.info("Speech analysis complete: \(speechAnalysis.transcription.wordCount) words")

                // Blend audio metrics with NLP analysis for comprehensive scoring
                let scores = blendScores(audioMetrics: analyzed, speechAnalysis: speechAnalysis, profile: profile)

                return FeedbackResult(
                    scores: scores,
                    transcription: speechAnalysis.transcription.text,
                    speechAnalysis: speechAnalysis,
                    usedSpeechAnalysis: true,
                    profile: profile,
                    coachTone: coachTone
                )
            } catch {
                logger.warning("Speech analysis failed, using audio-only: \(error.localizedDescription)")
            }
        }

        // Fallback to audio-only scoring
        let scores = generateScoresFromAudioOnly(analyzed)
        return FeedbackResult(
            scores: scores,
            transcription: nil,
            speechAnalysis: nil,
            usedSpeechAnalysis: false,
            profile: profile,
            coachTone: coachTone
        )
    }

    /// Blend audio metrics with NLP analysis for comprehensive scoring
    private static func blendScores(
        audioMetrics: AnalyzedMetrics,
        speechAnalysis: SpeechAnalysisResult,
        profile: ScoringProfile
    ) -> FeedbackScores {
        // Use NLP scores as primary, audio metrics as modifiers
        var clarityScore = speechAnalysis.clarity.score(using: profile)
        var pacingScore = speechAnalysis.pacing.score(using: profile)
        var toneScore = speechAnalysis.tone.score(using: profile)
        var confidenceScore = speechAnalysis.confidence.score(using: profile)

        // Adjust based on audio metrics
        // If audio shows good pause patterns, boost clarity
        if audioMetrics.hasGoodPausePattern {
            clarityScore += 5
        }

        // If audio shows high volume stability, boost tone
        if audioMetrics.volumeStability > profile.tuning.toneStabilityBonusThreshold {
            toneScore += 5
        }

        // If audio shows good projection, boost confidence
        if audioMetrics.averageLevel > profile.audio.averageLevelStrong {
            confidenceScore += 5
        }

        // If audio pacing matches NLP pacing assessment, boost pacing score
        let audioOptimalPacing = profile.audio.pacingOptimalRange.contains(audioMetrics.segmentsPerMinute)
        if audioOptimalPacing && speechAnalysis.pacing.isOptimalPace(using: profile) {
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
    static func generateScores(
        from metrics: AudioMetrics,
        scenario: Scenario,
        baseline: BaselineMetrics? = nil,
        coachTone: CoachTone = CoachToneSettings.current
    ) -> FeedbackScores {
        let profile = ScoringProfile.forScenario(
            scenario,
            baseline: baseline,
            coachTone: coachTone
        )
        let analyzed = AudioMetricsAnalyzer.analyze(metrics, profile: profile)
        return generateScoresFromAudioOnly(analyzed)
    }

    // MARK: - Clarity Score

    /// Clarity: Based on pause patterns and silence usage
    /// Clear speakers pause intentionally, don't trail off
    private static func calculateClarity(_ metrics: AnalyzedMetrics) -> Int {
        let profile = metrics.profile
        var score = profile.tuning.baseScore

        // Ideal pauses based on duration (roughly 1 every 20 seconds)
        let idealPauses = metrics.idealPauseCount
        let pauseDelta = abs(metrics.pauseCount - idealPauses)

        // Penalize for being far from ideal pause count
        score -= pauseDelta * profile.tuning.clarityPausePenalty

        // Penalize for too much silence (trailing off, hesitation)
        if metrics.silenceRatio > profile.tuning.claritySilenceRatioThreshold {
            score -= Int((metrics.silenceRatio - profile.tuning.claritySilenceRatioThreshold) * profile.tuning.claritySilencePenaltyMultiplier)
        }

        // Bonus for sustained engagement
        if metrics.duration > profile.tuning.clarityDurationBonusShort {
            score += profile.tuning.clarityDurationBonusValue
        }
        if metrics.duration > profile.tuning.clarityDurationBonusLong {
            score += profile.tuning.clarityDurationBonusValue
        }

        // Bonus for good pause pattern
        if metrics.hasGoodPausePattern {
            score += profile.tuning.clarityGoodPauseBonus
        }

        return score
    }

    // MARK: - Pacing Score

    /// Pacing: Based on rhythm (speaking segments per minute)
    /// Too fast feels rushed, too slow loses engagement
    private static func calculatePacing(_ metrics: AnalyzedMetrics) -> Int {
        let profile = metrics.profile
        var score = profile.tuning.baseScore

        let segmentsPerMinute = metrics.segmentsPerMinute

        // Optimal range: 15-30 segments per minute
        if segmentsPerMinute < profile.audio.pacingTooSlowSegmentsPerMinute {
            // Too slow
            score -= Int((profile.audio.pacingTooSlowSegmentsPerMinute - segmentsPerMinute) * profile.tuning.pacingSlowPenaltyMultiplier)
        } else if segmentsPerMinute > profile.audio.pacingTooFastSegmentsPerMinute {
            // Too fast
            score -= Int((segmentsPerMinute - profile.audio.pacingTooFastSegmentsPerMinute) * profile.tuning.pacingFastPenaltyMultiplier)
        } else if profile.audio.pacingOptimalRange.contains(segmentsPerMinute) {
            // Optimal range bonus
            score += profile.tuning.pacingOptimalBonus
        }

        // Penalize very short recordings (didn't engage)
        if metrics.duration < profile.tuning.pacingShortRecordingThreshold {
            score -= profile.tuning.pacingShortRecordingPenalty
        }

        // Bonus for sustained delivery
        if metrics.effectiveDuration > profile.tuning.pacingSustainedDeliveryThreshold {
            score += profile.tuning.pacingSustainedDeliveryBonus
        }

        return score
    }

    // MARK: - Tone Score

    /// Tone: Based on volume consistency and spike control
    /// Consistent volume sounds calm and controlled
    private static func calculateTone(_ metrics: AnalyzedMetrics) -> Int {
        let profile = metrics.profile
        var score = profile.tuning.baseScore

        // Reward volume stability (0-1 scale, higher is better)
        score += Int(metrics.volumeStability * profile.tuning.toneStabilityMultiplier)

        // Penalize intensity spikes
        let spikesPerMinute = Float(metrics.spikeCount) / max(0.1, Float(metrics.duration / 60))
        if spikesPerMinute > profile.audio.spikesPerMinuteMax {
            score -= Int((spikesPerMinute - profile.audio.spikesPerMinuteMax) * profile.tuning.toneSpikePenaltyMultiplier)
        }

        // Small penalty for very inconsistent volume
        if metrics.hasInconsistentVolume {
            score -= profile.tuning.toneInconsistentPenalty
        }

        return score
    }

    // MARK: - Confidence Score

    /// Confidence: Based on volume level and consistency
    /// Speaking clearly and steadily sounds assured
    private static func calculateConfidence(_ metrics: AnalyzedMetrics) -> Int {
        let profile = metrics.profile
        var score = profile.tuning.baseScore

        // Penalize low volume (sounds timid)
        if metrics.averageLevel < profile.audio.averageLevelMinimum {
            score -= profile.tuning.confidenceLowVolumePenalty
        } else if metrics.averageLevel > profile.audio.averageLevelStrong {
            // Good projection
            score += profile.tuning.confidenceHighVolumeBonus
        }

        // Reward stability (consistency = confidence)
        score += Int(metrics.volumeStability * profile.tuning.confidenceStabilityMultiplier)

        // Penalize excessive silence (sounds hesitant)
        if metrics.silenceRatio > profile.audio.silenceRatioMax {
            score -= profile.tuning.confidenceSilenceRatioPenalty
        }

        // Penalize very short recordings
        if metrics.duration < profile.tuning.confidenceShortRecordingThreshold {
            score -= profile.tuning.confidenceShortRecordingPenalty
        }

        // Bonus for filling the space
        let effectiveDurationRatio = metrics.duration > 0
            ? metrics.effectiveDuration / metrics.duration
            : 0
        if effectiveDurationRatio > Double(profile.tuning.confidenceEffectiveDurationRatio) {
            score += profile.tuning.confidenceEffectiveDurationBonus
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

    /// Profile used to compute scores (for explainability)
    let profile: ScoringProfile

    /// Coach tone used for weighting and phrasing
    let coachTone: CoachTone

    /// Insights derived from the analysis
    var insights: [String] {
        let profile = profile
        guard let analysis = speechAnalysis else {
            return ["Audio analysis only - enable on-device transcription for richer feedback"]
        }

        var insights: [String] = []

        // Filler word insight
        if analysis.clarity.fillerWordCount > profile.nlp.insightFillerWordCountThreshold {
            let topFillers = analysis.clarity.fillerWords.prefix(3).joined(separator: ", ")
            insights.append("Reduce filler words like: \(topFillers)")
        }

        // Pacing insight
        if !analysis.pacing.isOptimalPace(using: profile) {
            if analysis.pacing.wordsPerMinute < profile.nlp.pacingOptimalRange.lowerBound {
                insights.append("Try speaking slightly faster for better engagement")
            } else if analysis.pacing.wordsPerMinute > profile.nlp.pacingOptimalRange.upperBound {
                insights.append("Slow down a bit to improve clarity")
            }
        }

        // Confidence insight
        if analysis.confidence.hedgingPhraseCount > profile.nlp.insightHedgingPhraseCountThreshold {
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

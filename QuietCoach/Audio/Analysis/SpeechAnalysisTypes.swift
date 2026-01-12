// SpeechAnalysisTypes.swift
// QuietCoach
//
// Result types and error definitions for speech analysis.

import Foundation

// MARK: - Main Result

struct SpeechAnalysisResult: Sendable {
    let transcription: TranscriptionResult
    let clarity: ClarityAnalysis
    let pacing: PacingAnalysis
    let confidence: ConfidenceAnalysis
    let tone: ToneAnalysis

    /// Generate feedback scores from analysis
    func generateScores(using profile: ScoringProfile = .default) -> FeedbackScores {
        FeedbackScores(
            clarity: clarity.score(using: profile),
            pacing: pacing.score(using: profile),
            tone: tone.score(using: profile),
            confidence: confidence.score(using: profile)
        )
    }
}

// MARK: - Transcription Types

struct TranscriptionResult: Sendable {
    let text: String
    let segments: [TranscriptionSegment]

    var wordCount: Int {
        text.split(separator: " ").count
    }

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct TranscriptionSegment: Sendable {
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Float
}

struct PauseEvent: Sendable {
    let timestamp: TimeInterval
    let duration: TimeInterval
    let wordBefore: String
    let wordAfter: String
}

// MARK: - Clarity Analysis

struct ClarityAnalysis: Sendable {
    let fillerWordCount: Int
    let fillerWords: [String]
    let repeatedWordCount: Int
    let incompleteSentenceCount: Int
    let averageWordLength: Double
    let lowConfidenceSegmentCount: Int
    let totalWordCount: Int

    /// Filler word ratio (lower is better)
    var fillerRatio: Double {
        guard totalWordCount > 0 else { return 0 }
        return Double(fillerWordCount) / Double(totalWordCount)
    }

    /// Calculate clarity score (0-100)
    var score: Int {
        score(using: .default)
    }

    func score(using profile: ScoringProfile) -> Int {
        var score = profile.nlp.clarityBaseScore

        // Penalize filler words (-3 per filler, max -30)
        score -= min(profile.nlp.fillerPenaltyMax, fillerWordCount * profile.nlp.fillerPenaltyPerWord)

        // Penalize repeated words (-5 per repeat, max -15)
        score -= min(profile.nlp.repeatedPenaltyMax, repeatedWordCount * profile.nlp.repeatedPenaltyPerWord)

        // Penalize incomplete sentences (-5 per incomplete, max -15)
        score -= min(profile.nlp.incompletePenaltyMax, incompleteSentenceCount * profile.nlp.incompletePenaltyPerSentence)

        // Penalize low confidence segments (-2 per segment, max -10)
        score -= min(profile.nlp.lowConfidencePenaltyMax, lowConfidenceSegmentCount * profile.nlp.lowConfidencePenaltyPerSegment)

        // Bonus for good word variety (based on avg word length)
        if averageWordLength > profile.nlp.averageWordLengthBonusThreshold {
            score += profile.nlp.averageWordLengthBonus
        }

        return max(0, min(100, score))
    }
}

// MARK: - Pacing Analysis

struct PacingAnalysis: Sendable {
    let wordsPerMinute: Double
    let totalWordCount: Int
    let totalPauseCount: Int
    let shortPauses: Int
    let mediumPauses: Int
    let longPauses: Int
    let averagePauseDuration: Double
    let averageSentenceLength: Double
    let duration: TimeInterval

    /// Optimal WPM range: 120-160
    var isOptimalPace: Bool {
        isOptimalPace(using: .default)
    }

    func isOptimalPace(using profile: ScoringProfile) -> Bool {
        wordsPerMinute >= profile.nlp.pacingOptimalRange.lowerBound &&
            wordsPerMinute <= profile.nlp.pacingOptimalRange.upperBound
    }

    /// Calculate pacing score (0-100)
    var score: Int {
        score(using: .default)
    }

    func score(using profile: ScoringProfile) -> Int {
        var score = profile.nlp.pacingBaseScore

        // Pacing evaluation
        if wordsPerMinute < profile.nlp.pacingSlowWordsPerMinute {
            // Too slow
            score -= Int((profile.nlp.pacingSlowWordsPerMinute - wordsPerMinute) / profile.nlp.pacingPenaltyDivisor)
        } else if wordsPerMinute > profile.nlp.pacingFastWordsPerMinute {
            // Too fast
            score -= Int((wordsPerMinute - profile.nlp.pacingFastWordsPerMinute) / profile.nlp.pacingPenaltyDivisor)
        } else if isOptimalPace(using: profile) {
            // Optimal range bonus
            score += profile.nlp.pacingOptimalBonus
        }

        // Pause pattern evaluation
        // Good: medium pauses are intentional
        // Bad: too many long pauses (hesitation) or no pauses (rushing)
        if totalPauseCount == 0 && duration > profile.nlp.noPausePenaltyDuration {
            score -= profile.nlp.noPausePenalty // No pauses in longer recording = rushing
        }
        if longPauses > profile.nlp.longPausePenaltyThreshold {
            score -= (longPauses - profile.nlp.longPausePenaltyThreshold) * profile.nlp.longPausePenaltyPerPause
        }

        // Bonus for good pause distribution
        if mediumPauses > shortPauses && mediumPauses > longPauses {
            score += profile.nlp.mediumPauseBonus // Intentional pausing pattern
        }

        return max(0, min(100, score))
    }
}

// MARK: - Confidence Analysis

struct ConfidenceAnalysis: Sendable {
    let hedgingPhraseCount: Int
    let hedgingPhrases: [String]
    let questionWordCount: Int
    let weakOpenerCount: Int
    let apologeticPhraseCount: Int
    let assertivePhraseCount: Int
    let totalWordCount: Int

    /// Calculate confidence score (0-100)
    var score: Int {
        score(using: .default)
    }

    func score(using profile: ScoringProfile) -> Int {
        var score = profile.nlp.confidenceBaseScore

        // Penalize hedging (-4 per hedge, max -24)
        score -= min(profile.nlp.hedgingPenaltyMax, hedgingPhraseCount * profile.nlp.hedgingPenaltyPerPhrase)

        // Penalize weak openers (-5 per opener, max -15)
        score -= min(profile.nlp.weakOpenerPenaltyMax, weakOpenerCount * profile.nlp.weakOpenerPenaltyPerPhrase)

        // Penalize excessive apologetic language (-5 per phrase, max -15)
        score -= min(profile.nlp.apologeticPenaltyMax, apologeticPhraseCount * profile.nlp.apologeticPenaltyPerPhrase)

        // Bonus for assertive language (+3 per phrase, max +15)
        score += min(profile.nlp.assertiveBonusMax, assertivePhraseCount * profile.nlp.assertiveBonusPerPhrase)

        // Small penalty for excessive question words (uncertainty)
        if totalWordCount > 0 {
            let questionRatio = Double(questionWordCount) / Double(totalWordCount)
            if questionRatio > profile.nlp.questionRatioThreshold {
                score -= profile.nlp.questionRatioPenalty
            }
        }

        return max(0, min(100, score))
    }
}

// MARK: - Tone Analysis

struct ToneAnalysis: Sendable {
    let sentimentScore: Double // -1 to 1
    let positiveWordCount: Int
    let negativeWordCount: Int
    let contractionCount: Int
    let formalPhraseCount: Int
    let sentenceCount: Int

    /// Whether tone is predominantly positive
    var isPositive: Bool {
        sentimentScore > 0.1
    }

    /// Whether tone is predominantly negative
    var isNegative: Bool {
        sentimentScore < -0.1
    }

    /// Calculate tone score (0-100)
    var score: Int {
        score(using: .default)
    }

    func score(using profile: ScoringProfile) -> Int {
        var score = profile.nlp.toneBaseScore

        // Sentiment contribution (-15 to +15 based on sentiment)
        score += Int(sentimentScore * profile.nlp.sentimentMultiplier)

        // Word balance
        let emotionBalance = positiveWordCount - negativeWordCount
        if emotionBalance > profile.nlp.emotionBalanceThreshold {
            score += profile.nlp.emotionBalanceBonus
        } else if emotionBalance < -profile.nlp.emotionBalanceThreshold {
            score -= profile.nlp.emotionBalanceBonus
        }

        // Formality balance (some formality is good, too much is stiff)
        if profile.nlp.formalityBonusRange.contains(formalPhraseCount) {
            score += profile.nlp.formalityBonus
        } else if formalPhraseCount > profile.nlp.formalityPenaltyThreshold {
            score -= profile.nlp.formalityPenalty
        }

        // Contractions indicate natural speech (bonus if moderate)
        if profile.nlp.contractionBonusRange.contains(contractionCount) {
            score += profile.nlp.contractionBonus
        }

        return max(0, min(100, score))
    }
}

// MARK: - Errors

enum SpeechAnalysisError: LocalizedError {
    case recognizerUnavailable
    case transcriptionFailed(Error)
    case notAuthorized
    case audioFileNotFound

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognition is not available"
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .audioFileNotFound:
            return "Audio file not found"
        }
    }
}

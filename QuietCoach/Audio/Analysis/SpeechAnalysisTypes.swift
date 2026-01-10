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
    func generateScores() -> FeedbackScores {
        FeedbackScores(
            clarity: clarity.score,
            pacing: pacing.score,
            tone: tone.score,
            confidence: confidence.score
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
        var score = 85 // Base score

        // Penalize filler words (-3 per filler, max -30)
        score -= min(30, fillerWordCount * 3)

        // Penalize repeated words (-5 per repeat, max -15)
        score -= min(15, repeatedWordCount * 5)

        // Penalize incomplete sentences (-5 per incomplete, max -15)
        score -= min(15, incompleteSentenceCount * 5)

        // Penalize low confidence segments (-2 per segment, max -10)
        score -= min(10, lowConfidenceSegmentCount * 2)

        // Bonus for good word variety (based on avg word length)
        if averageWordLength > 5.0 {
            score += 5
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
        wordsPerMinute >= 120 && wordsPerMinute <= 160
    }

    /// Calculate pacing score (0-100)
    var score: Int {
        var score = 80 // Base score

        // Pacing evaluation
        if wordsPerMinute < 100 {
            // Too slow
            score -= Int((100 - wordsPerMinute) / 5)
        } else if wordsPerMinute > 180 {
            // Too fast
            score -= Int((wordsPerMinute - 180) / 5)
        } else if isOptimalPace {
            // Optimal range bonus
            score += 10
        }

        // Pause pattern evaluation
        // Good: medium pauses are intentional
        // Bad: too many long pauses (hesitation) or no pauses (rushing)
        if totalPauseCount == 0 && duration > 30 {
            score -= 10 // No pauses in longer recording = rushing
        }
        if longPauses > 3 {
            score -= (longPauses - 3) * 3 // Too many long pauses
        }

        // Bonus for good pause distribution
        if mediumPauses > shortPauses && mediumPauses > longPauses {
            score += 5 // Intentional pausing pattern
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
        var score = 80 // Base score

        // Penalize hedging (-4 per hedge, max -24)
        score -= min(24, hedgingPhraseCount * 4)

        // Penalize weak openers (-5 per opener, max -15)
        score -= min(15, weakOpenerCount * 5)

        // Penalize excessive apologetic language (-5 per phrase, max -15)
        score -= min(15, apologeticPhraseCount * 5)

        // Bonus for assertive language (+3 per phrase, max +15)
        score += min(15, assertivePhraseCount * 3)

        // Small penalty for excessive question words (uncertainty)
        if totalWordCount > 0 {
            let questionRatio = Double(questionWordCount) / Double(totalWordCount)
            if questionRatio > 0.1 {
                score -= 5
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
        var score = 75 // Base score

        // Sentiment contribution (-15 to +15 based on sentiment)
        score += Int(sentimentScore * 15)

        // Word balance
        let emotionBalance = positiveWordCount - negativeWordCount
        if emotionBalance > 2 {
            score += 5
        } else if emotionBalance < -2 {
            score -= 5
        }

        // Formality balance (some formality is good, too much is stiff)
        if formalPhraseCount > 0 && formalPhraseCount <= 3 {
            score += 5
        } else if formalPhraseCount > 5 {
            score -= 5
        }

        // Contractions indicate natural speech (bonus if moderate)
        if contractionCount > 0 && contractionCount <= 5 {
            score += 5
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

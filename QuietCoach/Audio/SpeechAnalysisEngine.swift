// SpeechAnalysisEngine.swift
// QuietCoach
//
// Real speech analysis using Apple's Speech and NaturalLanguage frameworks.
// Transforms spoken words into actionable coaching insights.

import Foundation
import Speech
import NaturalLanguage
import OSLog

// MARK: - Speech Analysis Engine

/// Actor-isolated speech analysis engine for thread-safe transcription and NLP
actor SpeechAnalysisEngine {

    // MARK: - Singleton

    static let shared = SpeechAnalysisEngine()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "SpeechAnalysis")
    private var speechRecognizer: SFSpeechRecognizer?

    // MARK: - Initialization

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    }

    // MARK: - Authorization

    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Check current authorization status
    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Main Analysis

    /// Analyze audio file and return comprehensive speech metrics
    func analyze(audioURL: URL, duration: TimeInterval) async throws -> SpeechAnalysisResult {
        logger.info("Starting speech analysis for: \(audioURL.lastPathComponent)")

        // Track analysis performance
        await MainActor.run { PerformanceMonitor.shared.trackAnalysisStart() }

        // 1. Transcribe audio
        await MainActor.run { PerformanceMonitor.shared.trackTranscriptionStart() }
        let transcription = try await transcribe(audioURL: audioURL)
        await MainActor.run { PerformanceMonitor.shared.trackTranscriptionEnd() }

        // 2. Analyze transcription
        let clarityMetrics = analyzeClarity(transcription: transcription)
        let pacingMetrics = analyzePacing(transcription: transcription, duration: duration)
        let confidenceMetrics = analyzeConfidence(transcription: transcription)
        let toneMetrics = analyzeTone(transcription: transcription)

        // Track analysis end
        await MainActor.run { PerformanceMonitor.shared.trackAnalysisEnd(wordCount: transcription.wordCount) }

        logger.info("Analysis complete. Words: \(transcription.wordCount), Fillers: \(clarityMetrics.fillerWordCount)")

        return SpeechAnalysisResult(
            transcription: transcription,
            clarity: clarityMetrics,
            pacing: pacingMetrics,
            confidence: confidenceMetrics,
            tone: toneMetrics
        )
    }

    // MARK: - Transcription

    /// Transcribe audio file using Speech framework
    private func transcribe(audioURL: URL) async throws -> TranscriptionResult {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechAnalysisError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: SpeechAnalysisError.transcriptionFailed(error))
                    return
                }

                guard let result = result, result.isFinal else { return }

                let segments = result.bestTranscription.segments.map { segment in
                    TranscriptionSegment(
                        text: segment.substring,
                        timestamp: segment.timestamp,
                        duration: segment.duration,
                        confidence: segment.confidence
                    )
                }

                let transcription = TranscriptionResult(
                    text: result.bestTranscription.formattedString,
                    segments: segments
                )

                continuation.resume(returning: transcription)
            }
        }
    }

    // MARK: - Clarity Analysis

    /// Analyze clarity: filler words, incomplete sentences, articulation
    private func analyzeClarity(transcription: TranscriptionResult) -> ClarityAnalysis {
        let text = transcription.text.lowercased()
        let words = tokenize(text)

        // Filler word detection
        let fillerWords = Self.fillerPatterns.flatMap { pattern in
            words.filter { $0.matches(pattern) }
        }

        // Repeated word detection (stammering)
        var repeatedWords = 0
        for i in 1..<words.count {
            if words[i] == words[i-1] && words[i].count > 2 {
                repeatedWords += 1
            }
        }

        // Incomplete sentence detection (sentences ending with filler or trailing off)
        let sentences = tokenizeSentences(transcription.text)
        let incompleteSentences = sentences.filter { sentence in
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return Self.incompleteEndings.contains(where: { trimmed.hasSuffix($0) })
        }.count

        // Average word length (articulation indicator)
        let avgWordLength = words.isEmpty ? 0 : Double(words.map { $0.count }.reduce(0, +)) / Double(words.count)

        // Low-confidence segments (mumbling indicator)
        let lowConfidenceSegments = transcription.segments.filter { $0.confidence < 0.5 }.count

        return ClarityAnalysis(
            fillerWordCount: fillerWords.count,
            fillerWords: Array(Set(fillerWords)).sorted(),
            repeatedWordCount: repeatedWords,
            incompleteSentenceCount: incompleteSentences,
            averageWordLength: avgWordLength,
            lowConfidenceSegmentCount: lowConfidenceSegments,
            totalWordCount: words.count
        )
    }

    // MARK: - Pacing Analysis

    /// Analyze pacing: words per minute, pause patterns
    private func analyzePacing(transcription: TranscriptionResult, duration: TimeInterval) -> PacingAnalysis {
        let words = tokenize(transcription.text)
        let wordCount = words.count

        // Words per minute
        let minutes = max(0.1, duration / 60.0)
        let wordsPerMinute = Double(wordCount) / minutes

        // Pause detection from segment timestamps
        var pauses: [PauseEvent] = []
        let segments = transcription.segments

        for i in 1..<segments.count {
            let gap = segments[i].timestamp - (segments[i-1].timestamp + segments[i-1].duration)
            if gap > 0.3 { // Pause threshold: 300ms
                pauses.append(PauseEvent(
                    timestamp: segments[i-1].timestamp + segments[i-1].duration,
                    duration: gap,
                    wordBefore: segments[i-1].text,
                    wordAfter: segments[i].text
                ))
            }
        }

        // Categorize pauses
        let shortPauses = pauses.filter { $0.duration < 1.0 }.count
        let mediumPauses = pauses.filter { $0.duration >= 1.0 && $0.duration < 2.0 }.count
        let longPauses = pauses.filter { $0.duration >= 2.0 }.count

        // Average sentence length
        let sentences = tokenizeSentences(transcription.text)
        let avgSentenceLength = sentences.isEmpty ? 0 :
            Double(words.count) / Double(sentences.count)

        return PacingAnalysis(
            wordsPerMinute: wordsPerMinute,
            totalWordCount: wordCount,
            totalPauseCount: pauses.count,
            shortPauses: shortPauses,
            mediumPauses: mediumPauses,
            longPauses: longPauses,
            averagePauseDuration: pauses.isEmpty ? 0 : pauses.map { $0.duration }.reduce(0, +) / Double(pauses.count),
            averageSentenceLength: avgSentenceLength,
            duration: duration
        )
    }

    // MARK: - Confidence Analysis

    /// Analyze confidence: hedging language, uptalk indicators, assertiveness
    private func analyzeConfidence(transcription: TranscriptionResult) -> ConfidenceAnalysis {
        let text = transcription.text.lowercased()
        let words = tokenize(text)

        // Hedging phrase detection
        var hedgingPhrases: [String] = []
        for pattern in Self.hedgingPatterns {
            if text.contains(pattern) {
                hedgingPhrases.append(pattern)
            }
        }

        // Question word count (excessive questions can indicate uncertainty)
        let questionWords = words.filter { Self.questionWords.contains($0) }.count

        // Weak opener detection
        let sentences = tokenizeSentences(transcription.text)
        let weakOpeners = sentences.filter { sentence in
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return Self.weakOpeners.contains(where: { trimmed.hasPrefix($0) })
        }.count

        // Apologetic language
        let apologeticPhrases = Self.apologeticPatterns.filter { text.contains($0) }

        // Assertive language (positive indicator)
        let assertivePhrases = Self.assertivePatterns.filter { text.contains($0) }

        return ConfidenceAnalysis(
            hedgingPhraseCount: hedgingPhrases.count,
            hedgingPhrases: hedgingPhrases,
            questionWordCount: questionWords,
            weakOpenerCount: weakOpeners,
            apologeticPhraseCount: apologeticPhrases.count,
            assertivePhraseCount: assertivePhrases.count,
            totalWordCount: words.count
        )
    }

    // MARK: - Tone Analysis

    /// Analyze tone: sentiment, formality, emotional indicators
    private func analyzeTone(transcription: TranscriptionResult) -> ToneAnalysis {
        let text = transcription.text

        // Sentiment analysis using NLTagger
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var sentimentScores: [Double] = []
        let sentences = tokenizeSentences(text)

        for sentence in sentences {
            tagger.string = sentence
            if let tag = tagger.tag(at: sentence.startIndex, unit: .paragraph, scheme: .sentimentScore).0,
               let score = Double(tag.rawValue) {
                sentimentScores.append(score)
            }
        }

        let averageSentiment = sentimentScores.isEmpty ? 0 :
            sentimentScores.reduce(0, +) / Double(sentimentScores.count)

        // Emotion word detection
        let words = tokenize(text.lowercased())
        let positiveWords = words.filter { Self.positiveWords.contains($0) }.count
        let negativeWords = words.filter { Self.negativeWords.contains($0) }.count

        // Formality indicators
        let contractions = Self.contractionPatterns.filter { text.lowercased().contains($0) }.count
        let formalPhrases = Self.formalPatterns.filter { text.lowercased().contains($0) }.count

        return ToneAnalysis(
            sentimentScore: averageSentiment,
            positiveWordCount: positiveWords,
            negativeWordCount: negativeWords,
            contractionCount: contractions,
            formalPhraseCount: formalPhrases,
            sentenceCount: sentences.count
        )
    }

    // MARK: - Tokenization Helpers

    private func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var words: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            words.append(String(text[range]))
            return true
        }
        return words
    }

    private func tokenizeSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            sentences.append(String(text[range]))
            return true
        }
        return sentences
    }

    // MARK: - Pattern Dictionaries

    private static let fillerPatterns = [
        "um", "uh", "uhh", "umm", "er", "ah", "ahh",
        "like", "you know", "basically", "actually",
        "literally", "honestly", "right", "so yeah",
        "i mean", "kind of", "sort of"
    ]

    private static let hedgingPatterns = [
        "i think", "i guess", "i feel like", "maybe",
        "probably", "might", "could be", "sort of",
        "kind of", "in a way", "it seems", "perhaps",
        "i'm not sure", "i don't know"
    ]

    private static let questionWords = [
        "what", "why", "how", "when", "where", "who", "which"
    ]

    private static let weakOpeners = [
        "i just", "i'm just", "sorry", "i was just",
        "i don't know if", "this might be", "i'm not sure"
    ]

    private static let apologeticPatterns = [
        "sorry", "apologize", "my fault", "excuse me",
        "forgive me", "i'm sorry"
    ]

    private static let assertivePatterns = [
        "i need", "i want", "i will", "i expect",
        "i require", "i believe", "i'm confident",
        "it's important", "this matters"
    ]

    private static let incompleteEndings = [
        "...", "um", "uh", "so", "and", "but", "or"
    ]

    private static let positiveWords = [
        "good", "great", "excellent", "happy", "pleased",
        "confident", "strong", "clear", "effective", "success"
    ]

    private static let negativeWords = [
        "bad", "terrible", "worried", "anxious", "nervous",
        "weak", "unclear", "difficult", "problem", "fail"
    ]

    private static let contractionPatterns = [
        "don't", "can't", "won't", "wouldn't", "couldn't",
        "shouldn't", "isn't", "aren't", "wasn't", "weren't",
        "i'm", "you're", "we're", "they're", "it's"
    ]

    private static let formalPatterns = [
        "therefore", "however", "furthermore", "consequently",
        "nevertheless", "regarding", "pertaining to"
    ]
}

// MARK: - Result Types

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

// MARK: - Analysis Result Types

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

// MARK: - String Extension

private extension String {
    func matches(_ pattern: String) -> Bool {
        self.lowercased() == pattern.lowercased()
    }
}

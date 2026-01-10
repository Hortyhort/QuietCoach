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
        let fillerWords = SpeechPatterns.fillerPatterns.flatMap { pattern in
            words.filter { $0.matchesPattern(pattern) }
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
            return SpeechPatterns.incompleteEndings.contains(where: { trimmed.hasSuffix($0) })
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
        for pattern in SpeechPatterns.hedgingPatterns {
            if text.contains(pattern) {
                hedgingPhrases.append(pattern)
            }
        }

        // Question word count (excessive questions can indicate uncertainty)
        let questionWords = words.filter { SpeechPatterns.questionWords.contains($0) }.count

        // Weak opener detection
        let sentences = tokenizeSentences(transcription.text)
        let weakOpeners = sentences.filter { sentence in
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return SpeechPatterns.weakOpeners.contains(where: { trimmed.hasPrefix($0) })
        }.count

        // Apologetic language
        let apologeticPhrases = SpeechPatterns.apologeticPatterns.filter { text.contains($0) }

        // Assertive language (positive indicator)
        let assertivePhrases = SpeechPatterns.assertivePatterns.filter { text.contains($0) }

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
        let positiveWords = words.filter { SpeechPatterns.positiveWords.contains($0) }.count
        let negativeWords = words.filter { SpeechPatterns.negativeWords.contains($0) }.count

        // Formality indicators
        let contractions = SpeechPatterns.contractionPatterns.filter { text.lowercased().contains($0) }.count
        let formalPhrases = SpeechPatterns.formalPatterns.filter { text.lowercased().contains($0) }.count

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
}

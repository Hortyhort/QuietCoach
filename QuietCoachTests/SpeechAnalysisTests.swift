// SpeechAnalysisTests.swift
// QuietCoachTests
//
// Unit tests for speech analysis components.
// To use: Add a test target in Xcode (File > New > Target > Unit Testing Bundle)

import XCTest
@testable import QuietCoach

// MARK: - Clarity Analysis Tests

final class ClarityAnalysisTests: XCTestCase {

    func testFillerRatioIsCalculatedCorrectly() {
        let analysis = ClarityAnalysis(
            fillerWordCount: 5,
            fillerWords: ["um", "uh", "like"],
            repeatedWordCount: 0,
            incompleteSentenceCount: 0,
            averageWordLength: 5.0,
            lowConfidenceSegmentCount: 0,
            totalWordCount: 100
        )

        XCTAssertEqual(analysis.fillerRatio, 0.05, accuracy: 0.001)
    }

    func testFillerRatioIsZeroWhenNoWords() {
        let analysis = ClarityAnalysis(
            fillerWordCount: 0,
            fillerWords: [],
            repeatedWordCount: 0,
            incompleteSentenceCount: 0,
            averageWordLength: 0,
            lowConfidenceSegmentCount: 0,
            totalWordCount: 0
        )

        XCTAssertEqual(analysis.fillerRatio, 0)
    }

    func testClarityScoreDecreasesWithMoreFillers() {
        let fewFillers = ClarityAnalysis(
            fillerWordCount: 1,
            fillerWords: ["um"],
            repeatedWordCount: 0,
            incompleteSentenceCount: 0,
            averageWordLength: 5.0,
            lowConfidenceSegmentCount: 0,
            totalWordCount: 100
        )

        let manyFillers = ClarityAnalysis(
            fillerWordCount: 10,
            fillerWords: ["um", "uh", "like"],
            repeatedWordCount: 0,
            incompleteSentenceCount: 0,
            averageWordLength: 5.0,
            lowConfidenceSegmentCount: 0,
            totalWordCount: 100
        )

        XCTAssertGreaterThan(fewFillers.score, manyFillers.score)
    }

    func testClarityScoreStaysInValidRange() {
        // Test with extreme values
        let terrible = ClarityAnalysis(
            fillerWordCount: 50,
            fillerWords: Array(repeating: "um", count: 50),
            repeatedWordCount: 20,
            incompleteSentenceCount: 10,
            averageWordLength: 2.0,
            lowConfidenceSegmentCount: 30,
            totalWordCount: 100
        )

        let perfect = ClarityAnalysis(
            fillerWordCount: 0,
            fillerWords: [],
            repeatedWordCount: 0,
            incompleteSentenceCount: 0,
            averageWordLength: 6.0,
            lowConfidenceSegmentCount: 0,
            totalWordCount: 200
        )

        XCTAssertGreaterThanOrEqual(terrible.score, 0)
        XCTAssertLessThanOrEqual(terrible.score, 100)
        XCTAssertGreaterThanOrEqual(perfect.score, 0)
        XCTAssertLessThanOrEqual(perfect.score, 100)
    }
}

// MARK: - Pacing Analysis Tests

final class PacingAnalysisTests: XCTestCase {

    func testOptimalPaceIsDetectedCorrectly() {
        let optimalPacing = PacingAnalysis(
            wordsPerMinute: 140,
            totalWordCount: 280,
            totalPauseCount: 10,
            shortPauses: 5,
            mediumPauses: 4,
            longPauses: 1,
            averagePauseDuration: 0.8,
            averageSentenceLength: 15.0,
            duration: 120
        )

        XCTAssertTrue(optimalPacing.isOptimalPace)
    }

    func testTooSlowIsDetected() {
        let slowPacing = PacingAnalysis(
            wordsPerMinute: 90,
            totalWordCount: 90,
            totalPauseCount: 5,
            shortPauses: 2,
            mediumPauses: 2,
            longPauses: 1,
            averagePauseDuration: 1.0,
            averageSentenceLength: 10.0,
            duration: 60
        )

        XCTAssertFalse(slowPacing.isOptimalPace)
    }

    func testTooFastIsDetected() {
        let fastPacing = PacingAnalysis(
            wordsPerMinute: 200,
            totalWordCount: 200,
            totalPauseCount: 2,
            shortPauses: 2,
            mediumPauses: 0,
            longPauses: 0,
            averagePauseDuration: 0.3,
            averageSentenceLength: 25.0,
            duration: 60
        )

        XCTAssertFalse(fastPacing.isOptimalPace)
    }

    func testPacingScoreStaysInValidRange() {
        let veryFast = PacingAnalysis(
            wordsPerMinute: 300,
            totalWordCount: 300,
            totalPauseCount: 0,
            shortPauses: 0,
            mediumPauses: 0,
            longPauses: 0,
            averagePauseDuration: 0,
            averageSentenceLength: 50.0,
            duration: 60
        )

        let verySlow = PacingAnalysis(
            wordsPerMinute: 30,
            totalWordCount: 30,
            totalPauseCount: 20,
            shortPauses: 5,
            mediumPauses: 5,
            longPauses: 10,
            averagePauseDuration: 5.0,
            averageSentenceLength: 3.0,
            duration: 60
        )

        XCTAssertGreaterThanOrEqual(veryFast.score, 0)
        XCTAssertLessThanOrEqual(veryFast.score, 100)
        XCTAssertGreaterThanOrEqual(verySlow.score, 0)
        XCTAssertLessThanOrEqual(verySlow.score, 100)
    }
}

// MARK: - Confidence Analysis Tests

final class ConfidenceAnalysisTests: XCTestCase {

    func testHedgingPhrasesReduceConfidenceScore() {
        let confident = ConfidenceAnalysis(
            hedgingPhraseCount: 0,
            hedgingPhrases: [],
            questionWordCount: 2,
            weakOpenerCount: 0,
            apologeticPhraseCount: 0,
            assertivePhraseCount: 3,
            totalWordCount: 100
        )

        let hedging = ConfidenceAnalysis(
            hedgingPhraseCount: 5,
            hedgingPhrases: ["i think", "maybe", "kind of"],
            questionWordCount: 2,
            weakOpenerCount: 2,
            apologeticPhraseCount: 1,
            assertivePhraseCount: 0,
            totalWordCount: 100
        )

        XCTAssertGreaterThan(confident.score, hedging.score)
    }

    func testAssertiveLanguageBoostsScore() {
        let baseline = ConfidenceAnalysis(
            hedgingPhraseCount: 0,
            hedgingPhrases: [],
            questionWordCount: 0,
            weakOpenerCount: 0,
            apologeticPhraseCount: 0,
            assertivePhraseCount: 0,
            totalWordCount: 100
        )

        let assertive = ConfidenceAnalysis(
            hedgingPhraseCount: 0,
            hedgingPhrases: [],
            questionWordCount: 0,
            weakOpenerCount: 0,
            apologeticPhraseCount: 0,
            assertivePhraseCount: 5,
            totalWordCount: 100
        )

        XCTAssertGreaterThan(assertive.score, baseline.score)
    }
}

// MARK: - Tone Analysis Tests

final class ToneAnalysisTests: XCTestCase {

    func testPositiveSentimentIsDetected() {
        let positive = ToneAnalysis(
            sentimentScore: 0.5,
            positiveWordCount: 10,
            negativeWordCount: 2,
            contractionCount: 3,
            formalPhraseCount: 1,
            sentenceCount: 5
        )

        XCTAssertTrue(positive.isPositive)
        XCTAssertFalse(positive.isNegative)
    }

    func testNegativeSentimentIsDetected() {
        let negative = ToneAnalysis(
            sentimentScore: -0.5,
            positiveWordCount: 2,
            negativeWordCount: 10,
            contractionCount: 1,
            formalPhraseCount: 0,
            sentenceCount: 5
        )

        XCTAssertFalse(negative.isPositive)
        XCTAssertTrue(negative.isNegative)
    }

    func testNeutralSentimentIsNeitherPositiveNorNegative() {
        let neutral = ToneAnalysis(
            sentimentScore: 0.0,
            positiveWordCount: 5,
            negativeWordCount: 5,
            contractionCount: 2,
            formalPhraseCount: 1,
            sentenceCount: 5
        )

        XCTAssertFalse(neutral.isPositive)
        XCTAssertFalse(neutral.isNegative)
    }
}

// MARK: - Transcription Result Tests

final class TranscriptionResultTests: XCTestCase {

    func testWordCountIsCalculatedCorrectly() {
        let result = TranscriptionResult(
            text: "This is a test sentence with seven words",
            segments: []
        )

        XCTAssertEqual(result.wordCount, 7)
    }

    func testEmptyTextIsDetected() {
        let empty = TranscriptionResult(text: "", segments: [])
        let whitespace = TranscriptionResult(text: "   \n\t  ", segments: [])
        let content = TranscriptionResult(text: "Hello", segments: [])

        XCTAssertTrue(empty.isEmpty)
        XCTAssertTrue(whitespace.isEmpty)
        XCTAssertFalse(content.isEmpty)
    }
}

// FeedbackEngineTests.swift
// QuietCoachTests
//
// Unit tests for FeedbackEngine scoring logic.
// To use: Add a test target in Xcode (File > New > Target > Unit Testing Bundle)

import XCTest
@testable import QuietCoach

final class FeedbackEngineTests: XCTestCase {

    // MARK: - Score Clamping

    func testScoresAreClampedBetween0And100() {
        // Create metrics that would produce extreme scores
        let metrics = AudioMetrics(
            duration: 5,  // Very short
            rmsWindows: [],
            silenceRatio: 0.9,
            pauseCount: 0,
            spikeCount: 20
        )

        let scores = FeedbackEngine.generateScores(from: metrics, scenario: .jobInterview)

        // All scores should be within valid range
        XCTAssertGreaterThanOrEqual(scores.clarity, 0)
        XCTAssertLessThanOrEqual(scores.clarity, 100)
        XCTAssertGreaterThanOrEqual(scores.pacing, 0)
        XCTAssertLessThanOrEqual(scores.pacing, 100)
        XCTAssertGreaterThanOrEqual(scores.tone, 0)
        XCTAssertLessThanOrEqual(scores.tone, 100)
        XCTAssertGreaterThanOrEqual(scores.confidence, 0)
        XCTAssertLessThanOrEqual(scores.confidence, 100)
    }

    // MARK: - Overall Score

    func testOverallScoreIsAverageOfFourDimensions() {
        let scores = FeedbackScores(
            clarity: 80,
            pacing: 70,
            tone: 60,
            confidence: 90
        )

        XCTAssertEqual(scores.overall, 75)
    }

    // MARK: - Score Interpretation

    func testScoreInterpretationsAreAppropriate() {
        XCTAssertTrue(FeedbackEngine.interpretation(for: 95).contains("Excellent"))
        XCTAssertTrue(FeedbackEngine.interpretation(for: 85).contains("Strong"))
        XCTAssertTrue(FeedbackEngine.interpretation(for: 75).contains("Good"))
        XCTAssertTrue(FeedbackEngine.interpretation(for: 65).contains("Developing"))
        XCTAssertTrue(FeedbackEngine.interpretation(for: 55).contains("Room"))
        XCTAssertTrue(FeedbackEngine.interpretation(for: 40).contains("basics"))
    }

    // MARK: - Tier Classification

    func testScoreTiersAreCorrectlyClassified() {
        let excellent = FeedbackScores(clarity: 90, pacing: 90, tone: 90, confidence: 90)
        let good = FeedbackScores(clarity: 75, pacing: 75, tone: 75, confidence: 75)
        let developing = FeedbackScores(clarity: 60, pacing: 60, tone: 60, confidence: 60)
        let needsWork = FeedbackScores(clarity: 40, pacing: 40, tone: 40, confidence: 40)

        XCTAssertEqual(excellent.tier, .excellent)
        XCTAssertEqual(good.tier, .good)
        XCTAssertEqual(developing.tier, .developing)
        XCTAssertEqual(needsWork.tier, .needsWork)
    }

    // MARK: - Primary Strength/Weakness

    func testPrimaryStrengthIdentifiesHighestScore() {
        let scores = FeedbackScores(
            clarity: 90,  // Highest
            pacing: 70,
            tone: 60,
            confidence: 80
        )

        XCTAssertEqual(scores.primaryStrength, .clarity)
    }

    func testPrimaryWeaknessIdentifiesLowestScore() {
        let scores = FeedbackScores(
            clarity: 80,
            pacing: 70,
            tone: 50,  // Lowest
            confidence: 60
        )

        XCTAssertEqual(scores.primaryWeakness, .tone)
    }

    // MARK: - Score Delta

    func testScoreDeltaCalculatesImprovementsCorrectly() {
        let previous = FeedbackScores(clarity: 70, pacing: 60, tone: 80, confidence: 75)
        let current = FeedbackScores(clarity: 75, pacing: 65, tone: 75, confidence: 80)

        let delta = current.delta(from: previous)

        XCTAssertEqual(delta?.clarity, 5)
        XCTAssertEqual(delta?.pacing, 5)
        XCTAssertEqual(delta?.tone, -5)
        XCTAssertEqual(delta?.confidence, 5)
        XCTAssertTrue(delta?.hasImprovement ?? false)
        XCTAssertTrue(delta?.hasDecline ?? false)
    }

    func testDeltaFromNilReturnsNil() {
        let scores = FeedbackScores(clarity: 70, pacing: 60, tone: 80, confidence: 75)
        XCTAssertNil(scores.delta(from: nil))
    }

    // MARK: - Good Metrics Produce Good Scores

    func testGoodMetricsProduceGoodScores() {
        let goodMetrics = AudioMetrics(
            duration: 60,
            rmsWindows: Array(repeating: 0.3, count: 600),
            silenceRatio: 0.2,
            pauseCount: 3,
            spikeCount: 1
        )

        let scores = FeedbackEngine.generateScores(from: goodMetrics, scenario: .presentation)

        // With good metrics, all scores should be reasonably high
        XCTAssertGreaterThan(scores.overall, 60)
    }
}

// MARK: - Audio Metrics Factory

extension AudioMetrics {
    /// Create test metrics with sensible defaults
    static func testMetrics(
        duration: TimeInterval = 60,
        averageLevel: Float = 0.3,
        silenceRatio: Double = 0.2,
        pauseCount: Int = 5,
        spikeCount: Int = 2
    ) -> AudioMetrics {
        // Create RMS windows based on duration
        let windowCount = Int(duration * 10) // 10 windows per second
        let rmsWindows = (0..<windowCount).map { _ in
            averageLevel + Float.random(in: -0.1...0.1)
        }

        return AudioMetrics(
            duration: duration,
            rmsWindows: rmsWindows,
            silenceRatio: silenceRatio,
            pauseCount: pauseCount,
            spikeCount: spikeCount
        )
    }
}

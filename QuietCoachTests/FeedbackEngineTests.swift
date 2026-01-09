// FeedbackEngineTests.swift
// QuietCoachTests
//
// Unit tests for FeedbackEngine scoring logic.

import XCTest
@testable import QuietCoach

final class FeedbackEngineTests: XCTestCase {

    // MARK: - Score Clamping

    func testScoresAreClampedBetween0And100() {
        // Create metrics that would produce extreme scores (very short, minimal audio)
        let metrics = AudioMetrics(
            rmsWindows: [0.01],
            peakWindows: [0.02],
            duration: 5  // Very short
        )

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

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
        // Use the mock factory from AudioMetrics
        let goodMetrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        let scores = FeedbackEngine.generateScores(from: goodMetrics, scenario: scenario)

        // With good metrics, all scores should be reasonably high
        XCTAssertGreaterThan(scores.overall, 50)
    }
}

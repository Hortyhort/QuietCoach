// CoachNotesTests.swift
// QuietCoachTests
//
// Unit tests for CoachNote and feedback generation.

import XCTest
@testable import QuietCoach

final class CoachNoteTests: XCTestCase {

    func testCoachNoteHasRequiredProperties() {
        let note = CoachNote(
            title: "Test Title",
            body: "Test body message",
            type: .general,
            priority: .medium
        )

        XCTAssertEqual(note.title, "Test Title")
        XCTAssertEqual(note.body, "Test body message")
        XCTAssertEqual(note.type, .general)
        XCTAssertEqual(note.priority, .medium)
    }

    func testCoachNoteTypesExist() {
        let types: [CoachNote.NoteType] = [.scenario, .pacing, .intensity, .general]

        XCTAssertEqual(types.count, 4)
    }

    func testCoachNotePrioritiesAreOrdered() {
        XCTAssertTrue(CoachNote.Priority.low < CoachNote.Priority.medium)
        XCTAssertTrue(CoachNote.Priority.medium < CoachNote.Priority.high)
    }

    func testCoachNoteIsEquatableById() {
        let note1 = CoachNote(title: "Test", body: "Body", type: .general, priority: .low)
        let note2 = CoachNote(title: "Test", body: "Body", type: .general, priority: .low)

        // Different UUIDs means they're not equal
        XCTAssertNotEqual(note1.id, note2.id)

        // Same instance is equal
        XCTAssertEqual(note1.id, note1.id)
    }

    func testCoachNoteTemplates() {
        let tooFast = CoachNote.tooFast()
        XCTAssertEqual(tooFast.type, .pacing)
        XCTAssertEqual(tooFast.priority, .high)

        let tooSlow = CoachNote.tooSlow()
        XCTAssertEqual(tooSlow.type, .pacing)

        let speakUp = CoachNote.speakUp()
        XCTAssertEqual(speakUp.type, .intensity)
    }
}

// MARK: - Try Again Focus Tests

final class TryAgainFocusTests: XCTestCase {

    func testTryAgainFocusHasGoalAndReason() {
        let focus = TryAgainFocus(goal: "Test Goal", reason: "Test Reason")

        XCTAssertEqual(focus.goal, "Test Goal")
        XCTAssertEqual(focus.reason, "Test Reason")
    }

    func testTryAgainFocusDefaultExists() {
        let defaultFocus = TryAgainFocus.default

        XCTAssertFalse(defaultFocus.goal.isEmpty)
        XCTAssertFalse(defaultFocus.reason.isEmpty)
    }
}

// MARK: - Feedback Scores Tests

final class FeedbackScoresTests: XCTestCase {

    func testOverallScoreIsAverageOfFour() {
        let scores = FeedbackScores(clarity: 80, pacing: 60, tone: 100, confidence: 60)

        // (80 + 60 + 100 + 60) / 4 = 75
        XCTAssertEqual(scores.overall, 75)
    }

    func testOverallScoreRoundsDown() {
        let scores = FeedbackScores(clarity: 81, pacing: 81, tone: 81, confidence: 81)

        // (81 + 81 + 81 + 81) / 4 = 81 (integer division)
        XCTAssertEqual(scores.overall, 81)
    }

    func testPrimaryStrengthIdentifiesMax() {
        let scores = FeedbackScores(clarity: 70, pacing: 90, tone: 80, confidence: 85)

        XCTAssertEqual(scores.primaryStrength, .pacing)
    }

    func testPrimaryWeaknessIdentifiesMin() {
        let scores = FeedbackScores(clarity: 70, pacing: 90, tone: 80, confidence: 85)

        XCTAssertEqual(scores.primaryWeakness, .clarity)
    }

    func testTierClassification() {
        XCTAssertEqual(FeedbackScores(clarity: 90, pacing: 90, tone: 90, confidence: 90).tier, .excellent)
        XCTAssertEqual(FeedbackScores(clarity: 80, pacing: 80, tone: 80, confidence: 80).tier, .good)
        XCTAssertEqual(FeedbackScores(clarity: 65, pacing: 65, tone: 65, confidence: 65).tier, .developing)
        XCTAssertEqual(FeedbackScores(clarity: 40, pacing: 40, tone: 40, confidence: 40).tier, .needsWork)
    }

    func testTierBoundaries() {
        // Test exact boundaries
        XCTAssertEqual(FeedbackScores(clarity: 85, pacing: 85, tone: 85, confidence: 85).tier, .excellent)
        XCTAssertEqual(FeedbackScores(clarity: 84, pacing: 84, tone: 84, confidence: 84).tier, .good)
        XCTAssertEqual(FeedbackScores(clarity: 70, pacing: 70, tone: 70, confidence: 70).tier, .good)
        XCTAssertEqual(FeedbackScores(clarity: 69, pacing: 69, tone: 69, confidence: 69).tier, .developing)
        XCTAssertEqual(FeedbackScores(clarity: 55, pacing: 55, tone: 55, confidence: 55).tier, .developing)
        XCTAssertEqual(FeedbackScores(clarity: 54, pacing: 54, tone: 54, confidence: 54).tier, .needsWork)
    }

    func testEmptyScoresAreZero() {
        let empty = FeedbackScores.empty

        XCTAssertEqual(empty.clarity, 0)
        XCTAssertEqual(empty.pacing, 0)
        XCTAssertEqual(empty.tone, 0)
        XCTAssertEqual(empty.confidence, 0)
        XCTAssertEqual(empty.overall, 0)
    }
}

// MARK: - Score Delta Tests

final class ScoreDeltaTests: XCTestCase {

    func testDeltaCalculation() {
        let previous = FeedbackScores(clarity: 70, pacing: 60, tone: 80, confidence: 75)
        let current = FeedbackScores(clarity: 75, pacing: 55, tone: 85, confidence: 75)

        let delta = current.delta(from: previous)

        XCTAssertNotNil(delta)
        XCTAssertEqual(delta?.clarity, 5)
        XCTAssertEqual(delta?.pacing, -5)
        XCTAssertEqual(delta?.tone, 5)
        XCTAssertEqual(delta?.confidence, 0)
    }

    func testDeltaFromNilIsNil() {
        let scores = FeedbackScores(clarity: 80, pacing: 70, tone: 60, confidence: 90)

        XCTAssertNil(scores.delta(from: nil))
    }

    func testHasImprovementDetectsPositiveChanges() {
        let delta = ScoreDelta(clarity: 5, pacing: 0, tone: -3, confidence: 0)

        XCTAssertTrue(delta.hasImprovement)
    }

    func testHasDeclineDetectsNegativeChanges() {
        let delta = ScoreDelta(clarity: 5, pacing: 0, tone: -3, confidence: 0)

        XCTAssertTrue(delta.hasDecline)
    }

    func testNoChangeMeansNoImprovementOrDecline() {
        let delta = ScoreDelta(clarity: 0, pacing: 0, tone: 0, confidence: 0)

        XCTAssertFalse(delta.hasImprovement)
        XCTAssertFalse(delta.hasDecline)
    }

    func testFormattedDeltaShowsPlusForPositive() {
        let delta = ScoreDelta(clarity: 5, pacing: -3, tone: 0, confidence: 10)

        XCTAssertEqual(delta.formatted(5), "+5")
        XCTAssertEqual(delta.formatted(-3), "-3")
        XCTAssertEqual(delta.formatted(0), "0")
    }
}

// MARK: - Score Type Tests

final class ScoreTypeTests: XCTestCase {

    func testAllScoreTypesHaveIcons() {
        for type in FeedbackScores.ScoreType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type) should have an icon")
        }
    }

    func testAllScoreTypesHaveExplanations() {
        for type in FeedbackScores.ScoreType.allCases {
            XCTAssertFalse(type.explanation.isEmpty, "\(type) should have an explanation")
        }
    }

    func testScoreTypeRawValuesAreCapitalized() {
        for type in FeedbackScores.ScoreType.allCases {
            let firstChar = type.rawValue.first!
            XCTAssertTrue(firstChar.isUppercase, "\(type.rawValue) should be capitalized")
        }
    }
}

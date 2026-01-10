// ErrorHandlingTests.swift
// QuietCoachTests
//
// Unit tests for error handling, edge cases, and graceful degradation.

import XCTest
@testable import QuietCoach

// MARK: - Recording Error Tests

final class RecordingErrorTests: XCTestCase {

    func testMicrophoneAccessDeniedHasRecoveryAction() {
        let error = RecordingError.microphoneAccessDenied

        XCTAssertEqual(error.title, "Microphone Access Required")
        XCTAssertEqual(error.recoveryAction, .openSettings)
        XCTAssertTrue(error.isRecoverable)
    }

    func testRecordingInterruptedIsRecoverable() {
        let error = RecordingError.recordingInterrupted

        XCTAssertEqual(error.recoveryAction, .retry)
        XCTAssertTrue(error.isRecoverable)
        XCTAssertEqual(error.logLevel, .info) // External event, not a bug
    }

    func testNoAudioRecordedHasClearMessage() {
        let error = RecordingError.noAudioRecorded

        XCTAssertTrue(error.message.contains("microphone"))
        XCTAssertEqual(error.recoveryAction, .retry)
    }

    func testAudioSessionFailedIncludesUnderlyingError() {
        let underlying = NSError(domain: "AVAudioSession", code: -10, userInfo: nil)
        let error = RecordingError.audioSessionFailed(underlying)

        XCTAssertTrue(error.message.contains("Could not set up"))
        XCTAssertEqual(error.logLevel, .error)
    }

    func testSaveFailedIsRecoverable() {
        let underlying = NSError(domain: "FileManager", code: -1, userInfo: nil)
        let error = RecordingError.saveFailed(underlying)

        XCTAssertEqual(error.recoveryAction, .retry)
    }
}

// MARK: - Analysis Error Tests

final class AnalysisErrorTests: XCTestCase {

    func testSpeechRecognitionDeniedOpensSettings() {
        let error = AnalysisError.speechRecognitionDenied

        XCTAssertEqual(error.recoveryAction, .openSettings)
        XCTAssertTrue(error.message.contains("speech recognition"))
    }

    func testSpeechRecognizerUnavailableDismisses() {
        let error = AnalysisError.speechRecognizerUnavailable

        XCTAssertEqual(error.recoveryAction, .dismiss)
        XCTAssertTrue(error.message.contains("Audio-only feedback"))
    }

    func testInsufficientAudioGivesGuidance() {
        let error = AnalysisError.insufficientAudio

        XCTAssertTrue(error.message.contains("10 seconds"))
        XCTAssertEqual(error.recoveryAction, .retry)
    }

    func testAnalysisTimeoutIsRecoverable() {
        let error = AnalysisError.analysisTimeout

        XCTAssertTrue(error.message.contains("shorter recording"))
        XCTAssertEqual(error.recoveryAction, .retry)
    }

    func testTranscriptionFailedSuggestsClarity() {
        let underlying = NSError(domain: "Speech", code: -1, userInfo: nil)
        let error = AnalysisError.transcriptionFailed(underlying)

        XCTAssertTrue(error.message.contains("more clearly"))
    }
}

// MARK: - Storage Error Tests

final class StorageErrorTests: XCTestCase {

    func testInsufficientSpaceOpensSettings() {
        let error = StorageError.insufficientSpace

        XCTAssertEqual(error.recoveryAction, .openSettings)
        XCTAssertTrue(error.message.contains("low on storage"))
    }

    func testFileNotFoundDismisses() {
        let error = StorageError.fileNotFound

        XCTAssertEqual(error.recoveryAction, .dismiss)
        XCTAssertTrue(error.message.contains("deleted"))
    }

    func testCorruptedDataContactsSupport() {
        let error = StorageError.corruptedData

        XCTAssertEqual(error.recoveryAction, .contactSupport)
    }

    func testLoadFailedIsRecoverable() {
        let underlying = NSError(domain: "SwiftData", code: -1, userInfo: nil)
        let error = StorageError.loadFailed(underlying)

        XCTAssertEqual(error.recoveryAction, .retry)
    }
}

// MARK: - Subscription Error Tests

final class SubscriptionErrorTests: XCTestCase {

    func testPurchaseCancelledNeedsNoAction() {
        let error = SubscriptionError.purchaseCancelled

        XCTAssertEqual(error.recoveryAction, .dismiss)
        XCTAssertTrue(error.message.contains("No charges"))
    }

    func testNetworkErrorIsRecoverable() {
        let error = SubscriptionError.networkError

        XCTAssertEqual(error.recoveryAction, .retry)
        XCTAssertTrue(error.message.contains("internet"))
    }

    func testRestoreFailedIsRecoverable() {
        let underlying = NSError(domain: "StoreKit", code: -1, userInfo: nil)
        let error = SubscriptionError.restoreFailed(underlying)

        XCTAssertEqual(error.recoveryAction, .retry)
    }
}

// MARK: - Error Recovery Action Tests

final class ErrorRecoveryActionTests: XCTestCase {

    func testRetryButtonTitle() {
        XCTAssertEqual(ErrorRecoveryAction.retry.buttonTitle, "Try Again")
    }

    func testOpenSettingsButtonTitle() {
        XCTAssertEqual(ErrorRecoveryAction.openSettings.buttonTitle, "Open Settings")
    }

    func testRequestPermissionButtonTitle() {
        XCTAssertEqual(ErrorRecoveryAction.requestPermission.buttonTitle, "Grant Permission")
    }

    func testDismissButtonTitle() {
        XCTAssertEqual(ErrorRecoveryAction.dismiss.buttonTitle, "OK")
    }

    func testContactSupportButtonTitle() {
        XCTAssertEqual(ErrorRecoveryAction.contactSupport.buttonTitle, "Get Help")
    }
}

// MARK: - Edge Case Tests

final class EdgeCaseTests: XCTestCase {

    func testEmptyRecordingProducesValidMetrics() {
        // Given: Empty audio metrics (no samples)
        let emptyMetrics = AudioMetrics(
            rmsWindows: [],
            peakWindows: [],
            duration: 0
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(emptyMetrics)

        // Then: Returns valid defaults without crashing
        XCTAssertEqual(analyzed.pauseCount, 0)
        XCTAssertEqual(analyzed.spikeCount, 0)
        XCTAssertEqual(analyzed.volumeStability, 1.0)
        XCTAssertEqual(analyzed.silenceRatio, 0)
    }

    func testVeryShortRecordingIsHandled() {
        // Given: Very short recording (1 second)
        let shortMetrics = AudioMetrics(
            rmsWindows: [0.3, 0.4, 0.35],
            peakWindows: [0.4, 0.5, 0.45],
            duration: 0.3
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(shortMetrics)

        // Then: Valid metrics produced
        XCTAssertGreaterThanOrEqual(analyzed.volumeStability, 0)
        XCTAssertLessThanOrEqual(analyzed.volumeStability, 1)
    }

    func testAllSilenceRecordingIsHandled() {
        // Given: Recording of all silence
        let silentMetrics = AudioMetrics(
            rmsWindows: Array(repeating: Float(0.005), count: 100),
            peakWindows: Array(repeating: Float(0.01), count: 100),
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(silentMetrics)

        // Then: High silence ratio, flagged as too quiet
        XCTAssertGreaterThan(analyzed.silenceRatio, 0.9)
        XCTAssertTrue(analyzed.isTooQuiet)
        XCTAssertTrue(analyzed.hasTooMuchSilence)
    }

    func testExtremelyLoudRecordingIsHandled() {
        // Given: Recording at max volume
        let loudMetrics = AudioMetrics(
            rmsWindows: Array(repeating: Float(1.0), count: 100),
            peakWindows: Array(repeating: Float(1.0), count: 100),
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(loudMetrics)

        // Then: High stability (consistent), no spikes (all same level)
        XCTAssertEqual(analyzed.volumeStability, 1.0, accuracy: 0.01)
        XCTAssertEqual(analyzed.spikeCount, 0)
    }

    func testMaxDurationRecordingIsHandled() {
        // Given: Recording at max allowed duration (5 minutes = 3000 windows at 0.1s)
        let sampleCount = 3000
        var rmsWindows: [Float] = []
        for i in 0..<sampleCount {
            rmsWindows.append(Float.random(in: 0.2...0.5))
        }

        let longMetrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 300
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(longMetrics)

        // Then: Valid metrics produced
        XCTAssertGreaterThan(analyzed.effectiveDuration, 0)
        XCTAssertLessThanOrEqual(analyzed.effectiveDuration, analyzed.duration)
    }
}

// MARK: - Graceful Degradation Tests

final class GracefulDegradationTests: XCTestCase {

    func testFeedbackScoresClampedToValidRange() {
        // Test that scores never exceed 100 or go below 0
        let extremeMetrics = AudioMetrics(
            rmsWindows: Array(repeating: Float(0.5), count: 1000),
            peakWindows: Array(repeating: Float(0.6), count: 1000),
            duration: 100
        )

        let scores = FeedbackEngine.generateScores(
            from: extremeMetrics,
            scenario: Scenario.allScenarios[0]
        )

        XCTAssertGreaterThanOrEqual(scores.clarity, 0)
        XCTAssertLessThanOrEqual(scores.clarity, 100)
        XCTAssertGreaterThanOrEqual(scores.pacing, 0)
        XCTAssertLessThanOrEqual(scores.pacing, 100)
        XCTAssertGreaterThanOrEqual(scores.tone, 0)
        XCTAssertLessThanOrEqual(scores.tone, 100)
        XCTAssertGreaterThanOrEqual(scores.confidence, 0)
        XCTAssertLessThanOrEqual(scores.confidence, 100)
    }

    func testScoreInterpretationCoversAllRanges() {
        // Test all score tiers have interpretations
        let tiers = [95, 85, 75, 65, 55, 40]

        for score in tiers {
            let interpretation = FeedbackEngine.interpretation(for: score)
            XCTAssertFalse(interpretation.isEmpty, "Score \(score) should have interpretation")
        }
    }

    func testEmojiForAllScoreTiers() {
        let tiers = [95, 80, 60, 40]

        for score in tiers {
            let emoji = FeedbackEngine.emoji(for: score)
            XCTAssertFalse(emoji.isEmpty, "Score \(score) should have emoji")
        }
    }
}

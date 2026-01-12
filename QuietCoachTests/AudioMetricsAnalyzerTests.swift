// AudioMetricsAnalyzerTests.swift
// QuietCoachTests
//
// Unit tests for AudioMetricsAnalyzer - pause detection, spike detection, and rhythm analysis.

import XCTest
@testable import QuietCoach

final class AudioMetricsAnalyzerTests: XCTestCase {

    // MARK: - Pause Detection Tests

    func testNoPausesDetectedInContinuousSpeech() {
        // Given: Continuous audio with no silence
        let rmsWindows = Array(repeating: Float(0.3), count: 100)
        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: No pauses detected
        XCTAssertEqual(analyzed.pauseCount, 0)
    }

    func testPausesDetectedInSpeechWithSilence() {
        // Given: Audio with distinct pauses (silence gaps)
        var rmsWindows: [Float] = []

        // Speech
        rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 20))
        // Pause (silence)
        rmsWindows.append(contentsOf: Array(repeating: Float(0.005), count: 5))
        // Speech
        rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 20))
        // Pause (silence)
        rmsWindows.append(contentsOf: Array(repeating: Float(0.005), count: 5))
        // Speech
        rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 20))

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 7
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: Pauses are detected
        XCTAssertEqual(analyzed.pauseCount, 2)
    }

    func testShortSilenceIsNotCountedAsPause() {
        // Given: Audio with very short silence (less than min consecutive windows)
        var rmsWindows: [Float] = []

        rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 20))
        // Too short to count as pause (only 2 windows, min is 3)
        rmsWindows.append(contentsOf: Array(repeating: Float(0.005), count: 2))
        rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 20))

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 4.2
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: No pauses detected (silence too short)
        XCTAssertEqual(analyzed.pauseCount, 0)
    }

    // MARK: - Spike Detection Tests

    func testNoSpikesInConsistentAudio() {
        // Given: Consistent volume audio
        let rmsWindows = Array(repeating: Float(0.3), count: 100)
        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: No spikes detected
        XCTAssertEqual(analyzed.spikeCount, 0)
    }

    func testSpikesDetectedInVariableAudio() {
        // Given: Audio with distinct volume spikes
        var rmsWindows = Array(repeating: Float(0.2), count: 50)
        // Add loud spikes
        rmsWindows[10] = 0.9
        rmsWindows[25] = 0.85
        rmsWindows[40] = 0.95

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 5
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: Spikes are detected
        XCTAssertGreaterThan(analyzed.spikeCount, 0)
    }

    // MARK: - Volume Stability Tests

    func testPerfectStabilityForConstantVolume() {
        // Given: Perfectly constant volume
        let rmsWindows = Array(repeating: Float(0.3), count: 100)
        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: Stability is perfect (1.0)
        XCTAssertEqual(analyzed.volumeStability, 1.0, accuracy: 0.01)
    }

    func testLowStabilityForVariableVolume() {
        // Given: Highly variable volume
        var rmsWindows: [Float] = []
        for i in 0..<100 {
            rmsWindows.append(i % 2 == 0 ? 0.1 : 0.9)
        }

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: Stability is low
        XCTAssertLessThan(analyzed.volumeStability, 0.5)
    }

    // MARK: - Silence Ratio Tests

    func testSilenceRatioIsZeroForContinuousSpeech() {
        // Given: All audio above noise floor
        let rmsWindows = Array(repeating: Float(0.3), count: 100)
        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: No silence
        XCTAssertEqual(analyzed.silenceRatio, 0.0, accuracy: 0.01)
    }

    func testSilenceRatioForHalfSilentRecording() {
        // Given: Half speech, half silence
        var rmsWindows: [Float] = []
        rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 50))
        rmsWindows.append(contentsOf: Array(repeating: Float(0.005), count: 50))

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: 50% silence
        XCTAssertEqual(analyzed.silenceRatio, 0.5, accuracy: 0.01)
    }

    // MARK: - Segments Per Minute Tests

    func testSegmentsPerMinuteCalculation() {
        // Given: Audio with clear speech segments
        var rmsWindows: [Float] = []

        // Create 4 distinct speech segments in 60 seconds worth of windows
        for _ in 0..<4 {
            // Speech segment
            rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 100))
            // Silence between
            rmsWindows.append(contentsOf: Array(repeating: Float(0.005), count: 50))
        }

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 60
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: About 4 segments per minute
        XCTAssertEqual(analyzed.segmentsPerMinute, 4, accuracy: 1)
    }

    // MARK: - Effective Duration Tests

    func testEffectiveDurationExcludesSilence() {
        // Given: Recording with 50% silence
        var rmsWindows: [Float] = []
        rmsWindows.append(contentsOf: Array(repeating: Float(0.3), count: 50))
        rmsWindows.append(contentsOf: Array(repeating: Float(0.005), count: 50))

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: Effective duration is roughly half
        XCTAssertLessThan(analyzed.effectiveDuration, analyzed.duration)
    }

    // MARK: - Derived Properties Tests

    func testIsPacingTooFast() {
        // Given: Metrics with high segments per minute
        let analyzed = AnalyzedMetrics(
            profile: .default,
            pauseCount: 0,
            spikeCount: 0,
            segmentsPerMinute: 50, // > 40 threshold
            volumeStability: 0.8,
            averageLevel: 0.3,
            peakLevel: 0.5,
            silenceRatio: 0.1,
            duration: 60,
            effectiveDuration: 54
        )

        // Then: Pacing is too fast
        XCTAssertTrue(analyzed.isPacingTooFast)
        XCTAssertFalse(analyzed.isPacingTooSlow)
    }

    func testIsPacingTooSlow() {
        // Given: Metrics with low segments per minute
        let analyzed = AnalyzedMetrics(
            profile: .default,
            pauseCount: 5,
            spikeCount: 0,
            segmentsPerMinute: 5, // < 10 threshold
            volumeStability: 0.8,
            averageLevel: 0.3,
            peakLevel: 0.5,
            silenceRatio: 0.4,
            duration: 60,
            effectiveDuration: 36
        )

        // Then: Pacing is too slow
        XCTAssertFalse(analyzed.isPacingTooFast)
        XCTAssertTrue(analyzed.isPacingTooSlow)
    }

    func testHasTooManySpikes() {
        // Given: Metrics with many spikes
        let analyzed = AnalyzedMetrics(
            profile: .default,
            pauseCount: 2,
            spikeCount: 10, // > 5 per minute
            segmentsPerMinute: 20,
            volumeStability: 0.5,
            averageLevel: 0.3,
            peakLevel: 0.9,
            silenceRatio: 0.2,
            duration: 60,
            effectiveDuration: 48
        )

        // Then: Too many spikes
        XCTAssertTrue(analyzed.hasTooManySpikes)
    }

    func testHasInconsistentVolume() {
        // Given: Metrics with low stability
        let analyzed = AnalyzedMetrics(
            profile: .default,
            pauseCount: 2,
            spikeCount: 3,
            segmentsPerMinute: 20,
            volumeStability: 0.3, // < 0.5 threshold
            averageLevel: 0.3,
            peakLevel: 0.8,
            silenceRatio: 0.2,
            duration: 60,
            effectiveDuration: 48
        )

        // Then: Volume is inconsistent
        XCTAssertTrue(analyzed.hasInconsistentVolume)
    }

    func testIsTooQuiet() {
        // Given: Metrics with low average level
        let analyzed = AnalyzedMetrics(
            profile: .default,
            pauseCount: 2,
            spikeCount: 1,
            segmentsPerMinute: 20,
            volumeStability: 0.8,
            averageLevel: 0.05, // < 0.1 threshold
            peakLevel: 0.2,
            silenceRatio: 0.2,
            duration: 60,
            effectiveDuration: 48
        )

        // Then: Too quiet
        XCTAssertTrue(analyzed.isTooQuiet)
    }

    func testHasTooMuchSilence() {
        // Given: Metrics with high silence ratio
        let analyzed = AnalyzedMetrics(
            profile: .default,
            pauseCount: 5,
            spikeCount: 1,
            segmentsPerMinute: 15,
            volumeStability: 0.8,
            averageLevel: 0.3,
            peakLevel: 0.5,
            silenceRatio: 0.6, // > 0.5 threshold
            duration: 60,
            effectiveDuration: 24
        )

        // Then: Too much silence
        XCTAssertTrue(analyzed.hasTooMuchSilence)
    }

    func testIdealPauseCount() {
        // Given: 60 second recording
        let analyzed = AnalyzedMetrics(
            profile: .default,
            pauseCount: 3,
            spikeCount: 1,
            segmentsPerMinute: 20,
            volumeStability: 0.8,
            averageLevel: 0.3,
            peakLevel: 0.5,
            silenceRatio: 0.2,
            duration: 60,
            effectiveDuration: 48
        )

        // Then: Ideal is about 3 pauses (one per 20 seconds)
        XCTAssertEqual(analyzed.idealPauseCount, 3)
        XCTAssertTrue(analyzed.hasGoodPausePattern)
    }

    // MARK: - Edge Cases

    func testEmptyMetricsHandledGracefully() {
        // Given: Empty audio data
        let metrics = AudioMetrics(
            rmsWindows: [],
            peakWindows: [],
            duration: 0
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: Defaults are returned without crash
        XCTAssertEqual(analyzed.pauseCount, 0)
        XCTAssertEqual(analyzed.spikeCount, 0)
        XCTAssertEqual(analyzed.volumeStability, 1.0)
    }

    func testSingleWindowHandledGracefully() {
        // Given: Single audio sample
        let metrics = AudioMetrics(
            rmsWindows: [0.3],
            peakWindows: [0.4],
            duration: 0.1
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: Analysis completes without crash
        XCTAssertEqual(analyzed.spikeCount, 0)
        XCTAssertEqual(analyzed.volumeStability, 1.0)
    }

    func testAllSilenceHandledGracefully() {
        // Given: All silence
        let rmsWindows = Array(repeating: Float(0.005), count: 100)
        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: rmsWindows,
            duration: 10
        )

        // When: Analyzed
        let analyzed = AudioMetricsAnalyzer.analyze(metrics)

        // Then: High silence ratio, no crashes
        XCTAssertGreaterThan(analyzed.silenceRatio, 0.9)
        XCTAssertEqual(analyzed.averageLevel, 0)
    }
}

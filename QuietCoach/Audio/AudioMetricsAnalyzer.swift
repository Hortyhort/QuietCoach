// AudioMetricsAnalyzer.swift
// QuietCoach
//
// Post-recording analysis. Takes raw audio metrics and extracts
// meaningful patterns for feedback scoring.
//
// ## Algorithm Overview
//
// The analyzer processes RMS (root mean square) audio windows to detect:
// - **Pauses**: Consecutive windows below noise floor (indicates intentional breaks)
// - **Spikes**: Windows exceeding 2 standard deviations from mean (volume control)
// - **Rhythm**: Speech segment transitions per minute (pacing indicator)
// - **Stability**: Coefficient of variation inverted to 0-1 scale (consistency)
//
// These metrics map to the four scoring dimensions:
// - Clarity ← pause patterns, silence ratio
// - Pacing ← segments per minute, effective duration
// - Tone ← volume stability, spike count
// - Confidence ← average level, silence ratio

import Foundation

struct AudioMetricsAnalyzer {

    // MARK: - Main Analysis

    /// Analyze raw audio metrics into structured patterns.
    ///
    /// - Parameters:
    ///   - metrics: Raw RMS and peak windows from the recording
    ///   - profile: Centralized scoring thresholds
    /// - Returns: Analyzed patterns ready for scoring
    static func analyze(_ metrics: AudioMetrics, profile: ScoringProfile = .default) -> AnalyzedMetrics {
        let noiseFloor = profile.audio.noiseFloor

        // Filter out noise
        let effectiveWindows = metrics.rmsWindows.filter { $0 > noiseFloor }

        // Calculate patterns
        let pauses = countPauses(
            windows: metrics.rmsWindows,
            threshold: noiseFloor,
            minConsecutiveWindows: profile.audio.pauseMinConsecutiveWindows
        )

        let spikes = countSpikes(
            windows: metrics.rmsWindows,
            stdDevMultiplier: profile.audio.spikeStdDevMultiplier
        )

        let segmentsPerMin = calculateSegmentsPerMinute(
            windows: metrics.rmsWindows,
            threshold: noiseFloor,
            duration: metrics.duration
        )

        let stability = calculateVolumeStability(windows: effectiveWindows)

        let averageLevel = effectiveWindows.isEmpty
            ? 0
            : effectiveWindows.reduce(0, +) / Float(effectiveWindows.count)

        let silenceRatio = metrics.rmsWindows.isEmpty
            ? 0
            : Float(metrics.rmsWindows.count - effectiveWindows.count) / Float(metrics.rmsWindows.count)

        return AnalyzedMetrics(
            profile: profile,
            pauseCount: pauses,
            spikeCount: spikes,
            segmentsPerMinute: segmentsPerMin,
            volumeStability: stability,
            averageLevel: averageLevel,
            peakLevel: metrics.peakWindows.max() ?? 0,
            silenceRatio: silenceRatio,
            duration: metrics.duration,
            effectiveDuration: calculateEffectiveDuration(
                windows: metrics.rmsWindows,
                threshold: noiseFloor,
                intervalSeconds: Constants.Limits.meteringInterval
            )
        )
    }

    // MARK: - Pause Detection

    /// Count distinct pause events (consecutive silence).
    ///
    /// A pause is detected when `minConsecutiveWindows` or more consecutive
    /// windows fall below the noise threshold. This filters out brief hesitations
    /// and captures intentional breaks in speech.
    ///
    /// At the default metering interval of 0.1s and minConsecutive of 3,
    /// a pause must be at least 0.3 seconds to register.
    ///
    /// - Parameters:
    ///   - windows: RMS values for each audio window
    ///   - threshold: Level below which audio is considered silence
    ///   - minConsecutiveWindows: Minimum consecutive silent windows to count as pause
    /// - Returns: Number of distinct pause events
    private static func countPauses(
        windows: [Float],
        threshold: Float,
        minConsecutiveWindows: Int
    ) -> Int {
        var count = 0
        var consecutiveSilent = 0

        for rms in windows {
            if rms < threshold {
                consecutiveSilent += 1
            } else {
                // Transition from silence to speech - count if long enough
                if consecutiveSilent >= minConsecutiveWindows {
                    count += 1
                }
                consecutiveSilent = 0
            }
        }

        // Check for trailing pause (recording ended during silence)
        if consecutiveSilent >= minConsecutiveWindows {
            count += 1
        }

        return count
    }

    // MARK: - Spike Detection

    /// Count volume spikes (sudden loudness increases).
    ///
    /// Uses statistical analysis to identify outliers. A spike is any window
    /// that exceeds `mean + (stdDev × stdDevMultiplier)`. With the default
    /// multiplier of 2.0, this captures values in the top ~2.5% of the distribution.
    ///
    /// Too many spikes indicates poor volume control or nervous energy.
    /// Some spikes are natural for emphasis, but excessive spikes hurt tone scores.
    ///
    /// - Parameters:
    ///   - windows: RMS values for each audio window
    ///   - stdDevMultiplier: How many standard deviations above mean constitutes a spike
    /// - Returns: Number of windows exceeding the spike threshold
    private static func countSpikes(
        windows: [Float],
        stdDevMultiplier: Float
    ) -> Int {
        guard windows.count > 1 else { return 0 }

        // Calculate mean (average volume level)
        let mean = windows.reduce(0, +) / Float(windows.count)

        // Calculate variance and standard deviation
        let variance = windows.map { pow($0 - mean, 2) }.reduce(0, +) / Float(windows.count)
        let stdDev = sqrt(variance)

        // Spike threshold = mean + (stdDev × multiplier)
        let threshold = mean + (stdDev * stdDevMultiplier)

        return windows.filter { $0 > threshold }.count
    }

    // MARK: - Rhythm Analysis

    /// Calculate speaking segments per minute (rhythm indicator)
    private static func calculateSegmentsPerMinute(
        windows: [Float],
        threshold: Float,
        duration: TimeInterval
    ) -> Float {
        guard duration > 0 else { return 0 }

        var segmentCount = 0
        var inVoicedSegment = false

        for rms in windows {
            if rms >= threshold {
                if !inVoicedSegment {
                    segmentCount += 1
                    inVoicedSegment = true
                }
            } else {
                inVoicedSegment = false
            }
        }

        // Convert to per-minute rate
        let minutes = max(0.1, duration / 60.0)
        return Float(segmentCount) / Float(minutes)
    }

    // MARK: - Stability Analysis

    /// Calculate volume consistency (0 = chaotic, 1 = perfectly stable)
    private static func calculateVolumeStability(windows: [Float]) -> Float {
        guard windows.count > 1 else { return 1.0 }

        let mean = windows.reduce(0, +) / Float(windows.count)
        guard mean > 0 else { return 1.0 }

        // Coefficient of variation (lower = more stable)
        let variance = windows.map { pow($0 - mean, 2) }.reduce(0, +) / Float(windows.count)
        let stdDev = sqrt(variance)
        let cv = stdDev / mean

        // Invert and clamp to 0-1 range
        // CV of 0 = perfect stability (1.0)
        // CV of 1+ = very unstable (0.0)
        return max(0, min(1, 1 - cv))
    }

    // MARK: - Duration Analysis

    /// Calculate effective speaking duration (excluding silence)
    private static func calculateEffectiveDuration(
        windows: [Float],
        threshold: Float,
        intervalSeconds: TimeInterval
    ) -> TimeInterval {
        let voicedWindows = windows.filter { $0 >= threshold }.count
        return TimeInterval(voicedWindows) * intervalSeconds
    }
}

// MARK: - Analyzed Metrics

struct AnalyzedMetrics {
    let profile: ScoringProfile

    /// Number of distinct pause events
    let pauseCount: Int

    /// Number of volume spikes
    let spikeCount: Int

    /// Speaking segments per minute (rhythm)
    let segmentsPerMinute: Float

    /// Volume consistency (0-1, higher = more stable)
    let volumeStability: Float

    /// Average volume level during speech
    let averageLevel: Float

    /// Peak volume level
    let peakLevel: Float

    /// Ratio of silence to total duration
    let silenceRatio: Float

    /// Total recording duration
    let duration: TimeInterval

    /// Duration spent actually speaking
    let effectiveDuration: TimeInterval

    // MARK: - Derived Properties

    /// Whether pacing seems too fast
    var isPacingTooFast: Bool {
        segmentsPerMinute > profile.audio.pacingTooFastSegmentsPerMinute
    }

    /// Whether pacing seems too slow
    var isPacingTooSlow: Bool {
        segmentsPerMinute < profile.audio.pacingTooSlowSegmentsPerMinute
    }

    /// Whether there are too many intensity spikes
    var hasTooManySpikes: Bool {
        guard duration > 0 else { return false }
        let spikesPerMinute = Float(spikeCount) / Float(duration / 60)
        return spikesPerMinute > profile.audio.spikesPerMinuteMax
    }

    /// Whether volume is inconsistent
    var hasInconsistentVolume: Bool {
        volumeStability < profile.audio.volumeStabilityMinimum
    }

    /// Whether average level is too quiet
    var isTooQuiet: Bool {
        averageLevel < profile.audio.averageLevelMinimum
    }

    /// Whether there's too much silence
    var hasTooMuchSilence: Bool {
        silenceRatio > profile.audio.silenceRatioMax
    }

    /// Ideal pause count based on duration
    var idealPauseCount: Int {
        // Roughly one pause every configured interval
        max(1, Int(duration / profile.audio.idealPauseIntervalSeconds))
    }

    /// Whether pause count is optimal
    var hasGoodPausePattern: Bool {
        let ideal = idealPauseCount
        let tolerance = max(1, Int(Float(ideal) * profile.audio.pauseToleranceFactor))
        return abs(pauseCount - ideal) <= tolerance
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension AnalyzedMetrics {
    /// Create mock analyzed metrics for testing
    static func mock() -> AnalyzedMetrics {
        AnalyzedMetrics(
            profile: .default,
            pauseCount: 3,
            spikeCount: 2,
            segmentsPerMinute: 22,
            volumeStability: 0.75,
            averageLevel: 0.35,
            peakLevel: 0.8,
            silenceRatio: 0.2,
            duration: 45,
            effectiveDuration: 36
        )
    }
}
#endif

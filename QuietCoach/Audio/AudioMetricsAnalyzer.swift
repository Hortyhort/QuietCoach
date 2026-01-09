// AudioMetricsAnalyzer.swift
// QuietCoach
//
// Post-recording analysis. Takes raw audio metrics and extracts
// meaningful patterns for feedback scoring.

import Foundation

struct AudioMetricsAnalyzer {

    // MARK: - Main Analysis

    /// Analyze raw audio metrics into structured patterns
    static func analyze(_ metrics: AudioMetrics, noiseFloor: Float = 0.01) -> AnalyzedMetrics {
        // Filter out noise
        let effectiveWindows = metrics.rmsWindows.filter { $0 > noiseFloor }

        // Calculate patterns
        let pauses = countPauses(
            windows: metrics.rmsWindows,
            threshold: noiseFloor,
            minConsecutiveWindows: 3
        )

        let spikes = countSpikes(
            windows: metrics.rmsWindows,
            stdDevMultiplier: 2.0
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

    /// Count distinct pause events (consecutive silence)
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
                if consecutiveSilent >= minConsecutiveWindows {
                    count += 1
                }
                consecutiveSilent = 0
            }
        }

        // Check for trailing pause
        if consecutiveSilent >= minConsecutiveWindows {
            count += 1
        }

        return count
    }

    // MARK: - Spike Detection

    /// Count volume spikes (sudden loudness increases)
    private static func countSpikes(
        windows: [Float],
        stdDevMultiplier: Float
    ) -> Int {
        guard windows.count > 1 else { return 0 }

        let mean = windows.reduce(0, +) / Float(windows.count)
        let variance = windows.map { pow($0 - mean, 2) }.reduce(0, +) / Float(windows.count)
        let stdDev = sqrt(variance)

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
        segmentsPerMinute > 40
    }

    /// Whether pacing seems too slow
    var isPacingTooSlow: Bool {
        segmentsPerMinute < 10
    }

    /// Whether there are too many intensity spikes
    var hasTooManySpikes: Bool {
        guard duration > 0 else { return false }
        let spikesPerMinute = Float(spikeCount) / Float(duration / 60)
        return spikesPerMinute > 5
    }

    /// Whether volume is inconsistent
    var hasInconsistentVolume: Bool {
        volumeStability < 0.5
    }

    /// Whether average level is too quiet
    var isTooQuiet: Bool {
        averageLevel < 0.1
    }

    /// Whether there's too much silence
    var hasTooMuchSilence: Bool {
        silenceRatio > 0.5
    }

    /// Ideal pause count based on duration
    var idealPauseCount: Int {
        // Roughly one pause every 20 seconds
        max(1, Int(duration / 20))
    }

    /// Whether pause count is optimal
    var hasGoodPausePattern: Bool {
        let ideal = idealPauseCount
        let tolerance = max(1, ideal / 2)
        return abs(pauseCount - ideal) <= tolerance
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension AnalyzedMetrics {
    /// Create mock analyzed metrics for testing
    static func mock() -> AnalyzedMetrics {
        AnalyzedMetrics(
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

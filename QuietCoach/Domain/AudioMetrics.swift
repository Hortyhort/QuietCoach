// AudioMetrics.swift
// QuietCoach
//
// Raw audio measurements captured during recording.
// These feed into the FeedbackEngine for scoring.

import Foundation

struct AudioMetrics {

    // MARK: - Raw Data

    /// RMS (Root Mean Square) values sampled at 10Hz
    let rmsWindows: [Float]

    /// Peak values sampled at 10Hz
    let peakWindows: [Float]

    /// Total recording duration in seconds
    let duration: TimeInterval

    // MARK: - Computed Properties

    /// Average RMS across all windows
    var averageRMS: Float {
        guard !rmsWindows.isEmpty else { return 0 }
        return rmsWindows.reduce(0, +) / Float(rmsWindows.count)
    }

    /// Standard deviation of RMS values
    var rmsStandardDeviation: Float {
        guard rmsWindows.count > 1 else { return 0 }
        let mean = averageRMS
        let variance = rmsWindows.map { pow($0 - mean, 2) }.reduce(0, +) / Float(rmsWindows.count - 1)
        return sqrt(variance)
    }

    /// Count of volume spikes (2+ std dev above mean)
    var spikeCount: Int {
        guard !rmsWindows.isEmpty else { return 0 }
        let threshold = averageRMS + (rmsStandardDeviation * 2)
        return rmsWindows.filter { $0 > threshold }.count
    }

    /// Ratio of silent windows to total windows
    var silenceRatio: Float {
        guard !rmsWindows.isEmpty else { return 0 }
        let silentWindows = rmsWindows.filter { $0 < 0.01 }.count
        return Float(silentWindows) / Float(rmsWindows.count)
    }

    /// Number of distinct pause events (consecutive silence)
    var pauseCount: Int {
        guard rmsWindows.count > 2 else { return 0 }
        var count = 0
        var inPause = false

        for rms in rmsWindows {
            if rms < 0.01 {
                if !inPause {
                    count += 1
                    inPause = true
                }
            } else {
                inPause = false
            }
        }

        return count
    }

    /// Speaking segments per minute (rhythm indicator)
    var voicedSegmentsPerMinute: Float {
        guard duration > 0 else { return 0 }
        var segmentCount = 0
        var inVoiced = false

        for rms in rmsWindows {
            if rms >= 0.01 {
                if !inVoiced {
                    segmentCount += 1
                    inVoiced = true
                }
            } else {
                inVoiced = false
            }
        }

        return Float(segmentCount) / Float(duration / 60.0)
    }

    /// Waveform normalized to 0-1 range for display
    var normalizedWaveform: [Float] {
        guard let maxRMS = rmsWindows.max(), maxRMS > 0 else {
            return rmsWindows
        }
        return rmsWindows.map { $0 / maxRMS }
    }

    /// Peak level for the entire recording
    var peakLevel: Float {
        peakWindows.max() ?? 0
    }

    // MARK: - Empty State

    static let empty = AudioMetrics(
        rmsWindows: [],
        peakWindows: [],
        duration: 0
    )
}

// MARK: - Debug Helpers

#if DEBUG
extension AudioMetrics {
    /// Create mock metrics for testing
    static func mock(duration: TimeInterval = 60, averageLevel: Float = 0.3) -> AudioMetrics {
        let windowCount = Int(duration / Constants.Limits.meteringInterval)
        var rmsWindows: [Float] = []
        var peakWindows: [Float] = []

        for _ in 0..<windowCount {
            let variation = Float.random(in: -0.1...0.1)
            let rms = max(0, min(1, averageLevel + variation))
            let peak = min(1, rms * 1.3)
            rmsWindows.append(rms)
            peakWindows.append(peak)
        }

        return AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: peakWindows,
            duration: duration
        )
    }
}
#endif

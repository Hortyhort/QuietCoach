// SoundDesign.swift
// QuietCoach
//
// Bespoke audio identity. Every sound is intentional.
// Organic, warm, never jarring.

import AVFoundation
import UIKit

// MARK: - Sound Manager

@MainActor
final class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var isEnabled: Bool = true

    // MARK: - Sound Types

    enum SoundType: String, CaseIterable {
        case ready = "qc_ready"           // Soft chime — "I'm listening"
        case recording = "qc_recording"   // Subtle low hum — grounding
        case milestone = "qc_milestone"   // Gentle arpeggio — encouragement
        case complete = "qc_complete"     // Resolved chord — accomplishment
        case insight = "qc_insight"       // Single clear note — "aha"
        case celebration = "qc_celebration" // Warm swell — pride

        var filename: String { rawValue }

        var volume: Float {
            switch self {
            case .ready: return 0.4
            case .recording: return 0.2
            case .milestone: return 0.5
            case .complete: return 0.6
            case .insight: return 0.4
            case .celebration: return 0.7
            }
        }
    }

    // MARK: - Initialization

    private init() {
        prepareAudioSession()
        preloadSounds()
    }

    // MARK: - Audio Session

    private func prepareAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            print("SoundManager: Failed to set audio session category")
        }
    }

    // MARK: - Preloading

    private func preloadSounds() {
        // In production, sounds would be loaded from bundle
        // For now, we'll generate them programmatically
        for soundType in SoundType.allCases {
            if let url = Bundle.main.url(forResource: soundType.filename, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = soundType.volume
                    audioPlayers[soundType] = player
                } catch {
                    print("SoundManager: Failed to load \(soundType.filename)")
                }
            }
        }
    }

    // MARK: - Playback

    func play(_ sound: SoundType) {
        guard isEnabled else { return }

        // If sound file exists, play it
        if let player = audioPlayers[sound] {
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system haptic for feedback
            playFallbackHaptic(for: sound)
        }
    }

    private func playFallbackHaptic(for sound: SoundType) {
        let generator: UIImpactFeedbackGenerator

        switch sound {
        case .ready:
            generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.5)

        case .recording:
            generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred(intensity: 0.3)

        case .milestone, .insight:
            generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred(intensity: 0.6)

        case .complete:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

        case .celebration:
            generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred(intensity: 0.8)
            // Double tap for celebration
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                generator.impactOccurred(intensity: 0.6)
            }
        }
    }

    // MARK: - Settings

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    var soundsEnabled: Bool {
        isEnabled
    }
}

// MARK: - Haptic Choreography

/// Choreographed haptic patterns for key moments
@MainActor
enum HapticChoreography {

    /// Confidence pulse — heartbeat pattern
    static func confidencePulse() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        // First beat
        generator.impactOccurred(intensity: 0.9)

        // Second beat (softer, closer)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            generator.impactOccurred(intensity: 0.5)
        }
    }

    /// Score reveal — building anticipation
    static func scoreReveal(score: Int) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        Task { @MainActor in
            // Quick build-up
            for i in 0..<5 {
                try? await Task.sleep(for: .milliseconds(80))
                generator.impactOccurred(intensity: CGFloat(0.3 + Double(i) * 0.1))
            }

            // Final reveal based on score
            try? await Task.sleep(for: .milliseconds(100))
            if score >= 80 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else if score >= 60 {
                generator.impactOccurred(intensity: 0.7)
            } else {
                generator.impactOccurred(intensity: 0.5)
            }
        }
    }

    /// Recording start — confident forward pulse
    static func recordingStart() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
    }

    /// Recording stop — definitive end
    static func recordingStop() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred(intensity: 0.9)
    }

    /// Milestone reached — encouraging pattern
    static func milestone() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        generator.impactOccurred(intensity: 0.6)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            generator.impactOccurred(intensity: 0.8)
            try? await Task.sleep(for: .milliseconds(100))
            generator.impactOccurred(intensity: 0.4)
        }
    }

    /// Error/warning — attention without alarm
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Selection tick
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Subtle breathing pulse for ambient feedback
    static func breathingPulse() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.3)
    }
}

// MARK: - Synthesized Sounds

/// Generates simple tones programmatically as fallback
/// In production, these would be replaced with professionally composed audio
final class ToneGenerator {

    static func generateTone(frequency: Double, duration: Double, volume: Float = 0.5) -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let samples = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: samples)

        for i in 0..<samples {
            let time = Double(i) / sampleRate
            // Sine wave with envelope
            let envelope = sin(.pi * time / duration) // Smooth fade in/out
            audioData[i] = Float(sin(2 * .pi * frequency * time) * envelope) * volume
        }

        // Convert to Data
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples)) else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(samples)
        let channelData = buffer.floatChannelData![0]
        for i in 0..<samples {
            channelData[i] = audioData[i]
        }

        // This would need additional work to convert to playable audio
        // For MVP, we rely on haptics as the primary feedback mechanism
        return nil
    }

    /// Frequencies for our sound palette (warm, organic)
    enum Tone {
        static let ready: Double = 440       // A4 — warm, centered
        static let insight: Double = 523.25  // C5 — clear, bright
        static let success: Double = 392     // G4 — resolved, complete
        static let gentle: Double = 349.23   // F4 — soft, approachable
    }
}

// MARK: - Focus Sounds (Optional)

/// Binaural-style focus sounds for anxiety reduction
/// User-controllable in settings
@MainActor
final class FocusSoundscape {

    static let shared = FocusSoundscape()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var isPlaying = false

    private init() {}

    /// Start subtle background soundscape during recording
    func startFocusMode() {
        guard !isPlaying else { return }
        isPlaying = true

        // In production, this would play a subtle ambient loop
        // with optional binaural beat undertones (10Hz alpha waves)
        // For now, this is a placeholder for the feature
    }

    /// Stop the focus soundscape
    func stopFocusMode() {
        isPlaying = false
        audioEngine?.stop()
        playerNode?.stop()
    }

    var isFocusModeActive: Bool {
        isPlaying
    }
}

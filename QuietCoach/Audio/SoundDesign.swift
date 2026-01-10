// SoundDesign.swift
// QuietCoach
//
// Bespoke audio identity. Every sound is intentional.
// Organic, warm, never jarring.

import AVFoundation
import UIKit
import OSLog

// MARK: - Sound Manager

@MainActor
final class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "SoundManager")
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
            logger.error("Failed to set audio session category: \(error.localizedDescription)")
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
                    logger.error("Failed to load \(soundType.filename): \(error.localizedDescription)")
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
            playAccompanyingHaptic(for: sound)
        } else {
            // Use synthesized sounds
            playSynthesizedSound(for: sound)
            playAccompanyingHaptic(for: sound)
        }
    }

    private func playSynthesizedSound(for sound: SoundType) {
        let engine = SynthesizedSoundEngine.shared

        switch sound {
        case .ready:
            engine.playReady()
        case .recording:
            engine.playRecordingStart()
        case .milestone:
            engine.playMilestone()
        case .complete:
            engine.playComplete()
        case .insight:
            engine.playInsight()
        case .celebration:
            engine.playCelebration()
        }
    }

    private func playAccompanyingHaptic(for sound: SoundType) {
        let generator: UIImpactFeedbackGenerator

        switch sound {
        case .ready:
            generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.5)

        case .recording:
            generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred(intensity: 0.7)

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

// MARK: - Synthesized Sound Engine

/// Real-time audio synthesis using AVAudioEngine
/// Generates warm, organic sounds without external audio files
@MainActor
final class SynthesizedSoundEngine {

    static let shared = SynthesizedSoundEngine()

    private let audioEngine = AVAudioEngine()
    private var toneNodes: [AVAudioSourceNode] = []
    private let logger = Logger(subsystem: "com.quietcoach", category: "SynthSound")

    private var isEngineRunning = false

    private init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
        } catch {
            logger.error("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    private func ensureEngineRunning() {
        guard !isEngineRunning else { return }
        do {
            try audioEngine.start()
            isEngineRunning = true
        } catch {
            logger.error("Audio engine failed to start: \(error.localizedDescription)")
        }
    }

    // MARK: - Sound Definitions

    /// Play ready sound — soft ascending chime
    func playReady() {
        playSynthesizedSound(
            frequencies: [523.25, 659.25],  // C5, E5
            durations: [0.15, 0.2],
            delays: [0, 0.1],
            volume: 0.3
        )
    }

    /// Play recording start — confident low tone
    func playRecordingStart() {
        playSynthesizedSound(
            frequencies: [220, 330],  // A3, E4 — power fifth
            durations: [0.2, 0.15],
            delays: [0, 0.05],
            volume: 0.35
        )
    }

    /// Play recording stop — resolved chord
    func playRecordingStop() {
        playSynthesizedSound(
            frequencies: [392, 493.88],  // G4, B4
            durations: [0.25, 0.3],
            delays: [0, 0.08],
            volume: 0.35
        )
    }

    /// Play completion — warm resolved chord
    func playComplete() {
        playSynthesizedSound(
            frequencies: [261.63, 329.63, 392],  // C4, E4, G4 — C major
            durations: [0.3, 0.35, 0.4],
            delays: [0, 0.05, 0.1],
            volume: 0.4
        )
    }

    /// Play insight — single clear bell tone
    func playInsight() {
        playSynthesizedSound(
            frequencies: [880],  // A5 — clear, bright
            durations: [0.3],
            delays: [0],
            volume: 0.25
        )
    }

    /// Play milestone — encouraging arpeggio
    func playMilestone() {
        playSynthesizedSound(
            frequencies: [392, 493.88, 587.33, 783.99],  // G4, B4, D5, G5
            durations: [0.12, 0.12, 0.12, 0.25],
            delays: [0, 0.08, 0.16, 0.24],
            volume: 0.35
        )
    }

    /// Play celebration — warm swelling chord
    func playCelebration() {
        playSynthesizedSound(
            frequencies: [261.63, 329.63, 392, 523.25],  // C4, E4, G4, C5
            durations: [0.5, 0.5, 0.5, 0.6],
            delays: [0, 0.02, 0.04, 0.06],
            volume: 0.45
        )
    }

    /// Play score reveal tick — subtle anticipation
    func playScoreTick() {
        playSynthesizedSound(
            frequencies: [1046.5],  // C6 — high, subtle tick
            durations: [0.05],
            delays: [0],
            volume: 0.15
        )
    }

    // MARK: - Synthesis Engine

    private func playSynthesizedSound(
        frequencies: [Double],
        durations: [Double],
        delays: [Double],
        volume: Float
    ) {
        ensureEngineRunning()

        for (index, frequency) in frequencies.enumerated() {
            let duration = durations[index]
            let delay = delays[index]

            Task { @MainActor in
                if delay > 0 {
                    try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                }
                self.playTone(frequency: frequency, duration: duration, volume: volume)
            }
        }
    }

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        let sampleRate = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate
        var phase: Double = 0
        let phaseIncrement = 2 * Double.pi * frequency / sampleRate
        let totalSamples = Int(sampleRate * duration)
        var currentSample = 0

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                if currentSample >= totalSamples {
                    // Silence after duration
                    for buffer in bufferList {
                        let ptr = buffer.mData?.assumingMemoryBound(to: Float.self)
                        ptr?[frame] = 0
                    }
                } else {
                    // Envelope: smooth fade in/out
                    let progress = Double(currentSample) / Double(totalSamples)
                    let envelope = sin(Double.pi * progress)

                    // Warm sine wave with slight harmonics for organic feel
                    let fundamental = sin(phase)
                    let harmonic = sin(phase * 2) * 0.15  // Subtle second harmonic
                    let sample = Float((fundamental + harmonic) * envelope) * volume

                    for buffer in bufferList {
                        let ptr = buffer.mData?.assumingMemoryBound(to: Float.self)
                        ptr?[frame] = sample
                    }

                    phase += phaseIncrement
                    if phase > 2 * Double.pi {
                        phase -= 2 * Double.pi
                    }
                    currentSample += 1
                }
            }
            return noErr
        }

        let format = audioEngine.outputNode.outputFormat(forBus: 0)
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: audioEngine.mainMixerNode, format: format)

        toneNodes.append(sourceNode)

        // Clean up after sound completes
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(duration * 1000) + 100))
            self.audioEngine.disconnectNodeOutput(sourceNode)
            self.audioEngine.detach(sourceNode)
            self.toneNodes.removeAll { $0 === sourceNode }
        }
    }

    /// Stop all sounds immediately
    func stopAllSounds() {
        for node in toneNodes {
            audioEngine.disconnectNodeOutput(node)
            audioEngine.detach(node)
        }
        toneNodes.removeAll()
    }
}

// MARK: - Frequencies Reference

/// Musical frequencies for our warm, organic sound palette
enum SoundFrequencies {
    // Warm, grounding tones
    static let a3: Double = 220      // Low, centered
    static let e4: Double = 329.63   // Warm, supportive

    // Clear, bright tones
    static let c5: Double = 523.25   // Clear, forward
    static let a5: Double = 880      // Bright, attention

    // Resolved, complete tones
    static let g4: Double = 392      // Resolved, stable
    static let c4: Double = 261.63   // Home, grounded
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

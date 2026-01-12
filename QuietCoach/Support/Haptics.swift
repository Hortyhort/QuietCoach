// Haptics.swift
// QuietCoach
//
// Haptics are language. Each interaction has a distinct tactile signature.
// We use them sparingly — only for moments that matter.
//
// Apple Modern Stack: CoreHaptics for sophisticated patterns,
// UIFeedbackGenerator for simple interactions.

import UIKit
import CoreHaptics

@MainActor
final class HapticEngine {
    static let shared = HapticEngine()

    private var engine: CHHapticEngine?
    private var recordingPlayer: CHHapticAdvancedPatternPlayer?

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            engine?.isAutoShutdownEnabled = true

            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }

            engine?.stoppedHandler = { reason in
                // Engine stopped, will restart on next use
            }

            try engine?.start()
        } catch {
            engine = nil
        }
    }

    // MARK: - Recording Pulse Pattern

    /// Continuous gentle pulse during recording - like a heartbeat
    func startRecordingPulse() {
        guard let engine = engine, Constants.Haptics.enabled else { return }

        do {
            // Create a gentle, rhythmic pulse pattern
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)

            var events: [CHHapticEvent] = []

            // Create 4 pulses that repeat
            for i in 0..<4 {
                let time = TimeInterval(i) * 1.5 // Every 1.5 seconds
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [sharpness, intensity],
                    relativeTime: time
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            recordingPlayer = try engine.makeAdvancedPlayer(with: pattern)
            recordingPlayer?.loopEnabled = true
            try recordingPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fallback handled silently
        }
    }

    func stopRecordingPulse() {
        try? recordingPlayer?.stop(atTime: CHHapticTimeImmediate)
        recordingPlayer = nil
    }

    // MARK: - Score Reveal Pattern

    /// Satisfying cascade as scores are revealed
    func playScoreReveal(scores: [Int]) {
        guard let engine = engine, Constants.Haptics.enabled else { return }

        do {
            var events: [CHHapticEvent] = []

            for (index, score) in scores.enumerated() {
                let time = TimeInterval(index) * 0.15
                let normalizedScore = Float(score) / 100.0

                // Higher scores feel more substantial
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: 0.3 + (normalizedScore * 0.5)
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: 0.2 + (normalizedScore * 0.4)
                )

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: time
                )
                events.append(event)
            }

            // Final satisfying thump for overall score
            let finalEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: TimeInterval(scores.count) * 0.15 + 0.1
            )
            events.append(finalEvent)

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fallback to notification haptic
            Haptics.scoresRevealed()
        }
    }

    // MARK: - Celebration Pattern

    /// Burst pattern for completion moments
    func playCelebration() {
        guard let engine = engine, Constants.Haptics.enabled else { return }

        do {
            var events: [CHHapticEvent] = []

            // Ascending burst pattern
            let intensities: [Float] = [0.4, 0.6, 0.8, 1.0, 0.7, 0.5]
            let timings: [TimeInterval] = [0, 0.08, 0.16, 0.24, 0.4, 0.5]

            for (index, intensity) in intensities.enumerated() {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: timings[index]
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            Haptics.celebration()
        }
    }

    // MARK: - Countdown Pattern

    /// 3-2-1 countdown before recording
    func playCountdown() {
        guard let engine = engine, Constants.Haptics.enabled else { return }

        do {
            var events: [CHHapticEvent] = []

            // Three ticks, getting stronger
            for i in 0..<3 {
                let intensity = 0.4 + (Float(i) * 0.2)
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: TimeInterval(i) * 0.8
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silent fallback
        }
    }
}

@MainActor
enum Haptics {

    // MARK: - Feedback Generators

    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private static let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    // MARK: - Recording Lifecycle

    /// Recording begins — a confident, forward pulse
    static func startRecording() {
        guard Constants.Haptics.enabled else { return }
        impactMedium.prepare()
        impactMedium.impactOccurred(intensity: 0.8)
    }

    /// Recording paused — a soft, momentary hold
    static func pauseRecording() {
        guard Constants.Haptics.enabled else { return }
        impactSoft.prepare()
        impactSoft.impactOccurred(intensity: 0.6)
    }

    /// Recording stopped — a definitive end
    static func stopRecording() {
        guard Constants.Haptics.enabled else { return }
        impactRigid.prepare()
        impactRigid.impactOccurred(intensity: 0.9)
    }

    // MARK: - Navigation & Selection

    /// Scenario selected — a gentle acknowledgment
    static func selectScenario() {
        guard Constants.Haptics.enabled else { return }
        selection.prepare()
        selection.selectionChanged()
    }

    /// Tab or segment changed
    static func tabChanged() {
        guard Constants.Haptics.enabled else { return }
        selection.prepare()
        selection.selectionChanged()
    }

    /// Button pressed — light confirmation
    static func buttonPress() {
        guard Constants.Haptics.enabled else { return }
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.5)
    }

    // MARK: - Feedback & Results

    /// Scores revealed — a satisfying arrival
    static func scoresRevealed() {
        guard Constants.Haptics.enabled else { return }
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// Share action triggered
    static func share() {
        guard Constants.Haptics.enabled else { return }
        impactMedium.prepare()
        impactMedium.impactOccurred(intensity: 0.7)
    }

    /// Celebration — a soft success double tap
    static func celebration() {
        guard Constants.Haptics.enabled else { return }
        notification.prepare()
        notification.notificationOccurred(.success)

        // Double tap for celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            impactRigid.impactOccurred(intensity: 0.9)
        }
    }

    // MARK: - Warnings & Errors

    /// Audio too quiet/loud warning
    static func warning() {
        guard Constants.Haptics.enabled else { return }
        notification.prepare()
        notification.notificationOccurred(.warning)
    }

    /// Error occurred
    static func error() {
        guard Constants.Haptics.enabled else { return }
        notification.prepare()
        notification.notificationOccurred(.error)
    }

    /// Destructive action (delete)
    static func destructive() {
        guard Constants.Haptics.enabled else { return }
        impactHeavy.prepare()
        impactHeavy.impactOccurred(intensity: 1.0)
    }

    // MARK: - Scenario-Specific Haptics

    /// Firm haptic for boundary-setting scenarios
    static func firmFeedback() {
        guard Constants.Haptics.enabled else { return }
        impactRigid.prepare()
        impactRigid.impactOccurred(intensity: 0.8)
    }

    /// Soft haptic for relationship scenarios
    static func softFeedback() {
        guard Constants.Haptics.enabled else { return }
        impactSoft.prepare()
        impactSoft.impactOccurred(intensity: 0.7)
    }

    /// Steady haptic for negotiation scenarios
    static func steadyFeedback() {
        guard Constants.Haptics.enabled else { return }
        impactMedium.prepare()
        impactMedium.impactOccurred(intensity: 0.6)
    }

    // MARK: - Preparation

    /// Prepare all generators for responsive feedback
    static func prepareAll() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selection.prepare()
        notification.prepare()
    }

    // MARK: - Additional Interactions

    /// Toggle switched on/off
    static func toggle(_ isOn: Bool) {
        guard Constants.Haptics.enabled else { return }
        if isOn {
            impactMedium.prepare()
            impactMedium.impactOccurred(intensity: 0.7)
        } else {
            impactLight.prepare()
            impactLight.impactOccurred(intensity: 0.5)
        }
    }

    /// Slider value changed
    static func sliderTick() {
        guard Constants.Haptics.enabled else { return }
        selection.prepare()
        selection.selectionChanged()
    }

    /// Pull to refresh triggered
    static func pullToRefresh() {
        guard Constants.Haptics.enabled else { return }
        impactMedium.prepare()
        impactMedium.impactOccurred(intensity: 0.6)
    }

    /// Swipe action revealed
    static func swipeAction() {
        guard Constants.Haptics.enabled else { return }
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.4)
    }

    /// Card expanded/collapsed
    static func cardToggle() {
        guard Constants.Haptics.enabled else { return }
        impactSoft.prepare()
        impactSoft.impactOccurred(intensity: 0.5)
    }

    /// Navigation push/pop
    static func navigation() {
        guard Constants.Haptics.enabled else { return }
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.3)
    }

    /// Modal presented/dismissed
    static func modal() {
        guard Constants.Haptics.enabled else { return }
        impactSoft.prepare()
        impactSoft.impactOccurred(intensity: 0.6)
    }

    /// Long press recognized
    static func longPress() {
        guard Constants.Haptics.enabled else { return }
        impactHeavy.prepare()
        impactHeavy.impactOccurred(intensity: 0.7)
    }

    /// Drag started
    static func dragStart() {
        guard Constants.Haptics.enabled else { return }
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.4)
    }

    /// Item dropped
    static func drop() {
        guard Constants.Haptics.enabled else { return }
        impactMedium.prepare()
        impactMedium.impactOccurred(intensity: 0.8)
    }

    /// Scroll snapped to position
    static func scrollSnap() {
        guard Constants.Haptics.enabled else { return }
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.3)
    }

    /// Text copied
    static func copy() {
        guard Constants.Haptics.enabled else { return }
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// Item favorited/unfavorited
    static func favorite(_ isFavorite: Bool) {
        guard Constants.Haptics.enabled else { return }
        if isFavorite {
            impactMedium.prepare()
            impactMedium.impactOccurred(intensity: 0.8)
        } else {
            impactLight.prepare()
            impactLight.impactOccurred(intensity: 0.4)
        }
    }
}

// MARK: - SwiftUI View Modifier

import SwiftUI

/// Adds haptic feedback to any view interaction
struct HapticFeedbackModifier: ViewModifier {
    let style: HapticStyle

    enum HapticStyle {
        case light, medium, heavy, soft, rigid
        case selection, success, warning, error
    }

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    triggerHaptic()
                }
        )
    }

    @MainActor
    private func triggerHaptic() {
        guard Constants.Haptics.enabled else { return }

        switch style {
        case .light:
            Haptics.buttonPress()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred(intensity: 0.7)
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred(intensity: 0.9)
        case .soft:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred(intensity: 0.6)
        case .rigid:
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred(intensity: 0.8)
        case .selection:
            Haptics.tabChanged()
        case .success:
            Haptics.scoresRevealed()
        case .warning:
            Haptics.warning()
        case .error:
            Haptics.error()
        }
    }
}

extension View {
    /// Adds haptic feedback on tap
    func hapticFeedback(_ style: HapticFeedbackModifier.HapticStyle = .light) -> some View {
        modifier(HapticFeedbackModifier(style: style))
    }
}

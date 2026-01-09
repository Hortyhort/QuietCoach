// Haptics.swift
// QuietCoach
//
// Haptics are language. Each interaction has a distinct tactile signature.
// We use them sparingly — only for moments that matter.

import UIKit
import CoreHaptics

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
}

// SymbolAnimations.swift
// QuietCoach
//
// SF Symbol animations and sensory feedback modifiers.

import SwiftUI

// MARK: - SF Symbol Animations

extension View {
    /// Animated waveform effect for recording indicators
    func qcWaveformAnimation(isActive: Bool) -> some View {
        self.symbolEffect(.variableColor.iterative, options: .repeating, value: isActive)
    }

    /// Bounce effect for score reveals and celebrations
    func qcBounceEffect(trigger: Bool) -> some View {
        self.symbolEffect(.bounce, value: trigger)
    }

    /// Pulse effect for attention-grabbing elements
    func qcPulseEffect(isActive: Bool) -> some View {
        self.symbolEffect(.pulse, options: .repeating, value: isActive)
    }

    /// Scale effect for button interactions (uses replace effect)
    func qcScaleEffect(trigger: Bool) -> some View {
        self.symbolEffect(.bounce.up, value: trigger)
    }

    /// Wiggle effect for errors/warnings (iOS 18+)
    @ViewBuilder
    func qcWiggleEffect(trigger: Bool) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            self.symbolEffect(.wiggle, value: trigger)
        } else {
            self // Fallback: no effect
        }
    }

    /// Breathe effect for idle states (iOS 18+)
    @ViewBuilder
    func qcBreatheEffect(isActive: Bool) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            self.symbolEffect(.breathe, options: .repeating, value: isActive)
        } else {
            self // Fallback: no effect
        }
    }
}

// MARK: - Sensory Feedback Modifiers (iOS 17+)

extension View {
    /// Recording state change feedback
    func qcRecordingFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: trigger)
    }

    /// Score reveal feedback
    func qcScoreRevealFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.success, trigger: trigger)
    }

    /// Level change feedback (for sliders, progress)
    func qcLevelFeedback<T: Equatable>(trigger: T) -> some View {
        self.sensoryFeedback(.levelChange, trigger: trigger)
    }

    /// Warning feedback
    func qcWarningFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.warning, trigger: trigger)
    }

    /// Selection feedback
    func qcSelectionFeedback<T: Equatable>(trigger: T) -> some View {
        self.sensoryFeedback(.selection, trigger: trigger)
    }

    /// Error feedback
    func qcErrorFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.error, trigger: trigger)
    }
}

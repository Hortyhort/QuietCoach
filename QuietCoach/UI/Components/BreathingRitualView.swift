// BreathingRitualView.swift
// QuietCoach
//
// A calming pre-recording ritual. Deep breath in, slow exhale out.
// Helps ground anxious speakers before their rehearsal.

import SwiftUI

struct BreathingRitualView: View {

    // MARK: - Properties

    let onComplete: () -> Void
    let onSkip: () -> Void

    // MARK: - State

    @State private var phase: BreathPhase = .ready
    @State private var progress: CGFloat = 0
    @State private var circleScale: CGFloat = 0.6
    @State private var breathCount = 0

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let inhaleDuration: Double = 4.0
    private let holdDuration: Double = 1.0
    private let exhaleDuration: Double = 4.0
    private let totalBreaths = 1

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.qcBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Breathing circle
                breathingCircle

                // Instructions
                Text(phase.instruction)
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: phase)

                Text(phase.guidance)
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Skip button
                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.qcSubheadline)
                        .foregroundColor(.qcTextTertiary)
                }
                .padding(.bottom, 40)
                .accessibilityLabel("Skip breathing exercise")
                .accessibilityHint("Double tap to skip and start recording immediately")
            }
        }
        .onAppear {
            startBreathingCycle()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breathing exercise. \(phase.instruction)")
    }

    // MARK: - Breathing Circle

    private var breathingCircle: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.qcAccent.opacity(0.3),
                            Color.qcAccent.opacity(0)
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(circleScale * 1.2)

            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.qcAccent.opacity(0.8),
                            Color.qcAccent.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(circleScale)

            // Center icon
            if #available(iOS 18.0, *) {
                Image(systemName: phase.icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
                    .symbolEffect(.breathe, options: .repeating, value: phase == .inhale || phase == .exhale)
            } else {
                Image(systemName: phase.icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Breathing Cycle

    private func startBreathingCycle() {
        guard !reduceMotion else {
            // Skip animation for reduce motion users
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
            return
        }

        // Start with ready state
        phase = .ready

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            runBreathCycle()
        }
    }

    private func runBreathCycle() {
        // Inhale
        phase = .inhale
        Haptics.breatheIn()

        withAnimation(.easeInOut(duration: inhaleDuration)) {
            circleScale = 1.0
        }

        // Hold
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration) {
            phase = .hold
        }

        // Exhale
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration + holdDuration) {
            phase = .exhale
            Haptics.breatheOut()

            withAnimation(.easeInOut(duration: exhaleDuration)) {
                circleScale = 0.6
            }
        }

        // Complete or repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration + holdDuration + exhaleDuration) {
            breathCount += 1

            if breathCount >= totalBreaths {
                phase = .complete
                Haptics.streakMilestone()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            } else {
                runBreathCycle()
            }
        }
    }
}

// MARK: - Breath Phase

private enum BreathPhase {
    case ready
    case inhale
    case hold
    case exhale
    case complete

    var instruction: String {
        switch self {
        case .ready: return "Get comfortable"
        case .inhale: return "Breathe in"
        case .hold: return "Hold"
        case .exhale: return "Breathe out"
        case .complete: return "Ready"
        }
    }

    var guidance: String {
        switch self {
        case .ready: return "Take a moment to center yourself"
        case .inhale: return "Fill your lungs slowly"
        case .hold: return "Just a moment"
        case .exhale: return "Release any tension"
        case .complete: return "You've got this"
        }
    }

    var icon: String {
        switch self {
        case .ready: return "leaf.fill"
        case .inhale: return "arrow.down.circle"
        case .hold: return "pause.circle"
        case .exhale: return "arrow.up.circle"
        case .complete: return "checkmark.circle"
        }
    }
}

// MARK: - Haptics Extension

private extension Haptics {
    static func breatheIn() {
        guard Constants.Haptics.enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.5)
    }

    static func breatheOut() {
        guard Constants.Haptics.enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.3)
    }
}

// MARK: - Preview

#Preview {
    BreathingRitualView(
        onComplete: { print("Complete") },
        onSkip: { print("Skip") }
    )
}

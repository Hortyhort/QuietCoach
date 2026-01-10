// ConfidencePulse.swift
// QuietCoach
//
// The signature moment — waveform transforms to pulse on score reveal.

import SwiftUI
import UIKit

// MARK: - Confidence Pulse View

/// The signature moment — waveform transforms to pulse on score reveal
struct ConfidencePulseView: View {
    let score: Int
    let onComplete: () -> Void

    @State private var phase: PulsePhase = .waveform
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var scoreOpacity: Double = 0.0
    @State private var scoreScale: CGFloat = 0.5
    @State private var waveformSamples: [Float] = (0..<60).map { _ in Float.random(in: 0.3...0.9) }

    enum PulsePhase {
        case waveform
        case collapse
        case pulse
        case reveal
    }

    var body: some View {
        ZStack {
            // Background dim
            Color.black
                .opacity(phase == .waveform ? 0 : 0.95)
                .ignoresSafeArea()

            // Ripple rings
            if phase == .pulse || phase == .reveal {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(moodColor.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .scaleEffect(pulseScale + CGFloat(index) * 0.3)
                        .opacity(pulseOpacity)
                }
            }

            // Central glow
            if phase != .waveform {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [moodColor.opacity(0.6), moodColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(phase == .collapse ? 0.3 : 1.0)
                    .opacity(phase == .reveal ? 0.5 : 1.0)
            }

            // Waveform (collapses to center)
            if phase == .waveform || phase == .collapse {
                WaveformPulseView(samples: waveformSamples, isCollapsing: phase == .collapse)
                    .frame(height: 80)
                    .padding(.horizontal, 40)
                    .scaleEffect(phase == .collapse ? 0.1 : 1.0)
                    .opacity(phase == .collapse ? 0 : 1)
            }

            // Score reveal
            if phase == .reveal {
                VStack(spacing: 16) {
                    Text("\(score)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(moodColor)

                    Text(scoreInterpretation)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .scaleEffect(scoreScale)
                .opacity(scoreOpacity)
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    private var moodColor: Color {
        switch score {
        case 85...100: return Color.qcMoodCelebration
        case 70..<85: return Color.qcMoodSuccess
        case 50..<70: return Color.qcMoodReady
        default: return Color.qcMoodEngaged
        }
    }

    private var scoreInterpretation: String {
        switch score {
        case 90...100: return "Exceptional"
        case 80..<90: return "Strong"
        case 70..<80: return "Solid"
        case 60..<70: return "Building"
        default: return "Keep practicing"
        }
    }

    private func runAnimation() {
        // Phase 1: Show waveform (already visible)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Phase 2: Collapse
            withAnimation(.easeIn(duration: 0.4)) {
                phase = .collapse
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            // Phase 3: Pulse
            phase = .pulse
            withAnimation(.easeOut(duration: 1.2)) {
                pulseScale = 2.5
                pulseOpacity = 0
            }

            // Haptic heartbeat
            triggerPulseHaptic()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            // Phase 4: Reveal score
            phase = .reveal
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scoreScale = 1.0
                scoreOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete()
        }
    }

    private func triggerPulseHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        // Heartbeat pattern
        generator.impactOccurred(intensity: 0.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred(intensity: 0.5)
        }
    }
}

// MARK: - Waveform Pulse View

/// Waveform that can collapse to center
struct WaveformPulseView: View {
    let samples: [Float]
    let isCollapsing: Bool

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.qcMoodReady)
                    .frame(width: 3, height: CGFloat(sample) * 80)
                    .offset(x: isCollapsing ? offsetForCollapse(index: index) : 0)
            }
        }
        .animation(.easeIn(duration: 0.4), value: isCollapsing)
    }

    private func offsetForCollapse(index: Int) -> CGFloat {
        let center = CGFloat(samples.count) / 2
        let distanceFromCenter = CGFloat(index) - center
        return -distanceFromCenter * 5
    }
}

// WaveformView.swift
// QuietCoach
//
// The visual heartbeat of recording. Each bar responds to voice,
// creating a living representation of speech.

import SwiftUI

struct WaveformView: View {

    // MARK: - Properties

    let samples: [Float]
    let isActive: Bool
    var barCount: Int = 40
    var barSpacing: CGFloat = 3
    var minBarHeight: CGFloat = 4
    var maxBarHeight: CGFloat = 60
    var activeColor: Color = .qcAccent
    var inactiveColor: Color = .qcWaveformInactive

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        level: barLevel(for: index),
                        isActive: isActive,
                        minHeight: minBarHeight,
                        maxHeight: maxBarHeight,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        reduceMotion: reduceMotion
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(isActive ? "Recording" : "Idle")
    }

    // MARK: - Bar Level Calculation

    private func barLevel(for index: Int) -> Float {
        guard !samples.isEmpty else {
            // Idle state: show minimal bars
            return 0.1
        }

        // Map bar index to sample index
        let sampleIndex = Int(Float(index) / Float(barCount) * Float(samples.count))
        let clampedIndex = min(sampleIndex, samples.count - 1)

        // Get sample value, ensure minimum visibility
        let sample = samples[clampedIndex]
        return max(0.1, sample)
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        if samples.isEmpty {
            return "Audio waveform, waiting for input"
        }
        let avgLevel = samples.reduce(0, +) / Float(samples.count)
        if avgLevel > 0.5 {
            return "Audio waveform, strong input level"
        } else if avgLevel > 0.2 {
            return "Audio waveform, moderate input level"
        } else {
            return "Audio waveform, low input level"
        }
    }
}

// MARK: - Waveform Bar

private struct WaveformBar: View {
    let level: Float
    let isActive: Bool
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let activeColor: Color
    let inactiveColor: Color
    let reduceMotion: Bool

    @State private var animatedLevel: Float = 0.1

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(isActive ? activeColor : inactiveColor)
            .frame(width: 3, height: barHeight)
            .animation(animation, value: animatedLevel)
            .onChange(of: level) { _, newValue in
                animatedLevel = newValue
            }
            .onAppear {
                animatedLevel = level
            }
    }

    private var barHeight: CGFloat {
        let normalizedLevel = CGFloat(animatedLevel)
        let height = minHeight + (normalizedLevel * (maxHeight - minHeight))
        return max(minHeight, min(maxHeight, height))
    }

    private var animation: Animation {
        if reduceMotion {
            return .linear(duration: 0.05)
        }
        return .spring(response: 0.15, dampingFraction: 0.7)
    }
}

// MARK: - Compact Waveform (for playback scrubber)

struct CompactWaveformView: View {
    let samples: [Float]
    let progress: Double
    var barCount: Int = 60
    var height: CGFloat = 32

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let level = barLevel(for: index)
                    let isPast = Double(index) / Double(barCount) <= progress

                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(isPast ? Color.qcAccent : Color.qcWaveformInactive)
                        .frame(width: 2, height: barHeight(for: level))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Audio waveform")
        .accessibilityValue("\(Int(progress * 100)) percent played")
    }

    private func barLevel(for index: Int) -> Float {
        guard !samples.isEmpty else { return 0.2 }
        let sampleIndex = Int(Float(index) / Float(barCount) * Float(samples.count))
        let clampedIndex = min(sampleIndex, samples.count - 1)
        return max(0.2, samples[clampedIndex])
    }

    private func barHeight(for level: Float) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight = height
        return minHeight + (CGFloat(level) * (maxHeight - minHeight))
    }
}

// MARK: - Idle Waveform Animation

struct IdleWaveformView: View {
    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var barCount: Int = 40
    var height: CGFloat = 60

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let offset = Double(index) / Double(barCount) * .pi * 2
                let level = idleLevel(for: offset)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.qcWaveformInactive)
                    .frame(width: 3, height: barHeight(for: level))
            }
        }
        .frame(height: height)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .accessibilityHidden(true)
    }

    private func idleLevel(for offset: Double) -> Float {
        if reduceMotion {
            return 0.15
        }
        // Gentle wave animation
        let wave = sin(phase + offset) * 0.1 + 0.15
        return Float(wave)
    }

    private func barHeight(for level: Float) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight = height * 0.4
        return minHeight + (CGFloat(level) * (maxHeight - minHeight))
    }
}

// MARK: - Preview

#Preview("Active Waveform") {
    VStack(spacing: 32) {
        WaveformView(
            samples: (0..<50).map { _ in Float.random(in: 0.1...0.8) },
            isActive: true
        )
        .frame(height: 80)

        CompactWaveformView(
            samples: (0..<60).map { _ in Float.random(in: 0.2...0.9) },
            progress: 0.4
        )

        IdleWaveformView()
    }
    .padding()
    .background(Color.qcBackground)
}

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

    // MARK: - State for animation

    @State private var animatedLevels: [Float] = []

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            let barWidth: CGFloat = 3
            let totalBarWidth = barWidth + barSpacing
            let totalWidth = CGFloat(barCount) * totalBarWidth - barSpacing
            let startX = (size.width - totalWidth) / 2
            let centerY = size.height / 2

            for index in 0..<barCount {
                let level = animatedLevels.indices.contains(index) ? animatedLevels[index] : 0.1
                let normalizedLevel = CGFloat(level)
                let barHeight = minBarHeight + (normalizedLevel * (maxBarHeight - minBarHeight))
                let clampedHeight = max(minBarHeight, min(maxBarHeight, barHeight))

                let x = startX + CGFloat(index) * totalBarWidth
                let y = centerY - clampedHeight / 2

                let rect = CGRect(x: x, y: y, width: barWidth, height: clampedHeight)
                let path = Path(roundedRect: rect, cornerRadius: 2)

                context.fill(path, with: .color(isActive ? activeColor : inactiveColor))
            }
        }
        .onChange(of: samples) { _, newSamples in
            updateAnimatedLevels(from: newSamples)
        }
        .onAppear {
            updateAnimatedLevels(from: samples)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(isActive ? "Recording" : "Idle")
    }

    // MARK: - Level Updates

    private func updateAnimatedLevels(from samples: [Float]) {
        var newLevels: [Float] = []
        for index in 0..<barCount {
            newLevels.append(barLevel(for: index, from: samples))
        }

        if reduceMotion {
            animatedLevels = newLevels
        } else {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                animatedLevels = newLevels
            }
        }
    }

    // MARK: - Bar Level Calculation

    private func barLevel(for index: Int, from samples: [Float]) -> Float {
        guard !samples.isEmpty else {
            return 0.1
        }

        let sampleIndex = Int(Float(index) / Float(barCount) * Float(samples.count))
        let clampedIndex = min(sampleIndex, samples.count - 1)
        return max(0.1, samples[clampedIndex])
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

// MARK: - Compact Waveform (for playback scrubber)

struct CompactWaveformView: View {
    let samples: [Float]
    let progress: Double
    var barCount: Int = 60
    var height: CGFloat = 32

    var body: some View {
        Canvas { context, size in
            let barWidth: CGFloat = 2
            let barSpacing: CGFloat = 2
            let totalBarWidth = barWidth + barSpacing
            let totalWidth = CGFloat(barCount) * totalBarWidth - barSpacing
            let startX = (size.width - totalWidth) / 2
            let centerY = size.height / 2
            let minBarHeight: CGFloat = 4
            let maxBarHeight = size.height

            for index in 0..<barCount {
                let level = barLevel(for: index)
                let barHeight = minBarHeight + (CGFloat(level) * (maxBarHeight - minBarHeight))
                let isPast = Double(index) / Double(barCount) <= progress

                let x = startX + CGFloat(index) * totalBarWidth
                let y = centerY - barHeight / 2

                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: 1)

                context.fill(path, with: .color(isPast ? .qcAccent : .qcWaveformInactive))
            }
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

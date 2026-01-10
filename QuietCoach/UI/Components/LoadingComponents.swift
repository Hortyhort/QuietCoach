// LoadingComponents.swift
// QuietCoach
//
// Loading states and skeleton screens for perceived performance.
// Makes async operations feel instantaneous.

import SwiftUI

// MARK: - Analyzing Overlay

/// Full-screen overlay shown during audio analysis
struct AnalyzingOverlay: View {
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Animated waveform
                AnalyzingWaveform(phase: animationPhase)
                    .frame(height: 60)
                    .padding(.horizontal, 40)

                // Status text
                VStack(spacing: 8) {
                    Text("Analyzing...")
                        .font(.qcTitle3)
                        .foregroundColor(.qcTextPrimary)

                    Text("Processing your rehearsal")
                        .font(.qcSubheadline)
                        .foregroundColor(.qcTextSecondary)
                }

                // Pulsing indicator
                Circle()
                    .fill(Color.qcAccent.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(pulseScale)
            }
        }
        .onAppear {
            // Animate waveform
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
            // Pulse indicator
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.5
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Analyzing your rehearsal. Please wait.")
    }
}

/// Animated waveform for analyzing state
struct AnalyzingWaveform: View {
    let phase: CGFloat
    let barCount: Int = 30

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(barCount * 2)

            HStack(spacing: barWidth) {
                ForEach(0..<barCount, id: \.self) { index in
                    AnalyzingBar(
                        index: index,
                        phase: phase,
                        maxHeight: geometry.size.height
                    )
                    .frame(width: barWidth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Individual bar in analyzing waveform
struct AnalyzingBar: View {
    let index: Int
    let phase: CGFloat
    let maxHeight: CGFloat

    private var heightMultiplier: CGFloat {
        let normalizedIndex = CGFloat(index) / 30.0
        let wave = sin((normalizedIndex + phase) * .pi * 2)
        return 0.3 + (wave + 1) * 0.35
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.qcAccent.opacity(0.6 + heightMultiplier * 0.4))
            .frame(height: maxHeight * heightMultiplier)
    }
}

// MARK: - Session Card Skeleton

/// Placeholder skeleton for session cards
struct SessionCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Icon and title placeholder
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.qcSurface)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.qcSurface)
                        .frame(width: 120, height: 14)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.qcSurface.opacity(0.6))
                        .frame(width: 80, height: 10)
                }

                Spacer()

                // Score placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.qcSurface)
                    .frame(width: 50, height: 30)
            }

            // Bottom row: Duration and date placeholders
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.qcSurface.opacity(0.5))
                    .frame(width: 60, height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.qcSurface.opacity(0.5))
                    .frame(width: 80, height: 10)
            }
        }
        .padding(16)
        .background(Color.qcSurface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .qcShimmer(isActive: true)
    }
}

/// Multiple skeleton cards for loading state
struct SessionCardsLoadingSkeleton: View {
    let count: Int

    init(count: Int = 3) {
        self.count = count
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                SessionCardSkeleton()
            }
        }
    }
}

// MARK: - Score Skeleton

/// Placeholder skeleton for score display
struct ScoreSkeleton: View {
    var body: some View {
        VStack(spacing: 8) {
            // Score circle placeholder
            Circle()
                .fill(Color.qcSurface)
                .frame(width: 60, height: 60)

            // Label placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.qcSurface.opacity(0.6))
                .frame(width: 50, height: 12)
        }
        .qcShimmer(isActive: true)
    }
}

/// Score grid skeleton for loading state
struct ScoreGridSkeleton: View {
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { _ in
                ScoreSkeleton()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Content Placeholder

/// Generic content placeholder with customizable size
struct ContentPlaceholder: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: height / 4)
            .fill(Color.qcSurface.opacity(0.4))
            .frame(width: width, height: height)
            .qcShimmer(isActive: true)
    }
}

// MARK: - Staggered Score Animation

/// Animates scores with staggered reveal
struct StaggeredScoreReveal: ViewModifier {
    let index: Int
    let isRevealed: Bool
    let baseDelay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isRevealed ? 1 : 0)
            .scaleEffect(isRevealed ? 1 : 0.8)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(baseDelay + Double(index) * 0.15),
                value: isRevealed
            )
    }
}

extension View {
    /// Applies staggered reveal animation for scores
    func staggeredReveal(index: Int, isRevealed: Bool, baseDelay: Double = 0.2) -> some View {
        modifier(StaggeredScoreReveal(index: index, isRevealed: isRevealed, baseDelay: baseDelay))
    }
}

// MARK: - Previews

#Preview("Analyzing Overlay") {
    AnalyzingOverlay()
}

#Preview("Session Skeleton") {
    VStack(spacing: 20) {
        SessionCardSkeleton()
        SessionCardSkeleton()
    }
    .padding()
    .background(Color.qcBackground)
}

#Preview("Score Skeleton") {
    ScoreGridSkeleton()
        .padding()
        .background(Color.qcBackground)
}

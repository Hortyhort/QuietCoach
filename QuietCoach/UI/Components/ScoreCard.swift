// ScoreCard.swift
// QuietCoach
//
// The feedback reveal. Four scores, each meaningful.
// Animated entrance for that satisfying moment of discovery.

import SwiftUI

struct ScoreCard: View {

    // MARK: - Properties

    let scoreType: FeedbackScores.ScoreType
    let value: Int
    let delta: Int?
    var animate: Bool = true
    var delay: Double = 0

    // MARK: - State

    @State private var displayedValue: Int = 0
    @State private var isRevealed: Bool = false

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Score value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(displayedValue)")
                    .font(.qcScore)
                    .foregroundColor(scoreColor)
                    .contentTransition(.numericText())

                if let delta, delta != 0, isRevealed {
                    deltaView(delta)
                }
            }

            // Label with icon
            HStack(spacing: 6) {
                Image(systemName: scoreType.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(scoreType.rawValue)
                    .font(.qcCaption)
            }
            .foregroundColor(.qcTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.qcSurface)
        .qcSmallRadius()
        .opacity(isRevealed ? 1 : 0)
        .scaleEffect(isRevealed ? 1 : 0.8)
        .onAppear {
            revealScore()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scoreType.rawValue): \(value) out of 100")
        .accessibilityValue(deltaAccessibilityValue)
    }

    // MARK: - Delta View

    @ViewBuilder
    private func deltaView(_ delta: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 10, weight: .bold))

            Text("\(abs(delta))")
                .font(.qcCaption)
        }
        .foregroundColor(delta > 0 ? .qcSuccess : .qcError)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Score Color

    private var scoreColor: Color {
        switch value {
        case 85...100: return .qcSuccess
        case 70..<85: return .qcAccent
        case 55..<70: return .qcWarning
        default: return .qcTextSecondary
        }
    }

    // MARK: - Animation

    private func revealScore() {
        guard animate else {
            displayedValue = value
            isRevealed = true
            return
        }

        // Delay for staggered entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isRevealed = true
            }

            // Animate number counting up
            if reduceMotion {
                displayedValue = value
            } else {
                animateNumber()
            }
        }
    }

    private func animateNumber() {
        let duration: Double = 0.6
        let steps = 20
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                let progress = Double(step) / Double(steps)
                let easedProgress = easeOut(progress)
                displayedValue = Int(Double(value) * easedProgress)
            }
        }
    }

    private func easeOut(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }

    // MARK: - Accessibility

    private var deltaAccessibilityValue: String {
        guard let delta, delta != 0 else { return "" }
        if delta > 0 {
            return "Improved by \(delta) points"
        } else {
            return "Decreased by \(abs(delta)) points"
        }
    }
}

// MARK: - Score Grid

struct ScoreGrid: View {
    let scores: FeedbackScores
    let previousScores: FeedbackScores?
    var animate: Bool = true

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ScoreCard(
                scoreType: .clarity,
                value: scores.clarity,
                delta: previousScores.map { scores.clarity - $0.clarity },
                animate: animate,
                delay: 0
            )

            ScoreCard(
                scoreType: .pacing,
                value: scores.pacing,
                delta: previousScores.map { scores.pacing - $0.pacing },
                animate: animate,
                delay: 0.1
            )

            ScoreCard(
                scoreType: .tone,
                value: scores.tone,
                delta: previousScores.map { scores.tone - $0.tone },
                animate: animate,
                delay: 0.2
            )

            ScoreCard(
                scoreType: .confidence,
                value: scores.confidence,
                delta: previousScores.map { scores.confidence - $0.confidence },
                animate: animate,
                delay: 0.3
            )
        }
    }
}

// MARK: - Overall Score Badge

struct OverallScoreBadge: View {
    let score: Int
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.qcSurface, lineWidth: 6)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Score text
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.qcScore)
                    .foregroundColor(.qcTextPrimary)

                Text("overall")
                    .font(.qcCaption)
                    .foregroundColor(.qcTextTertiary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Overall score: \(score) out of 100")
    }

    private var scoreColor: Color {
        switch score {
        case 85...100: return .qcSuccess
        case 70..<85: return .qcAccent
        case 55..<70: return .qcWarning
        default: return .qcTextSecondary
        }
    }
}

// MARK: - Preview

#Preview("Score Cards") {
    VStack(spacing: 24) {
        ScoreGrid(
            scores: FeedbackScores(clarity: 82, pacing: 75, tone: 88, confidence: 70),
            previousScores: FeedbackScores(clarity: 78, pacing: 72, tone: 85, confidence: 75)
        )

        OverallScoreBadge(score: 79)
    }
    .padding()
    .background(Color.qcBackground)
}

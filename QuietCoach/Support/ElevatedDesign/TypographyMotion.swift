// TypographyMotion.swift
// QuietCoach
//
// Typography animations including typewriter and liquid number effects.

import SwiftUI

// MARK: - Typewriter Text

/// Typewriter text reveal effect
struct TypewriterText: View {
    let text: String
    let speed: TypewriterSpeed
    var emphasisWord: String? = nil
    var emphasisStyle: EmphasisStyle = .glow

    enum TypewriterSpeed {
        case fast, natural, slow

        var delay: Double {
            switch self {
            case .fast: return 0.02
            case .natural: return 0.04
            case .slow: return 0.07
            }
        }
    }

    enum EmphasisStyle {
        case glow, bold, color
    }

    @State private var visibleCharacters: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .opacity(index < visibleCharacters ? 1 : 0)
                    .foregroundStyle(shouldEmphasize(index: index) ? Color.qcMoodCelebration : Color.qcTextPrimary)
                    .fontWeight(shouldEmphasize(index: index) ? .bold : .regular)
                    .shadow(
                        color: shouldEmphasize(index: index) ? Color.qcMoodCelebration.opacity(0.5) : .clear,
                        radius: 8
                    )
            }
        }
        .onAppear {
            animateText()
        }
    }

    private func shouldEmphasize(index: Int) -> Bool {
        guard let emphasisWord = emphasisWord else { return false }
        guard let range = text.range(of: emphasisWord, options: .caseInsensitive) else { return false }
        let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
        let endIndex = text.distance(from: text.startIndex, to: range.upperBound)
        return index >= startIndex && index < endIndex
    }

    private func animateText() {
        for index in 0...text.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * speed.delay) {
                visibleCharacters = index
            }
        }
    }
}

// MARK: - Liquid Score Text

/// Liquid number morph for scores
struct LiquidScoreText: View {
    let score: Int
    @State private var displayedScore: Int = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        Text("\(displayedScore)")
            .font(.qcHeroScore)
            .foregroundStyle(scoreColor)
            .scaleEffect(scale)
            .contentTransition(.numericText(value: Double(displayedScore)))
            .shadow(color: scoreColor.opacity(0.5), radius: 20)
            .qcDynamicTypeScaled(maximum: .xxxLarge)
            .onAppear {
                animateScore()
            }
    }

    private var scoreColor: Color {
        switch displayedScore {
        case 85...100: return .qcMoodCelebration
        case 70..<85: return .qcMoodSuccess
        case 50..<70: return .qcMoodReady
        default: return .qcMoodEngaged
        }
    }

    private func animateScore() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            scale = 1.0
        }

        // Animate number counting up
        let duration = 1.0
        let steps = 30
        let increment = Double(score) / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(steps)) * Double(step)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedScore = min(Int(increment * Double(step)), score)
                }
            }
        }
    }
}

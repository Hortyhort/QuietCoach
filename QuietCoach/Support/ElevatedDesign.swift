// ElevatedDesign.swift
// QuietCoach
//
// The 10/10 design system. Every interaction is intentional.
// Every animation tells a story. Every moment matters.

import SwiftUI
import UIKit

// MARK: - Mood-Adaptive Color System

/// Dynamic color palette that responds to app state
enum AppMood: Equatable {
    case ready      // Idle, waiting — warm amber
    case engaged    // Recording — soft coral
    case thinking   // Processing — cool violet
    case success    // Achievement — mint green
    case celebration // Triumph — gold burst

    var primaryColor: Color {
        switch self {
        case .ready: return Color.qcMoodReady
        case .engaged: return Color.qcMoodEngaged
        case .thinking: return Color.qcMoodThinking
        case .success: return Color.qcMoodSuccess
        case .celebration: return Color.qcMoodCelebration
        }
    }

    var glowColor: Color {
        primaryColor.opacity(0.4)
    }

    var backgroundAccent: Color {
        primaryColor.opacity(0.1)
    }
}

extension Color {
    // Mood colors
    static let qcMoodReady = Color(red: 0.98, green: 0.82, blue: 0.47)       // Warm amber
    static let qcMoodEngaged = Color(red: 0.98, green: 0.56, blue: 0.52)    // Soft coral
    static let qcMoodThinking = Color(red: 0.65, green: 0.55, blue: 0.88)   // Cool violet
    static let qcMoodSuccess = Color(red: 0.45, green: 0.82, blue: 0.68)    // Mint green
    static let qcMoodCelebration = Color(red: 1.0, green: 0.84, blue: 0.35) // Gold burst
}

// MARK: - Confidence Pulse Animation

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

// MARK: - Liquid Glass Components

/// Glass card with depth and parallax
struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var depth: CGFloat = 1.0

    @State private var offset: CGSize = .zero

    init(depth: CGFloat = 1.0, @ViewBuilder content: () -> Content) {
        self.depth = depth
        self.content = content()
    }

    var body: some View {
        content
            .background {
                ZStack {
                    // Base glass
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Aurora edge glow
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.qcMoodReady.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )

                    // Inner shadow for depth
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        .blur(radius: 2)
                        .offset(x: 1, y: 1)
                        .mask(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.black)
                        )
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10 * depth)
            .rotation3DEffect(
                .degrees(Double(offset.width) / 20),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-offset.height) / 20),
                axis: (x: 1, y: 0, z: 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            offset = .zero
                        }
                    }
            )
    }
}

/// Breathing UI element — gentle scale pulse on idle
struct BreathingModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    scale = 1.03
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        scale = 1.03
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scale = 1.0
                    }
                }
            }
    }
}

extension View {
    func qcBreathing(isActive: Bool = true) -> some View {
        modifier(BreathingModifier(isActive: isActive))
    }
}

// MARK: - Typography Motion

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

/// Liquid number morph for scores
struct LiquidScoreText: View {
    let score: Int
    @State private var displayedScore: Int = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        Text("\(displayedScore)")
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .foregroundStyle(scoreColor)
            .scaleEffect(scale)
            .contentTransition(.numericText(value: Double(displayedScore)))
            .shadow(color: scoreColor.opacity(0.5), radius: 20)
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

// MARK: - Enhanced Micro-Interactions

/// Magnetic pull button effect
struct MagneticButton<Content: View>: View {
    let action: () -> Void
    let content: Content

    @State private var offset: CGSize = .zero
    @State private var isPressed: Bool = false
    @GestureState private var dragOffset: CGSize = .zero

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        content
            .offset(x: offset.width + dragOffset.width * 0.3,
                    y: offset.height + dragOffset.height * 0.3)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: offset)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { value in
                        isPressed = false

                        // Snap back with particle burst would go here
                        if abs(value.translation.width) < 50 && abs(value.translation.height) < 50 {
                            action()
                            triggerHaptic()
                        }
                    }
            )
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.8)
    }
}

/// Tilt card effect on hover/press
struct TiltCardModifier: ViewModifier {
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @GestureState private var dragLocation: CGPoint = .zero

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .rotation3DEffect(
                    .degrees(rotationX),
                    axis: (x: 1, y: 0, z: 0)
                )
                .rotation3DEffect(
                    .degrees(rotationY),
                    axis: (x: 0, y: 1, z: 0)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragLocation) { value, state, _ in
                            state = value.location
                        }
                        .onChanged { value in
                            let centerX = geometry.size.width / 2
                            let centerY = geometry.size.height / 2

                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                                rotationY = Double((value.location.x - centerX) / centerX) * 10
                                rotationX = Double((centerY - value.location.y) / centerY) * 10
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                rotationX = 0
                                rotationY = 0
                            }
                        }
                )
        }
    }
}

extension View {
    func qcTiltEffect() -> some View {
        modifier(TiltCardModifier())
    }
}

// MARK: - Aurora Glow Effect

struct AuroraGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    color.opacity(0.8),
                                    color.opacity(0.2),
                                    color.opacity(0.8),
                                    color.opacity(0.2),
                                    color.opacity(0.8)
                                ],
                                center: .center,
                                startAngle: .degrees(phase),
                                endAngle: .degrees(phase + 360)
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 4)
                }
            }
            .onAppear {
                guard isActive else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
    }
}

extension View {
    func qcAuroraGlow(color: Color = .qcMoodReady, isActive: Bool = true) -> some View {
        modifier(AuroraGlowModifier(color: color, isActive: isActive))
    }
}

// MARK: - Particle Burst Effect

struct ParticleBurstView: View {
    let color: Color
    @Binding var trigger: Bool

    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(x: particle.x, y: particle.y)
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                createBurst()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    trigger = false
                }
            }
        }
    }

    private func createBurst() {
        particles = (0..<12).map { _ in
            Particle(x: 0, y: 0, scale: 1, opacity: 1)
        }

        for (index, _) in particles.enumerated() {
            let angle = Double(index) * (360.0 / 12.0) * .pi / 180
            let distance: CGFloat = 60

            withAnimation(.easeOut(duration: 0.5)) {
                particles[index].x = cos(angle) * distance
                particles[index].y = sin(angle) * distance
                particles[index].scale = 0
                particles[index].opacity = 0
            }
        }
    }
}

// MARK: - Preview

#Preview("Confidence Pulse") {
    ConfidencePulseView(score: 85) {
        print("Complete")
    }
    .preferredColorScheme(.dark)
}

#Preview("Liquid Glass Card") {
    LiquidGlassCard {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.title)
                .foregroundStyle(Color.qcMoodReady)

            Text("Set a Boundary")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Practice saying no")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
    }
    .frame(width: 200, height: 150)
    .preferredColorScheme(.dark)
}

#Preview("Typography") {
    VStack(spacing: 40) {
        TypewriterText(
            text: "Pause after your key point.",
            speed: .natural,
            emphasisWord: "Pause",
            emphasisStyle: .glow
        )
        .font(.title3)

        LiquidScoreText(score: 87)
    }
    .padding()
    .background(Color.qcBackground)
    .preferredColorScheme(.dark)
}

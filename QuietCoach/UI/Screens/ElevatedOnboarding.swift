// ElevatedOnboarding.swift
// QuietCoach
//
// 90 seconds to first recording. No tutorials.
// Immediate value. First win.

import SwiftUI
import AVFoundation

// MARK: - Elevated Onboarding

struct ElevatedOnboardingView: View {

    // MARK: - State

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedScenario: Scenario?
    @State private var hasCompletedFirstRecording = false
    @State private var firstScore: Int?
    @State private var micPermissionGranted = false
    @State private var showingPermissionAlert = false

    // Animation states
    @State private var welcomeTextVisible = false
    @State private var welcomeButtonVisible = false
    @State private var hookTextVisible = false
    @State private var hookButtonVisible = false
    @State private var selectHeaderVisible = false
    @State private var cardsVisible = false
    @State private var recordPromptVisible = false
    @State private var resultConfettiShowing = false

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Namespace

    @Namespace private var onboardingNamespace

    // MARK: - Callbacks

    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.qcBackground.ignoresSafeArea()

            // Ambient gradient with step-based color
            AmbientMeshGradient()
                .ignoresSafeArea()
                .opacity(0.5)
                .hueRotation(.degrees(stepHueRotation))
                .animation(.easeInOut(duration: 1.0), value: currentStep)

            // Content
            VStack(spacing: 0) {
                switch currentStep {
                case .welcome:
                    welcomeStep
                case .hook:
                    hookStep
                case .select:
                    selectStep
                case .record:
                    recordStep
                case .result:
                    resultStep
                }
            }

            // Confetti overlay for result
            if resultConfettiShowing {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var stepHueRotation: Double {
        switch currentStep {
        case .welcome: return 0
        case .hook: return 15
        case .select: return 30
        case .record: return 45
        case .result: return -20
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Statement with staggered reveal
            VStack(spacing: 16) {
                Text("Everyone has conversations")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .opacity(welcomeTextVisible ? 1 : 0)
                    .offset(y: welcomeTextVisible ? 0 : 20)

                Text("they dread.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.qcMoodReady)
                    .opacity(welcomeTextVisible ? 1 : 0)
                    .offset(y: welcomeTextVisible ? 0 : 20)
                    .shadow(color: Color.qcMoodReady.opacity(welcomeTextVisible ? 0.5 : 0), radius: 20)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Spacer()

            // Continue button with delayed entrance
            Button {
                Haptics.buttonPress()
                transitionToStep(.hook)
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            Color.qcMoodReady
                            // Glass shimmer
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .opacity(welcomeButtonVisible ? 1 : 0)
            .offset(y: welcomeButtonVisible ? 0 : 30)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .transition(.opacity)
        .onAppear {
            if !reduceMotion {
                // Staggered entrance animation
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                    welcomeTextVisible = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.8)) {
                    welcomeButtonVisible = true
                }
            } else {
                welcomeTextVisible = true
                welcomeButtonVisible = true
            }
        }
    }

    // MARK: - Step Transition

    private func transitionToStep(_ step: OnboardingStep) {
        // Reset animation states for next step
        hookTextVisible = false
        hookButtonVisible = false
        selectHeaderVisible = false
        cardsVisible = false
        recordPromptVisible = false

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = step
        }
    }

    // MARK: - Step 2: Hook

    private var hookStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Question with float effect
            VStack(spacing: 24) {
                Text("What if you could")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(hookTextVisible ? 1 : 0)
                    .offset(y: hookTextVisible ? 0 : 20)

                Text("practice them first?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(hookTextVisible ? 1 : 0)
                    .offset(y: hookTextVisible ? 0 : 20)
                    .shadow(color: .white.opacity(hookTextVisible ? 0.3 : 0), radius: 20)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Spacer()

            // Action button with arrow animation
            Button {
                Haptics.buttonPress()
                transitionToStep(.select)
            } label: {
                HStack(spacing: 8) {
                    Text("Show me")
                    Image(systemName: "arrow.right")
                        .symbolEffect(.bounce, options: .repeating.speed(0.5), value: hookButtonVisible)
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    ZStack {
                        Color.qcMoodReady
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .opacity(hookButtonVisible ? 1 : 0)
            .offset(y: hookButtonVisible ? 0 : 30)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    hookTextVisible = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
                    hookButtonVisible = true
                }
            } else {
                hookTextVisible = true
                hookButtonVisible = true
            }
        }
    }

    // MARK: - Step 3: Select Scenario

    private var selectStep: some View {
        VStack(spacing: 32) {
            // Header with staggered entrance
            VStack(spacing: 8) {
                Text("Pick one that's been")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(selectHeaderVisible ? 1 : 0)
                    .offset(y: selectHeaderVisible ? 0 : 15)

                Text("on your mind")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(selectHeaderVisible ? 1 : 0)
                    .offset(y: selectHeaderVisible ? 0 : 15)
            }
            .padding(.top, 60)

            // Scenario grid with staggered card entrances
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(Array(Scenario.freeScenarios.prefix(4).enumerated()), id: \.element.id) { index, scenario in
                        OnboardingScenarioCard(
                            scenario: scenario,
                            isSelected: selectedScenario?.id == scenario.id,
                            cardIndex: index,
                            isVisible: cardsVisible
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedScenario = scenario
                            }
                            Haptics.selectScenario()
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Continue with glass effect when enabled
            selectContinueButton
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                    selectHeaderVisible = true
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3)) {
                    cardsVisible = true
                }
            } else {
                selectHeaderVisible = true
                cardsVisible = true
            }
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Skip for Now", role: .cancel) {
                transitionToStep(.record)
            }
        } message: {
            Text("Quiet Coach needs microphone access to hear your practice. You can enable this in Settings.")
        }
    }

    // MARK: - Select Continue Button

    private var selectContinueButton: some View {
        let isEnabled = selectedScenario != nil
        let bgColor: Color = isEnabled ? .qcMoodReady : .qcSurface
        let textColor: Color = isEnabled ? .black : .white.opacity(0.3)

        return Button {
            Haptics.buttonPress()
            requestMicrophoneAndProceed()
        } label: {
            Text("Let's practice")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!isEnabled)
        .animation(.spring(response: 0.3), value: isEnabled)
    }

    // MARK: - Microphone Permission

    private func requestMicrophoneAndProceed() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                micPermissionGranted = granted
                if granted {
                    Haptics.selectScenario()
                    transitionToStep(.record)
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }

    // MARK: - Step 4: Record

    private var recordStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Prompt with breathing animation
            if let scenario = selectedScenario {
                VStack(spacing: 16) {
                    // Glowing icon
                    ZStack {
                        Circle()
                            .fill(Color.qcMoodReady.opacity(recordPromptVisible ? 0.2 : 0))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)

                        Image(systemName: scenario.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(Color.qcMoodReady)
                            .qcBreatheEffect(isActive: recordPromptVisible)
                    }
                    .opacity(recordPromptVisible ? 1 : 0)
                    .scaleEffect(recordPromptVisible ? 1 : 0.5)

                    Text("Take 30 seconds.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .opacity(recordPromptVisible ? 1 : 0)
                        .offset(y: recordPromptVisible ? 0 : 20)

                    Text("Say what you need to say.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(recordPromptVisible ? 1 : 0)
                        .offset(y: recordPromptVisible ? 0 : 20)
                }
                .multilineTextAlignment(.center)
            }

            Spacer()

            // Record button
            OnboardingRecordButton { score in
                firstScore = score
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    hasCompletedFirstRecording = true
                    currentStep = .result
                }
            }
            .opacity(recordPromptVisible ? 1 : 0)
            .scaleEffect(recordPromptVisible ? 1 : 0.8)
            .padding(.bottom, 60)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .opacity
        ))
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                    recordPromptVisible = true
                }
            } else {
                recordPromptVisible = true
            }
        }
    }

    // MARK: - Step 5: Result

    @State private var resultTextVisible = false
    @State private var resultButtonVisible = false

    private var resultStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Celebration with floating animation
            VStack(spacing: 24) {
                if let score = firstScore {
                    LiquidScoreText(score: score)
                        .scaleEffect(resultTextVisible ? 1 : 0.3)
                }

                Text("See? You did it.")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .opacity(resultTextVisible ? 1 : 0)
                    .offset(y: resultTextVisible ? 0 : 20)

                Text("That's the whole app.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(resultTextVisible ? 1 : 0)
                    .offset(y: resultTextVisible ? 0 : 20)
            }
            .multilineTextAlignment(.center)

            Spacer()

            // Get started with celebration color
            Button {
                Haptics.buttonPress()
                onComplete()
            } label: {
                Text("Get started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            Color.qcMoodCelebration
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear, .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.qcMoodCelebration.opacity(0.4), radius: 20, y: 10)
            }
            .opacity(resultButtonVisible ? 1 : 0)
            .offset(y: resultButtonVisible ? 0 : 30)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .transition(.opacity)
        .onAppear {
            Haptics.scoresRevealed()
            SoundManager.shared.play(.celebration)

            if !reduceMotion {
                // Show confetti
                withAnimation(.easeOut(duration: 0.1)) {
                    resultConfettiShowing = true
                }

                // Staggered text entrance
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3)) {
                    resultTextVisible = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.0)) {
                    resultButtonVisible = true
                }

                // Hide confetti after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        resultConfettiShowing = false
                    }
                }
            } else {
                resultTextVisible = true
                resultButtonVisible = true
            }
        }
    }
}

// MARK: - Onboarding Step

enum OnboardingStep {
    case welcome
    case hook
    case select
    case record
    case result
}

// MARK: - Onboarding Scenario Card

struct OnboardingScenarioCard: View {
    let scenario: Scenario
    let isSelected: Bool
    var cardIndex: Int = 0
    var isVisible: Bool = true
    let action: () -> Void

    private var animationDelay: Double {
        Double(cardIndex) * 0.1
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Glowing icon when selected
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.qcMoodReady.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .blur(radius: 8)
                    }

                    Image(systemName: scenario.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? Color.qcMoodReady : .white.opacity(0.6))
                        .symbolEffect(.bounce, value: isSelected)
                }

                Text(scenario.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                ZStack {
                    isSelected ? Color.qcMoodReady.opacity(0.15) : Color.qcSurface
                    // Glass highlight
                    if isSelected {
                        LinearGradient(
                            colors: [.white.opacity(0.1), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.qcMoodReady : .clear, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(animationDelay), value: isVisible)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particle.shape
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(screenHeight: geometry.size.height)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                color: [.qcMoodCelebration, .qcMoodSuccess, .qcMoodReady, .yellow, .orange, .pink].randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                shape: [AnyShape(Circle()), AnyShape(Rectangle()), AnyShape(Capsule())].randomElement()!,
                velocity: CGFloat.random(in: 100...300),
                opacity: 1.0
            )
        }
    }

    private func animateParticles(screenHeight: CGFloat) {
        for index in particles.indices {
            let duration = Double.random(in: 2.0...3.5)
            let xDrift = CGFloat.random(in: -100...100)

            withAnimation(.easeOut(duration: duration)) {
                particles[index].position.y = screenHeight + 50
                particles[index].position.x += xDrift
                particles[index].rotation += Double.random(in: 180...720)
            }

            withAnimation(.easeIn(duration: duration).delay(duration * 0.7)) {
                particles[index].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var rotation: Double
    let shape: AnyShape
    let velocity: CGFloat
    var opacity: Double
}

// MARK: - Onboarding Record Button

struct OnboardingRecordButton: View {
    let onComplete: (Int) -> Void

    @State private var isRecording = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>?

    private let maxDuration: TimeInterval = 30

    var body: some View {
        VStack(spacing: 24) {
            // Timer
            Text(timeString)
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .foregroundStyle(isRecording ? Color.qcMoodEngaged : .white.opacity(0.4))
                .monospacedDigit()

            // Button
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(isRecording ? Color.qcMoodEngaged.opacity(0.3) : Color.qcSurface, lineWidth: 4)
                        .frame(width: 100, height: 100)

                    // Progress ring
                    if isRecording {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.qcMoodEngaged, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                    }

                    // Inner shape
                    Group {
                        if isRecording {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.qcMoodEngaged)
                                .frame(width: 32, height: 32)
                        } else {
                            Circle()
                                .fill(Color.qcMoodReady)
                                .frame(width: 70, height: 70)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Hint
            Text(isRecording ? "Tap to finish" : "Tap to start")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var progress: Double {
        elapsedTime / maxDuration
    }

    private var timeString: String {
        let remaining = max(0, maxDuration - elapsedTime)
        let seconds = Int(remaining)
        return String(format: "0:%02d", seconds)
    }

    private func startRecording() {
        isRecording = true
        elapsedTime = 0
        Haptics.startRecording()

        timerTask = Task { @MainActor in
            while !Task.isCancelled && elapsedTime < maxDuration {
                try? await Task.sleep(for: .milliseconds(100))
                if !Task.isCancelled {
                    elapsedTime += 0.1
                }
            }
            if !Task.isCancelled && elapsedTime >= maxDuration {
                stopRecording()
            }
        }
    }

    private func stopRecording() {
        timerTask?.cancel()
        timerTask = nil
        isRecording = false
        Haptics.stopRecording()

        // Generate a score based on duration (simple heuristic for onboarding)
        let score = min(95, max(65, Int(elapsedTime * 2.5) + Int.random(in: 0...10)))
        onComplete(score)
    }
}

// MARK: - Preview

#Preview {
    ElevatedOnboardingView {
        print("Onboarding complete")
    }
}

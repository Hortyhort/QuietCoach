// ElevatedOnboarding.swift
// QuietCoach
//
// 90 seconds to first recording. No tutorials.
// Immediate value. First win.

import SwiftUI

// MARK: - Elevated Onboarding

struct ElevatedOnboardingView: View {

    // MARK: - State

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedScenario: Scenario?
    @State private var hasCompletedFirstRecording = false
    @State private var firstScore: Int?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Callbacks

    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.qcBackground.ignoresSafeArea()

            // Ambient gradient
            AmbientMeshGradient()
                .ignoresSafeArea()
                .opacity(0.5)

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
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Statement
            VStack(spacing: 16) {
                Text("Everyone has conversations")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)

                Text("they dread.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.qcMoodReady)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Spacer()

            // Continue button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .hook
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.qcMoodReady)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .transition(.opacity)
    }

    // MARK: - Step 2: Hook

    private var hookStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Question
            VStack(spacing: 24) {
                Text("What if you could")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))

                Text("practice them first?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Spacer()

            // Action button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .select
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Show me")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.qcMoodReady)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Step 3: Select Scenario

    private var selectStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Pick one that's been")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))

                Text("on your mind")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 60)

            // Scenario grid
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(Scenario.freeScenarios.prefix(4)) { scenario in
                        OnboardingScenarioCard(
                            scenario: scenario,
                            isSelected: selectedScenario?.id == scenario.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedScenario = scenario
                            }
                            HapticChoreography.selection()
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Continue (enabled when selected)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .record
                }
            } label: {
                Text("Let's practice")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(selectedScenario != nil ? .black : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedScenario != nil ? Color.qcMoodReady : Color.qcSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(selectedScenario == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Step 4: Record

    private var recordStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Prompt
            if let scenario = selectedScenario {
                VStack(spacing: 16) {
                    Image(systemName: scenario.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(Color.qcMoodReady)
                        .qcBreatheEffect(isActive: true)

                    Text("Take 30 seconds.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Say what you need to say.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .multilineTextAlignment(.center)
            }

            Spacer()

            // Record button (simplified)
            OnboardingRecordButton { score in
                firstScore = score
                withAnimation(.easeInOut(duration: 0.5)) {
                    hasCompletedFirstRecording = true
                    currentStep = .result
                }
            }
            .padding(.bottom, 60)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Step 5: Result

    private var resultStep: some View {
        VStack(spacing: 40) {
            Spacer()

            // Celebration
            VStack(spacing: 24) {
                if let score = firstScore {
                    LiquidScoreText(score: score)
                }

                Text("See? You did it.")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)

                Text("That's the whole app.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .multilineTextAlignment(.center)

            Spacer()

            // Get started
            Button {
                onComplete()
            } label: {
                Text("Get started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.qcMoodCelebration)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .transition(.opacity)
        .onAppear {
            HapticChoreography.scoreReveal(score: firstScore ?? 75)
            SoundManager.shared.play(.celebration)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: scenario.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.qcMoodReady : .white.opacity(0.6))

                Text(scenario.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(isSelected ? Color.qcMoodReady.opacity(0.15) : Color.qcSurface)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.qcMoodReady : .clear, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
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
        HapticChoreography.recordingStart()

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
        HapticChoreography.recordingStop()

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

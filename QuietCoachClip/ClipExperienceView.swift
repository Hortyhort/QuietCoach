// ClipExperienceView.swift
// QuietCoach App Clip
//
// A focused, instant practice experience.
// One scenario, immediate value, clear path to full app.

import SwiftUI
import StoreKit

struct ClipExperienceView: View {

    // MARK: - State

    @Binding var hasCompletedSession: Bool
    @State private var phase: ClipPhase = .welcome
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingAppStoreOverlay = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                switch phase {
                case .welcome:
                    welcomePhase

                case .practice:
                    practicePhase

                case .complete:
                    completePhase
                }
            }
        }
        .appStoreOverlay(isPresented: $showingAppStoreOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
    }

    // MARK: - Welcome Phase

    private var welcomePhase: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and name
            VStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Quiet Coach")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Practice difficult conversations")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Scenario preview
            VStack(alignment: .leading, spacing: 16) {
                Text("Try it now")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.2)

                // Featured scenario card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Set a Boundary")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Practice saying no with confidence")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)

            Spacer()

            // Start button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    phase = .practice
                }
            } label: {
                Text("Start Practicing")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Practice Phase

    private var practicePhase: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 28))
                    .foregroundColor(accentColor)

                Text("Set a Boundary")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                Text("Say what you need to say")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 60)

            Spacer()

            // Waveform placeholder
            HStack(spacing: 3) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(isRecording ? 0.8 : 0.3))
                        .frame(width: 4, height: isRecording ? CGFloat.random(in: 20...60) : 20)
                        .animation(.easeInOut(duration: 0.15).repeatForever(), value: isRecording)
                }
            }
            .frame(height: 60)

            // Timer
            Text(formatTime(recordingTime))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.white)

            Spacer()

            // Record button
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : accentColor)
                        .frame(width: 80, height: 80)

                    if isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Complete Phase

    private var completePhase: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("Great Practice!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("You practiced for \(formatTime(recordingTime))")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Value proposition
            VStack(alignment: .leading, spacing: 16) {
                Text("Get the full experience")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.2)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "waveform", text: "AI-powered feedback on your delivery")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress over time")
                    FeatureRow(icon: "rectangle.stack", text: "10+ conversation scenarios")
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Get full app button
            Button {
                showingAppStoreOverlay = true
            } label: {
                Text("Get Quiet Coach")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)

            // Try again button
            Button {
                withAnimation {
                    recordingTime = 0
                    phase = .practice
                }
            } label: {
                Text("Practice Again")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(accentColor)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }
    }

    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        hasCompletedSession = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            phase = .complete
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var accentColor: Color {
        Color(red: 0.98, green: 0.82, blue: 0.47)
    }
}

// MARK: - Clip Phase

enum ClipPhase {
    case welcome
    case practice
    case complete
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.98, green: 0.82, blue: 0.47))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Preview

#Preview {
    ClipExperienceView(hasCompletedSession: .constant(false))
}

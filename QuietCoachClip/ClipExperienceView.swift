// ClipExperienceView.swift
// QuietCoach App Clip
//
// A focused, instant practice experience.
// One scenario, immediate value, clear path to full app.
// iOS 26 Liquid Glass design language.

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

    // Animation states
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var cardOpacity: CGFloat = 0
    @State private var buttonOpacity: CGFloat = 0
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 0.3, count: 40)
    @State private var pulseScale: CGFloat = 1.0
    @State private var completionScale: CGFloat = 0.5
    @State private var glowOpacity: CGFloat = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        ZStack {
            // Animated background
            backgroundGradient
                .ignoresSafeArea()

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
        .onAppear {
            animateWelcome()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            // Deep background
            Color.black

            // Animated gradient overlay
            RadialGradient(
                colors: [
                    accentColor.opacity(isRecording ? 0.15 : 0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .scaleEffect(pulseScale)
            .animation(
                reduceMotion ? nil :
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: pulseScale
            )

            // Top glow
            LinearGradient(
                colors: [accentColor.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .onAppear {
            if !reduceMotion {
                pulseScale = 1.15
            }
        }
    }

    // MARK: - Welcome Phase

    private var welcomePhase: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(accentColor.opacity(glowOpacity))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                // Glass container
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Circle()
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    }

                // Icon
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)

            // Title and tagline
            VStack(spacing: 12) {
                Text("Quiet Coach")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Practice difficult conversations")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            .opacity(titleOpacity)

            Spacer()

            // Scenario preview card with glass effect
            VStack(alignment: .leading, spacing: 16) {
                Text("Try it now")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.5)

                // Glass card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        // Icon with glow
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 22))
                                .foregroundColor(accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Set a Boundary")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Practice saying no with confidence")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .padding(.horizontal, 24)
            .opacity(cardOpacity)

            Spacer()

            // Start button with glass effect
            Button {
                triggerHaptic(.medium)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    phase = .practice
                }
            } label: {
                Text("Start Practicing")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            accentColor
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: accentColor.opacity(0.4), radius: 16, y: 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(buttonOpacity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quiet Coach. Practice difficult conversations. Try Set a Boundary scenario.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Practice Phase

    private var practicePhase: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 26))
                        .foregroundColor(accentColor)
                }

                Text("Set a Boundary")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Text("Say what you need to say")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 60)

            Spacer()

            // Liquid glass waveform
            ZStack {
                // Glass container
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 100)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }

                // Waveform bars
                HStack(spacing: 3) {
                    ForEach(0..<40, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 4, height: waveformAmplitudes[index] * 60)
                    }
                }
            }
            .padding(.horizontal, 24)

            // Timer with glass background
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 160, height: 72)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }

                Text(formatTime(recordingTime))
                    .font(.system(size: 42, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            // Record button with liquid glass effect
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.3) : accentColor.opacity(0.3))
                        .frame(width: 110, height: 110)
                        .blur(radius: 20)

                    // Glass ring
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 88, height: 88)
                        .overlay {
                            Circle()
                                .stroke(
                                    isRecording ? Color.red.opacity(0.5) : accentColor.opacity(0.5),
                                    lineWidth: 2
                                )
                        }

                    // Inner button
                    if isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                    } else {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 64, height: 64)
                    }
                }
            }
            .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
            .padding(.bottom, 60)
        }
        .onAppear {
            startWaveformAnimation()
        }
    }

    // MARK: - Complete Phase

    private var completePhase: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon with celebration
            ZStack {
                // Glow
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)

                // Glass container
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    }

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.green)
            }
            .scaleEffect(completionScale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    completionScale = 1.0
                }
            }

            VStack(spacing: 12) {
                Text("Great Practice!")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)

                Text("You practiced for \(formatTime(recordingTime))")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Value proposition card
            VStack(alignment: .leading, spacing: 16) {
                Text("Get the full experience")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.5)

                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(icon: "waveform", text: "AI-powered feedback on your delivery")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress over time")
                    FeatureRow(icon: "rectangle.stack", text: "10+ conversation scenarios")
                    FeatureRow(icon: "flame.fill", text: "Daily streak motivation")
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Get full app button
            VStack(spacing: 16) {
                Button {
                    triggerHaptic(.heavy)
                    showingAppStoreOverlay = true
                } label: {
                    Text("Get Quiet Coach")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                accentColor
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: accentColor.opacity(0.4), radius: 16, y: 8)
                }

                Button {
                    triggerHaptic(.light)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        recordingTime = 0
                        completionScale = 0.5
                        phase = .practice
                    }
                } label: {
                    Text("Practice Again")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Animations

    private func animateWelcome() {
        guard !reduceMotion else {
            iconScale = 1.0
            iconOpacity = 1.0
            titleOpacity = 1.0
            cardOpacity = 1.0
            buttonOpacity = 1.0
            glowOpacity = 0.5
            return
        }

        // Staggered entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
            glowOpacity = 0.5
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            titleOpacity = 1.0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
            cardOpacity = 1.0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
            buttonOpacity = 1.0
        }
    }

    private func startWaveformAnimation() {
        guard isRecording else { return }

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isRecording {
                timer.invalidate()
                return
            }

            withAnimation(.easeInOut(duration: 0.1)) {
                waveformAmplitudes = (0..<40).map { _ in
                    CGFloat.random(in: 0.2...1.0)
                }
            }
        }
    }

    // MARK: - Recording

    private func startRecording() {
        triggerHaptic(.heavy)
        isRecording = true
        startWaveformAnimation()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }
    }

    private func stopRecording() {
        triggerHaptic(.success)
        isRecording = false
        timer?.invalidate()
        timer = nil
        hasCompletedSession = true

        // Reset waveform
        withAnimation(.easeOut(duration: 0.3)) {
            waveformAmplitudes = Array(repeating: 0.3, count: 40)
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
        Color(red: 0.98, green: 0.82, blue: 0.47)  // Warm gold
    }

    private func triggerHaptic(_ style: HapticStyle) {
        #if !targetEnvironment(simulator)
        switch style {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        #endif
    }

    private enum HapticStyle {
        case light, medium, heavy, success
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

    private var accentColor: Color {
        Color(red: 0.98, green: 0.82, blue: 0.47)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

// MARK: - Preview

#Preview {
    ClipExperienceView(hasCompletedSession: .constant(false))
}

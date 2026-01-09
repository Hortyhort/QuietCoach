// OnboardingView.swift
// QuietCoach
//
// First-run experience. Builds trust, requests permission, starts practice.
// Maximum 4 screens. Every word earns its place.

import SwiftUI
import AVFoundation

struct OnboardingView: View {

    // MARK: - Properties

    let onComplete: () -> Void

    // MARK: - State

    @State private var currentPage = 0
    @State private var micPermissionGranted = false

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.qcBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    privacyPage.tag(1)
                    microphonePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Page indicator and button
                bottomSection
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundColor(.qcAccent)
                .accessibilityHidden(true)

            // Text
            VStack(spacing: 12) {
                Text("Practice the words\nbefore they count.")
                    .font(.qcTitle)
                    .foregroundColor(.qcTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Quiet Coach helps you rehearse hard conversations—privately, with instant feedback.")
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Constants.Layout.horizontalPadding)
    }

    // MARK: - Privacy Page

    private var privacyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundColor(.qcAccent)
                .accessibilityHidden(true)

            // Text
            VStack(spacing: 12) {
                Text("Your voice stays yours.")
                    .font(.qcTitle)
                    .foregroundColor(.qcTextPrimary)
                    .multilineTextAlignment(.center)

                Text("All audio is processed on your device. Nothing is uploaded. Nothing is stored unless you choose.")
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Constants.Layout.horizontalPadding)
    }

    // MARK: - Microphone Page

    private var microphonePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "mic.fill")
                .font(.system(size: 64))
                .foregroundColor(.qcAccent)
                .accessibilityHidden(true)

            // Text
            VStack(spacing: 12) {
                Text("One permission.\nThat's it.")
                    .font(.qcTitle)
                    .foregroundColor(.qcTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Quiet Coach needs microphone access to hear your rehearsal. You're always in control.")
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Constants.Layout.horizontalPadding)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.qcAccent : Color.qcTextTertiary)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(currentPage + 1) of 3")

            // Button
            Button {
                handleButtonTap()
            } label: {
                Text(buttonTitle)
                    .font(.qcButton)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.qcAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, Constants.Layout.horizontalPadding)
            .accessibilityLabel(buttonTitle)
            .accessibilityHint(buttonAccessibilityHint)
        }
        .padding(.bottom, 48)
    }

    private var buttonAccessibilityHint: String {
        switch currentPage {
        case 0: return "Double tap to continue to privacy information"
        case 1: return "Double tap to continue to microphone permission"
        case 2: return micPermissionGranted ? "Double tap to start using Quiet Coach" : "Double tap to grant microphone access"
        default: return "Double tap to continue"
        }
    }

    // MARK: - Button Logic

    private var buttonTitle: String {
        switch currentPage {
        case 0: return "Get Started"
        case 1: return "Continue"
        case 2: return micPermissionGranted ? "Start Practicing" : "Allow Microphone"
        default: return "Continue"
        }
    }

    private func handleButtonTap() {
        Haptics.buttonPress()

        switch currentPage {
        case 0, 1:
            if reduceMotion {
                currentPage += 1
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            }

        case 2:
            if micPermissionGranted {
                onComplete()
            } else {
                requestMicrophonePermission()
            }

        default:
            break
        }
    }

    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                micPermissionGranted = granted
                if granted {
                    Haptics.scoresRevealed()
                    onComplete()
                } else {
                    Haptics.warning()
                    // User denied - they can still proceed but recording won't work
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

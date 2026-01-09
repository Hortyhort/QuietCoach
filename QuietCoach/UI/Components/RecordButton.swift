// RecordButton.swift
// QuietCoach
//
// The primary action. One button, three states.
// Every state transition is intentional and satisfying.

import SwiftUI

struct RecordButton: View {

    // MARK: - Properties

    let state: RehearsalRecorder.State
    let onTap: () -> Void

    var size: CGFloat = Constants.Layout.recordButtonSize

    // MARK: - State

    @State private var isPressing: Bool = false
    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        buttonContent
            .onAppear {
                startPulseAnimation()
            }
            .onChange(of: state) { _, newState in
                if newState == .recording {
                    startPulseAnimation()
                }
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(.isButton)
    }

    private var buttonContent: some View {
        Button(action: handleTap) {
            buttonVisuals
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressing = true }
                .onEnded { _ in isPressing = false }
        )
    }

    private var buttonVisuals: some View {
        ZStack {
            pulseRing
            backgroundCircle
            innerShapeView
        }
        .scaleEffect(isPressing ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressing)
    }

    @ViewBuilder
    private var pulseRing: some View {
        if state == .recording {
            Circle()
                .stroke(Color.qcRecording.opacity(0.3), lineWidth: 3)
                .frame(width: size + 20, height: size + 20)
                .scaleEffect(pulseScale)
                .opacity(2 - pulseScale)
        }
    }

    private var backgroundCircle: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private var innerShapeView: some View {
        switch state {
        case .idle:
            Circle()
                .fill(foregroundColor)
                .frame(width: innerSize, height: innerSize)
        case .recording:
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(foregroundColor)
                .frame(width: innerSize, height: innerSize)
        case .paused:
            PlayIconShape()
                .fill(foregroundColor)
                .frame(width: innerSize, height: innerSize)
        case .finished:
            Circle()
                .fill(foregroundColor)
                .frame(width: innerSize, height: innerSize)
        }
    }

    // MARK: - Sizing

    private var innerSize: CGFloat {
        switch state {
        case .idle: return size * 0.7
        case .recording: return size * 0.35
        case .paused: return size * 0.4
        case .finished: return size * 0.7
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        switch state {
        case .idle: return .qcSurface
        case .recording: return .qcRecording.opacity(0.2)
        case .paused: return .qcPaused.opacity(0.2)
        case .finished: return .qcSurface
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .idle: return .qcAccent
        case .recording: return .qcRecording
        case .paused: return .qcPaused
        case .finished: return .qcAccent
        }
    }

    // MARK: - Actions

    private func handleTap() {
        // Haptic feedback and VoiceOver announcements based on current state
        switch state {
        case .idle:
            Haptics.startRecording()
            AccessibilityAnnouncement.recordingStarted()
        case .recording:
            Haptics.stopRecording()
            AccessibilityAnnouncement.recordingStopped()
        case .paused:
            Haptics.startRecording()
            AccessibilityAnnouncement.recordingStarted()
        case .finished:
            Haptics.buttonPress()
        }

        onTap()
    }

    // MARK: - Pulse Animation

    private func startPulseAnimation() {
        guard state == .recording, !reduceMotion else { return }

        pulseScale = 1.0
        withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
            pulseScale = 1.5
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        switch state {
        case .idle: return "Record"
        case .recording: return "Stop recording"
        case .paused: return "Resume recording"
        case .finished: return "Record again"
        }
    }

    private var accessibilityHint: String {
        switch state {
        case .idle: return "Double tap to start recording your rehearsal"
        case .recording: return "Double tap to stop recording"
        case .paused: return "Double tap to resume recording"
        case .finished: return "Double tap to start a new recording"
        }
    }
}

// MARK: - Play Icon Shape

private struct PlayIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Triangle pointing right
        let padding: CGFloat = rect.width * 0.15
        let left = rect.minX + padding
        let right = rect.maxX - padding
        let top = rect.minY + padding
        let bottom = rect.maxY - padding

        path.move(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: right, y: rect.midY))
        path.addLine(to: CGPoint(x: left, y: bottom))
        path.closeSubpath()

        return path
    }
}

// MARK: - Secondary Action Button

struct SecondaryActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var size: CGFloat = Constants.Layout.secondaryButtonSize

    var body: some View {
        Button(action: {
            Haptics.buttonPress()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.qcSurface)
                        .frame(width: size, height: size)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.qcTextPrimary)
                }

                Text(label)
                    .font(.qcCaption)
                    .foregroundColor(.qcTextSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Timer Display

struct TimerDisplay: View {
    let time: TimeInterval
    var isWarning: Bool = false

    var body: some View {
        Text(time.qcFormattedDuration)
            .font(.qcTimer)
            .foregroundColor(isWarning ? .qcWarning : .qcTextPrimary)
            .monospacedDigit()
            .contentTransition(.numericText())
            .accessibilityLabel("Recording time: \(formattedAccessibleTime)")
    }

    private var formattedAccessibleTime: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if minutes > 0 {
            return "\(minutes) minutes and \(seconds) seconds"
        }
        return "\(seconds) seconds"
    }
}

// MARK: - Recording Warning Banner

struct RecordingWarningBanner: View {
    let warning: RehearsalRecorder.RecordingWarning

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: warning.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.qcWarning)

            Text(warning.message)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextPrimary)

            Spacer()
        }
        .padding(12)
        .background(Color.qcWarning.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityLabel(warning.accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("Record Button States") {
    VStack(spacing: 40) {
        HStack(spacing: 40) {
            VStack {
                RecordButton(state: .idle, onTap: {})
                Text("Idle").font(.caption)
            }
            VStack {
                RecordButton(state: .recording, onTap: {})
                Text("Recording").font(.caption)
            }
        }
        HStack(spacing: 40) {
            VStack {
                RecordButton(state: .paused, onTap: {})
                Text("Paused").font(.caption)
            }
            VStack {
                RecordButton(state: .finished, onTap: {})
                Text("Finished").font(.caption)
            }
        }

        TimerDisplay(time: 127)

        RecordingWarningBanner(warning: .tooQuiet)
    }
    .padding()
    .background(Color.qcBackground)
}

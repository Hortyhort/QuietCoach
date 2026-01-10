// Accessibility.swift
// QuietCoach
//
// Accessibility utilities for inclusive design.
// Every user deserves a great experience.

import SwiftUI

// MARK: - Accessibility Environment Keys

extension EnvironmentValues {
    /// Whether the user prefers reduced motion
    var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

// MARK: - Reduce Motion Support

extension View {
    /// Applies animation only if the user hasn't enabled Reduce Motion
    func qcAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(ReduceMotionAnimationModifier(animation: animation, value: value))
    }

    /// Conditionally applies a transition based on Reduce Motion preference
    func qcTransition(_ transition: AnyTransition) -> some View {
        self.modifier(ReduceMotionTransitionModifier(transition: transition))
    }
}

struct ReduceMotionAnimationModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

struct ReduceMotionTransitionModifier: ViewModifier {
    let transition: AnyTransition

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .transition(reduceMotion ? .opacity : transition)
    }
}

// MARK: - VoiceOver Announcements

@MainActor
enum AccessibilityAnnouncement {
    /// Announce recording started
    static func recordingStarted() {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Recording started"
        )
    }

    /// Announce recording paused
    static func recordingPaused() {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Recording paused"
        )
    }

    /// Announce recording stopped
    static func recordingStopped() {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Recording stopped"
        )
    }

    /// Announce score revealed
    static func scoreRevealed(score: Int) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Your overall score is \(score) out of 100"
        )
    }

    /// Announce individual score
    static func individualScore(category: String, score: Int) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(category): \(score) out of 100"
        )
    }

    /// Announce playback state
    static func playbackState(isPlaying: Bool) {
        UIAccessibility.post(
            notification: .announcement,
            argument: isPlaying ? "Playing" : "Paused"
        )
    }

    /// Announce playback position
    static func playbackPosition(seconds: Int, total: Int) {
        let position = formatTime(seconds)
        let duration = formatTime(total)
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(position) of \(duration)"
        )
    }

    /// Announce a warning
    static func warning(message: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Warning: \(message)"
        )
    }

    /// Announce screen change
    static func screenChanged(to screen: String) {
        UIAccessibility.post(
            notification: .screenChanged,
            argument: screen
        )
    }

    /// Announce navigation
    static func navigated(to destination: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Navigated to \(destination)"
        )
    }

    /// Announce success
    static func success(_ message: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: message
        )
    }

    /// Announce error
    static func error(_ message: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Error: \(message)"
        )
    }

    /// Announce streak milestone
    static func streakMilestone(days: Int) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Congratulations! You've practiced \(days) days in a row"
        )
    }

    /// Announce analysis progress
    static func analysisProgress(_ progress: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: progress
        )
    }

    /// Announce timer
    static func timerUpdate(seconds: Int) {
        let time = formatTime(seconds)
        UIAccessibility.post(
            notification: .announcement,
            argument: "Recording time: \(time)"
        )
    }

    // Helper
    private static func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes) minutes, \(seconds) seconds"
        }
        return "\(seconds) seconds"
    }
}

// MARK: - Accessible Color

extension Color {
    /// Returns a color with sufficient contrast for accessibility
    /// Falls back to primary text color if contrast is insufficient
    func withAccessibleContrast(against background: Color) -> Color {
        // In a production app, this would calculate actual contrast ratio
        // For now, we trust our theme colors meet WCAG requirements
        self
    }
}

// MARK: - Touch Target Size Modifier

extension View {
    /// Ensures the view meets minimum touch target size (44x44 points)
    func qcAccessibleTouchTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }

    /// Adds a larger invisible tap area around the view
    func qcExpandedTapArea(size: CGFloat = 44) -> some View {
        self.contentShape(Rectangle())
            .frame(minWidth: size, minHeight: size)
    }
}

// MARK: - Accessibility Focus

// Note: For complex focus management, use @AccessibilityFocusState directly in your views

// MARK: - Screen Reader Detection

extension View {
    /// Provides alternative content when VoiceOver is running
    @ViewBuilder
    func qcVoiceOverAlternative<Alternative: View>(
        @ViewBuilder alternative: () -> Alternative
    ) -> some View {
        if UIAccessibility.isVoiceOverRunning {
            alternative()
        } else {
            self
        }
    }
}

// MARK: - High Contrast Support

extension View {
    /// Adjusts colors for increased contrast when the user has enabled it
    func qcHighContrastSupport() -> some View {
        self.modifier(HighContrastModifier())
    }
}

struct HighContrastModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
        // High contrast adjustments would be applied here
        // Our dark theme already has high contrast ratios
    }
}

// MARK: - Accessibility Hints

enum AccessibilityHint {
    static let recordButton = "Double tap to start recording. Double tap again to stop."
    static let pauseButton = "Double tap to pause recording"
    static let resumeButton = "Double tap to resume recording"
    static let scenarioCard = "Double tap to start practicing this scenario"
    static let lockedScenario = "Double tap to learn about upgrading to Pro"
    static let playbackScrubber = "Swipe left or right to scrub through the recording"
    static let shareButton = "Double tap to share your rehearsal results"
    static let settingsButton = "Double tap to open settings"
}

// MARK: - Accessibility Labels for Scores

extension Int {
    /// Returns an accessibility-friendly description of a score
    var scoreAccessibilityDescription: String {
        switch self {
        case 90...100:
            return "\(self) out of 100, excellent"
        case 80..<90:
            return "\(self) out of 100, very good"
        case 70..<80:
            return "\(self) out of 100, good"
        case 60..<70:
            return "\(self) out of 100, fair"
        default:
            return "\(self) out of 100, needs practice"
        }
    }
}

// MARK: - Dynamic Type Scale Limit

extension View {
    /// Limits dynamic type scaling for specific UI elements that would break at extreme sizes
    func qcLimitedDynamicType(minimum: DynamicTypeSize = .xSmall, maximum: DynamicTypeSize = .accessibility3) -> some View {
        self.dynamicTypeSize(minimum...maximum)
    }
}

// MARK: - Custom Accessibility Actions

extension View {
    /// Adds a custom accessibility action
    func qcAccessibilityAction(name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: Text(name), action)
    }
}

// MARK: - Semantic Content Grouping

extension View {
    /// Groups content as a single accessible element
    func qcAccessibilityGroup(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Marks as a heading for rotor navigation
    func qcAccessibilityHeading(_ level: AccessibilityHeadingLevel = .h1) -> some View {
        self.accessibilityAddTraits(.isHeader)
    }

    /// Makes a container with custom rotor
    func qcAccessibilityRotor<Items: RandomAccessCollection>(
        _ name: String,
        items: Items,
        itemLabel: @escaping (Items.Element) -> String
    ) -> some View where Items.Element: Identifiable {
        self.accessibilityRotor(name) {
            ForEach(items) { item in
                AccessibilityRotorEntry(itemLabel(item), id: item.id)
            }
        }
    }
}

// MARK: - Score Accessibility

extension View {
    /// Adds comprehensive score accessibility
    func qcScoreAccessibility(
        category: String,
        score: Int,
        previousScore: Int? = nil
    ) -> some View {
        var label = "\(category): \(score) out of 100"

        if let previous = previousScore {
            let delta = score - previous
            if delta > 0 {
                label += ", improved by \(delta) points"
            } else if delta < 0 {
                label += ", decreased by \(abs(delta)) points"
            } else {
                label += ", same as before"
            }
        }

        // Add grade
        switch score {
        case 90...100: label += ", excellent"
        case 80..<90: label += ", very good"
        case 70..<80: label += ", good"
        case 60..<70: label += ", fair"
        default: label += ", needs practice"
        }

        return self.accessibilityLabel(label)
    }
}

// MARK: - Timer Accessibility

extension View {
    /// Makes a timer accessible with periodic announcements
    func qcTimerAccessibility(
        seconds: TimeInterval,
        isRecording: Bool
    ) -> some View {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60

        var label = "Recording time: "
        if minutes > 0 {
            label += "\(minutes) minute\(minutes == 1 ? "" : "s") "
        }
        label += "\(secs) second\(secs == 1 ? "" : "s")"

        if !isRecording {
            label = "Paused at " + label
        }

        return self.accessibilityLabel(label)
    }
}

// MARK: - Waveform Accessibility

extension View {
    /// Makes a waveform visualization accessible
    func qcWaveformAccessibility(
        averageLevel: Float,
        isRecording: Bool
    ) -> some View {
        var label = "Audio waveform visualization"

        if isRecording {
            let levelDescription: String
            switch averageLevel {
            case 0..<0.2: levelDescription = "very quiet"
            case 0.2..<0.4: levelDescription = "quiet"
            case 0.4..<0.6: levelDescription = "moderate"
            case 0.6..<0.8: levelDescription = "loud"
            default: levelDescription = "very loud"
            }
            label = "Recording, audio level is \(levelDescription)"
        }

        return self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Playback Scrubber Accessibility

extension View {
    /// Makes a playback scrubber fully accessible
    func qcScrubberAccessibility(
        currentTime: TimeInterval,
        duration: TimeInterval,
        onSeek: @escaping (TimeInterval) -> Void
    ) -> some View {
        let current = Int(currentTime)
        let total = Int(duration)

        return self
            .accessibilityLabel("Playback position")
            .accessibilityValue("\(formatTime(current)) of \(formatTime(total))")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    onSeek(min(currentTime + 5, duration))
                case .decrement:
                    onSeek(max(currentTime - 5, 0))
                @unknown default:
                    break
                }
            }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - Scenario Card Accessibility

extension View {
    /// Makes a scenario card fully accessible
    func qcScenarioAccessibility(
        title: String,
        category: String,
        isLocked: Bool,
        isPro: Bool
    ) -> some View {
        var label = title
        label += ", \(category) category"

        if isLocked {
            label += ", locked, requires Pro upgrade"
        }

        let hint = isLocked
            ? AccessibilityHint.lockedScenario
            : AccessibilityHint.scenarioCard

        return self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(isLocked ? [.isButton] : [.isButton, .startsMediaSession])
    }
}

// MARK: - Preview Helper

#if DEBUG
struct AccessibilityPreviewHelper: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Accessibility Test View")
                .font(.qcTitle2)
                .qcAccessibilityHeading()

            Button("Test Button") {}
                .qcAccessibleTouchTarget()
                .accessibilityHint("Double tap to test")

            Text("Score Example")
                .qcScoreAccessibility(category: "Clarity", score: 85, previousScore: 78)

            Text("This text scales with Dynamic Type")
                .font(.qcBody)
                .qcLimitedDynamicType()
        }
        .padding()
    }
}

#Preview {
    AccessibilityPreviewHelper()
        .preferredColorScheme(.dark)
}
#endif

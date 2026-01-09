// LiveActivityManager.swift
// QuietCoach
//
// Manages Live Activities for rehearsal recording. Shows recording
// status in Dynamic Island and on the lock screen.

#if os(iOS)
import ActivityKit
import OSLog

// Re-declare the attributes here so the main app can use them
struct RehearsalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: TimeInterval
        var isRecording: Bool
        var isPaused: Bool
    }

    let scenarioTitle: String
    let scenarioIcon: String
}

@Observable
@MainActor
final class LiveActivityManager {

    // MARK: - Singleton

    static let shared = LiveActivityManager()

    // MARK: - Properties

    private(set) var currentActivityId: String?
    private(set) var isActivityActive = false

    private let logger = Logger(subsystem: "com.quietcoach", category: "LiveActivity")

    // MARK: - Initialization

    private init() {}

    // MARK: - Activity Management

    /// Start a Live Activity for the given scenario
    func startActivity(scenarioTitle: String, scenarioIcon: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are not enabled")
            return
        }

        // End any existing activity first
        if currentActivityId != nil {
            Task {
                await endActivity()
            }
        }

        let attributes = RehearsalActivityAttributes(
            scenarioTitle: scenarioTitle,
            scenarioIcon: scenarioIcon
        )

        let initialState = RehearsalActivityAttributes.ContentState(
            elapsedTime: 0,
            isRecording: true,
            isPaused: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivityId = activity.id
            isActivityActive = true
            logger.info("Started Live Activity: \(activity.id)")
        } catch {
            logger.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    /// Update the Live Activity state
    nonisolated func updateActivity(elapsedTime: TimeInterval, isRecording: Bool, isPaused: Bool) async {
        let activities = Activity<RehearsalActivityAttributes>.activities

        let updatedState = RehearsalActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            isRecording: isRecording,
            isPaused: isPaused
        )

        for activity in activities {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }

    /// Pause the Live Activity
    nonisolated func pauseActivity(elapsedTime: TimeInterval) async {
        await updateActivity(elapsedTime: elapsedTime, isRecording: true, isPaused: true)
    }

    /// Resume the Live Activity
    nonisolated func resumeActivity(elapsedTime: TimeInterval) async {
        await updateActivity(elapsedTime: elapsedTime, isRecording: true, isPaused: false)
    }

    /// End the Live Activity
    func endActivity() async {
        let finalState = RehearsalActivityAttributes.ContentState(
            elapsedTime: 0,
            isRecording: false,
            isPaused: false
        )

        // Perform end on nonisolated context
        await Self.endAllActivitiesStatic(with: finalState)

        currentActivityId = nil
        isActivityActive = false
        logger.info("Ended Live Activity")
    }

    /// End all activities (cleanup)
    func endAllActivities() async {
        await Self.endAllActivitiesStatic(with: nil)
        currentActivityId = nil
        isActivityActive = false
    }

    /// Static nonisolated helper to end activities
    private nonisolated static func endAllActivitiesStatic(with finalState: RehearsalActivityAttributes.ContentState?) async {
        for activity in Activity<RehearsalActivityAttributes>.activities {
            if let state = finalState {
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Availability

    /// Check if Live Activities are available and enabled
    static var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Check if there's an ongoing activity
    nonisolated var hasOngoingActivity: Bool {
        !Activity<RehearsalActivityAttributes>.activities.isEmpty
    }
}
#endif

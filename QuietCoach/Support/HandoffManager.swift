// HandoffManager.swift
// QuietCoach
//
// Handoff support for seamless continuity between devices.
// Start on iPhone, continue on iPad or Mac.

import Foundation
import UIKit
import OSLog

// MARK: - Handoff Manager

@MainActor
final class HandoffManager {

    // MARK: - Singleton

    static let shared = HandoffManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Handoff")

    // MARK: - Activity Types

    /// Activity type identifiers (must match Info.plist NSUserActivityTypes)
    enum ActivityType: String {
        case viewScenario = "com.quietcoach.viewScenario"
        case reviewSession = "com.quietcoach.reviewSession"
        case practicing = "com.quietcoach.practicing"

        var title: String {
            switch self {
            case .viewScenario: return "Viewing Scenario"
            case .reviewSession: return "Reviewing Session"
            case .practicing: return "Practicing"
            }
        }
    }

    // MARK: - User Info Keys

    private enum UserInfoKey {
        static let scenarioId = "scenarioId"
        static let sessionId = "sessionId"
        static let scenarioTitle = "scenarioTitle"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Create Activities

    /// Create a Handoff activity for viewing a scenario
    func createViewScenarioActivity(scenario: Scenario) -> NSUserActivity {
        let activity = NSUserActivity(activityType: ActivityType.viewScenario.rawValue)

        // Basic configuration
        activity.title = scenario.title
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        // Payload
        activity.userInfo = [
            UserInfoKey.scenarioId: scenario.id,
            UserInfoKey.scenarioTitle: scenario.title
        ]

        // Rich metadata
        activity.contentAttributeSet = createAttributeSet(
            title: scenario.title,
            description: scenario.subtitle
        )

        // Keywords for Siri suggestions
        activity.keywords = Set([
            scenario.title,
            scenario.category.rawValue,
            "practice",
            "rehearsal"
        ])

        // Expiration (activities expire after 24 hours)
        activity.expirationDate = Date().addingTimeInterval(24 * 60 * 60)

        logger.debug("Created view scenario activity: \(scenario.id)")
        return activity
    }

    /// Create a Handoff activity for reviewing a session
    func createReviewSessionActivity(session: RehearsalSession) -> NSUserActivity {
        let activity = NSUserActivity(activityType: ActivityType.reviewSession.rawValue)

        let scenarioTitle = session.scenario?.title ?? "Session"

        // Basic configuration
        activity.title = "Review: \(scenarioTitle)"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        // Payload
        activity.userInfo = [
            UserInfoKey.sessionId: session.id.uuidString,
            UserInfoKey.scenarioTitle: scenarioTitle
        ]

        // Rich metadata
        var description = session.formattedDate
        if let scores = session.scores {
            description += " • Score: \(scores.overall)"
        }
        activity.contentAttributeSet = createAttributeSet(
            title: "Review: \(scenarioTitle)",
            description: description
        )

        // Keywords
        activity.keywords = Set([
            scenarioTitle,
            "review",
            "session",
            "feedback"
        ])

        // Expiration
        activity.expirationDate = Date().addingTimeInterval(24 * 60 * 60)

        logger.debug("Created review session activity: \(session.id)")
        return activity
    }

    /// Create a Handoff activity for active practice
    func createPracticingActivity(scenario: Scenario) -> NSUserActivity {
        let activity = NSUserActivity(activityType: ActivityType.practicing.rawValue)

        // Basic configuration
        activity.title = "Practicing: \(scenario.title)"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = false  // Don't show in Spotlight while practicing
        activity.isEligibleForPrediction = false

        // Payload
        activity.userInfo = [
            UserInfoKey.scenarioId: scenario.id,
            UserInfoKey.scenarioTitle: scenario.title
        ]

        // No expiration for active activity
        activity.expirationDate = nil

        logger.debug("Created practicing activity: \(scenario.id)")
        return activity
    }

    // MARK: - Parse Activities

    /// Parse an incoming Handoff activity
    func parseActivity(_ activity: NSUserActivity) -> HandoffAction? {
        guard let activityType = ActivityType(rawValue: activity.activityType) else {
            logger.warning("Unknown activity type: \(activity.activityType)")
            return nil
        }

        switch activityType {
        case .viewScenario, .practicing:
            guard let scenarioId = activity.userInfo?[UserInfoKey.scenarioId] as? String else {
                logger.warning("Missing scenario ID in activity")
                return nil
            }
            return .openScenario(id: scenarioId)

        case .reviewSession:
            guard let sessionIdString = activity.userInfo?[UserInfoKey.sessionId] as? String,
                  let sessionId = UUID(uuidString: sessionIdString) else {
                logger.warning("Missing or invalid session ID in activity")
                return nil
            }
            return .reviewSession(id: sessionId)
        }
    }

    // MARK: - Helpers

    private func createAttributeSet(title: String, description: String) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = title
        attributeSet.contentDescription = description
        attributeSet.creator = "Quiet Coach"
        return attributeSet
    }
}

// MARK: - Handoff Action

enum HandoffAction {
    case openScenario(id: String)
    case reviewSession(id: UUID)
}

// MARK: - CSSearchableItemAttributeSet

import CoreSpotlight
import UniformTypeIdentifiers

// MARK: - View Modifier for Handoff

import SwiftUI

/// View modifier to advertise a Handoff activity
struct HandoffActivityModifier: ViewModifier {
    let activity: NSUserActivity?

    func body(content: Content) -> some View {
        content
            .userActivity(activity?.activityType ?? "") { userActivity in
                if let activity = activity {
                    // Copy properties from our activity
                    userActivity.title = activity.title
                    userActivity.isEligibleForHandoff = activity.isEligibleForHandoff
                    userActivity.isEligibleForSearch = activity.isEligibleForSearch
                    userActivity.isEligibleForPrediction = activity.isEligibleForPrediction
                    userActivity.userInfo = activity.userInfo
                    userActivity.keywords = activity.keywords
                    userActivity.contentAttributeSet = activity.contentAttributeSet
                }
            }
    }
}

extension View {
    /// Advertise this view for Handoff
    func handoffActivity(_ activity: NSUserActivity?) -> some View {
        modifier(HandoffActivityModifier(activity: activity))
    }
}

// MARK: - Scene Phase Handling

/// Manage activity lifecycle based on scene phase
extension HandoffManager {

    /// Start advertising an activity
    func startActivity(_ activity: NSUserActivity) {
        activity.becomeCurrent()
        logger.debug("Started activity: \(activity.activityType)")
    }

    /// Stop advertising an activity
    func stopActivity(_ activity: NSUserActivity) {
        activity.resignCurrent()
        logger.debug("Stopped activity: \(activity.activityType)")
    }

    /// Invalidate an activity (when no longer relevant)
    func invalidateActivity(_ activity: NSUserActivity) {
        activity.invalidate()
        logger.debug("Invalidated activity: \(activity.activityType)")
    }
}

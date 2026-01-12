// SpotlightManager.swift
// QuietCoach
//
// Spotlight integration for discoverability.
// Users can find scenarios and past sessions from system search.

import CoreSpotlight
import UniformTypeIdentifiers
import UIKit
import OSLog
import SwiftUI

// MARK: - Spotlight Manager

@MainActor
final class SpotlightManager {

    // MARK: - Singleton

    static let shared = SpotlightManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Spotlight")
    private let domainIdentifier = "com.quietcoach.spotlight"

    // MARK: - Domain Identifiers

    private enum Domain {
        static let scenarios = "scenarios"
        static let sessions = "sessions"
        static let quickActions = "quickActions"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Index All Content

    /// Index all searchable content
    func indexAllContent() {
        Task {
            await indexScenarios()
            await indexQuickActions()
            logger.info("Spotlight indexing completed")
        }
    }

    // MARK: - Index Scenarios

    /// Index all available scenarios for Spotlight search
    func indexScenarios() async {
        let scenarios = Scenario.allScenarios
        var items: [CSSearchableItem] = []

        for scenario in scenarios {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.title = scenario.title
            attributeSet.contentDescription = scenario.subtitle
            attributeSet.keywords = buildKeywords(for: scenario)

            // Thumbnail generation for rich results
            attributeSet.thumbnailData = generateThumbnail(
                systemName: scenario.icon,
                categoryColor: scenario.category.color
            )

            // Activity type for Handoff
            attributeSet.relatedUniqueIdentifier = scenario.id
            attributeSet.domainIdentifier = Domain.scenarios

            let item = CSSearchableItem(
                uniqueIdentifier: "scenario-\(scenario.id)",
                domainIdentifier: "\(domainIdentifier).\(Domain.scenarios)",
                attributeSet: attributeSet
            )

            // Keep scenarios indexed indefinitely
            item.expirationDate = Date.distantFuture

            items.append(item)
        }

        do {
            try await CSSearchableIndex.default().indexSearchableItems(items)
            logger.info("Indexed \(items.count) scenarios")
        } catch {
            logger.error("Failed to index scenarios: \(error.localizedDescription)")
        }
    }

    /// Build search keywords for a scenario
    private func buildKeywords(for scenario: Scenario) -> [String] {
        var keywords = [
            scenario.title,
            scenario.subtitle,
            scenario.category.rawValue,
            "practice",
            "rehearsal",
            "conversation",
            "communication"
        ]

        // Add category-specific keywords
        switch scenario.category {
        case .boundaries:
            keywords += ["boundary", "say no", "assertive", "limits", "refuse"]
        case .career:
            keywords += ["work", "job", "professional", "boss", "negotiate", "salary", "promotion"]
        case .relationships:
            keywords += ["personal", "family", "friend", "partner", "emotion", "feelings"]
        case .difficult:
            keywords += ["hard", "challenging", "tough", "conflict", "confrontation"]
        }

        return keywords
    }

    // MARK: - Index Sessions

    /// Index a completed session for search
    func indexSession(_ session: RehearsalSession) async {
        guard let scenario = session.scenario else { return }

        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = "Practice: \(scenario.title)"

        // Build rich description
        var description = "Practiced on \(session.formattedDate)"
        if let scores = session.scores {
            description += " • Score: \(scores.overall)"
        }
        description += " • Duration: \(session.formattedDuration)"
        attributeSet.contentDescription = description

        // Keywords
        attributeSet.keywords = [
            scenario.title,
            "practice",
            "session",
            "recording",
            session.formattedDate
        ]

        // Metadata
        attributeSet.startDate = session.createdAt
        attributeSet.duration = NSNumber(value: session.duration)

        // Thumbnail
        attributeSet.thumbnailData = generateThumbnail(
            systemName: scenario.icon,
            categoryColor: scenario.category.color
        )

        attributeSet.domainIdentifier = Domain.sessions

        let item = CSSearchableItem(
            uniqueIdentifier: "session-\(session.id.uuidString)",
            domainIdentifier: "\(domainIdentifier).\(Domain.sessions)",
            attributeSet: attributeSet
        )

        // Sessions expire after 90 days to keep index fresh
        item.expirationDate = Date().addingTimeInterval(90 * 24 * 60 * 60)

        do {
            try await CSSearchableIndex.default().indexSearchableItems([item])
            logger.debug("Indexed session: \(session.id)")
        } catch {
            logger.error("Failed to index session: \(error.localizedDescription)")
        }
    }

    /// Remove a session from the index
    func removeSession(_ session: RehearsalSession) async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(
                withIdentifiers: ["session-\(session.id.uuidString)"]
            )
            logger.debug("Removed session from index: \(session.id)")
        } catch {
            logger.error("Failed to remove session: \(error.localizedDescription)")
        }
    }

    // MARK: - Quick Actions

    /// Index quick actions for common tasks
    func indexQuickActions() async {
        var items: [CSSearchableItem] = []

        // Start Practice action
        let startAttributes = CSSearchableItemAttributeSet(contentType: .content)
        startAttributes.title = "Start Practice"
        startAttributes.contentDescription = "Begin a new Quiet Coach practice session"
        startAttributes.keywords = ["start", "begin", "practice", "new", "record"]
        startAttributes.thumbnailData = generateThumbnail(systemName: "mic.fill", categoryColor: .qcAccent)
        startAttributes.domainIdentifier = Domain.quickActions

        let startItem = CSSearchableItem(
            uniqueIdentifier: "action-start-practice",
            domainIdentifier: "\(domainIdentifier).\(Domain.quickActions)",
            attributeSet: startAttributes
        )
        startItem.expirationDate = Date.distantFuture
        items.append(startItem)

        // View History action
        let historyAttributes = CSSearchableItemAttributeSet(contentType: .content)
        historyAttributes.title = "View Practice History"
        historyAttributes.contentDescription = "See all your past Quiet Coach sessions"
        historyAttributes.keywords = ["history", "past", "sessions", "progress", "review"]
        historyAttributes.thumbnailData = generateThumbnail(systemName: "clock.arrow.circlepath", categoryColor: .gray)
        historyAttributes.domainIdentifier = Domain.quickActions

        let historyItem = CSSearchableItem(
            uniqueIdentifier: "action-view-history",
            domainIdentifier: "\(domainIdentifier).\(Domain.quickActions)",
            attributeSet: historyAttributes
        )
        historyItem.expirationDate = Date.distantFuture
        items.append(historyItem)

        do {
            try await CSSearchableIndex.default().indexSearchableItems(items)
            logger.info("Indexed \(items.count) quick actions")
        } catch {
            logger.error("Failed to index quick actions: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Search Results

    /// Parse a Spotlight search result identifier
    func parseIdentifier(_ identifier: String) -> SpotlightResult? {
        if identifier.hasPrefix("scenario-") {
            let scenarioId = String(identifier.dropFirst("scenario-".count))
            return .scenario(id: scenarioId)
        } else if identifier.hasPrefix("session-") {
            let uuidString = String(identifier.dropFirst("session-".count))
            guard let uuid = UUID(uuidString: uuidString) else { return nil }
            return .session(id: uuid)
        } else if identifier.hasPrefix("action-") {
            let action = String(identifier.dropFirst("action-".count))
            return .quickAction(action: action)
        }
        return nil
    }

    // MARK: - Maintenance

    /// Remove all indexed content
    func removeAllContent() async {
        do {
            try await CSSearchableIndex.default().deleteAllSearchableItems()
            logger.info("Removed all Spotlight content")
        } catch {
            logger.error("Failed to remove content: \(error.localizedDescription)")
        }
    }

    /// Remove expired sessions
    func cleanupExpiredSessions() async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: ["\(domainIdentifier).\(Domain.sessions)"]
            )
            logger.info("Cleaned up session index")
        } catch {
            logger.error("Failed to cleanup sessions: \(error.localizedDescription)")
        }
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(systemName: String, categoryColor: Color) -> Data? {
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        guard let image = UIImage(systemName: systemName, withConfiguration: config) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 60))
        let thumbnail = renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 60, height: 60)))

            // Icon (centered)
            let iconSize = image.size
            let origin = CGPoint(
                x: (60 - iconSize.width) / 2,
                y: (60 - iconSize.height) / 2
            )
            image.withTintColor(UIColor(categoryColor)).draw(at: origin)
        }

        return thumbnail.pngData()
    }
}

// MARK: - Spotlight Result

enum SpotlightResult {
    case scenario(id: String)
    case session(id: UUID)
    case quickAction(action: String)
}

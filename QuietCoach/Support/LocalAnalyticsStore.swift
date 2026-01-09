// LocalAnalyticsStore.swift
// QuietCoach
//
// Persistent local storage for analytics events.
// Stores events offline and syncs when possible.

import Foundation
import OSLog

// MARK: - Stored Event

struct StoredAnalyticsEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let parameters: [String: String]
    let timestamp: Date
    var synced: Bool

    init(event: AnalyticsEvent) {
        self.id = UUID()
        self.name = event.name
        self.parameters = event.parameters
        self.timestamp = Date()
        self.synced = false
    }
}

// MARK: - Local Analytics Store

actor LocalAnalyticsStore {
    static let shared = LocalAnalyticsStore()

    private let logger = Logger(subsystem: "com.quietcoach", category: "LocalAnalytics")
    private let fileManager = FileManager.default
    private let maxStoredEvents = 1000
    private let maxEventAge: TimeInterval = 30 * 24 * 60 * 60 // 30 days

    private var events: [StoredAnalyticsEvent] = []
    private var isLoaded = false

    private init() {}

    // MARK: - Storage Path

    private var storageURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("analytics_events.json")
    }

    // MARK: - Event Recording

    /// Record an event locally
    func record(_ event: AnalyticsEvent) async {
        await loadIfNeeded()

        let storedEvent = StoredAnalyticsEvent(event: event)
        events.append(storedEvent)

        // Trim old events if needed
        await trimEventsIfNeeded()

        // Save to disk
        await save()

        logger.debug("Recorded event: \(event.name)")
    }

    /// Mark events as synced
    func markSynced(_ eventIds: [UUID]) async {
        await loadIfNeeded()

        for i in events.indices {
            if eventIds.contains(events[i].id) {
                events[i].synced = true
            }
        }

        // Remove old synced events
        events.removeAll { $0.synced && Date().timeIntervalSince($0.timestamp) > 24 * 60 * 60 }

        await save()
    }

    /// Get unsynced events for upload
    func getUnsyncedEvents() async -> [StoredAnalyticsEvent] {
        await loadIfNeeded()
        return events.filter { !$0.synced }
    }

    /// Get all events (for debugging)
    func getAllEvents() async -> [StoredAnalyticsEvent] {
        await loadIfNeeded()
        return events
    }

    /// Get event count
    func eventCount() async -> Int {
        await loadIfNeeded()
        return events.count
    }

    /// Clear all events
    func clearAll() async {
        events = []
        await save()
        logger.info("Cleared all analytics events")
    }

    // MARK: - Persistence

    private func loadIfNeeded() async {
        guard !isLoaded else { return }

        do {
            if fileManager.fileExists(atPath: storageURL.path) {
                let data = try Data(contentsOf: storageURL)
                events = try JSONDecoder().decode([StoredAnalyticsEvent].self, from: data)
                logger.debug("Loaded \(self.events.count) events from disk")
            }
        } catch {
            logger.error("Failed to load events: \(error.localizedDescription)")
            events = []
        }

        isLoaded = true
    }

    private func save() async {
        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            logger.error("Failed to save events: \(error.localizedDescription)")
        }
    }

    private func trimEventsIfNeeded() async {
        let now = Date()

        // Remove events older than maxEventAge
        events.removeAll { now.timeIntervalSince($0.timestamp) > maxEventAge }

        // Keep only maxStoredEvents
        if events.count > maxStoredEvents {
            // Keep newest events
            events = Array(events.suffix(maxStoredEvents))
        }
    }

    // MARK: - Aggregated Stats

    /// Get event counts by name for the last N days
    func getEventCounts(days: Int = 7) async -> [String: Int] {
        await loadIfNeeded()

        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        let recentEvents = events.filter { $0.timestamp > cutoff }

        var counts: [String: Int] = [:]
        for event in recentEvents {
            counts[event.name, default: 0] += 1
        }

        return counts
    }

    /// Get daily active usage for the last N days
    func getDailyActivity(days: Int = 7) async -> [Date: Int] {
        await loadIfNeeded()

        let calendar = Calendar.current
        var dailyCounts: [Date: Int] = [:]

        for event in events {
            let day = calendar.startOfDay(for: event.timestamp)
            dailyCounts[day, default: 0] += 1
        }

        return dailyCounts
    }
}

// MARK: - Analytics Extension for Local Storage

extension Analytics {
    /// Record event to local storage
    func recordLocally(_ event: AnalyticsEvent) {
        Task {
            await LocalAnalyticsStore.shared.record(event)
        }
    }
}

// MARK: - Debug View

#if DEBUG
import SwiftUI

struct LocalAnalyticsDebugView: View {
    @State private var events: [StoredAnalyticsEvent] = []
    @State private var eventCounts: [String: Int] = [:]

    var body: some View {
        List {
            Section("Summary") {
                Text("Total Events: \(events.count)")
                Text("Unsynced: \(events.filter { !$0.synced }.count)")
            }

            Section("Event Counts (7 days)") {
                ForEach(eventCounts.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                        Spacer()
                        Text("\(value)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Recent Events") {
                ForEach(events.suffix(20).reversed()) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(event.name)
                                .font(.headline)
                            Spacer()
                            if event.synced {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        Text(event.timestamp.formatted())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !event.parameters.isEmpty {
                            Text(event.parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Local Analytics")
        .task {
            events = await LocalAnalyticsStore.shared.getAllEvents()
            eventCounts = await LocalAnalyticsStore.shared.getEventCounts()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") {
                    Task {
                        await LocalAnalyticsStore.shared.clearAll()
                        events = []
                        eventCounts = [:]
                    }
                }
            }
        }
    }
}
#endif

// CloudSyncManager.swift
// QuietCoach
//
// Cross-device continuity via CloudKit.
// Seamless sync across iPhone, iPad, and Mac.

import Foundation
import CloudKit
import SwiftData
import OSLog
import Combine

// MARK: - Sync Status

enum CloudSyncStatus: Equatable {
    case idle
    case syncing
    case synced(Date)
    case error(String)
    case disabled

    var displayText: String {
        switch self {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .synced(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .error(let message):
            return message
        case .disabled:
            return "iCloud sync disabled"
        }
    }

    var icon: String {
        switch self {
        case .idle:
            return "icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .synced:
            return "checkmark.icloud"
        case .error:
            return "exclamationmark.icloud"
        case .disabled:
            return "icloud.slash"
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

// MARK: - Cloud Sync Manager

@Observable
@MainActor
final class CloudSyncManager {

    // MARK: - Singleton

    static let shared = CloudSyncManager()

    // MARK: - Properties

    private(set) var syncStatus: CloudSyncStatus = .idle
    private(set) var iCloudAvailable: Bool = false
    private(set) var lastSyncDate: Date?

    private let container = CKContainer(identifier: Constants.App.cloudKitContainerID)
    private let logger = Logger(subsystem: "com.quietcoach", category: "CloudSync")
    private var isSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: Constants.SettingsKeys.iCloudSyncEnabled)
    }

    // MARK: - Initialization

    private init() {
        checkiCloudStatus()
        setupNotifications()
    }

    // MARK: - iCloud Status

    func checkiCloudStatus() {
        guard isSyncEnabled else {
            syncStatus = .disabled
            iCloudAvailable = false
            return
        }

        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error {
                    self.logger.error("iCloud status check failed: \(error.localizedDescription)")
                    self.syncStatus = .error("iCloud unavailable")
                    self.iCloudAvailable = false
                    return
                }

                switch status {
                case .available:
                    self.iCloudAvailable = true
                    self.syncStatus = .idle
                    self.logger.info("iCloud available")

                case .noAccount:
                    self.iCloudAvailable = false
                    self.syncStatus = .disabled
                    self.logger.info("No iCloud account")

                case .restricted, .couldNotDetermine:
                    self.iCloudAvailable = false
                    self.syncStatus = .disabled
                    self.logger.info("iCloud restricted or unknown")

                case .temporarilyUnavailable:
                    self.iCloudAvailable = false
                    self.syncStatus = .error("iCloud temporarily unavailable")
                    self.logger.warning("iCloud temporarily unavailable")

                @unknown default:
                    self.iCloudAvailable = false
                    self.syncStatus = .disabled
                }
            }
        }
    }

    // MARK: - Sync Operations

    func triggerSync() {
        guard isSyncEnabled else {
            syncStatus = .disabled
            return
        }

        guard iCloudAvailable else {
            syncStatus = .disabled
            return
        }

        syncStatus = .syncing
        logger.info("Manual sync triggered")

        // SwiftData with CloudKit handles sync automatically
        // This is for manual refresh/status update
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                self.lastSyncDate = Date()
                self.syncStatus = .synced(Date())
                self.logger.info("Sync completed")
            }
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        // Listen for iCloud account changes
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            guard self.isSyncEnabled else {
                self.syncStatus = .disabled
                self.iCloudAvailable = false
                return
            }
            self.checkiCloudStatus()
        }
    }

    // MARK: - Conflict Resolution

    /// Handle sync conflicts by preferring the most recent change
    func resolveConflict<T: Identifiable>(
        local: T,
        remote: T,
        localDate: Date,
        remoteDate: Date
    ) -> T {
        // Last-write-wins strategy
        if remoteDate > localDate {
            logger.info("Conflict resolved: using remote version")
            return remote
        } else {
            logger.info("Conflict resolved: using local version")
            return local
        }
    }
}

// MARK: - SwiftData CloudKit Configuration

extension ModelConfiguration {
    /// Creates a CloudKit-enabled configuration for SwiftData
    static func cloudKitConfiguration(schema: Schema) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(Constants.App.cloudKitContainerID)
        )
    }
}

// MARK: - Sync Status View

import SwiftUI

struct SyncStatusIndicator: View {
    @State private var syncManager = CloudSyncManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: syncManager.syncStatus.icon)
                .font(.system(size: 12))
                .foregroundColor(iconColor)
                .symbolEffect(.pulse, isActive: syncManager.syncStatus == .syncing)

            if showText {
                Text(syncManager.syncStatus.displayText)
                    .font(.caption)
                    .foregroundColor(.qcTextSecondary)
            }
        }
        .onTapGesture {
            if syncManager.iCloudAvailable {
                syncManager.triggerSync()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sync status: \(syncManager.syncStatus.displayText)")
        .accessibilityHint(syncManager.iCloudAvailable ? "Double tap to sync now" : "")
    }

    private var showText: Bool {
        switch syncManager.syncStatus {
        case .syncing, .error:
            return true
        default:
            return false
        }
    }

    private var iconColor: Color {
        switch syncManager.syncStatus {
        case .synced:
            return .qcSuccess
        case .error:
            return .qcWarning
        case .disabled:
            return .qcTextTertiary
        default:
            return .qcTextSecondary
        }
    }
}

// MARK: - Sync Settings Row

struct SyncSettingsRow: View {
    @State private var syncManager = CloudSyncManager.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("iCloud Sync")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                Text(syncManager.syncStatus.displayText)
                    .font(.qcFootnote)
                    .foregroundColor(.qcTextSecondary)
            }

            Spacer()

            Image(systemName: syncManager.syncStatus.icon)
                .font(.system(size: 20))
                .foregroundColor(syncManager.iCloudAvailable ? .qcAccent : .qcTextTertiary)
                .symbolEffect(.pulse, isActive: syncManager.syncStatus == .syncing)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if syncManager.iCloudAvailable {
                Haptics.buttonPress()
                syncManager.triggerSync()
            }
        }
    }
}

// MARK: - Preview

#Preview("Sync Indicator") {
    VStack(spacing: 20) {
        SyncStatusIndicator()
        SyncSettingsRow()
    }
    .padding()
    .background(Color.qcBackground)
}

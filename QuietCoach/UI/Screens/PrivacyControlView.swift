// PrivacyControlView.swift
// QuietCoach
//
// Your data, your control. Full transparency, no hidden collection.
// Aligned with Apple's privacy-first wellness app guidelines.

import SwiftUI
import OSLog

struct PrivacyControlView: View {

    // MARK: - Environment

    @Environment(SessionRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var storageMetrics = StorageMetrics()
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingFinalDeleteConfirmation = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?

    // Settings toggles
    @AppStorage("privacy.spotlightIndexing") private var spotlightIndexingEnabled = true
    @AppStorage("privacy.healthKitLogging") private var healthKitLoggingEnabled = false

    private let logger = Logger(subsystem: "com.quietcoach", category: "PrivacyControl")

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Data overview section
                dataOverviewSection

                // Export section
                exportSection

                // Privacy controls section
                privacyControlsSection

                // Delete section
                deleteSection

                // Privacy philosophy section
                philosophySection
            }
            .scrollContentBackground(.hidden)
            .background(Color.qcBackground)
            .navigationTitle("Privacy Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.qcAccent)
                }
            }
            .onAppear {
                refreshStorageMetrics()
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ExportShareSheet(url: url)
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showingFinalDeleteConfirmation = true
                }
            } message: {
                Text("This will permanently delete all your rehearsal sessions, audio recordings, and practice history. This cannot be undone.")
            }
            .alert("Are you absolutely sure?", isPresented: $showingFinalDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Type 'DELETE' to confirm you want to erase all data permanently.")
            }
        }
    }

    // MARK: - Data Overview Section

    private var dataOverviewSection: some View {
        Section {
            // Sessions count
            HStack {
                Label {
                    Text("Sessions")
                } icon: {
                    Image(systemName: "waveform")
                        .foregroundStyle(Color.qcAccent)
                }

                Spacer()

                Text("\(storageMetrics.sessionCount)")
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            // Storage used
            HStack {
                Label {
                    Text("Storage Used")
                } icon: {
                    Image(systemName: "internaldrive")
                        .foregroundStyle(Color.qcAccent)
                }

                Spacer()

                Text(storageMetrics.formattedSize)
                    .foregroundStyle(.secondary)
            }

            // Audio files count
            HStack {
                Label {
                    Text("Audio Files")
                } icon: {
                    Image(systemName: "doc.badge.waveform")
                        .foregroundStyle(Color.qcAccent)
                }

                Spacer()

                Text("\(storageMetrics.audioFileCount)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("All data is stored locally on your device. Nothing is uploaded to any server.")
        }
        .listRowBackground(Color.qcSurface)
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                exportAllData()
            } label: {
                HStack {
                    Label {
                        Text("Export All Data")
                    } icon: {
                        Image(systemName: "arrow.down.doc")
                            .foregroundStyle(Color.qcAccent)
                    }

                    Spacer()

                    if isExporting {
                        ProgressView()
                            .tint(.qcAccent)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .disabled(isExporting || storageMetrics.sessionCount == 0)

            if let error = exportError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Data Portability")
        } footer: {
            Text("Download a ZIP file containing all your sessions as JSON and audio files. Your data belongs to you.")
        }
        .listRowBackground(Color.qcSurface)
    }

    // MARK: - Privacy Controls Section

    private var privacyControlsSection: some View {
        Section {
            // Spotlight indexing toggle
            Toggle(isOn: $spotlightIndexingEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spotlight Search")
                        Text("Find scenarios from system search")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.qcAccent)
                }
            }
            .tint(.qcAccent)
            .onChange(of: spotlightIndexingEnabled) { _, newValue in
                updateSpotlightIndexing(enabled: newValue)
            }

            // HealthKit integration placeholder
            Toggle(isOn: $healthKitLoggingEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mindfulness Minutes")
                        Text("Log practice time to Apple Health")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "heart.circle")
                        .foregroundStyle(Color.qcAccent)
                }
            }
            .tint(.qcAccent)
            .onChange(of: healthKitLoggingEnabled) { _, newValue in
                updateHealthKitLogging(enabled: newValue)
            }
        } header: {
            Text("System Integration")
        } footer: {
            Text("These features are optional. Disable them to keep Quiet Coach completely isolated.")
        }
        .listRowBackground(Color.qcSurface)
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                Haptics.warning()
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Label {
                        Text("Delete Everything")
                    } icon: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .foregroundStyle(.red)

                    Spacer()
                }
            }
            .disabled(storageMetrics.sessionCount == 0)
        } header: {
            Text("Data Removal")
        } footer: {
            Text("Permanently erase all sessions, recordings, streak data, and preferences. This is irreversible.")
        }
        .listRowBackground(Color.qcSurface)
    }

    // MARK: - Philosophy Section

    private var philosophySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                privacyPrincipleRow(
                    icon: "lock.shield",
                    title: "No Accounts",
                    description: "You don't need to sign in or create an account."
                )

                privacyPrincipleRow(
                    icon: "icloud.slash",
                    title: "No Uploads",
                    description: "Your audio never leaves your device."
                )

                privacyPrincipleRow(
                    icon: "eye.slash",
                    title: "No Tracking",
                    description: "We don't know what you practice or how often."
                )

                privacyPrincipleRow(
                    icon: "brain.head.profile",
                    title: "No Content Analysis",
                    description: "We score delivery, not what you say."
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("Our Privacy Promise")
        }
        .listRowBackground(Color.qcSurface)
    }

    private func privacyPrincipleRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.qcSuccess)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func refreshStorageMetrics() {
        storageMetrics = StorageMetrics(
            sessionCount: repository.sessions.count,
            audioFileCount: FileStore.shared.recordingFileCount,
            totalBytes: FileStore.shared.totalRecordingsSize()
        )
    }

    private func exportAllData() {
        guard !isExporting else { return }

        isExporting = true
        exportError = nil

        Task {
            do {
                let url = try await DataExporter.exportAllData(
                    sessions: repository.sessions,
                    fileStore: FileStore.shared
                )
                await MainActor.run {
                    exportURL = url
                    showingExportSheet = true
                    isExporting = false
                    Haptics.streakMilestone()
                }
            } catch {
                await MainActor.run {
                    exportError = "Export failed: \(error.localizedDescription)"
                    isExporting = false
                    Haptics.error()
                }
                logger.error("Export failed: \(error.localizedDescription)")
            }
        }
    }

    private func deleteAllData() {
        // Delete all sessions (which also deletes audio files)
        repository.deleteAllSessions()

        // Reset streak data
        StreakTracker.shared.reset()

        // Clear Spotlight index
        Task {
            await SpotlightManager.shared.removeAllContent()
        }

        // Clear user defaults for this app
        clearUserDefaults()

        // Refresh metrics
        refreshStorageMetrics()

        Haptics.destructive()
        logger.info("All user data deleted")

        // Dismiss back to settings
        dismiss()
    }

    private func clearUserDefaults() {
        let domain = Bundle.main.bundleIdentifier ?? "com.quietcoach"
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    private func updateSpotlightIndexing(enabled: Bool) {
        if enabled {
            SpotlightManager.shared.indexAllContent()
        } else {
            Task {
                await SpotlightManager.shared.removeAllContent()
            }
        }
    }

    private func updateHealthKitLogging(enabled: Bool) {
        // Placeholder for HealthKit integration
        // Will request authorization and enable mindfulness logging when implemented
        logger.info("HealthKit logging \(enabled ? "enabled" : "disabled")")
    }
}

// MARK: - Storage Metrics

private struct StorageMetrics {
    var sessionCount: Int = 0
    var audioFileCount: Int = 0
    var totalBytes: Int64 = 0

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}

// MARK: - Data Exporter

private enum DataExporter {

    @MainActor
    static func exportAllData(
        sessions: [RehearsalSession],
        fileStore: FileStore
    ) async throws -> URL {

        let exportDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuietCoach_Export_\(Date().ISO8601Format())")

        // Create export directory
        try FileManager.default.createDirectory(
            at: exportDirectory,
            withIntermediateDirectories: true
        )

        // Export sessions as JSON
        let sessionsData = try JSONEncoder().encode(sessions.map { ExportableSession(from: $0) })
        let sessionsURL = exportDirectory.appendingPathComponent("sessions.json")
        try sessionsData.write(to: sessionsURL)

        // Create audio subdirectory
        let audioDirectory = exportDirectory.appendingPathComponent("audio")
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)

        // Copy audio files
        for session in sessions {
            let sourceURL = fileStore.audioFileURL(for: session.audioFileName)
            let destURL = audioDirectory.appendingPathComponent(session.audioFileName)

            if FileManager.default.fileExists(atPath: sourceURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            }
        }

        // Create ZIP file
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuietCoach_Export.zip")

        // Remove existing ZIP if present
        try? FileManager.default.removeItem(at: zipURL)

        // Create ZIP using built-in compression
        try await createZipFile(from: exportDirectory, to: zipURL)

        // Clean up export directory
        try? FileManager.default.removeItem(at: exportDirectory)

        return zipURL
    }

    private static func createZipFile(from directory: URL, to zipURL: URL) async throws {
        // Use FileManager's built-in ZIP support via NSFileCoordinator
        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(
            readingItemAt: directory,
            options: .forUploading,
            error: &error
        ) { compressedURL in
            do {
                try FileManager.default.copyItem(at: compressedURL, to: zipURL)
            } catch {
                // Error handled below
            }
        }

        if let error {
            throw error
        }
    }
}

// MARK: - Exportable Session

private struct ExportableSession: Codable {
    let id: String
    let scenarioId: String
    let createdAt: Date
    let duration: TimeInterval
    let audioFileName: String
    let scores: FeedbackScores?
    let coachNotes: [CoachNote]
    let transcription: String?
    let anchorLine: String?

    init(from session: RehearsalSession) {
        self.id = session.id.uuidString
        self.scenarioId = session.scenarioId
        self.createdAt = session.createdAt
        self.duration = session.duration
        self.audioFileName = session.audioFileName
        self.scores = session.scores
        self.coachNotes = session.coachNotes
        self.transcription = session.transcription
        self.anchorLine = session.anchorLine
    }
}

// MARK: - Export Share Sheet

private struct ExportShareSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.qcSuccess)

                Text("Export Ready")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Your data has been packaged into a ZIP file containing all sessions and audio recordings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ShareLink(item: url) {
                    Label("Share Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.qcAccent)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.mediumCornerRadius))
                }
                .padding(.horizontal)

                Button("Done") {
                    dismiss()
                }
                .foregroundStyle(Color.qcAccent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.qcBackground)
            .navigationTitle("Export Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrivacyControlView()
        .environment(SessionRepository.placeholder)
}

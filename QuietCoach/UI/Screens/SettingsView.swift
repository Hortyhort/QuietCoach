// SettingsView.swift
// QuietCoach
//
// Your data, your rules. Clean, respectful settings.

import SwiftUI

struct SettingsView: View {

    // MARK: - Environment

    @Environment(SessionRepository.self) private var repository
    @Environment(FeatureGates.self) private var featureGates
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @AppStorage("shareCard.showWatermark") private var showWatermark = true
    @State private var showingDeleteAllConfirm = false
    @State private var showingProUpgrade = false
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var notificationManager = NotificationManager.shared
    @State private var showingAchievements = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Pro section
                proSection

                // Reminders section
                remindersSection

                // Sharing section
                sharingSection

                // Data section
                dataSection

                // Sync section
                syncSection

                // Achievements section
                achievementsSection

                // Keyboard shortcuts (iPad/Mac only)
                #if !os(watchOS)
                if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
                    keyboardShortcutsSection
                }
                #endif

                // About section
                aboutSection

                // Privacy note
                privacySection
            }
            .scrollContentBackground(.hidden)
            .background(Color.qcBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.qcAccent)
                }
            }
            .alert("Delete all data?", isPresented: $showingDeleteAllConfirm) {
                Button("Delete All", role: .destructive) {
                    repository.deleteAllSessions()
                    StreakTracker.shared.reset()
                    Haptics.destructive()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your rehearsal sessions, audio files, and streak data. This cannot be undone.")
            }
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeView()
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ExportDataSheet(data: data)
                }
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementGalleryView()
            }
        }
    }
}

// MARK: - Export Data Sheet

struct ExportDataSheet: View {
    let data: Data
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(.qcAccent)

                Text("Export Ready")
                    .font(.qcTitle2)
                    .foregroundColor(.qcTextPrimary)

                Text("\(formattedSize) of session data")
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)

                Spacer()

                ShareLink(
                    item: exportFile,
                    preview: SharePreview("QuietCoach Sessions", image: Image(systemName: "waveform"))
                ) {
                    Text("Share Export")
                        .font(.qcButton)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.qcAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.qcBackground)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.qcAccent)
                }
            }
        }
    }

    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(data.count))
    }

    private var exportFile: URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("quietcoach-sessions-\(Date().timeIntervalSince1970).json")
        try? data.write(to: tempURL)
        return tempURL
    }
}

// MARK: - SettingsView Sections

private extension SettingsView {

    // MARK: - Pro Section

    var proSection: some View {
        Section {
            if featureGates.isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .accessibilityHidden(true)

                    Text("Quiet Coach Pro")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)

                    Spacer()

                    Text("Active")
                        .font(.qcSubheadline)
                        .foregroundColor(.qcTextSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Quiet Coach Pro subscription is active")
            } else {
                Button {
                    showingProUpgrade = true
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)

                        Text("Upgrade to Pro")
                            .font(.qcBody)
                            .foregroundColor(.qcTextPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.qcTextTertiary)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Upgrade to Pro")
                .accessibilityHint("Double tap to view Pro subscription options")
            }
        }
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { notificationManager.remindersEnabled },
                set: { newValue in
                    if newValue && !notificationManager.canScheduleNotifications {
                        Task {
                            let granted = await notificationManager.requestAuthorization()
                            if granted {
                                notificationManager.remindersEnabled = true
                            }
                        }
                    } else {
                        notificationManager.remindersEnabled = newValue
                    }
                }
            )) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.qcAccent)
                        .accessibilityHidden(true)

                    Text("Daily reminder")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)
                }
            }
            .tint(.qcAccent)

            if notificationManager.remindersEnabled {
                DatePicker(
                    "Reminder time",
                    selection: Binding(
                        get: { notificationManager.reminderTime },
                        set: { notificationManager.reminderTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .font(.qcBody)
                .foregroundColor(.qcTextPrimary)
                .tint(.qcAccent)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Get a gentle reminder to practice and protect your streak.")
        }
    }

    // MARK: - Sharing Section

    private var sharingSection: some View {
        Section("Sharing") {
            Toggle(isOn: $showWatermark) {
                Text("Show watermark on share cards")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)
            }
            .tint(.qcAccent)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section("Data") {
            HStack {
                Text("Sessions")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                Text("\(repository.sessionCount)")
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
            }

            HStack {
                Text("Current streak")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(StreakTracker.shared.currentStreak) days")
                        .font(.qcBody)
                        .foregroundColor(.qcTextSecondary)
                }
            }

            HStack {
                Text("Longest streak")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                Text("\(StreakTracker.shared.longestStreak) days")
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
            }

            HStack {
                Text("Storage used")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                Text(FileStore.shared.formattedRecordingsSize)
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
            }

            Button {
                exportData = repository.exportAllData()
                showingExportSheet = exportData != nil
            } label: {
                HStack {
                    Text("Export Data")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.qcAccent)
                }
            }
            .accessibilityLabel("Export session data")
            .accessibilityHint("Double tap to export all sessions as JSON")

            Button(role: .destructive) {
                showingDeleteAllConfirm = true
            } label: {
                Text("Delete All Data")
                    .font(.qcBody)
            }
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        Section("Sync") {
            SyncSettingsRow()
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        Section("Progress") {
            Button {
                showingAchievements = true
            } label: {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.qcMoodCelebration)
                        .accessibilityHidden(true)

                    Text("Achievements")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)

                    Spacer()

                    Text("\(AchievementManager.shared.unlockedAchievements.count)/\(Achievement.allAchievements.count)")
                        .font(.qcSubheadline)
                        .foregroundColor(.qcTextSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.qcTextTertiary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Achievements")
            .accessibilityHint("Double tap to view your achievement badges")
        }
    }

    // MARK: - Keyboard Shortcuts Section

    private var keyboardShortcutsSection: some View {
        Section("Keyboard Shortcuts") {
            VStack(alignment: .leading, spacing: 12) {
                KeyboardShortcutRow(shortcut: "N", description: "New practice session")
                KeyboardShortcutRow(shortcut: "1-4", description: "Quick scenario access")
                KeyboardShortcutRow(shortcut: ",", description: "Open settings")
                KeyboardShortcutRow(shortcut: "H", description: "View history")
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                Text(Constants.App.version)
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
            }

            if let privacyURL = URL(string: "https://quietcoach.app/privacy") {
                Link(destination: privacyURL) {
                    HStack {
                        Text("Privacy Policy")
                            .font(.qcBody)
                            .foregroundColor(.qcTextPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.qcTextTertiary)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Privacy Policy")
                .accessibilityHint("Opens in Safari")
            }

            if let supportURL = URL(string: "https://quietcoach.app/support") {
                Link(destination: supportURL) {
                    HStack {
                        Text("Support")
                            .font(.qcBody)
                            .foregroundColor(.qcTextPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.qcTextTertiary)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Support")
                .accessibilityHint("Opens in Safari")
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Text("All audio is processed on your device. Nothing is uploaded. Your rehearsals are private.")
                .font(.qcFootnote)
                .foregroundColor(.qcTextTertiary)
        }
    }
}

// MARK: - Keyboard Shortcut Row

struct KeyboardShortcutRow: View {
    let shortcut: String
    let description: String

    var body: some View {
        HStack {
            // Command key badge
            HStack(spacing: 2) {
                Image(systemName: "command")
                    .font(.system(size: 11, weight: .medium))
                Text(shortcut)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.qcTextPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.qcSurface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(description)
                .font(.qcBody)
                .foregroundColor(.qcTextSecondary)
                .padding(.leading, 8)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(SessionRepository.placeholder)
        .environment(FeatureGates.shared)
}

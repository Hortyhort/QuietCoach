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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Pro section
                proSection

                // Sharing section
                sharingSection

                // Data section
                dataSection

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

            Link(destination: URL(string: "https://quietcoach.app/privacy")!) {
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

            Link(destination: URL(string: "https://quietcoach.app/support")!) {
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

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Text("All audio is processed on your device. Nothing is uploaded. Your rehearsals are private.")
                .font(.qcFootnote)
                .foregroundColor(.qcTextTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(SessionRepository.placeholder)
        .environment(FeatureGates.shared)
}

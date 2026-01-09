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
                    Haptics.destructive()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your rehearsal sessions and audio files. This cannot be undone.")
            }
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeView()
            }
        }
    }

    // MARK: - Pro Section

    private var proSection: some View {
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
                Text("Storage used")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                Text(FileStore.shared.formattedRecordingsSize)
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
            }

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

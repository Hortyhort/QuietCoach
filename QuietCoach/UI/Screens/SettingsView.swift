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
    @AppStorage(Constants.SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(Constants.SettingsKeys.soundsEnabled) private var soundsEnabled = true
    @AppStorage(Constants.SettingsKeys.focusSoundsEnabled) private var focusSoundsEnabled = false
    @AppStorage(Constants.SettingsKeys.voiceIsolationEnabled) private var voiceIsolationEnabled = false
    @AppStorage(Constants.SettingsKeys.breathingRitualEnabled) private var breathingRitualEnabled = true
    @AppStorage(Constants.SettingsKeys.coachTone) private var coachToneRaw = CoachTone.default.rawValue
    @State private var showingDeleteAllConfirm = false
    @State private var showingProUpgrade = false
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var notificationManager = NotificationManager.shared
    @State private var showingPrivacyControl = false
    @Bindable private var privacySettings = PrivacySettings.shared

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Pro section
                proSection

                // Reminders section
                remindersSection

                // Sound & Haptics section
                soundHapticsSection

                // Recording section
                recordingSection

                // Coaching section
                coachingSection

                // Sharing section
                sharingSection

                // Data section
                dataSection

                // Sync section
                syncSection

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
                    Haptics.destructive()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your rehearsal sessions and audio files. This cannot be undone.")
            }
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeView()
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ExportDataSheet(data: data)
                }
            }
            .sheet(isPresented: $showingPrivacyControl) {
                PrivacyControlView()
                    .environment(repository)
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
            Text("Get a gentle reminder to rehearse something important.")
        }
    }

    // MARK: - Sound & Haptics Section

    private var soundHapticsSection: some View {
        Section {
            Toggle(isOn: $soundsEnabled) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.qcAccent)
                        .accessibilityHidden(true)

                    Text("Interface sounds")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)
                }
            }
            .tint(.qcAccent)
            .onChange(of: soundsEnabled) { _, newValue in
                if newValue {
                    // Play a preview sound when enabled
                    SoundManager.shared.play(.ready)
                }
            }

            Toggle(isOn: $hapticsEnabled) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.qcAccent)
                        .accessibilityHidden(true)

                    Text("Haptic feedback")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)
                }
            }
            .tint(.qcAccent)
            .onChange(of: hapticsEnabled) { _, newValue in
                if newValue {
                    Haptics.buttonPress()
                }
            }

            Toggle(isOn: $focusSoundsEnabled) {
                HStack {
                    Image(systemName: "waveform.path")
                        .foregroundColor(.qcAccent)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus sounds")
                            .font(.qcBody)
                            .foregroundColor(.qcTextPrimary)

                        Text("Subtle ambient tones during recording")
                            .font(.qcCaption)
                            .foregroundColor(.qcTextTertiary)
                    }
                }
            }
            .tint(.qcAccent)
        } header: {
            Text("Sound & Haptics")
        } footer: {
            Text("Sounds help you stay present. Haptics provide confirmation.")
        }
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        Section {
            // Breathing ritual toggle
            Toggle(isOn: $breathingRitualEnabled) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.qcAccent)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calm Start")
                            .font(.qcBody)
                            .foregroundColor(.qcTextPrimary)

                        Text("Brief breathing exercise before recording")
                            .font(.qcCaption)
                            .foregroundColor(.qcTextTertiary)
                    }
                }
            }
            .tint(.qcAccent)

            // Voice isolation toggle (iOS 17+)
            if Constants.VoiceIsolation.isAvailable {
                Toggle(isOn: $voiceIsolationEnabled) {
                    HStack {
                        Image(systemName: "person.wave.2.fill")
                            .foregroundColor(.qcAccent)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Voice Isolation")
                                .font(.qcBody)
                                .foregroundColor(.qcTextPrimary)

                            Text("Reduces background noise during recording")
                                .font(.qcCaption)
                                .foregroundColor(.qcTextTertiary)
                        }
                    }
                }
                .tint(.qcAccent)
            }

            Toggle(isOn: $privacySettings.transcriptionEnabled) {
                HStack {
                    Image(systemName: "text.quote")
                        .foregroundColor(.qcAccent)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("On-Device Transcription")
                            .font(.qcBody)
                            .foregroundColor(.qcTextPrimary)

                        Text("Optional speech-to-text for richer coaching")
                            .font(.qcCaption)
                            .foregroundColor(.qcTextTertiary)
                    }
                }
            }
            .tint(.qcAccent)
        } header: {
            Text("Recording")
        } footer: {
            if Constants.VoiceIsolation.isAvailable {
                Text("Calm Start helps you center before rehearsing. Voice Isolation works best with AirPods. Transcription is optional and stays on this device.")
            } else {
                Text("Calm Start helps you center before rehearsing. Transcription is optional and stays on this device.")
            }
        }
    }

    // MARK: - Coaching Section

    private var coachToneSelection: Binding<CoachTone> {
        Binding(
            get: { CoachTone(rawValue: coachToneRaw) ?? .default },
            set: { coachToneRaw = $0.rawValue }
        )
    }

    private var coachingSection: some View {
        let currentTone = CoachTone(rawValue: coachToneRaw) ?? .default

        return Section {
            Picker("Coach Tone", selection: coachToneSelection) {
                ForEach(CoachTone.allCases) { tone in
                    Text(tone.title)
                        .tag(tone)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!featureGates.isPro)
            .opacity(featureGates.isPro ? 1.0 : 0.6)
        } header: {
            Text("Coaching")
        } footer: {
            if featureGates.isPro {
                Text(currentTone.description)
            } else {
                Text("Upgrade to Pro to customize your coach tone.")
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

            // Privacy Control Center - comprehensive data management
            Button {
                showingPrivacyControl = true
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.qcAccent)
                        .accessibilityHidden(true)

                    Text("Privacy Control")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.qcTextTertiary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Privacy Control")
            .accessibilityHint("Double tap to manage your data, export, or delete everything")
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        Section("Sync") {
            SyncSettingsRow()
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

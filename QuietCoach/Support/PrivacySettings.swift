// PrivacySettings.swift
// QuietCoach
//
// User privacy preferences for analytics and crash reporting.
// Respects user choice while maintaining app functionality.

import Foundation
import SwiftUI
import OSLog

// MARK: - Privacy Settings

@Observable
@MainActor
final class PrivacySettings {
    static let shared = PrivacySettings()

    private let logger = Logger(subsystem: "com.quietcoach", category: "Privacy")

    // MARK: - User Preferences

    /// Whether analytics collection is enabled
    var analyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: Keys.analyticsEnabled)
            updateAnalyticsState()
            logger.info("Analytics \(self.analyticsEnabled ? "enabled" : "disabled")")
        }
    }

    /// Whether crash reporting is enabled
    var crashReportingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(crashReportingEnabled, forKey: Keys.crashReportingEnabled)
            updateCrashReportingState()
            logger.info("Crash reporting \(self.crashReportingEnabled ? "enabled" : "disabled")")
        }
    }

    /// Whether performance monitoring is enabled
    var performanceMonitoringEnabled: Bool {
        didSet {
            UserDefaults.standard.set(performanceMonitoringEnabled, forKey: Keys.performanceEnabled)
            logger.info("Performance monitoring \(self.performanceMonitoringEnabled ? "enabled" : "disabled")")
        }
    }

    /// Whether the user has made an explicit choice about privacy
    var hasUserConsent: Bool {
        UserDefaults.standard.bool(forKey: Keys.hasUserConsent)
    }

    // MARK: - Initialization

    private init() {
        // Load saved preferences or use defaults
        self.analyticsEnabled = UserDefaults.standard.object(forKey: Keys.analyticsEnabled) as? Bool ?? true
        self.crashReportingEnabled = UserDefaults.standard.object(forKey: Keys.crashReportingEnabled) as? Bool ?? true
        self.performanceMonitoringEnabled = UserDefaults.standard.object(forKey: Keys.performanceEnabled) as? Bool ?? true
    }

    // MARK: - Consent Management

    /// Record that user has explicitly consented to current settings
    func recordConsent() {
        UserDefaults.standard.set(true, forKey: Keys.hasUserConsent)
        UserDefaults.standard.set(Date(), forKey: Keys.consentDate)
        logger.info("User consent recorded")
    }

    /// Enable all data collection (user opted in)
    func enableAll() {
        analyticsEnabled = true
        crashReportingEnabled = true
        performanceMonitoringEnabled = true
        recordConsent()
    }

    /// Disable all data collection (user opted out)
    func disableAll() {
        analyticsEnabled = false
        crashReportingEnabled = false
        performanceMonitoringEnabled = false
        recordConsent()
    }

    // MARK: - State Updates

    private func updateAnalyticsState() {
        Analytics.shared.setEnabled(analyticsEnabled)
    }

    private func updateCrashReportingState() {
        CrashReporting.shared.setEnabled(crashReportingEnabled)
    }

    // MARK: - Keys

    private enum Keys {
        static let analyticsEnabled = "privacy.analytics.enabled"
        static let crashReportingEnabled = "privacy.crashReporting.enabled"
        static let performanceEnabled = "privacy.performance.enabled"
        static let hasUserConsent = "privacy.hasUserConsent"
        static let consentDate = "privacy.consentDate"
    }
}

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {
    @Bindable private var settings = PrivacySettings.shared

    var body: some View {
        List {
            Section {
                Toggle(isOn: $settings.analyticsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Usage Analytics")
                            .font(.body)
                        Text("Help improve the app by sharing anonymous usage data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $settings.crashReportingEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crash Reports")
                            .font(.body)
                        Text("Send crash data to help fix bugs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $settings.performanceMonitoringEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Performance Data")
                            .font(.body)
                        Text("Share performance metrics to optimize the app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Data Collection")
            } footer: {
                Text("All data is anonymous and never includes your recordings or personal information.")
            }

            Section {
                Button("Enable All") {
                    settings.enableAll()
                }

                Button("Disable All") {
                    settings.disableAll()
                }
                .foregroundStyle(.red)
            }

            Section {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }

                if let privacyURL = URL(string: "https://quietcoach.app/privacy") {
                    Link("Learn More About Your Data", destination: privacyURL)
                        .foregroundStyle(.accent)
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Privacy Policy")
                        .font(.title.bold())

                    Text("Last updated: January 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Group {
                    Text("Your Privacy Matters")
                        .font(.headline)

                    Text("""
                    QuietCoach is designed with your privacy in mind. We believe in transparency about what data we collect and why.
                    """)
                }

                Group {
                    Text("What We Collect")
                        .font(.headline)

                    Text("""
                    • Usage Analytics: Anonymous data about how you use the app (screens visited, features used)
                    • Crash Reports: Technical information when the app crashes
                    • Performance Data: App performance metrics
                    """)
                }

                Group {
                    Text("What We Don't Collect")
                        .font(.headline)

                    Text("""
                    • Your voice recordings (they stay on your device)
                    • Personal information
                    • Anything that could identify you
                    """)
                }

                Group {
                    Text("Your Choices")
                        .font(.headline)

                    Text("""
                    You can disable any or all data collection at any time in Settings. The app will continue to work normally.
                    """)
                }

                Group {
                    Text("Data Security")
                        .font(.headline)

                    Text("""
                    All data transmitted from the app is encrypted. We use industry-standard security practices to protect any data we do collect.
                    """)
                }

                Group {
                    Text("Contact")
                        .font(.headline)

                    Text("Questions? Email privacy@quietcoach.app")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Consent Sheet

struct PrivacyConsentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings = PrivacySettings.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)

                Text("Your Privacy")
                    .font(.title.bold())

                Text("QuietCoach collects anonymous usage data to improve the app. Your voice recordings never leave your device.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        settings.enableAll()
                        dismiss()
                    } label: {
                        Text("Accept All")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        settings.disableAll()
                        dismiss()
                    } label: {
                        Text("Decline")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    Button {
                        // Will be shown in sheet
                    } label: {
                        Text("Customize")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        settings.recordConsent()
                        dismiss()
                    }
                }
            }
        }
    }
}

// RootView.swift
// QuietCoach
//
// The navigation root. Handles onboarding state and main app flow.
// Adapts to platform with native experiences for iOS, macOS, watchOS, and visionOS.

import SwiftUI
import SwiftData
import StoreKit
import CoreSpotlight

struct RootView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasUpgradedFromAppClip") private var hasUpgradedFromAppClip = false
    @State private var repository = SessionRepository.placeholder
    @State private var showingAppClipWelcome = false
    @State private var spotlightScenario: Scenario?
    @State private var showingHistory = false
    private let featureGates = FeatureGates.shared

    // MARK: - Body

    var body: some View {
        Group {
            if hasCompletedOnboarding || hasUpgradedFromAppClip {
                mainContent
            } else {
                ElevatedOnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .onAppear {
            // Initialize repository with actual model context
            repository.configure(with: modelContext)

            // Check for App Clip upgrade
            checkForAppClipUpgrade()
        }
        .sheet(isPresented: $showingAppClipWelcome) {
            AppClipUpgradeWelcome {
                hasUpgradedFromAppClip = true
                showingAppClipWelcome = false
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
                .environment(repository)
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            handleSpotlightActivity(activity)
        }
        .onContinueUserActivity(HandoffManager.ActivityType.viewScenario.rawValue) { activity in
            handleHandoffActivity(activity)
        }
        .onContinueUserActivity(HandoffManager.ActivityType.reviewSession.rawValue) { activity in
            handleHandoffActivity(activity)
        }
        .onContinueUserActivity(HandoffManager.ActivityType.practicing.rawValue) { activity in
            handleHandoffActivity(activity)
        }
    }

    // MARK: - Handoff Handling

    private func handleHandoffActivity(_ activity: NSUserActivity) {
        guard let action = HandoffManager.shared.parseActivity(activity) else {
            return
        }

        switch action {
        case .openScenario(let scenarioId):
            if let scenario = Scenario.scenario(for: scenarioId) {
                spotlightScenario = scenario
            }

        case .reviewSession:
            showingHistory = true
        }
    }

    // MARK: - Spotlight Handling

    private func handleSpotlightActivity(_ activity: NSUserActivity) {
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }

        guard let result = SpotlightManager.shared.parseIdentifier(identifier) else {
            return
        }

        switch result {
        case .scenario(let scenarioId):
            // Find and open the scenario
            if let scenario = Scenario.scenario(for: scenarioId) {
                spotlightScenario = scenario
                // Note: The HomeView should observe spotlightScenario to navigate
            }

        case .session:
            // Open history to show the session
            showingHistory = true

        case .quickAction(let action):
            handleQuickAction(action)
        }
    }

    private func handleQuickAction(_ action: String) {
        switch action {
        case "start-practice":
            // The HomeView is already the practice start point
            break

        case "view-history":
            showingHistory = true

        case "view-streak":
            // Could show streak detail, for now just go home
            break

        default:
            break
        }
    }

    // MARK: - App Clip Upgrade Detection

    private func checkForAppClipUpgrade() {
        // Check if user has App Clip data in shared container
        let sharedDefaults = UserDefaults(suiteName: "group.com.quietcoach")
        if let hasUsedClip = sharedDefaults?.bool(forKey: "hasUsedAppClip"), hasUsedClip {
            // User upgraded from App Clip - show welcome and skip onboarding
            if !hasUpgradedFromAppClip && !hasCompletedOnboarding {
                showingAppClipWelcome = true
            }
        }
    }

    // MARK: - Platform-Specific Main Content

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        MacHomeView()
            .environment(repository)
            .environment(featureGates)
        #elseif os(visionOS)
        SpatialHomeView()
            .environment(repository)
            .environment(featureGates)
        #else
        HomeView()
            .environment(repository)
            .environment(featureGates)
        #endif
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(for: RehearsalSession.self, inMemory: true)
}

// MARK: - App Clip Upgrade Welcome

/// Shown when user installs the full app after using the App Clip
struct AppClipUpgradeWelcome: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Welcome icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.qcAccent)

            VStack(spacing: 12) {
                Text("Welcome to Quiet Coach!")
                    .font(.qcTitle2)
                    .foregroundColor(.qcTextPrimary)

                Text("Thanks for downloading the full app.\nAll your practice features are now unlocked.")
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Features unlocked
            VStack(alignment: .leading, spacing: 16) {
                UpgradeFeatureRow(icon: "waveform", text: "AI-powered delivery feedback")
                UpgradeFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress over time")
                UpgradeFeatureRow(icon: "rectangle.stack", text: "All conversation scenarios")
                UpgradeFeatureRow(icon: "flame", text: "Practice streaks & achievements")
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button {
                onContinue()
            } label: {
                Text("Get Started")
                    .font(.qcButton)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.qcAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.qcBackground.ignoresSafeArea())
    }
}

struct UpgradeFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.qcAccent)
                .frame(width: 28)

            Text(text)
                .font(.qcBody)
                .foregroundColor(.qcTextPrimary)
        }
    }
}

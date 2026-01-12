// RootView.swift
// QuietCoach
//
// The navigation root. Handles onboarding state and main app flow.
// Adapts to platform with native experiences for iOS, macOS, watchOS, and visionOS.

import SwiftUI
import SwiftData
import StoreKit
import CoreSpotlight
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct RootView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasUpgradedFromAppClip") private var hasUpgradedFromAppClip = false
    @State private var repository = SessionRepository.placeholder
    @State private var router = AppRouter()
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

            // Handle any pending routes from intents or widgets
            handlePendingRoutes()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            handlePendingRoutes()
        }
#if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handlePendingRoutes()
        }
#elseif os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            handlePendingRoutes()
        }
#endif
        .sheet(item: $router.presentedSheet) { destination in
            switch destination {
            case .appClipWelcome:
                AppClipUpgradeWelcome {
                    hasUpgradedFromAppClip = true
                    router.presentedSheet = nil
                }
            case .history:
                HistoryView()
                    .environment(repository)
            }
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
            router.enqueueScenario(id: scenarioId)

        case .reviewSession(let sessionId):
            router.enqueueSession(id: sessionId)
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
            router.enqueueScenario(id: scenarioId)

        case .session(let sessionId):
            router.enqueueSession(id: sessionId)

        case .quickAction(let action):
            handleQuickAction(action)
        }
    }

    private func handleQuickAction(_ action: String) {
        switch action {
        case "start-practice":
            if let scenario = Scenario.freeScenarios.first {
                router.enqueueScenario(id: scenario.id)
            }

        case "view-history":
            router.presentHistory()

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
                router.presentAppClipWelcome()
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
            .environment(router)
        #elseif os(visionOS)
        SpatialHomeView()
            .environment(repository)
            .environment(featureGates)
            .environment(router)
        #else
        HomeView()
            .environment(repository)
            .environment(featureGates)
            .environment(router)
        #endif
    }
}

// MARK: - Pending Routes

private extension RootView {
    func handlePendingRoutes() {
        router.refreshPendingRoutes()

        if let scenarioId = WidgetDataManager.shared.consumePendingScenarioId() {
            router.enqueueScenario(id: scenarioId)
        } else if WidgetDataManager.shared.consumeLaunchToQuickPractice() {
            if let scenario = Scenario.freeScenarios.first {
                router.enqueueScenario(id: scenario.id)
            }
        }
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
                UpgradeFeatureRow(icon: "clock", text: "Unlimited rehearsal history")
                UpgradeFeatureRow(icon: "rectangle.stack", text: "All conversation scenarios")
                UpgradeFeatureRow(icon: "wand.and.stars", text: "Coach tone controls")
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

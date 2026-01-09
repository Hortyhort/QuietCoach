// FeatureGates.swift
// QuietCoach
//
// Clean separation of free vs pro features.
// Integrated with StoreKit 2 SubscriptionManager.

import Foundation
import SwiftUI

@Observable
@MainActor
final class FeatureGates {

    // MARK: - Singleton

    static let shared = FeatureGates()

    // MARK: - Observable State

    /// Whether the user has Pro access
    private(set) var isPro: Bool = false

    /// Whether Pro status has been verified (for loading states)
    private(set) var isLoaded: Bool = false

    // MARK: - Dependencies

    private let subscriptionManager = SubscriptionManager()

    // MARK: - Initialization

    private init() {
        // Load cached status first for instant UI
        loadCachedStatus()

        // Then verify with StoreKit 2
        Task {
            await verifySubscriptionStatus()
        }
    }

    // MARK: - Feature Checks

    /// Whether user can access a specific scenario
    func canAccessScenario(_ scenario: Scenario) -> Bool {
        if !scenario.isPro { return true }
        return isPro
    }

    /// Whether user has unlimited session history
    var hasUnlimitedHistory: Bool {
        isPro
    }

    /// Maximum number of sessions user can view
    var maxVisibleSessions: Int {
        isPro ? Int.max : Constants.Limits.freeSessionLimit
    }

    /// Whether user can access advanced feedback features
    var hasAdvancedFeedback: Bool {
        isPro
    }

    // MARK: - Subscription Manager Access

    /// Get the subscription manager for purchases
    var subscriptions: SubscriptionManager {
        subscriptionManager
    }

    // MARK: - Pro Status Management

    /// Load cached Pro status for instant UI
    private func loadCachedStatus() {
        isPro = UserDefaults.standard.bool(forKey: "quietcoach.isPro")
        isLoaded = true
    }

    /// Verify subscription status with StoreKit 2
    func verifySubscriptionStatus() async {
        await subscriptionManager.updateSubscriptionStatus()
    }

    /// Update Pro status (called by SubscriptionManager)
    func updateProStatus(_ newStatus: Bool) {
        isPro = newStatus
        UserDefaults.standard.set(newStatus, forKey: "quietcoach.isPro")
    }

    /// Restore purchases
    func restorePurchases() async {
        await subscriptionManager.restorePurchases()
    }

    // MARK: - Debug (Remove before App Store submission)

    #if DEBUG
    /// Toggle Pro status for testing
    func debugTogglePro() {
        updateProStatus(!isPro)
    }
    #endif
}

// MARK: - Scenario Extension

extension Scenario {
    /// Convenience check for whether this scenario is accessible
    @MainActor
    var isAccessible: Bool {
        FeatureGates.shared.canAccessScenario(self)
    }
}

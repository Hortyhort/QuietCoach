// FeatureGates.swift
// QuietCoach
//
// Clean separation of free vs pro features.
// StoreKit 2 integration comes in Phase 2 — this is the gate logic.

import Foundation
import SwiftUI

@MainActor
final class FeatureGates: ObservableObject {

    // MARK: - Singleton

    static let shared = FeatureGates()

    // MARK: - Published State

    /// Whether the user has Pro access
    @Published private(set) var isPro: Bool = false

    /// Whether Pro status has been verified (for loading states)
    @Published private(set) var isLoaded: Bool = false

    // MARK: - Initialization

    private init() {
        // In V1, we start with free tier
        // StoreKit 2 integration will update this
        loadProStatus()
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

    // MARK: - Pro Status Management

    /// Load Pro status from persistent storage
    private func loadProStatus() {
        // Check UserDefaults for cached entitlement
        // This will be replaced with StoreKit 2 verification
        isPro = UserDefaults.standard.bool(forKey: "quietcoach.isPro")
        isLoaded = true
    }

    /// Update Pro status (called after StoreKit verification)
    func updateProStatus(_ newStatus: Bool) {
        isPro = newStatus
        UserDefaults.standard.set(newStatus, forKey: "quietcoach.isPro")
    }

    /// Restore purchases (placeholder for StoreKit 2)
    func restorePurchases() async {
        // TODO: Implement StoreKit 2 restore
        // For now, this is a no-op
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

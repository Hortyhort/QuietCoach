// AppRouter.swift
// QuietCoach
//
// Centralized routing for system entry points and sheets.

import Foundation

@Observable
@MainActor
final class AppRouter {

    enum SheetDestination: String, Identifiable {
        case history
        case appClipWelcome

        var id: String { rawValue }
    }

    private enum DefaultsKeys {
        static let pendingScenarioId = "pendingScenarioId"
        static let pendingRoute = "pendingRoute"
    }

    var presentedSheet: SheetDestination?
    var pendingScenarioId: String?

    func presentHistory() {
        presentedSheet = .history
    }

    func presentAppClipWelcome() {
        presentedSheet = .appClipWelcome
    }

    func enqueueScenario(id: String) {
        pendingScenarioId = id
    }

    func consumePendingScenarioId() -> String? {
        let id = pendingScenarioId
        pendingScenarioId = nil
        return id
    }

    func refreshPendingRoutes() {
        if let scenarioId = UserDefaults.standard.string(forKey: DefaultsKeys.pendingScenarioId) {
            UserDefaults.standard.removeObject(forKey: DefaultsKeys.pendingScenarioId)
            enqueueScenario(id: scenarioId)
        }

        if let pendingRoute = UserDefaults.standard.string(forKey: DefaultsKeys.pendingRoute),
           pendingRoute == "history" {
            UserDefaults.standard.removeObject(forKey: DefaultsKeys.pendingRoute)
            presentHistory()
        }
    }
}

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
        static let pendingSessionId = "pendingSessionId"
        static let pendingRoute = "pendingRoute"
    }

    var presentedSheet: SheetDestination?
    var pendingScenarioId: String?
    var pendingSessionId: UUID?

    func presentHistory() {
        guard presentedSheet != .history else { return }
        presentedSheet = .history
    }

    func presentAppClipWelcome() {
        guard presentedSheet != .appClipWelcome else { return }
        presentedSheet = .appClipWelcome
    }

    func enqueueScenario(id: String) {
        pendingScenarioId = id
    }

    func enqueueSession(id: UUID) {
        pendingSessionId = id
    }

    func consumePendingScenarioId() -> String? {
        let id = pendingScenarioId
        pendingScenarioId = nil
        return id
    }

    func consumePendingSessionId() -> UUID? {
        let id = pendingSessionId
        pendingSessionId = nil
        return id
    }

    func refreshPendingRoutes() {
        if let scenarioId = UserDefaults.standard.string(forKey: DefaultsKeys.pendingScenarioId) {
            UserDefaults.standard.removeObject(forKey: DefaultsKeys.pendingScenarioId)
            enqueueScenario(id: scenarioId)
        }

        if let sessionIdString = UserDefaults.standard.string(forKey: DefaultsKeys.pendingSessionId),
           let sessionId = UUID(uuidString: sessionIdString) {
            UserDefaults.standard.removeObject(forKey: DefaultsKeys.pendingSessionId)
            enqueueSession(id: sessionId)
        }

        if let pendingRoute = UserDefaults.standard.string(forKey: DefaultsKeys.pendingRoute),
           pendingRoute == "history" {
            UserDefaults.standard.removeObject(forKey: DefaultsKeys.pendingRoute)
            presentHistory()
        }
    }
}

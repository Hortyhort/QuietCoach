// AppContainer.swift
// QuietCoach
//
// Central dependency container and injection utilities.

import Foundation
import SwiftUI

// MARK: - App Container

/// Central dependency container for the app
/// Provides both production and mock implementations
@MainActor
final class AppContainer: ObservableObject {

    // MARK: - Shared Instance

    static let shared = AppContainer()

    // MARK: - Service Dependencies

    /// Session repository for data access
    lazy var sessionRepository: SessionRepositoryProtocol = SessionRepository()

    /// Feature gates for pro/free access
    lazy var featureGates: FeatureGatesProtocol = FeatureGates.shared

    /// Speech analyzer for audio analysis
    lazy var speechAnalyzer: SpeechAnalyzerProtocol = SpeechAnalysisEngine.shared

    /// Analytics for event tracking
    lazy var analytics: AnalyticsProtocol = Analytics.shared

    /// Network monitor for connectivity
    lazy var networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared

    /// Performance monitor for timing
    lazy var performanceMonitor: PerformanceMonitorProtocol = PerformanceMonitor.shared

    /// Crash reporting
    lazy var crashReporting: CrashReportingProtocol = CrashReporting.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Testing Support

    #if DEBUG
    /// Create a container with custom dependencies for testing
    static func forTesting(
        sessionRepository: SessionRepositoryProtocol? = nil,
        featureGates: FeatureGatesProtocol? = nil,
        speechAnalyzer: SpeechAnalyzerProtocol? = nil,
        analytics: AnalyticsProtocol? = nil,
        networkMonitor: NetworkMonitorProtocol? = nil,
        performanceMonitor: PerformanceMonitorProtocol? = nil,
        crashReporting: CrashReportingProtocol? = nil
    ) -> AppContainer {
        let container = AppContainer()

        if let repo = sessionRepository {
            container.sessionRepository = repo
        }
        if let gates = featureGates {
            container.featureGates = gates
        }
        if let analyzer = speechAnalyzer {
            container.speechAnalyzer = analyzer
        }
        if let tracker = analytics {
            container.analytics = tracker
        }
        if let monitor = networkMonitor {
            container.networkMonitor = monitor
        }
        if let perf = performanceMonitor {
            container.performanceMonitor = perf
        }
        if let crash = crashReporting {
            container.crashReporting = crash
        }

        return container
    }

    /// Override a specific dependency
    func override<T>(_ keyPath: ReferenceWritableKeyPath<AppContainer, T>, with value: T) {
        self[keyPath: keyPath] = value
    }
    #endif
}

// MARK: - Environment Key

@MainActor
private enum AppContainerKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: AppContainer = {
        MainActor.assumeIsolated { AppContainer.shared }
    }()
}

extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject a custom app container (useful for testing/previews)
    func appContainer(_ container: AppContainer) -> some View {
        environment(\.appContainer, container)
    }
}

// MARK: - Injected Property Wrapper

/// Property wrapper for easy dependency injection in views
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<AppContainer, T>

    init(_ keyPath: KeyPath<AppContainer, T>) {
        self.keyPath = keyPath
    }

    @MainActor
    var wrappedValue: T {
        AppContainer.shared[keyPath: keyPath]
    }
}

// NetworkMonitor.swift
// QuietCoach
//
// Monitors network connectivity status.
// Provides real-time updates for offline/online state.

import Foundation
import Network
import OSLog

// MARK: - Network Status

enum NetworkStatus: Equatable, Sendable {
    case connected
    case disconnected
    case connecting

    var isConnected: Bool {
        self == .connected
    }

    var localizedDescription: String {
        switch self {
        case .connected: return L10n.Network.connected
        case .disconnected: return L10n.Network.offline
        case .connecting: return L10n.Network.reconnecting
        }
    }

    var icon: String {
        switch self {
        case .connected: return "wifi"
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        }
    }
}

// MARK: - Network Monitor

@Observable
@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let logger = Logger(subsystem: "com.quietcoach", category: "Network")
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.quietcoach.networkmonitor")

    // MARK: - Observable State

    private(set) var status: NetworkStatus = .connecting
    private(set) var connectionType: ConnectionType = .unknown
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false

    // MARK: - Connection Type

    enum ConnectionType: String, Sendable {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wired = "Wired"
        case unknown = "Unknown"
    }

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    deinit {
        // NWPathMonitor.cancel() is thread-safe
        monitor.cancel()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
        logger.info("Network monitoring started")
    }

    private func handlePathUpdate(_ path: NWPath) {
        // Update status
        let newStatus: NetworkStatus
        switch path.status {
        case .satisfied:
            newStatus = .connected
        case .unsatisfied:
            newStatus = .disconnected
        case .requiresConnection:
            newStatus = .connecting
        @unknown default:
            newStatus = .disconnected
        }

        // Only log and notify on status change
        if newStatus != status {
            status = newStatus
            logger.info("Network status changed: \(newStatus.localizedDescription)")

            // Track in analytics
            CrashReporting.shared.recordBreadcrumb(
                "Network status: \(newStatus.localizedDescription)",
                category: .stateChange
            )
        }

        // Update connection type
        connectionType = determineConnectionType(path)

        // Update network conditions
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }

    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        }
        return .unknown
    }

    // MARK: - Retry Logic

    /// Execute a network operation with retry logic
    func withRetry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = initialDelay

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry if offline
                guard status.isConnected else {
                    logger.warning("Network offline, not retrying")
                    throw error
                }

                // Last attempt, don't wait
                guard attempt < maxAttempts else { break }

                logger.info("Attempt \(attempt) failed, retrying in \(delay)s")

                try await Task.sleep(for: .seconds(delay))

                // Exponential backoff with jitter
                delay = min(delay * 2 + Double.random(in: 0...1), maxDelay)
            }
        }

        throw lastError ?? NetworkError.maxRetriesExceeded
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case offline
    case maxRetriesExceeded
    case timeout

    var errorDescription: String? {
        switch self {
        case .offline:
            return L10n.Network.offline
        case .maxRetriesExceeded:
            return "Request failed after multiple attempts"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Offline Indicator View

import SwiftUI

struct OfflineIndicatorView: View {
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.status.isConnected {
            HStack(spacing: 8) {
                Image(systemName: networkMonitor.status.icon)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 2) {
                    Text(networkMonitor.status.localizedDescription)
                        .font(.caption.weight(.semibold))

                    if networkMonitor.status == .disconnected {
                        Text(L10n.Network.offlineDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - View Modifier

struct OfflineAwareModifier: ViewModifier {
    @State private var networkMonitor = NetworkMonitor.shared

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            OfflineIndicatorView()

            content
        }
        .animation(.spring(response: 0.3), value: networkMonitor.status)
    }
}

extension View {
    /// Add an offline indicator banner at the top of the view
    func offlineAware() -> some View {
        modifier(OfflineAwareModifier())
    }
}

// MARK: - Cached Value

/// A value that caches results for offline access
@propertyWrapper
struct CachedValue<Value: Codable> {
    private let key: String
    private let defaultValue: Value
    private let validityDuration: TimeInterval

    struct CachedData: Codable {
        let value: Value
        let timestamp: Date
    }

    init(key: String, default defaultValue: Value, validFor duration: TimeInterval = 3600) {
        self.key = key
        self.defaultValue = defaultValue
        self.validityDuration = duration
    }

    var wrappedValue: Value {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let cached = try? JSONDecoder().decode(CachedData.self, from: data)
            else {
                return defaultValue
            }
            return cached.value
        }
        set {
            let cached = CachedData(value: newValue, timestamp: Date())
            if let data = try? JSONEncoder().encode(cached) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    var isStale: Bool {
        guard let data = UserDefaults.standard.data(forKey: key),
              let cached = try? JSONDecoder().decode(CachedData.self, from: data)
        else {
            return true
        }
        return Date().timeIntervalSince(cached.timestamp) > validityDuration
    }

    var projectedValue: Self { self }
}

#if DEBUG
// MARK: - Preview

#Preview("Offline Indicator") {
    VStack {
        OfflineIndicatorView()
        Spacer()
    }
}
#endif

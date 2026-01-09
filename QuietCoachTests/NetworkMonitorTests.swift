// NetworkMonitorTests.swift
// QuietCoachTests
//
// Unit tests for NetworkMonitor and offline resilience.

import XCTest
@testable import QuietCoach

final class NetworkStatusTests: XCTestCase {

    func testConnectedStatusIsConnected() {
        let status = NetworkStatus.connected

        XCTAssertTrue(status.isConnected)
        XCTAssertEqual(status.icon, "wifi")
    }

    func testDisconnectedStatusIsNotConnected() {
        let status = NetworkStatus.disconnected

        XCTAssertFalse(status.isConnected)
        XCTAssertEqual(status.icon, "wifi.slash")
    }

    func testConnectingStatusIsNotConnected() {
        let status = NetworkStatus.connecting

        XCTAssertFalse(status.isConnected)
        XCTAssertEqual(status.icon, "wifi.exclamationmark")
    }
}

// MARK: - Network Error Tests

final class NetworkErrorTests: XCTestCase {

    func testOfflineErrorHasCorrectDescription() {
        let error = NetworkError.offline

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("offline") ?? false)
    }

    func testMaxRetriesErrorHasDescription() {
        let error = NetworkError.maxRetriesExceeded

        XCTAssertNotNil(error.errorDescription)
    }

    func testTimeoutErrorHasDescription() {
        let error = NetworkError.timeout

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("timed out") ?? false)
    }
}

// MARK: - Retry Logic Tests

final class RetryLogicTests: XCTestCase {

    @MainActor
    func testRetryExecutesOperationOnce() async throws {
        let monitor = MockNetworkMonitor()
        var executionCount = 0

        _ = try await monitor.withRetry(maxAttempts: 3) {
            executionCount += 1
            return "success"
        }

        XCTAssertEqual(executionCount, 1)
    }

    @MainActor
    func testRetryReturnsSuccessResult() async throws {
        let monitor = MockNetworkMonitor()

        let result = try await monitor.withRetry {
            return 42
        }

        XCTAssertEqual(result, 42)
    }

    @MainActor
    func testRetryPropagatesErrors() async {
        let monitor = MockNetworkMonitor()

        do {
            _ = try await monitor.withRetry {
                throw NetworkError.timeout
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

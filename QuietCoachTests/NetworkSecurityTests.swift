// NetworkSecurityTests.swift
// QuietCoachTests
//
// Tests for certificate pinning and network security infrastructure.

import XCTest
@testable import QuietCoach

// MARK: - Certificate Pin Configuration Tests

final class CertificatePinConfigurationTests: XCTestCase {

    func testConfigurationInitialization() {
        let config = CertificatePinConfiguration(
            host: "api.example.com",
            pinnedPublicKeyHashes: ["hash1", "hash2"],
            includeSubdomains: true,
            enforceMode: true
        )

        XCTAssertEqual(config.host, "api.example.com")
        XCTAssertEqual(config.pinnedPublicKeyHashes.count, 2)
        XCTAssertTrue(config.includeSubdomains)
        XCTAssertTrue(config.enforceMode)
    }

    func testConfigurationDefaults() {
        let config = CertificatePinConfiguration(
            host: "example.com",
            pinnedPublicKeyHashes: ["hash"]
        )

        // Default values
        XCTAssertTrue(config.includeSubdomains)
        XCTAssertTrue(config.enforceMode)
    }

    func testEmptyHashesConfiguration() {
        let config = CertificatePinConfiguration(
            host: "example.com",
            pinnedPublicKeyHashes: [],
            enforceMode: false
        )

        XCTAssertTrue(config.pinnedPublicKeyHashes.isEmpty)
        XCTAssertFalse(config.enforceMode)
    }
}

// MARK: - Network Security Manager Tests

final class NetworkSecurityManagerTests: XCTestCase {

    @MainActor
    func testDefaultConfigurationsLoaded() {
        let manager = NetworkSecurityManager.shared

        // Should have default configurations
        XCTAssertNotNil(manager.configuration(for: "api.quietcoach.app"))
    }

    @MainActor
    func testAddPinConfiguration() {
        let manager = NetworkSecurityManager.shared

        let config = CertificatePinConfiguration(
            host: "test.example.com",
            pinnedPublicKeyHashes: ["testhash"],
            enforceMode: false
        )

        manager.addPinConfiguration(config)

        let retrieved = manager.configuration(for: "test.example.com")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.host, "test.example.com")

        // Cleanup
        manager.removePinConfiguration(for: "test.example.com")
    }

    @MainActor
    func testRemovePinConfiguration() {
        let manager = NetworkSecurityManager.shared

        let config = CertificatePinConfiguration(
            host: "remove.example.com",
            pinnedPublicKeyHashes: ["hash"]
        )

        manager.addPinConfiguration(config)
        XCTAssertNotNil(manager.configuration(for: "remove.example.com"))

        manager.removePinConfiguration(for: "remove.example.com")
        XCTAssertNil(manager.configuration(for: "remove.example.com"))
    }

    @MainActor
    func testSubdomainMatching() {
        let manager = NetworkSecurityManager.shared

        let config = CertificatePinConfiguration(
            host: "parent.example.com",
            pinnedPublicKeyHashes: ["hash"],
            includeSubdomains: true
        )

        manager.addPinConfiguration(config)

        // Should match subdomain
        let subdomainConfig = manager.configuration(for: "api.parent.example.com")
        XCTAssertNotNil(subdomainConfig)

        // Cleanup
        manager.removePinConfiguration(for: "parent.example.com")
    }

    @MainActor
    func testNoConfigurationForUnknownHost() {
        let manager = NetworkSecurityManager.shared

        let config = manager.configuration(for: "unknown.host.that.doesnt.exist.com")
        XCTAssertNil(config)
    }
}

// MARK: - Secure Request Builder Tests

final class SecureRequestBuilderTests: XCTestCase {

    func testBuildGetRequest() {
        let url = URL(string: "https://api.example.com/test")!
        let request = SecureRequestBuilder.buildRequest(url: url)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url, url)
        XCTAssertNil(request.httpBody)
    }

    func testBuildPostRequest() {
        let url = URL(string: "https://api.example.com/test")!
        let body = "{\"key\": \"value\"}".data(using: .utf8)

        let request = SecureRequestBuilder.buildRequest(
            url: url,
            method: "POST",
            body: body
        )

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, body)
    }

    func testSecurityHeaders() {
        let url = URL(string: "https://api.example.com/test")!
        let request = SecureRequestBuilder.buildRequest(url: url)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cache-Control"), "no-cache")
    }

    func testCustomHeaders() {
        let url = URL(string: "https://api.example.com/test")!
        let request = SecureRequestBuilder.buildRequest(
            url: url,
            additionalHeaders: [
                "X-Custom-Header": "custom-value",
                "Authorization": "Bearer token"
            ]
        )

        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom-Header"), "custom-value")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testTimeout() {
        let url = URL(string: "https://api.example.com/test")!
        let request = SecureRequestBuilder.buildRequest(url: url)

        XCTAssertEqual(request.timeoutInterval, 30)
    }
}

// MARK: - Network Security Error Tests

final class NetworkSecurityErrorTests: XCTestCase {

    func testCertificatePinningFailedError() {
        let error = NetworkSecurityError.certificatePinningFailed(host: "example.com")

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("example.com"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testInvalidCertificateError() {
        let error = NetworkSecurityError.invalidCertificate

        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testUntrustedCertificateChainError() {
        let error = NetworkSecurityError.untrustedCertificateChain

        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testExpiredCertificateError() {
        let error = NetworkSecurityError.expiredCertificate

        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testAllErrorsAreLocalizedErrors() {
        let errors: [NetworkSecurityError] = [
            .certificatePinningFailed(host: "test"),
            .invalidCertificate,
            .untrustedCertificateChain,
            .expiredCertificate
        ]

        for error in errors {
            // LocalizedError protocol requirements
            XCTAssertNotNil(error.localizedDescription)
        }
    }
}

// MARK: - Certificate Pin Utility Tests

final class CertificatePinUtilityTests: XCTestCase {

    func testVerifyWithEmptyPins() {
        let certificateData = Data() // Invalid data
        let result = CertificatePinUtility.verify(certificateData: certificateData, againstPins: [])

        // Empty data should fail
        XCTAssertFalse(result)
    }

    func testVerifyWithInvalidCertificateData() {
        let invalidData = "not a certificate".data(using: .utf8)!
        let result = CertificatePinUtility.verify(certificateData: invalidData, againstPins: ["somehash"])

        XCTAssertFalse(result)
    }

    func testGeneratePinHashWithInvalidData() {
        let invalidData = Data()
        let hash = CertificatePinUtility.generatePinHash(from: invalidData)

        XCTAssertNil(hash)
    }
}

// MARK: - Secure URL Session Tests

final class SecureURLSessionTests: XCTestCase {

    func testSharedInstanceExists() {
        let session = SecureURLSession.shared

        XCTAssertNotNil(session)
        XCTAssertNotNil(session.session)
    }

    func testSessionConfiguration() {
        let urlSession = SecureURLSession.shared.session
        let config = urlSession.configuration

        // TLS version should be at least 1.2
        XCTAssertGreaterThanOrEqual(
            config.tlsMinimumSupportedProtocolVersion.rawValue,
            tls_protocol_version_t.TLSv12.rawValue
        )
    }
}

// MARK: - Integration Tests

final class NetworkSecurityIntegrationTests: XCTestCase {

    @MainActor
    func testFullPinningWorkflow() {
        let manager = NetworkSecurityManager.shared

        // Add a test configuration
        let config = CertificatePinConfiguration(
            host: "integration.test.com",
            pinnedPublicKeyHashes: ["integrationhash"],
            includeSubdomains: true,
            enforceMode: false // Non-enforcing for test
        )

        manager.addPinConfiguration(config)

        // Verify configuration exists
        XCTAssertNotNil(manager.configuration(for: "integration.test.com"))
        XCTAssertNotNil(manager.configuration(for: "api.integration.test.com"))

        // Cleanup
        manager.removePinConfiguration(for: "integration.test.com")
        XCTAssertNil(manager.configuration(for: "integration.test.com"))
    }

    func testSecureRequestWorkflow() {
        // Build a request
        let url = URL(string: "https://api.example.com/v1/test")!
        let body = try? JSONEncoder().encode(["message": "test"])

        let request = SecureRequestBuilder.buildRequest(
            url: url,
            method: "POST",
            body: body,
            additionalHeaders: ["X-API-Version": "1"]
        )

        // Verify request is properly configured
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertNotNil(request.httpBody)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Version"), "1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
}

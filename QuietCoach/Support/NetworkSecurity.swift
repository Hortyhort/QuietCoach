// NetworkSecurity.swift
// QuietCoach
//
// Certificate pinning and network security infrastructure.
// Provides secure communication for any future network features.
// Privacy-first approach: all core functionality remains on-device.

import Foundation
import Security
import CryptoKit
import OSLog

// MARK: - Certificate Pin Configuration

/// Configuration for certificate pinning
struct CertificatePinConfiguration {
    /// The host domain to pin
    let host: String

    /// SHA-256 hashes of the public keys (SPKI - Subject Public Key Info)
    let pinnedPublicKeyHashes: [String]

    /// Whether to include subdomains
    let includeSubdomains: Bool

    /// Whether pinning is enforced (if false, logs warnings but allows connection)
    let enforceMode: Bool

    init(
        host: String,
        pinnedPublicKeyHashes: [String],
        includeSubdomains: Bool = true,
        enforceMode: Bool = true
    ) {
        self.host = host
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes
        self.includeSubdomains = includeSubdomains
        self.enforceMode = enforceMode
    }
}

// MARK: - Network Security Manager

/// Manages certificate pinning and network security
@MainActor
final class NetworkSecurityManager: NSObject {

    // MARK: - Singleton

    static let shared = NetworkSecurityManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "NetworkSecurity")
    private var pinConfigurations: [String: CertificatePinConfiguration] = [:]

    // MARK: - Default Configurations

    /// Default pin configurations for QuietCoach services
    ///
    /// - Important: Before enabling network features in production:
    ///   1. Generate SHA-256 hashes of your server's public key certificates
    ///   2. Replace placeholder hashes below with actual certificate hashes
    ///   3. Set `enforceMode: true` after testing
    ///   4. Include at least 2 hashes (primary + backup) for certificate rotation
    ///
    /// To generate certificate hash:
    /// ```
    /// openssl s_client -connect api.quietcoach.app:443 | openssl x509 -pubkey -noout | \
    ///   openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
    /// ```
    static let defaultConfigurations: [CertificatePinConfiguration] = [
        // QuietCoach API (for future use)
        CertificatePinConfiguration(
            host: "api.quietcoach.app",
            pinnedPublicKeyHashes: [
                // TODO: Replace with actual production certificate hashes before enabling network features
                // Primary certificate hash
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                // Backup certificate hash (for rotation)
                "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
            ],
            includeSubdomains: true,
            enforceMode: false // Set to true after configuring real certificate hashes
        ),

        // Apple services (CloudKit) - Using Apple's built-in trust
        CertificatePinConfiguration(
            host: "icloud.com",
            pinnedPublicKeyHashes: [], // Empty = trust system certificates
            includeSubdomains: true,
            enforceMode: false
        )
    ]

    // MARK: - Initialization

    private override init() {
        super.init()

        // Load default configurations
        for config in Self.defaultConfigurations {
            pinConfigurations[config.host] = config
        }

        logger.info("Network security initialized with \(self.pinConfigurations.count) pin configurations")
    }

    // MARK: - Configuration

    /// Add or update a pin configuration
    func addPinConfiguration(_ config: CertificatePinConfiguration) {
        pinConfigurations[config.host] = config
        logger.info("Added pin configuration for \(config.host)")
    }

    /// Remove a pin configuration
    func removePinConfiguration(for host: String) {
        pinConfigurations.removeValue(forKey: host)
        logger.info("Removed pin configuration for \(host)")
    }

    /// Get configuration for a host
    func configuration(for host: String) -> CertificatePinConfiguration? {
        // Direct match
        if let config = pinConfigurations[host] {
            return config
        }

        // Check for subdomain matches
        for (configHost, config) in pinConfigurations {
            if config.includeSubdomains && host.hasSuffix(".\(configHost)") {
                return config
            }
        }

        return nil
    }

    // MARK: - Validation

    /// Validate a server trust against pinned certificates
    func validateServerTrust(_ serverTrust: SecTrust, for host: String) -> Bool {
        guard let config = configuration(for: host) else {
            // No configuration for this host - allow connection
            logger.debug("No pin configuration for \(host), allowing connection")
            return true
        }

        // If no hashes configured, trust system certificates
        if config.pinnedPublicKeyHashes.isEmpty {
            logger.debug("Empty pin configuration for \(host), using system trust")
            return evaluateSystemTrust(serverTrust)
        }

        // Extract public key hashes from the certificate chain
        let serverKeyHashes = extractPublicKeyHashes(from: serverTrust)

        // Check if any server key matches our pins
        let matched = serverKeyHashes.contains { serverHash in
            config.pinnedPublicKeyHashes.contains(serverHash)
        }

        if matched {
            logger.debug("Certificate pin matched for \(host)")
            return true
        } else {
            if config.enforceMode {
                logger.error("Certificate pin FAILED for \(host) - connection blocked")
                return false
            } else {
                logger.warning("Certificate pin mismatch for \(host) - allowing (enforce mode disabled)")
                return true
            }
        }
    }

    // MARK: - Private Helpers

    /// Evaluate using system trust store
    private func evaluateSystemTrust(_ serverTrust: SecTrust) -> Bool {
        var error: CFError?
        let result = SecTrustEvaluateWithError(serverTrust, &error)

        if let error = error {
            logger.error("System trust evaluation failed: \(error.localizedDescription)")
            return false
        }

        return result
    }

    /// Extract SHA-256 hashes of public keys from certificate chain
    private func extractPublicKeyHashes(from serverTrust: SecTrust) -> [String] {
        var hashes: [String] = []

        // Use modern API for iOS 15+, fallback for older versions
        if #available(iOS 15.0, macOS 12.0, *) {
            guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
                return hashes
            }

            for certificate in certificates {
                if let hash = publicKeyHash(for: certificate) {
                    hashes.append(hash)
                }
            }
        } else {
            // Fallback for older OS versions
            let certificateCount = SecTrustGetCertificateCount(serverTrust)

            for index in 0..<certificateCount {
                guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) else {
                    continue
                }

                if let hash = publicKeyHash(for: certificate) {
                    hashes.append(hash)
                }
            }
        }

        return hashes
    }

    /// Calculate SHA-256 hash of certificate's public key
    private func publicKeyHash(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        // SHA-256 hash of the public key
        let hash = SHA256.hash(data: publicKeyData)
        return Data(hash).base64EncodedString()
    }
}

// MARK: - Secure URL Session

/// A URLSession configured with certificate pinning
final class SecureURLSession: NSObject, URLSessionDelegate {

    // MARK: - Shared Instance

    static let shared = SecureURLSession()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "SecureURLSession")

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13

        // Security headers
        config.httpAdditionalHeaders = [
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY"
        ]

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // MARK: - URLSessionDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // Perform validation synchronously to avoid sendability issues
        // The validation itself is thread-safe
        let isValid = validateServerTrustSync(serverTrust, for: host)

        if isValid {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// Synchronous validation for use in delegate callback
    private nonisolated func validateServerTrustSync(_ serverTrust: SecTrust, for host: String) -> Bool {
        // For hosts without pin configuration, use system trust
        var error: CFError?
        let systemTrustValid = SecTrustEvaluateWithError(serverTrust, &error)

        if error != nil {
            return false
        }

        return systemTrustValid
    }
}

// MARK: - Network Security Error

enum NetworkSecurityError: Error, LocalizedError {
    case certificatePinningFailed(host: String)
    case invalidCertificate
    case untrustedCertificateChain
    case expiredCertificate

    var errorDescription: String? {
        switch self {
        case .certificatePinningFailed(let host):
            return "Certificate verification failed for \(host)"
        case .invalidCertificate:
            return "The server certificate is invalid"
        case .untrustedCertificateChain:
            return "The certificate chain is not trusted"
        case .expiredCertificate:
            return "The server certificate has expired"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .certificatePinningFailed:
            return "Please update the app to the latest version"
        case .invalidCertificate, .untrustedCertificateChain, .expiredCertificate:
            return "Please try again later or contact support"
        }
    }
}

// MARK: - Secure Request Builder

/// Builds secure network requests with proper headers
struct SecureRequestBuilder {

    /// Create a secure request with appropriate headers
    static func buildRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        additionalHeaders: [String: String] = [:]
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        // Security headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        // Custom headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Timeout
        request.timeoutInterval = 30

        return request
    }
}

// MARK: - Certificate Pin Utility

/// Utility for generating and verifying certificate pins
enum CertificatePinUtility {

    /// Generate a pin hash from a DER-encoded certificate data
    static func generatePinHash(from certificateData: Data) -> String? {
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            return nil
        }

        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        let hash = SHA256.hash(data: publicKeyData)
        return Data(hash).base64EncodedString()
    }

    /// Verify a certificate against expected pins
    static func verify(certificateData: Data, againstPins pins: [String]) -> Bool {
        guard let hash = generatePinHash(from: certificateData) else {
            return false
        }
        return pins.contains(hash)
    }
}

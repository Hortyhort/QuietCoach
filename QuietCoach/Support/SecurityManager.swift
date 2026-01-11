// SecurityManager.swift
// QuietCoach
//
// Device security and integrity verification.
// Detects compromised devices and validates app integrity.

import Foundation
import OSLog
import DeviceCheck
import CryptoKit

/// Manages device security checks and integrity verification
@MainActor
final class SecurityManager {

    // MARK: - Singleton

    static let shared = SecurityManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Security")

    /// Cached security status to avoid repeated checks
    private var cachedSecurityStatus: SecurityStatus?
    private var lastCheckTime: Date?
    private let cacheValiditySeconds: TimeInterval = 300 // 5 minutes

    // MARK: - Types

    struct SecurityStatus {
        let isDeviceSecure: Bool
        let isJailbroken: Bool
        let isDebuggerAttached: Bool
        let isRunningInSimulator: Bool
        let failedChecks: [String]

        var shouldAllowProFeatures: Bool {
            // Allow in simulator for development, but not on jailbroken devices
            #if targetEnvironment(simulator)
            return true
            #else
            return isDeviceSecure && !isJailbroken
            #endif
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Performs comprehensive security check
    /// - Returns: Security status with detailed results
    func checkDeviceSecurity() -> SecurityStatus {
        // Return cached result if still valid
        if let cached = cachedSecurityStatus,
           let lastCheck = lastCheckTime,
           Date().timeIntervalSince(lastCheck) < cacheValiditySeconds {
            return cached
        }

        var failedChecks: [String] = []

        let isJailbroken = checkJailbreak(&failedChecks)
        let isDebuggerAttached = checkDebugger(&failedChecks)
        let isSimulator = checkSimulator()

        let status = SecurityStatus(
            isDeviceSecure: failedChecks.isEmpty,
            isJailbroken: isJailbroken,
            isDebuggerAttached: isDebuggerAttached,
            isRunningInSimulator: isSimulator,
            failedChecks: failedChecks
        )

        // Cache result
        cachedSecurityStatus = status
        lastCheckTime = Date()

        // Log security status (without exposing specifics)
        if !status.isDeviceSecure {
            logger.warning("Device security check failed")
        }

        return status
    }

    /// Quick check if device is considered secure for Pro features
    var isDeviceSecure: Bool {
        checkDeviceSecurity().shouldAllowProFeatures
    }

    /// Invalidate cached security status (call when app becomes active)
    func invalidateCache() {
        cachedSecurityStatus = nil
        lastCheckTime = nil
    }

    // MARK: - Jailbreak Detection

    private func checkJailbreak(_ failedChecks: inout [String]) -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        var isJailbroken = false

        // Check 1: Suspicious files
        let suspiciousFiles = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Applications/Installer.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/var/cache/apt",
            "/var/lib/cydia",
            "/usr/bin/ssh"
        ]

        for path in suspiciousFiles {
            if FileManager.default.fileExists(atPath: path) {
                isJailbroken = true
                failedChecks.append("suspicious_file")
                break
            }
        }

        // Check 2: Can write to system directories
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            isJailbroken = true
            failedChecks.append("writable_system")
        } catch {
            // Expected to fail on non-jailbroken devices
        }

        // Check 3: Can open Cydia URL scheme
        #if canImport(UIKit)
        if let url = URL(string: "cydia://package/com.example.package") {
            if UIApplication.shared.canOpenURL(url) {
                isJailbroken = true
                failedChecks.append("cydia_scheme")
            }
        }
        #endif

        // Check 4: Check for symbolic links in system paths
        let systemPaths = ["/Applications", "/Library/Ringtones", "/Library/Wallpaper"]
        for path in systemPaths {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: path)
                if let type = attrs[.type] as? FileAttributeType, type == .typeSymbolicLink {
                    isJailbroken = true
                    failedChecks.append("symlink_detected")
                    break
                }
            } catch {
                // Path doesn't exist or can't be accessed
            }
        }

        // Check 5: Environment variables that indicate jailbreak
        let suspiciousEnvVars = ["DYLD_INSERT_LIBRARIES", "DYLD_LIBRARY_PATH"]
        for envVar in suspiciousEnvVars {
            if let value = getenv(envVar), String(cString: value).isEmpty == false {
                isJailbroken = true
                failedChecks.append("suspicious_env")
                break
            }
        }

        // Check 6: Dynamic library injection
        let suspiciousLibraries = [
            "SubstrateLoader",
            "MobileSubstrate",
            "TweakInject",
            "libhooker",
            "substitute"
        ]

        for i in 0..<_dyld_image_count() {
            if let imageName = _dyld_get_image_name(i) {
                let name = String(cString: imageName)
                for lib in suspiciousLibraries {
                    if name.lowercased().contains(lib.lowercased()) {
                        isJailbroken = true
                        failedChecks.append("injected_library")
                        break
                    }
                }
            }
        }

        return isJailbroken
        #endif
    }

    // MARK: - Debugger Detection

    private func checkDebugger(_ failedChecks: inout [String]) -> Bool {
        #if DEBUG
        // Allow debugger in debug builds
        return false
        #else
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        if result == 0 {
            let isDebugged = (info.kp_proc.p_flag & P_TRACED) != 0
            if isDebugged {
                failedChecks.append("debugger_attached")
            }
            return isDebugged
        }

        return false
        #endif
    }

    // MARK: - Simulator Detection

    private func checkSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - App Attest

    /// Generates an App Attest key for device integrity verification
    /// - Returns: Key identifier if successful
    func generateAppAttestKey() async throws -> String? {
        guard DCAppAttestService.shared.isSupported else {
            logger.info("App Attest not supported on this device")
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            DCAppAttestService.shared.generateKey { keyId, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: keyId)
                }
            }
        }
    }

    /// Attests a key with Apple's servers
    /// - Parameters:
    ///   - keyId: The key identifier from generateAppAttestKey
    ///   - challenge: Server-provided challenge data
    /// - Returns: Attestation data to send to server for verification
    func attestKey(_ keyId: String, challenge: Data) async throws -> Data? {
        guard DCAppAttestService.shared.isSupported else {
            return nil
        }

        // Hash the challenge
        let hash = Data(SHA256.hash(data: challenge))

        return try await withCheckedThrowingContinuation { continuation in
            DCAppAttestService.shared.attestKey(keyId, clientDataHash: hash) { attestation, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: attestation)
                }
            }
        }
    }

    /// Generates an assertion for ongoing integrity verification
    /// - Parameters:
    ///   - keyId: The attested key identifier
    ///   - challenge: Server-provided challenge data
    /// - Returns: Assertion data to send to server
    func generateAssertion(_ keyId: String, challenge: Data) async throws -> Data? {
        guard DCAppAttestService.shared.isSupported else {
            return nil
        }

        let hash = Data(SHA256.hash(data: challenge))

        return try await withCheckedThrowingContinuation { continuation in
            DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: hash) { assertion, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: assertion)
                }
            }
        }
    }
}

// MARK: - UIApplication Extension for URL Scheme Check

#if canImport(UIKit)
import UIKit
#endif

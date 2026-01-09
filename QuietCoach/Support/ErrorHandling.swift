// ErrorHandling.swift
// QuietCoach
//
// Unified error handling system with user-friendly messages,
// recovery options, and proper logging.

import Foundation
import OSLog
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - App Error Protocol

/// Protocol for all app errors with user-facing presentation
protocol AppError: Error, LocalizedError {
    /// User-friendly title for the error
    var title: String { get }

    /// User-friendly description explaining what went wrong
    var message: String { get }

    /// Optional recovery suggestion
    var recoverySuggestion: String? { get }

    /// Whether the error is recoverable
    var isRecoverable: Bool { get }

    /// Recovery action if available
    var recoveryAction: ErrorRecoveryAction? { get }

    /// Log level for this error
    var logLevel: OSLogType { get }
}

extension AppError {
    var errorDescription: String? { message }
    var recoverySuggestion: String? { nil }
    var isRecoverable: Bool { recoveryAction != nil }
    var logLevel: OSLogType { .error }
}

// MARK: - Error Recovery Action

/// Possible recovery actions for errors
enum ErrorRecoveryAction: Sendable {
    case retry
    case openSettings
    case requestPermission
    case dismiss
    case contactSupport

    var buttonTitle: String {
        switch self {
        case .retry: return "Try Again"
        case .openSettings: return "Open Settings"
        case .requestPermission: return "Grant Permission"
        case .dismiss: return "OK"
        case .contactSupport: return "Get Help"
        }
    }
}

// MARK: - Recording Errors

enum RecordingError: AppError {
    case microphoneAccessDenied
    case microphoneAccessRestricted
    case audioSessionFailed(Error)
    case recordingInterrupted
    case recordingFailed(Error)
    case noAudioRecorded
    case saveFailed(Error)

    var title: String {
        switch self {
        case .microphoneAccessDenied, .microphoneAccessRestricted:
            return "Microphone Access Required"
        case .audioSessionFailed:
            return "Audio Setup Failed"
        case .recordingInterrupted:
            return "Recording Interrupted"
        case .recordingFailed:
            return "Recording Failed"
        case .noAudioRecorded:
            return "No Audio Recorded"
        case .saveFailed:
            return "Save Failed"
        }
    }

    var message: String {
        switch self {
        case .microphoneAccessDenied:
            return "QuietCoach needs microphone access to record your practice sessions."
        case .microphoneAccessRestricted:
            return "Microphone access is restricted on this device."
        case .audioSessionFailed(let error):
            return "Could not set up audio recording: \(error.localizedDescription)"
        case .recordingInterrupted:
            return "Your recording was interrupted by another app or a phone call."
        case .recordingFailed(let error):
            return "Recording could not be completed: \(error.localizedDescription)"
        case .noAudioRecorded:
            return "No audio was captured. Please check your microphone and try again."
        case .saveFailed:
            return "Your recording could not be saved. Please try again."
        }
    }

    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .microphoneAccessDenied:
            return .openSettings
        case .microphoneAccessRestricted:
            return .contactSupport
        case .audioSessionFailed, .recordingFailed, .saveFailed:
            return .retry
        case .recordingInterrupted:
            return .retry
        case .noAudioRecorded:
            return .retry
        }
    }

    var logLevel: OSLogType {
        switch self {
        case .microphoneAccessDenied, .microphoneAccessRestricted:
            return .info  // User action needed, not a bug
        case .recordingInterrupted:
            return .info  // External interruption
        default:
            return .error
        }
    }
}

// MARK: - Analysis Errors

enum AnalysisError: AppError {
    case speechRecognitionDenied
    case speechRecognizerUnavailable
    case transcriptionFailed(Error)
    case analysisTimeout
    case insufficientAudio
    case unknownError(Error)

    var title: String {
        switch self {
        case .speechRecognitionDenied:
            return "Speech Recognition Required"
        case .speechRecognizerUnavailable:
            return "Speech Recognition Unavailable"
        case .transcriptionFailed:
            return "Transcription Failed"
        case .analysisTimeout:
            return "Analysis Timeout"
        case .insufficientAudio:
            return "Audio Too Short"
        case .unknownError:
            return "Analysis Failed"
        }
    }

    var message: String {
        switch self {
        case .speechRecognitionDenied:
            return "Enable speech recognition for detailed feedback on your delivery."
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available. Audio-only feedback will be provided."
        case .transcriptionFailed:
            return "Could not transcribe your recording. Try speaking more clearly."
        case .analysisTimeout:
            return "Analysis is taking too long. Try a shorter recording."
        case .insufficientAudio:
            return "Your recording was too short for detailed analysis. Try speaking for at least 10 seconds."
        case .unknownError(let error):
            return "Analysis failed: \(error.localizedDescription)"
        }
    }

    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .speechRecognitionDenied:
            return .openSettings
        case .speechRecognizerUnavailable:
            return .dismiss
        case .transcriptionFailed, .analysisTimeout:
            return .retry
        case .insufficientAudio:
            return .retry
        case .unknownError:
            return .retry
        }
    }
}

// MARK: - Storage Errors

enum StorageError: AppError {
    case loadFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case insufficientSpace
    case fileNotFound
    case corruptedData

    var title: String {
        switch self {
        case .loadFailed:
            return "Could Not Load Data"
        case .saveFailed:
            return "Could Not Save"
        case .deleteFailed:
            return "Could Not Delete"
        case .insufficientSpace:
            return "Storage Full"
        case .fileNotFound:
            return "File Not Found"
        case .corruptedData:
            return "Data Error"
        }
    }

    var message: String {
        switch self {
        case .loadFailed:
            return "Your sessions could not be loaded. Some data may be missing."
        case .saveFailed:
            return "Your session could not be saved. Please try again."
        case .deleteFailed:
            return "The session could not be deleted. Please try again."
        case .insufficientSpace:
            return "Your device is running low on storage. Delete some recordings to free up space."
        case .fileNotFound:
            return "The recording file could not be found. It may have been deleted."
        case .corruptedData:
            return "Some session data appears to be corrupted and cannot be read."
        }
    }

    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .loadFailed, .saveFailed, .deleteFailed:
            return .retry
        case .insufficientSpace:
            return .openSettings
        case .fileNotFound:
            return .dismiss
        case .corruptedData:
            return .contactSupport
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: AppError {
    case purchaseFailed(Error)
    case purchaseCancelled
    case restoreFailed(Error)
    case noActiveSubscription
    case networkError

    var title: String {
        switch self {
        case .purchaseFailed:
            return "Purchase Failed"
        case .purchaseCancelled:
            return "Purchase Cancelled"
        case .restoreFailed:
            return "Restore Failed"
        case .noActiveSubscription:
            return "No Subscription Found"
        case .networkError:
            return "Network Error"
        }
    }

    var message: String {
        switch self {
        case .purchaseFailed(let error):
            return "Purchase could not be completed: \(error.localizedDescription)"
        case .purchaseCancelled:
            return "You cancelled the purchase. No charges were made."
        case .restoreFailed:
            return "Could not restore your purchases. Please check your internet connection."
        case .noActiveSubscription:
            return "No active subscription was found for your account."
        case .networkError:
            return "Could not connect to the App Store. Please check your internet connection."
        }
    }

    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .purchaseFailed, .restoreFailed, .networkError:
            return .retry
        case .purchaseCancelled, .noActiveSubscription:
            return .dismiss
        }
    }
}

// MARK: - Error Logger

/// Centralized error logging
@MainActor
final class ErrorLogger {
    static let shared = ErrorLogger()

    private let logger = Logger(subsystem: "com.quietcoach", category: "Errors")
    private var recentErrors: [LoggedError] = []
    private let maxRecentErrors = 50

    private init() {}

    /// Log an error
    func log(_ error: any AppError, file: String = #file, function: String = #function, line: Int = #line) {
        let context = ErrorContext(file: file, function: function, line: line)
        let logged = LoggedError(error: error, context: context, timestamp: Date())

        // Log to OSLog
        switch error.logLevel {
        case .debug:
            logger.debug("[\(context.shortLocation)] \(error.title): \(error.message)")
        case .info:
            logger.info("[\(context.shortLocation)] \(error.title): \(error.message)")
        case .error:
            logger.error("[\(context.shortLocation)] \(error.title): \(error.message)")
        case .fault:
            logger.fault("[\(context.shortLocation)] \(error.title): \(error.message)")
        default:
            logger.log("[\(context.shortLocation)] \(error.title): \(error.message)")
        }

        // Store recent errors for debugging
        recentErrors.append(logged)
        if recentErrors.count > maxRecentErrors {
            recentErrors.removeFirst()
        }
    }

    /// Log a generic error
    func logGeneric(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let context = ErrorContext(file: file, function: function, line: line)
        logger.error("[\(context.shortLocation)] Generic error: \(error.localizedDescription)")
    }

    /// Get recent errors for debugging
    var recent: [LoggedError] {
        recentErrors
    }
}

struct LoggedError: Identifiable {
    let id = UUID()
    let error: any AppError
    let context: ErrorContext
    let timestamp: Date
}

struct ErrorContext {
    let file: String
    let function: String
    let line: Int

    var shortLocation: String {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        return "\(filename):\(line)"
    }
}

// MARK: - Error Alert State

/// Observable error state for presenting alerts
@Observable
@MainActor
final class ErrorAlertState {
    var currentError: (any AppError)?
    var isPresented: Bool = false

    func show(_ error: any AppError) {
        ErrorLogger.shared.log(error)
        self.currentError = error
        self.isPresented = true
    }

    func dismiss() {
        self.isPresented = false
        self.currentError = nil
    }

    func performRecovery() async {
        guard let error = currentError, let action = error.recoveryAction else {
            dismiss()
            return
        }

        switch action {
        case .openSettings:
            #if os(iOS)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                await UIApplication.shared.open(url)
            }
            #endif
        case .retry:
            // Caller should handle retry
            break
        case .requestPermission:
            // Caller should handle permission request
            break
        case .contactSupport:
            // Could open email or support URL
            break
        case .dismiss:
            break
        }

        dismiss()
    }
}

// MARK: - SwiftUI Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Bindable var state: ErrorAlertState
    var onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                state.currentError?.title ?? "Error",
                isPresented: $state.isPresented,
                presenting: state.currentError
            ) { error in
                if let action = error.recoveryAction {
                    Button(action.buttonTitle) {
                        if action == .retry {
                            onRetry?()
                        } else {
                            Task {
                                await state.performRecovery()
                            }
                        }
                    }
                    if action != .dismiss {
                        Button("Cancel", role: .cancel) {
                            state.dismiss()
                        }
                    }
                } else {
                    Button("OK") {
                        state.dismiss()
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    func errorAlert(_ state: ErrorAlertState, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(state: state, onRetry: onRetry))
    }
}

// MARK: - Result Extension

extension Result where Failure: AppError {
    /// Log failure if present
    func logFailure(file: String = #file, function: String = #function, line: Int = #line) {
        if case .failure(let error) = self {
            Task { @MainActor in
                ErrorLogger.shared.log(error, file: file, function: function, line: line)
            }
        }
    }
}

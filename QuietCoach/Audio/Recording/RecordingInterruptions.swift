// RecordingInterruptions.swift
// QuietCoach
//
// Handling audio interruptions and route changes.

import AVFoundation

// MARK: - Recording Interruption Delegate

/// Delegate protocol for handling recording interruptions
@MainActor
protocol RecordingInterruptionDelegate: AnyObject {
    /// Called when recording is interrupted (phone call, Siri, etc.)
    func recordingWasInterrupted()

    /// Called when interruption ends
    func recordingInterruptionEnded(canResume: Bool)

    /// Called when audio route changes (device connected/disconnected)
    func audioRouteChanged(deviceLost: Bool)
}

// MARK: - Interruption Handling Extension

extension RehearsalRecorder {
    
    /// Handle audio session interruption
    func handleInterruption(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Phone call, Siri, etc.
            if state == .recording {
                pauseRecording()
                logger.info("Recording paused due to interruption")

                // Track for crash reporting context
                CrashReporting.shared.recordBreadcrumb(
                    "Recording interrupted",
                    category: .audio,
                    data: ["duration": String(format: "%.1f", currentTime)]
                )

                // Notify delegate
                interruptionDelegate?.recordingWasInterrupted()
            }

        case .ended:
            // Interruption ended - don't auto-resume, let user decide
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    logger.info("Interruption ended, can resume")
                    interruptionDelegate?.recordingInterruptionEnded(canResume: true)
                } else {
                    interruptionDelegate?.recordingInterruptionEnded(canResume: false)
                }
            }

        @unknown default:
            break
        }
    }

    /// Handle audio route change
    func handleRouteChange(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // AirPods disconnected, etc.
            if state == .recording {
                pauseRecording()
                logger.info("Recording paused due to route change (device unavailable)")

                CrashReporting.shared.recordBreadcrumb(
                    "Audio route changed - device unavailable",
                    category: .audio
                )

                interruptionDelegate?.audioRouteChanged(deviceLost: true)
            }

        case .newDeviceAvailable:
            logger.info("New audio device available")
            interruptionDelegate?.audioRouteChanged(deviceLost: false)

        default:
            break
        }
    }

    /// Handle memory warning during recording
    func handleMemoryWarning() {
        if state == .recording {
            // Save what we have and stop
            logger.warning("Memory warning during recording - saving current progress")
            _ = stopRecording()

            CrashReporting.shared.recordBreadcrumb(
                "Recording stopped due to memory warning",
                category: .audio,
                data: ["duration": String(format: "%.1f", currentTime)]
            )
        }
    }
}

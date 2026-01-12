// NotificationManager.swift
// QuietCoach
//
// Daily reminder notifications for gentle practice nudges.
// Respectful, optional, user-controlled.

import Foundation
import UserNotifications
import OSLog

@MainActor
@Observable
final class NotificationManager {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "NotificationManager")
    private let notificationCenter = UNUserNotificationCenter.current()

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isScheduled = false

    // MARK: - User Defaults Keys

    private enum Keys {
        static let remindersEnabled = "notifications.remindersEnabled"
        static let reminderHour = "notifications.reminderHour"
        static let reminderMinute = "notifications.reminderMinute"
    }

    // MARK: - Public Properties

    var remindersEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.remindersEnabled) }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.remindersEnabled)
            if newValue {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    var reminderTime: Date {
        get {
            let hour = UserDefaults.standard.integer(forKey: Keys.reminderHour)
            let minute = UserDefaults.standard.integer(forKey: Keys.reminderMinute)

            // Default to 9:00 AM if not set
            let effectiveHour = hour == 0 && minute == 0 ? 9 : hour

            var components = DateComponents()
            components.hour = effectiveHour
            components.minute = minute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            UserDefaults.standard.set(components.hour ?? 9, forKey: Keys.reminderHour)
            UserDefaults.standard.set(components.minute ?? 0, forKey: Keys.reminderMinute)

            if remindersEnabled {
                scheduleReminder()
            }
        }
    }

    // MARK: - Initialization

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            await checkAuthorizationStatus()

            if granted {
                logger.info("Notification authorization granted")
            } else {
                logger.info("Notification authorization denied")
            }

            return granted
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    var canScheduleNotifications: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    // MARK: - Scheduling

    func scheduleReminder() {
        guard canScheduleNotifications else {
            logger.warning("Cannot schedule reminder - not authorized")
            return
        }

        // Cancel existing reminder first
        cancelReminder()

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = notificationBody
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        // Schedule for the user's preferred time
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-practice-reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self?.logger.error("Failed to schedule reminder: \(error.localizedDescription)")
                    self?.isScheduled = false
                } else {
                    self?.logger.info("Daily reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
                    self?.isScheduled = true
                }
            }
        }
    }

    func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily-practice-reminder"])
        isScheduled = false
        logger.info("Daily reminder cancelled")
    }

    // MARK: - Notification Content

    private var notificationTitle: String {
        "Quick rehearsal?"
    }

    private var notificationBody: String {
        let messages = [
            "One minute of practice can change your whole day.",
            "Your voice is worth practicing.",
            "What conversation is on your mind today?",
            "Ready to rehearse something important?",
            "Small practice, big confidence."
        ]
        return messages.randomElement() ?? messages[0]
    }

    // MARK: - Testing (Debug)

    #if DEBUG
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = notificationBody
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { [weak self] error in
            if let error {
                self?.logger.error("Test notification failed: \(error.localizedDescription)")
            } else {
                self?.logger.debug("Test notification scheduled for 5 seconds")
            }
        }
    }
    #endif
}

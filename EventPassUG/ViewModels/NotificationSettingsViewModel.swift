//
//  NotificationSettingsViewModel.swift
//  EventPassUG
//
//  ViewModel for managing notification preferences and scheduling
//  Handles user notification settings and quiet hours
//

import Foundation
import UserNotifications

@MainActor
class NotificationSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var preferences: UserNotificationPreferences
    @Published var isSystemEnabled = false
    @Published var hasPermission = false

    @Published var showPermissionAlert = false
    @Published var errorMessage: String?

    // MARK: - Services

    private let notificationService = AppNotificationService.shared

    // MARK: - Initialization

    init(preferences: UserNotificationPreferences = .default) {
        self.preferences = preferences
        checkSystemStatus()
    }

    // MARK: - Permission Management

    /// Check system notification status
    func checkSystemStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            isSystemEnabled = settings.authorizationStatus == .authorized
            hasPermission = isSystemEnabled
        }
    }

    /// Request notification permission
    func requestPermission() async {
        do {
            let granted = try await notificationService.requestPermission()
            hasPermission = granted

            if !granted {
                showPermissionAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Open system settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Preference Updates

    /// Update master notification toggle
    func updateMasterToggle(_ enabled: Bool) {
        preferences.isEnabled = enabled
        savePreferences()
    }

    /// Update event reminder preferences
    func updateEventReminder24h(_ enabled: Bool) {
        preferences.eventReminders24h = enabled
        savePreferences()
    }

    func updateEventReminder2h(_ enabled: Bool) {
        preferences.eventReminders2h = enabled
        savePreferences()
    }

    func updateEventStartingSoon(_ enabled: Bool) {
        preferences.eventStartingSoon = enabled
        savePreferences()
    }

    /// Update other notification types
    func updateTicketPurchaseConfirmation(_ enabled: Bool) {
        preferences.ticketPurchaseConfirmation = enabled
        savePreferences()
    }

    func updateEventUpdates(_ enabled: Bool) {
        preferences.eventUpdates = enabled
        savePreferences()
    }

    func updateRecommendations(_ enabled: Bool) {
        preferences.recommendations = enabled
        savePreferences()
    }

    func updateMarketing(_ enabled: Bool) {
        preferences.marketing = enabled
        savePreferences()
    }

    /// Update quiet hours
    func updateQuietHoursEnabled(_ enabled: Bool) {
        preferences.quietHoursEnabled = enabled
        savePreferences()
    }

    func updateQuietHoursStart(hour: Int, minute: Int) {
        preferences.quietHoursStart = NotificationPreferences.QuietHourTime(hour: hour, minute: minute)
        savePreferences()
    }

    func updateQuietHoursEnd(hour: Int, minute: Int) {
        preferences.quietHoursEnd = NotificationPreferences.QuietHourTime(hour: hour, minute: minute)
        savePreferences()
    }

    // MARK: - Save

    /// Save preferences to backend
    private func savePreferences() {
        // In a real app, this would save to backend and update user model
        // For now, just update the published property
        objectWillChange.send()

        print("=� Notification preferences updated")
        print("  - Master toggle: \(preferences.isEnabled)")
        print("  - 24h reminders: \(preferences.eventReminders24h)")
        print("  - 2h reminders: \(preferences.eventReminders2h)")
        print("  - Starting soon: \(preferences.eventStartingSoon)")
        print("  - Recommendations: \(preferences.recommendations)")
        print("  - Quiet hours: \(preferences.quietHoursEnabled)")
    }

    // MARK: - Quiet Hours Helpers

    /// Check if currently in quiet hours
    var isInQuietHours: Bool {
        preferences.isInQuietHours()
    }

    /// Get formatted quiet hours range
    var quietHoursRange: String {
        "\(preferences.quietHoursStart.displayString) - \(preferences.quietHoursEnd.displayString)"
    }

    // MARK: - Notification Testing

    /// Schedule a test notification
    func scheduleTestNotification() async {
        do {
            let content = UNMutableNotificationContent()
            content.title = "Test Notification"
            content.body = "Your notification settings are working correctly!"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(
                identifier: "test_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            try await UNUserNotificationCenter.current().add(request)
        } catch {
            errorMessage = "Failed to schedule test notification: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Preference Sections

extension NotificationSettingsViewModel {
    /// Get all preference sections for UI
    var preferenceSections: [PreferenceSection] {
        [
            PreferenceSection(
                title: "Event Reminders",
                items: [
                    PreferenceItem(
                        title: "24 Hours Before",
                        description: "Get reminded one day before your events",
                        isEnabled: preferences.eventReminders24h,
                        action: updateEventReminder24h
                    ),
                    PreferenceItem(
                        title: "2 Hours Before",
                        description: "Get reminded 2 hours before your events",
                        isEnabled: preferences.eventReminders2h,
                        action: updateEventReminder2h
                    ),
                    PreferenceItem(
                        title: "Event Starting Soon",
                        description: "Get notified when your event is about to start",
                        isEnabled: preferences.eventStartingSoon,
                        action: updateEventStartingSoon
                    )
                ]
            ),
            PreferenceSection(
                title: "Event Updates",
                items: [
                    PreferenceItem(
                        title: "Ticket Confirmations",
                        description: "Receive confirmation when you purchase tickets",
                        isEnabled: preferences.ticketPurchaseConfirmation,
                        action: updateTicketPurchaseConfirmation
                    ),
                    PreferenceItem(
                        title: "Event Changes",
                        description: "Get notified about changes to your events",
                        isEnabled: preferences.eventUpdates,
                        action: updateEventUpdates
                    )
                ]
            ),
            PreferenceSection(
                title: "Discovery",
                items: [
                    PreferenceItem(
                        title: "Recommendations",
                        description: "Get personalized event recommendations",
                        isEnabled: preferences.recommendations,
                        action: updateRecommendations
                    ),
                    PreferenceItem(
                        title: "Marketing & Promotions",
                        description: "Receive news about special offers and events",
                        isEnabled: preferences.marketing,
                        action: updateMarketing
                    )
                ]
            )
        ]
    }
}

// MARK: - Supporting Types

struct PreferenceSection {
    let title: String
    let items: [PreferenceItem]
}

struct PreferenceItem {
    let title: String
    let description: String
    let isEnabled: Bool
    let action: (Bool) -> Void
}

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
        preferences.quietHoursStart = UserNotificationPreferences.QuietHourTime(hour: hour, minute: minute)
        savePreferences()
    }

    func updateQuietHoursEnd(hour: Int, minute: Int) {
        preferences.quietHoursEnd = UserNotificationPreferences.QuietHourTime(hour: hour, minute: minute)
        savePreferences()
    }

    // MARK: - Save

    /// Save preferences to backend
    private func savePreferences() {
        // In a real app, this would save to backend and update user model
        // For now, just update the published property
        objectWillChange.send()


//
//  AppNotificationService.swift
//  EventPassUG
//
//  Push notification service for event reminders, updates, and recommendations
//  Respects user preferences and quiet hours
//

import Foundation
import UserNotifications

// MARK: - Push Notification Type

enum PushNotificationType: String {
    case eventReminder24h = "event_reminder_24h"
    case eventReminder2h = "event_reminder_2h"
    case eventStartingSoon = "event_starting_soon"
    case ticketPurchase = "ticket_purchase"
    case eventUpdate = "event_update"
    case recommendation = "recommendation"
    case marketing = "marketing"

    var title: String {
        switch self {
        case .eventReminder24h:
            return "Event Tomorrow"
        case .eventReminder2h:
            return "Event Starting Soon"
        case .eventStartingSoon:
            return "Event Starting Now"
        case .ticketPurchase:
            return "Ticket Confirmed"
        case .eventUpdate:
            return "Event Update"
        case .recommendation:
            return "Events You Might Like"
        case .marketing:
            return "EventPass"
        }
    }

    var categoryIdentifier: String {
        "eventpass.\(rawValue)"
    }
}

// MARK: - Notification Service

@MainActor
class AppNotificationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = AppNotificationService()

    // MARK: - Published Properties

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled = false

    // MARK: - Private Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Permission Handling

    /// Request notification permission from user
    func requestPermission() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        let granted = try await notificationCenter.requestAuthorization(options: options)
        await checkAuthorizationStatus()

        return granted
    }

    /// Check current authorization status
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            authorizationStatus = settings.authorizationStatus
            isEnabled = settings.authorizationStatus == .authorized
        }
    }

    /// Check if notifications are enabled for a specific type
    func shouldSendNotification(userId: UUID, preferences: UserNotificationPreferences, type: PushNotificationType) -> Bool {
        // Check if notifications are globally enabled
        guard preferences.isEnabled, isEnabled else { return false }

        // Check quiet hours
        if preferences.isInQuietHours() {
            // Allow critical notifications during quiet hours
            switch type {
            case .ticketPurchase, .eventUpdate:
                break // Always allow
            default:
                return false // Block during quiet hours
            }
        }

        // Check type-specific preferences
        switch type {
        case .eventReminder24h:
            return preferences.eventReminders24h
        case .eventReminder2h:
            return preferences.eventReminders2h
        case .eventStartingSoon:
            return preferences.eventStartingSoon
        case .ticketPurchase:
            return preferences.ticketPurchaseConfirmation
        case .eventUpdate:
            return preferences.eventUpdates
        case .recommendation:
            return preferences.recommendations
        case .marketing:
            return preferences.marketing
        }
    }

    // MARK: - Event Reminders

    /// Schedule 24-hour reminder for an event
    func scheduleEventReminder24h(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws {
        guard shouldSendNotification(userId: userId, preferences: preferences, type: .eventReminder24h) else { return }

        let notificationDate = event.startDate.addingTimeInterval(-24 * 60 * 60)

        // Don't schedule if event is less than 24 hours away
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.eventReminder24h.title
        content.body = "\(event.title) starts tomorrow at \(formatTime(event.startDate))"
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.eventReminder24h.categoryIdentifier
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.eventReminder24h.rawValue
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )

        let identifier = "event_24h_\(event.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule 2-hour reminder for an event
    func scheduleEventReminder2h(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws {
        guard shouldSendNotification(userId: userId, preferences: preferences, type: .eventReminder2h) else { return }

        let notificationDate = event.startDate.addingTimeInterval(-2 * 60 * 60)

        // Don't schedule if event is less than 2 hours away
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.eventReminder2h.title
        content.body = "\(event.title) starts in 2 hours at \(event.venue.name)"
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.eventReminder2h.categoryIdentifier
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.eventReminder2h.rawValue
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )

        let identifier = "event_2h_\(event.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule starting soon notification (15 minutes before)
    func scheduleEventStartingSoon(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws {
        guard shouldSendNotification(userId: userId, preferences: preferences, type: .eventStartingSoon) else { return }

        let notificationDate = event.startDate.addingTimeInterval(-15 * 60)

        // Don't schedule if event is less than 15 minutes away
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.eventStartingSoon.title
        content.body = "\(event.title) is starting soon! Get ready to head to \(event.venue.name)"
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.eventStartingSoon.categoryIdentifier
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.eventStartingSoon.rawValue
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )

        let identifier = "event_starting_\(event.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule all reminders for an event
    func scheduleAllReminders(for event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws {
        try await scheduleEventReminder24h(event: event, userId: userId, preferences: preferences)
        try await scheduleEventReminder2h(event: event, userId: userId, preferences: preferences)
        try await scheduleEventStartingSoon(event: event, userId: userId, preferences: preferences)
    }

    /// Cancel all reminders for an event
    func cancelReminders(for eventId: UUID) {
        let identifiers = [
            "event_24h_\(eventId.uuidString)",
            "event_2h_\(eventId.uuidString)",
            "event_starting_\(eventId.uuidString)"
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Instant Notifications

    /// Send ticket purchase confirmation
    func sendTicketPurchaseConfirmation(event: Event, ticketType: TicketType, quantity: Int, userId: UUID, preferences: UserNotificationPreferences) async throws {
        guard shouldSendNotification(userId: userId, preferences: preferences, type: .ticketPurchase) else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.ticketPurchase.title
        content.body = "You purchased \(quantity) x \(ticketType.name) for \(event.title)"
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.ticketPurchase.categoryIdentifier
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.ticketPurchase.rawValue
        ]

        let identifier = "ticket_purchase_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)
    }

    /// Send event update notification
    func sendEventUpdate(event: Event, updateMessage: String, userId: UUID, preferences: UserNotificationPreferences) async throws {
        guard shouldSendNotification(userId: userId, preferences: preferences, type: .eventUpdate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(event.title) - Update"
        content.body = updateMessage
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.eventUpdate.categoryIdentifier
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.eventUpdate.rawValue
        ]

        let identifier = "event_update_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)
    }

    /// Send recommendation notification
    func sendRecommendation(events: [Event], userId: UUID, preferences: UserNotificationPreferences) async throws {
        guard shouldSendNotification(userId: userId, preferences: preferences, type: .recommendation) else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.recommendation.title

        if events.count == 1, let event = events.first {
            content.body = "\(event.title) - \(formatDate(event.startDate))"
        } else {
            content.body = "\(events.count) events happening near you this week"
        }

        content.sound = .default
        content.categoryIdentifier = PushNotificationType.recommendation.categoryIdentifier
        content.userInfo = [
            "type": PushNotificationType.recommendation.rawValue,
            "eventIds": events.map { $0.id.uuidString }
        ]

        let identifier = "recommendation_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)
    }

    // MARK: - Notification Management

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    /// Get delivered notifications
    func getDeliveredNotifications() async -> [UNNotification] {
        await notificationCenter.deliveredNotifications()
    }

    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Remove all delivered notifications
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppNotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            handleNotificationResponse(response)
            completionHandler()
        }
    }

    /// Handle notification response (deep linking)
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        // Extract event ID if present
        if let eventIdString = userInfo["eventId"] as? String,
           let eventId = UUID(uuidString: eventIdString) {
            // Navigate to event detail
            // In a real app, you'd use a deep linking coordinator or navigation manager
            print("= Navigate to event: \(eventId)")

            // Post notification for app coordinator to handle
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToEvent"),
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }

        // Handle different notification types
        if let typeString = userInfo["type"] as? String,
           let type = PushNotificationType(rawValue: typeString) {
            switch type {
            case .recommendation:
                // Navigate to discovery/recommendations
                print("= Navigate to recommendations")
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToRecommendations"), object: nil)

            case .ticketPurchase:
                // Navigate to tickets
                print("= Navigate to tickets")
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToTickets"), object: nil)

            default:
                break
            }
        }
    }
}

// MARK: - Notification Category Setup

extension AppNotificationService {
    /// Register notification categories and actions
    func registerNotificationCategories() {
        let categories: Set<UNNotificationCategory> = [
            // Event reminder category
            UNNotificationCategory(
                identifier: PushNotificationType.eventReminder24h.categoryIdentifier,
                actions: [
                    UNNotificationAction(identifier: "VIEW", title: "View Event", options: .foreground),
                    UNNotificationAction(identifier: "ADD_CALENDAR", title: "Add to Calendar", options: [])
                ],
                intentIdentifiers: [],
                options: []
            ),

            // Event starting soon category
            UNNotificationCategory(
                identifier: PushNotificationType.eventStartingSoon.categoryIdentifier,
                actions: [
                    UNNotificationAction(identifier: "VIEW", title: "View Event", options: .foreground),
                    UNNotificationAction(identifier: "DIRECTIONS", title: "Get Directions", options: .foreground)
                ],
                intentIdentifiers: [],
                options: []
            ),

            // Recommendation category
            UNNotificationCategory(
                identifier: PushNotificationType.recommendation.categoryIdentifier,
                actions: [
                    UNNotificationAction(identifier: "EXPLORE", title: "Explore", options: .foreground),
                    UNNotificationAction(identifier: "DISMISS", title: "Not Interested", options: [])
                ],
                intentIdentifiers: [],
                options: []
            )
        ]

        notificationCenter.setNotificationCategories(categories)
    }
}

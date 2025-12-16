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
    // Attendee notifications
    case eventReminder24h = "event_reminder_24h"
    case eventReminder2h = "event_reminder_2h"
    case eventReminder30m = "event_reminder_30m"
    case eventStartingSoon = "event_starting_soon"
    case ticketPurchase = "ticket_purchase"
    case eventUpdate = "event_update"
    case recommendation = "recommendation"
    case marketing = "marketing"

    // Organizer notifications
    case ticketSold = "ticket_sold"
    case lowTicketInventory = "low_ticket_inventory"
    case attendeeCheckIn = "attendee_check_in"
    case eventAboutToStartOrganizer = "event_about_to_start_organizer"

    var title: String {
        switch self {
        case .eventReminder24h:
            return "Event Tomorrow"
        case .eventReminder2h:
            return "Event in 2 Hours"
        case .eventReminder30m:
            return "Event in 30 Minutes"
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
        case .ticketSold:
            return "Ticket Sold!"
        case .lowTicketInventory:
            return "Low Ticket Inventory"
        case .attendeeCheckIn:
            return "Attendee Checked In"
        case .eventAboutToStartOrganizer:
            return "Your Event Starts Soon"
        }
    }

    var categoryIdentifier: String {
        "eventpass.\(rawValue)"
    }

    /// Interruption level for Focus Mode (iOS 15+)
    @available(iOS 15.0, *)
    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .eventReminder24h, .recommendation, .marketing:
            return .passive // Don't break through Focus
        case .eventReminder2h, .ticketPurchase, .ticketSold, .attendeeCheckIn:
            return .active // Standard notifications
        case .eventReminder30m, .eventStartingSoon, .eventUpdate, .lowTicketInventory, .eventAboutToStartOrganizer:
            return .timeSensitive // Break through Focus
        }
    }

    /// Relevance score for notification prioritization (iOS 15+)
    var relevanceScore: Double {
        switch self {
        case .eventStartingSoon, .eventAboutToStartOrganizer:
            return 1.0 // Highest priority
        case .eventReminder30m, .lowTicketInventory:
            return 0.9
        case .eventReminder2h, .ticketSold, .attendeeCheckIn:
            return 0.8
        case .ticketPurchase:
            return 0.7
        case .eventUpdate:
            return 0.6
        case .eventReminder24h:
            return 0.5
        case .recommendation:
            return 0.4
        case .marketing:
            return 0.3
        }
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
        checkAuthorizationStatus()

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
            case .ticketPurchase, .eventUpdate, .ticketSold, .attendeeCheckIn, .lowTicketInventory:
                break // Always allow critical notifications
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
        case .eventReminder30m:
            return preferences.eventReminders30m ?? true // Default to true for new preference
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
        case .ticketSold:
            return preferences.organizerTicketSold ?? true // Organizer notifications default to true
        case .lowTicketInventory:
            return preferences.organizerLowInventory ?? true
        case .attendeeCheckIn:
            return preferences.organizerCheckIns ?? true
        case .eventAboutToStartOrganizer:
            return preferences.organizerEventReminders ?? true
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

        // Apply Focus Mode settings
        applyFocusModeSettings(to: content, type: .eventReminder2h)

        // Add rich media if available
        await addEventImage(to: content, event: event)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )

        let identifier = "event_2h_\(event.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)

        // Track analytics
        trackNotificationScheduled(type: .eventReminder2h, eventId: event.id, userId: userId)
    }

    /// Schedule 30-minute reminder for an event
    func scheduleEventReminder30m(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws {
        guard shouldSendNotification(userId: userId, preferences: preferences, type: .eventReminder30m) else { return }

        let notificationDate = event.startDate.addingTimeInterval(-30 * 60)

        // Don't schedule if event is less than 30 minutes away
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.eventReminder30m.title
        content.body = "\(event.title) starts soon at \(event.venue.name). Time to get ready!"
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.eventReminder30m.categoryIdentifier
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.eventReminder30m.rawValue
        ]

        // Apply Focus Mode settings
        applyFocusModeSettings(to: content, type: .eventReminder30m)

        // Add rich media if available
        await addEventImage(to: content, event: event)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )

        let identifier = "event_30m_\(event.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)

        // Track analytics
        trackNotificationScheduled(type: .eventReminder30m, eventId: event.id, userId: userId)
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
        try await scheduleEventReminder30m(event: event, userId: userId, preferences: preferences)
        try await scheduleEventStartingSoon(event: event, userId: userId, preferences: preferences)
    }

    /// Cancel all reminders for an event
    func cancelReminders(for eventId: UUID) {
        let identifiers = [
            "event_24h_\(eventId.uuidString)",
            "event_2h_\(eventId.uuidString)",
            "event_30m_\(eventId.uuidString)",
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

        // Apply Focus Mode settings
        applyFocusModeSettings(to: content, type: .recommendation)

        let identifier = "recommendation_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)

        // Track analytics
        trackNotificationScheduled(type: .recommendation, eventId: events.first?.id, userId: userId)
    }

    // MARK: - Organizer Notifications

    /// Notify organizer when a ticket is sold
    func notifyOrganizerTicketSold(
        event: Event,
        ticketType: TicketType,
        quantity: Int,
        organizerId: UUID,
        preferences: UserNotificationPreferences
    ) async throws {
        guard shouldSendNotification(userId: organizerId, preferences: preferences, type: .ticketSold) else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.ticketSold.title
        content.body = "\(quantity) x \(ticketType.name) sold for \(event.title)"
        content.sound = .default
        content.badge = NSNumber(value: 1) // Increment badge
        content.categoryIdentifier = PushNotificationType.ticketSold.categoryIdentifier
        content.threadIdentifier = "organizer_\(organizerId.uuidString)"
        content.userInfo = [
            "eventId": event.id.uuidString,
            "ticketTypeId": ticketType.id.uuidString,
            "quantity": quantity,
            "type": PushNotificationType.ticketSold.rawValue
        ]

        // Apply Focus Mode settings
        applyFocusModeSettings(to: content, type: .ticketSold)

        // Add event image
        await addEventImage(to: content, event: event)

        let identifier = "ticket_sold_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)

        // Track analytics
        trackNotificationScheduled(type: .ticketSold, eventId: event.id, userId: organizerId)
    }

    /// Notify organizer when ticket inventory is low
    func notifyOrganizerLowInventory(
        event: Event,
        ticketType: TicketType,
        remainingCount: Int,
        organizerId: UUID,
        preferences: UserNotificationPreferences
    ) async throws {
        guard shouldSendNotification(userId: organizerId, preferences: preferences, type: .lowTicketInventory) else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.lowTicketInventory.title
        content.body = "Only \(remainingCount) \(ticketType.name) tickets left for \(event.title)"
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.lowTicketInventory.categoryIdentifier
        content.threadIdentifier = "organizer_\(organizerId.uuidString)"
        content.userInfo = [
            "eventId": event.id.uuidString,
            "ticketTypeId": ticketType.id.uuidString,
            "remainingCount": remainingCount,
            "type": PushNotificationType.lowTicketInventory.rawValue
        ]

        // Apply Focus Mode settings
        applyFocusModeSettings(to: content, type: .lowTicketInventory)

        let identifier = "low_inventory_\(event.id.uuidString)_\(ticketType.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)

        // Track analytics
        trackNotificationScheduled(type: .lowTicketInventory, eventId: event.id, userId: organizerId)
    }

    /// Notify organizer when an attendee checks in
    func notifyOrganizerCheckIn(
        event: Event,
        attendeeName: String,
        ticketType: TicketType,
        organizerId: UUID,
        preferences: UserNotificationPreferences
    ) async throws {
        guard shouldSendNotification(userId: organizerId, preferences: preferences, type: .attendeeCheckIn) else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.attendeeCheckIn.title
        content.body = "\(attendeeName) checked in with \(ticketType.name) ticket"
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.attendeeCheckIn.categoryIdentifier
        content.threadIdentifier = "event_\(event.id.uuidString)"
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.attendeeCheckIn.rawValue
        ]

        // Apply Focus Mode settings
        applyFocusModeSettings(to: content, type: .attendeeCheckIn)

        let identifier = "check_in_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)

        // Track analytics
        trackNotificationScheduled(type: .attendeeCheckIn, eventId: event.id, userId: organizerId)
    }

    /// Notify organizer when their event is about to start
    func notifyOrganizerEventStarting(
        event: Event,
        organizerId: UUID,
        preferences: UserNotificationPreferences
    ) async throws {
        guard shouldSendNotification(userId: organizerId, preferences: preferences, type: .eventAboutToStartOrganizer) else { return }

        let notificationDate = event.startDate.addingTimeInterval(-30 * 60) // 30 minutes before

        // Don't schedule if event is less than 30 minutes away
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = PushNotificationType.eventAboutToStartOrganizer.title
        content.body = "\(event.title) starts in 30 minutes. \(event.ticketTypes.reduce(0) { $0 + $1.sold }) attendees expected."
        content.sound = .default
        content.categoryIdentifier = PushNotificationType.eventAboutToStartOrganizer.categoryIdentifier
        content.threadIdentifier = "organizer_\(organizerId.uuidString)"
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": PushNotificationType.eventAboutToStartOrganizer.rawValue
        ]

        // Apply Focus Mode settings
        applyFocusModeSettings(to: content, type: .eventAboutToStartOrganizer)

        // Add event image
        await addEventImage(to: content, event: event)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )

        let identifier = "organizer_event_starting_\(event.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)

        // Track analytics
        trackNotificationScheduled(type: .eventAboutToStartOrganizer, eventId: event.id, userId: organizerId)
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

    /// Apply Focus Mode settings to notification content (iOS 15+)
    private func applyFocusModeSettings(to content: UNMutableNotificationContent, type: PushNotificationType) {
        if #available(iOS 15.0, *) {
            content.interruptionLevel = type.interruptionLevel
            content.relevanceScore = type.relevanceScore
        }
    }

    /// Add event poster image as rich media attachment
    private func addEventImage(to content: UNMutableNotificationContent, event: Event) async {
        guard let posterURL = event.posterURL,
              let url = URL(string: posterURL) else { return }

        do {
            // Download image data
            let (data, _) = try await URLSession.shared.data(from: url)

            // Save to temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let imageURL = tempDir.appendingPathComponent("\(event.id.uuidString).jpg")
            try data.write(to: imageURL)

            // Create attachment
            let attachment = try UNNotificationAttachment(
                identifier: "event_image",
                url: imageURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg"]
            )
            content.attachments = [attachment]
        } catch {
            print("⚠️ Failed to attach event image: \(error.localizedDescription)")
        }
    }

    /// Track notification scheduled event for analytics
    private func trackNotificationScheduled(type: PushNotificationType, eventId: UUID?, userId: UUID) {
        let analytics = NotificationAnalytics.shared
        analytics.trackNotificationScheduled(
            type: type.rawValue,
            eventId: eventId,
            userId: userId,
            timestamp: Date()
        )
    }

    /// Track notification delivered event for analytics
    private func trackNotificationDelivered(type: PushNotificationType, eventId: UUID?, userId: UUID) {
        let analytics = NotificationAnalytics.shared
        analytics.trackNotificationDelivered(
            type: type.rawValue,
            eventId: eventId,
            userId: userId,
            timestamp: Date()
        )
    }

    /// Track notification opened event for analytics
    private func trackNotificationOpened(type: PushNotificationType, eventId: UUID?, userId: UUID) {
        let analytics = NotificationAnalytics.shared
        analytics.trackNotificationOpened(
            type: type.rawValue,
            eventId: eventId,
            userId: userId,
            timestamp: Date()
        )
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

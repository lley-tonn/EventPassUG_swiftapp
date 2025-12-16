//
//  NotificationAnalytics.swift
//  EventPassUG
//
//  Notification analytics tracking service
//  Tracks notification engagement metrics for optimization
//

import Foundation

// MARK: - Notification Event

struct NotificationEvent: Codable, Identifiable {
    let id: UUID
    let type: String
    let action: NotificationAction
    let eventId: UUID?
    let userId: UUID
    let timestamp: Date

    enum NotificationAction: String, Codable {
        case scheduled
        case delivered
        case opened
        case dismissed
    }

    init(
        id: UUID = UUID(),
        type: String,
        action: NotificationAction,
        eventId: UUID?,
        userId: UUID,
        timestamp: Date
    ) {
        self.id = id
        self.type = type
        self.action = action
        self.eventId = eventId
        self.userId = userId
        self.timestamp = timestamp
    }
}

// MARK: - Notification Analytics

@MainActor
class NotificationAnalytics: ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationAnalytics()

    // MARK: - Published Properties

    @Published private(set) var events: [NotificationEvent] = []

    // MARK: - Private Properties

    private let maxStoredEvents = 1000 // Keep last 1000 events
    private let userDefaultsKey = "com.eventpassug.notificationAnalytics"

    // MARK: - Initialization

    private init() {
        loadEvents()
    }

    // MARK: - Tracking Methods

    /// Track when a notification is scheduled
    func trackNotificationScheduled(type: String, eventId: UUID?, userId: UUID, timestamp: Date) {
        let event = NotificationEvent(
            type: type,
            action: .scheduled,
            eventId: eventId,
            userId: userId,
            timestamp: timestamp
        )
        addEvent(event)
    }

    /// Track when a notification is delivered to the device
    func trackNotificationDelivered(type: String, eventId: UUID?, userId: UUID, timestamp: Date) {
        let event = NotificationEvent(
            type: type,
            action: .delivered,
            eventId: eventId,
            userId: userId,
            timestamp: timestamp
        )
        addEvent(event)
    }

    /// Track when a notification is opened by the user
    func trackNotificationOpened(type: String, eventId: UUID?, userId: UUID, timestamp: Date) {
        let event = NotificationEvent(
            type: type,
            action: .opened,
            eventId: eventId,
            userId: userId,
            timestamp: timestamp
        )
        addEvent(event)
    }

    /// Track when a notification is dismissed by the user
    func trackNotificationDismissed(type: String, eventId: UUID?, userId: UUID, timestamp: Date) {
        let event = NotificationEvent(
            type: type,
            action: .dismissed,
            eventId: eventId,
            userId: userId,
            timestamp: timestamp
        )
        addEvent(event)
    }

    // MARK: - Analytics Queries

    /// Get open rate for a specific notification type
    func getOpenRate(for type: String, in timeRange: TimeRange = .last7Days) -> Double {
        let filteredEvents = events.filter { event in
            event.type == type && timeRange.contains(event.timestamp)
        }

        let delivered = filteredEvents.filter { $0.action == .delivered }.count
        let opened = filteredEvents.filter { $0.action == .opened }.count

        guard delivered > 0 else { return 0 }
        return Double(opened) / Double(delivered)
    }

    /// Get delivery rate (scheduled vs delivered)
    func getDeliveryRate(for type: String, in timeRange: TimeRange = .last7Days) -> Double {
        let filteredEvents = events.filter { event in
            event.type == type && timeRange.contains(event.timestamp)
        }

        let scheduled = filteredEvents.filter { $0.action == .scheduled }.count
        let delivered = filteredEvents.filter { $0.action == .delivered }.count

        guard scheduled > 0 else { return 0 }
        return Double(delivered) / Double(scheduled)
    }

    /// Get total count of notifications by action
    func getCount(for action: NotificationEvent.NotificationAction, in timeRange: TimeRange = .last7Days) -> Int {
        events.filter { event in
            event.action == action && timeRange.contains(event.timestamp)
        }.count
    }

    /// Get engagement metrics for all notification types
    func getEngagementMetrics(in timeRange: TimeRange = .last7Days) -> [NotificationTypeMetrics] {
        let notificationTypes = Set(events.map { $0.type })

        return notificationTypes.map { type in
            let typeEvents = events.filter { $0.type == type && timeRange.contains($0.timestamp) }

            let scheduled = typeEvents.filter { $0.action == .scheduled }.count
            let delivered = typeEvents.filter { $0.action == .delivered }.count
            let opened = typeEvents.filter { $0.action == .opened }.count
            let dismissed = typeEvents.filter { $0.action == .dismissed }.count

            return NotificationTypeMetrics(
                type: type,
                scheduled: scheduled,
                delivered: delivered,
                opened: opened,
                dismissed: dismissed,
                openRate: delivered > 0 ? Double(opened) / Double(delivered) : 0,
                deliveryRate: scheduled > 0 ? Double(delivered) / Double(scheduled) : 0
            )
        }.sorted { $0.openRate > $1.openRate }
    }

    /// Get best performing notification time slots
    func getBestTimeSlots(in timeRange: TimeRange = .last7Days) -> [TimeSlotMetrics] {
        let openedEvents = events.filter { event in
            event.action == .opened && timeRange.contains(event.timestamp)
        }

        // Group by hour of day
        var timeSlots: [Int: Int] = [:]
        let calendar = Calendar.current

        for event in openedEvents {
            let hour = calendar.component(.hour, from: event.timestamp)
            timeSlots[hour, default: 0] += 1
        }

        return timeSlots.map { hour, count in
            TimeSlotMetrics(hour: hour, engagementCount: count)
        }.sorted { $0.engagementCount > $1.engagementCount }
    }

    /// Clear old events to optimize storage
    func clearOldEvents(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        events = events.filter { $0.timestamp > cutoffDate }
        saveEvents()
    }

    // MARK: - Persistence

    private func addEvent(_ event: NotificationEvent) {
        events.append(event)

        // Keep only the most recent events
        if events.count > maxStoredEvents {
            events = Array(events.suffix(maxStoredEvents))
        }

        saveEvents()
    }

    private func saveEvents() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(events)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("⚠️ Failed to save notification analytics: \(error)")
        }
    }

    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }

        do {
            let decoder = JSONDecoder()
            events = try decoder.decode([NotificationEvent].self, from: data)
        } catch {
            print("⚠️ Failed to load notification analytics: \(error)")
            events = []
        }
    }

    /// Export analytics data for backend sync
    func exportAnalytics() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(events)
        } catch {
            print("⚠️ Failed to export analytics: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

enum TimeRange {
    case last24Hours
    case last7Days
    case last30Days
    case custom(from: Date, to: Date)

    func contains(_ date: Date) -> Bool {
        let now = Date()
        let calendar = Calendar.current

        switch self {
        case .last24Hours:
            let cutoff = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
            return date > cutoff
        case .last7Days:
            let cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return date > cutoff
        case .last30Days:
            let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return date > cutoff
        case .custom(let from, let to):
            return date >= from && date <= to
        }
    }
}

struct NotificationTypeMetrics {
    let type: String
    let scheduled: Int
    let delivered: Int
    let opened: Int
    let dismissed: Int
    let openRate: Double
    let deliveryRate: Double

    var formattedOpenRate: String {
        String(format: "%.1f%%", openRate * 100)
    }

    var formattedDeliveryRate: String {
        String(format: "%.1f%%", deliveryRate * 100)
    }
}

struct TimeSlotMetrics {
    let hour: Int
    let engagementCount: Int

    var timeRangeDisplay: String {
        let nextHour = (hour + 1) % 24
        return String(format: "%02d:00-%02d:00", hour, nextHour)
    }
}

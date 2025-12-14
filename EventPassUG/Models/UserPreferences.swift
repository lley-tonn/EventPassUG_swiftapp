//
//  UserPreferences.swift
//  EventPassUG
//
//  Supporting types for user personalization and preferences
//

import Foundation
import CoreLocation

// MARK: - User Location

/// User's location for proximity-based recommendations
/// Stores approximate location, not precise tracking
struct UserLocation: Codable, Equatable {
    let city: String
    let country: String
    let coordinate: LocationCoordinate
    let lastUpdated: Date

    struct LocationCoordinate: Codable, Equatable {
        let latitude: Double
        let longitude: Double

        var clLocation: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }

        init(clCoordinate: CLLocationCoordinate2D) {
            self.latitude = clCoordinate.latitude
            self.longitude = clCoordinate.longitude
        }
    }

    /// Distance to another location in kilometers
    func distance(to other: UserLocation) -> Double {
        let location1 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let location2 = CLLocation(latitude: other.coordinate.latitude, longitude: other.coordinate.longitude)
        return location1.distance(from: location2) / 1000 // Convert meters to kilometers
    }
}

// MARK: - User Notification Preferences

/// User's notification settings for personalization system
struct UserNotificationPreferences: Codable, Equatable {
    var isEnabled: Bool
    var eventReminders24h: Bool // Reminder 24 hours before event
    var eventReminders2h: Bool // Reminder 2 hours before event
    var eventStartingSoon: Bool // Notification when event is starting
    var ticketPurchaseConfirmation: Bool
    var eventUpdates: Bool // Organizer updates to events user has tickets for
    var recommendations: Bool // Personalized event recommendations
    var marketing: Bool // Marketing and promotional notifications
    var quietHoursEnabled: Bool
    var quietHoursStart: QuietHourTime
    var quietHoursEnd: QuietHourTime

    struct QuietHourTime: Codable, Equatable {
        let hour: Int // 0-23
        let minute: Int // 0-59

        var displayString: String {
            String(format: "%02d:%02d", hour, minute)
        }

        static let defaultStart = QuietHourTime(hour: 22, minute: 0) // 10 PM
        static let defaultEnd = QuietHourTime(hour: 8, minute: 0) // 8 AM
    }

    /// Check if current time is within quiet hours
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }

        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)

        guard let currentHour = currentComponents.hour,
              let currentMinute = currentComponents.minute else {
            return false
        }

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = quietHoursStart.hour * 60 + quietHoursStart.minute
        let endMinutes = quietHoursEnd.hour * 60 + quietHoursEnd.minute

        // Handle overnight quiet hours (e.g., 22:00 to 08:00)
        if startMinutes > endMinutes {
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }

    /// Default notification preferences (opt-in for important, opt-out for marketing)
    static let `default` = UserNotificationPreferences(
        isEnabled: true,
        eventReminders24h: true,
        eventReminders2h: true,
        eventStartingSoon: true,
        ticketPurchaseConfirmation: true,
        eventUpdates: true,
        recommendations: false, // Opt-in for recommendations
        marketing: false, // Opt-in for marketing
        quietHoursEnabled: true,
        quietHoursStart: .defaultStart,
        quietHoursEnd: .defaultEnd
    )
}

// MARK: - User Interaction Type

/// Types of user interactions with events for recommendation engine
enum UserInteractionType: String, Codable {
    case view = "view"
    case like = "like"
    case purchase = "purchase"
    case favorite = "favorite"
    case share = "share"

    /// Weight for recommendation scoring
    var weight: Double {
        switch self {
        case .view: return 1.0
        case .like: return 3.0
        case .favorite: return 3.0
        case .share: return 2.0
        case .purchase: return 5.0
        }
    }
}

// MARK: - User Interaction Record

/// Track user interactions with events
struct UserInteraction: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let eventId: UUID
    let type: UserInteractionType
    let timestamp: Date
    let category: EventCategory?

    init(
        id: UUID = UUID(),
        userId: UUID,
        eventId: UUID,
        type: UserInteractionType,
        timestamp: Date = Date(),
        category: EventCategory? = nil
    ) {
        self.id = id
        self.userId = userId
        self.eventId = eventId
        self.type = type
        self.timestamp = timestamp
        self.category = category
    }
}

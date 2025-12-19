//
//  UserInterests.swift
//  EventPassUG
//
//  User interests model for personalized event recommendations
//

import Foundation

// MARK: - User Interests Profile

/// Comprehensive user interest profile for personalized recommendations
/// All fields are optional to support gradual onboarding and privacy
struct UserInterests: Codable, Equatable {
    // MARK: - Category Preferences

    /// Event categories the user is interested in
    /// Explicitly selected during onboarding or settings
    var preferredCategories: [EventCategory]

    /// Categories inferred from user behavior (views, likes, purchases)
    /// Lower priority than explicit preferences
    var inferredCategories: [EventCategory]

    // MARK: - Location Preferences

    /// Preferred cities for events
    /// User may be interested in events outside their current location
    var preferredCities: [String]

    /// Maximum distance willing to travel (in kilometers)
    /// nil = no preference, show all
    var maxTravelDistance: Double?

    // MARK: - Event Type Preferences

    /// Preferred event types (free-form strings for flexibility)
    /// Examples: "Concerts", "Workshops", "Meetups", "Parties", "Conferences"
    var preferredEventTypes: [String]

    // MARK: - Price Preferences

    /// Price range preference
    var pricePreference: PricePreference?

    /// Interest in free events specifically
    var prefersFreeEvents: Bool

    // MARK: - Temporal Preferences

    /// Preferred days of week (0 = Sunday, 6 = Saturday)
    var preferredDaysOfWeek: [Int]

    /// Preferred time of day for events
    var preferredTimeOfDay: [TimeOfDayPreference]

    // MARK: - Social Preferences

    /// IDs of organizers the user follows/trusts
    var followedOrganizerIds: [UUID]

    /// Interest in popular events (high attendance)
    var prefersPopularEvents: Bool

    // MARK: - Behavior-Based Data

    /// Categories from events user has purchased tickets for
    /// Strongest signal for preferences
    var purchasedEventCategories: [EventCategory: Int] // Category -> count

    /// Categories from events user has liked
    var likedEventCategories: [EventCategory: Int] // Category -> count

    /// Categories from events user has viewed
    var viewedEventCategories: [EventCategory: Int] // Category -> count

    // MARK: - Metadata

    /// When interests were last updated (auto or manual)
    var lastUpdated: Date

    /// Confidence score for recommendations (0.0 - 1.0)
    /// Based on how much data we have about the user
    var confidenceScore: Double {
        var score = 0.0

        // Explicit preferences (highest weight)
        if !preferredCategories.isEmpty { score += 0.3 }
        if !preferredCities.isEmpty { score += 0.1 }
        if maxTravelDistance != nil { score += 0.05 }

        // Behavioral data (strong signal)
        if !purchasedEventCategories.isEmpty { score += 0.25 }
        if !likedEventCategories.isEmpty { score += 0.15 }
        if !viewedEventCategories.isEmpty { score += 0.10 }

        // Social data
        if !followedOrganizerIds.isEmpty { score += 0.05 }

        return min(score, 1.0)
    }

    /// Check if user is a new user with minimal preference data
    var isNewUser: Bool {
        preferredCategories.isEmpty &&
        purchasedEventCategories.isEmpty &&
        likedEventCategories.isEmpty &&
        viewedEventCategories.count < 5
    }

    // MARK: - Initialization

    init(
        preferredCategories: [EventCategory] = [],
        inferredCategories: [EventCategory] = [],
        preferredCities: [String] = [],
        maxTravelDistance: Double? = nil,
        preferredEventTypes: [String] = [],
        pricePreference: PricePreference? = nil,
        prefersFreeEvents: Bool = false,
        preferredDaysOfWeek: [Int] = [],
        preferredTimeOfDay: [TimeOfDayPreference] = [],
        followedOrganizerIds: [UUID] = [],
        prefersPopularEvents: Bool = false,
        purchasedEventCategories: [EventCategory: Int] = [:],
        likedEventCategories: [EventCategory: Int] = [:],
        viewedEventCategories: [EventCategory: Int] = [:],
        lastUpdated: Date = Date()
    ) {
        self.preferredCategories = preferredCategories
        self.inferredCategories = inferredCategories
        self.preferredCities = preferredCities
        self.maxTravelDistance = maxTravelDistance
        self.preferredEventTypes = preferredEventTypes
        self.pricePreference = pricePreference
        self.prefersFreeEvents = prefersFreeEvents
        self.preferredDaysOfWeek = preferredDaysOfWeek
        self.preferredTimeOfDay = preferredTimeOfDay
        self.followedOrganizerIds = followedOrganizerIds
        self.prefersPopularEvents = prefersPopularEvents
        self.purchasedEventCategories = purchasedEventCategories
        self.likedEventCategories = likedEventCategories
        self.viewedEventCategories = viewedEventCategories
        self.lastUpdated = lastUpdated
    }

    /// Default interests for new users
    static let `default` = UserInterests()
}

// MARK: - Price Preference

enum PricePreference: String, Codable, CaseIterable {
    case free = "Free Only"
    case budget = "Budget-Friendly" // Under 50,000 UGX
    case moderate = "Moderate" // 50,000 - 150,000 UGX
    case premium = "Premium" // 150,000+ UGX
    case any = "Any Price"

    var priceRange: ClosedRange<Double>? {
        switch self {
        case .free: return 0...0
        case .budget: return 0...50_000
        case .moderate: return 50_000...150_000
        case .premium: return 150_000...Double.infinity
        case .any: return nil
        }
    }
}

// MARK: - Time of Day Preference

enum TimeOfDayPreference: String, Codable, CaseIterable {
    case morning = "Morning" // 6 AM - 12 PM
    case afternoon = "Afternoon" // 12 PM - 5 PM
    case evening = "Evening" // 5 PM - 9 PM
    case night = "Night" // 9 PM - 6 AM

    var hourRange: ClosedRange<Int> {
        switch self {
        case .morning: return 6...11
        case .afternoon: return 12...16
        case .evening: return 17...20
        case .night: return 21...5 // Wraps around midnight
        }
    }

    func matches(hour: Int) -> Bool {
        let range = hourRange
        if range.lowerBound > range.upperBound {
            // Handle overnight range (night: 21-5)
            return hour >= range.lowerBound || hour <= range.upperBound
        } else {
            return range.contains(hour)
        }
    }
}

// MARK: - User Interests Update Methods

extension UserInterests {
    /// Update interests based on viewing an event
    mutating func recordEventView(category: EventCategory) {
        viewedEventCategories[category, default: 0] += 1
        lastUpdated = Date()
    }

    /// Update interests based on liking an event
    mutating func recordEventLike(category: EventCategory) {
        likedEventCategories[category, default: 0] += 1
        lastUpdated = Date()
    }

    /// Update interests based on purchasing tickets
    mutating func recordEventPurchase(category: EventCategory) {
        purchasedEventCategories[category, default: 0] += 1
        lastUpdated = Date()
    }

    /// Get top N categories based on user behavior
    func getTopCategories(limit: Int = 5) -> [EventCategory] {
        var categoryScores: [EventCategory: Double] = [:]

        // Weight purchases highest
        for (category, count) in purchasedEventCategories {
            categoryScores[category, default: 0] += Double(count) * 5.0
        }

        // Weight likes medium
        for (category, count) in likedEventCategories {
            categoryScores[category, default: 0] += Double(count) * 3.0
        }

        // Weight views lowest
        for (category, count) in viewedEventCategories {
            categoryScores[category, default: 0] += Double(count) * 1.0
        }

        // Sort by score and return top N
        return categoryScores
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
}

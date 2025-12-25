//
//  RecommendationService.swift
//  EventPassUG
//
//  Enhanced personalized event recommendation engine
//  Uses deterministic multi-factor scoring: interests, location, behavior, popularity, time
//

import Foundation
import CoreLocation

// MARK: - Recommendation Category

enum RecommendationCategory: String, CaseIterable {
    case forYou = "Recommended for You"
    case basedOnInterests = "Based on Your Interests"
    case nearYou = "Events Near You"
    case popularNow = "Popular Right Now"
    case happeningNow = "Happening Now"
    case freeEvents = "Free Events"
    case thisWeekend = "This Weekend"

    var icon: String {
        switch self {
        case .forYou: return "star.fill"
        case .basedOnInterests: return "heart.fill"
        case .nearYou: return "location.fill"
        case .popularNow: return "flame.fill"
        case .happeningNow: return "clock.fill"
        case .freeEvents: return "gift.fill"
        case .thisWeekend: return "calendar.badge.clock"
        }
    }
}

// MARK: - Scored Event

/// Event with recommendation score and reasoning
struct ScoredEvent: Identifiable {
    let event: Event
    let score: Double
    let reasons: [String]

    var id: UUID { event.id }

    var primaryReason: String {
        reasons.first ?? "Popular event"
    }
}

// MARK: - Recommendation Service Protocol

@MainActor
protocol RecommendationServiceProtocol {
    /// Get personalized event recommendations for a user
    func getRecommendedEvents(
        for user: User,
        from events: [Event],
        limit: Int?
    ) async -> [ScoredEvent]

    /// Get events by specific recommendation category
    func getEventsByCategory(
        for user: User,
        from events: [Event],
        category: RecommendationCategory,
        limit: Int
    ) async -> [Event]

    /// Update user interests based on interaction
    func recordInteraction(
        user: inout User,
        event: Event,
        type: UserInteractionType
    )

    /// Get explanation for why an event was recommended
    func getRecommendationReason(
        event: Event,
        user: User
    ) -> String
}

// MARK: - Recommendation Service Implementation

@MainActor
class RecommendationService: ObservableObject, RecommendationServiceProtocol {
    // MARK: - Singleton

    static let shared = RecommendationService()

    // MARK: - Published Properties

    @Published var recommendations: [ScoredEvent] = []
    @Published var isLoading = false

    // MARK: - Scoring Weights (Tunable for A/B testing)

    private struct Weights {
        // Category matching
        static let categoryExactMatch: Double = 40.0
        static let categoryPurchaseHistory: Double = 35.0
        static let categoryLikeHistory: Double = 25.0
        static let categoryViewHistory: Double = 10.0

        // Location proximity
        static let sameCity: Double = 20.0
        static let nearbyEvent: Double = 15.0 // Within max travel distance
        static let farEvent: Double = -10.0 // Outside max distance

        // Social signals
        static let followedOrganizer: Double = 30.0
        static let popularEvent: Double = 10.0 // High ticket sales ratio

        // Temporal signals
        static let happeningNow: Double = 25.0
        static let upcomingSoon: Double = 15.0 // Within 7 days
        static let thisWeekend: Double = 10.0

        // User behavior signals
        static let similarEventPurchased: Double = 15.0
        static let similarEventLiked: Double = 10.0

        // Price preference
        static let priceMatch: Double = 8.0
        static let freeEvent: Double = 5.0 // Bonus for free events

        // Event quality
        static let highRating: Double = 5.0 // Rating >= 4.0
        static let wellReviewed: Double = 3.0 // Many ratings

        // Recency bonus
        static let recentlyAdded: Double = 5.0 // Created in last 7 days
    }

    private init() {}

    // MARK: - Main Recommendation Method

    func getRecommendedEvents(
        for user: User,
        from events: [Event],
        limit: Int? = nil
    ) async -> [ScoredEvent] {
        isLoading = true
        defer { isLoading = false }

        // Filter out past events and drafts
        let upcomingEvents = events.filter { $0.endDate >= Date() && $0.status == .published }

        // Score all events
        let scoredEvents = upcomingEvents.map { event in
            let (score, reasons) = calculateScore(for: event, user: user)
            return ScoredEvent(event: event, score: score, reasons: reasons)
        }

        // Sort by score descending
        let sorted = scoredEvents.sorted { $0.score > $1.score }

        // Apply limit if specified
        if let limit = limit {
            recommendations = Array(sorted.prefix(limit))
            return recommendations
        }

        recommendations = sorted
        return sorted
    }

    // MARK: - Category-Specific Recommendations

    func getEventsByCategory(
        for user: User,
        from events: [Event],
        category: RecommendationCategory,
        limit: Int = 10
    ) async -> [Event] {
        let upcomingEvents = events.filter { $0.endDate >= Date() && $0.status == .published }

        switch category {
        case .forYou:
            let scored = await getRecommendedEvents(for: user, from: upcomingEvents, limit: limit)
            return scored.map { $0.event }

        case .basedOnInterests:
            return await getInterestBasedEvents(for: user, from: upcomingEvents, limit: limit)

        case .nearYou:
            return await getNearbyEvents(for: user, from: upcomingEvents, limit: limit)

        case .popularNow:
            return getPopularEvents(from: upcomingEvents, limit: limit)

        case .happeningNow:
            return getHappeningNowEvents(from: upcomingEvents, limit: limit)

        case .freeEvents:
            return getFreeEvents(from: upcomingEvents, limit: limit)

        case .thisWeekend:
            return getWeekendEvents(from: upcomingEvents, limit: limit)
        }
    }

    // MARK: - Interaction Recording

    func recordInteraction(
        user: inout User,
        event: Event,
        type: UserInteractionType
    ) {
        // Update user interaction arrays
        switch type {
        case .view:
            if !user.viewedEventIds.contains(event.id) {
                user.viewedEventIds.append(event.id)
            }
            user.interests.recordEventView(category: event.category)

        case .like, .favorite:
            if !user.likedEventIds.contains(event.id) {
                user.likedEventIds.append(event.id)
            }
            user.interests.recordEventLike(category: event.category)

        case .purchase:
            if !user.purchasedEventIds.contains(event.id) {
                user.purchasedEventIds.append(event.id)
            }
            user.interests.recordEventPurchase(category: event.category)

        case .share:
            // Share is a weaker signal, just update interests
            user.interests.recordEventView(category: event.category)
        }
    }

    // MARK: - Recommendation Explanation

    func getRecommendationReason(event: Event, user: User) -> String {
        let (_, reasons) = calculateScore(for: event, user: user)

        if reasons.isEmpty {
            return "This event might interest you"
        }

        // Return the top reason
        return reasons.first ?? "Popular event"
    }

    // MARK: - Private Scoring Logic

    private func calculateScore(
        for event: Event,
        user: User
    ) -> (score: Double, reasons: [String]) {
        var score: Double = 0.0
        var reasons: [String] = []

        // 1. Category Matching
        let categoryScore = calculateCategoryScore(event: event, user: user, reasons: &reasons)
        score += categoryScore

        // 2. Location Proximity
        let locationScore = calculateLocationScore(event: event, user: user, reasons: &reasons)
        score += locationScore

        // 3. Social Signals
        let socialScore = calculateSocialScore(event: event, user: user, reasons: &reasons)
        score += socialScore

        // 4. Temporal Signals
        let temporalScore = calculateTemporalScore(event: event, user: user, reasons: &reasons)
        score += temporalScore

        // 5. Price Preference
        let priceScore = calculatePriceScore(event: event, user: user, reasons: &reasons)
        score += priceScore

        // 6. Event Quality
        let qualityScore = calculateQualityScore(event: event, reasons: &reasons)
        score += qualityScore

        // 7. Recency Bonus
        let recencyScore = calculateRecencyScore(event: event, reasons: &reasons)
        score += recencyScore

        return (score, reasons)
    }

    // MARK: - Individual Scoring Components

    private func calculateCategoryScore(
        event: Event,
        user: User,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0.0

        // Exact match with preferred categories
        if user.interests.preferredCategories.contains(event.category) {
            score += Weights.categoryExactMatch
            reasons.append("Matches your \(event.category.rawValue) interests")
        }

        // Match with purchase history
        if let count = user.interests.purchasedEventCategories[event.category], count > 0 {
            score += Weights.categoryPurchaseHistory * min(Double(count), 3.0) / 3.0
            reasons.append("Similar to events you've attended")
        }

        // Match with like history
        if let count = user.interests.likedEventCategories[event.category], count > 0 {
            score += Weights.categoryLikeHistory * min(Double(count), 3.0) / 3.0
            if reasons.count < 3 {
                reasons.append("Based on events you liked")
            }
        }

        // Match with view history (weaker signal)
        if let count = user.interests.viewedEventCategories[event.category], count >= 3 {
            score += Weights.categoryViewHistory
        }

        return score
    }

    private func calculateLocationScore(
        event: Event,
        user: User,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0.0

        // Same city
        if let userCity = user.city, event.venue.city.localizedCaseInsensitiveCompare(userCity) == .orderedSame {
            score += Weights.sameCity
            reasons.append("In \(event.venue.city)")
        }

        // Distance-based scoring if location is available
        if let userLocation = user.location, user.allowLocationTracking {
            let eventLocation = UserLocation(
                city: event.venue.city,
                country: event.venue.address,
                coordinate: UserLocation.LocationCoordinate(
                    latitude: event.venue.coordinate.latitude,
                    longitude: event.venue.coordinate.longitude
                ),
                lastUpdated: Date()
            )

            let distance = userLocation.distance(to: eventLocation)

            if let maxDistance = user.interests.maxTravelDistance {
                if distance <= maxDistance {
                    score += Weights.nearbyEvent
                    if reasons.count < 3 {
                        reasons.append("Only \(Int(distance))km away")
                    }
                } else {
                    score += Weights.farEvent
                }
            } else if distance <= 20 { // Default 20km
                score += Weights.nearbyEvent
            }
        }

        return score
    }

    private func calculateSocialScore(
        event: Event,
        user: User,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0.0

        // Followed organizer
        if user.followedOrganizerIds.contains(event.organizerId) {
            score += Weights.followedOrganizer
            reasons.append("From \(event.organizerName) (organizer you follow)")
        }

        // Popular event (high ticket sales ratio)
        let totalTickets = event.ticketTypes.reduce(0) { $0 + $1.quantity }
        let soldTickets = event.ticketTypes.reduce(0) { $0 + $1.sold }

        if totalTickets > 0 {
            let salesRatio = Double(soldTickets) / Double(totalTickets)
            if salesRatio >= 0.7 {
                score += Weights.popularEvent
                if reasons.count < 3 {
                    reasons.append("Popular event (\(Int(salesRatio * 100))% sold)")
                }
            }
        }

        return score
    }

    private func calculateTemporalScore(
        event: Event,
        user: User,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0.0
        let now = Date()
        let calendar = Calendar.current

        // Happening now
        if event.isHappeningNow {
            score += Weights.happeningNow
            reasons.append("Happening right now!")
        }

        // Coming soon (within 7 days)
        if let daysUntil = calendar.dateComponents([.day], from: now, to: event.startDate).day,
           daysUntil >= 0 && daysUntil <= 7 {
            score += Weights.upcomingSoon
            if reasons.count < 3 {
                if daysUntil == 0 {
                    reasons.append("Today")
                } else if daysUntil == 1 {
                    reasons.append("Tomorrow")
                } else {
                    reasons.append("In \(daysUntil) days")
                }
            }
        }

        // This weekend
        let eventWeekday = calendar.component(.weekday, from: event.startDate)
        if (eventWeekday == 7 || eventWeekday == 1) { // Saturday or Sunday
            if let daysUntil = calendar.dateComponents([.day], from: now, to: event.startDate).day,
               daysUntil >= 0 && daysUntil <= 7 {
                score += Weights.thisWeekend
            }
        }

        return score
    }

    private func calculatePriceScore(
        event: Event,
        user: User,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0.0

        let minPrice = event.ticketTypes.map { $0.price }.min() ?? 0

        // Free event
        if minPrice == 0 {
            if user.interests.prefersFreeEvents {
                score += Weights.priceMatch
                reasons.append("Free event")
            } else {
                score += Weights.freeEvent
            }
        }

        // Price preference match
        if let pricePreference = user.interests.pricePreference {
            if let range = pricePreference.priceRange {
                if range.contains(minPrice) {
                    score += Weights.priceMatch
                    if reasons.count < 3 && pricePreference != .any {
                        reasons.append("Matches your price preference")
                    }
                }
            }
        }

        return score
    }

    private func calculateQualityScore(
        event: Event,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0.0

        // High rating
        if event.rating >= 4.0 {
            score += Weights.highRating
            if event.totalRatings >= 20 {
                score += Weights.wellReviewed
                if reasons.count < 3 {
                    reasons.append("Highly rated (\(String(format: "%.1f", event.rating))⭐)")
                }
            }
        }

        return score
    }

    private func calculateRecencyScore(
        event: Event,
        reasons: inout [String]
    ) -> Double {
        let now = Date()
        let daysSinceCreated = Calendar.current.dateComponents([.day], from: event.createdAt, to: now).day ?? 0

        if daysSinceCreated <= 7 {
            return Weights.recentlyAdded
        }

        return 0.0
    }

    // MARK: - Category-Specific Helpers

    func getInterestBasedEvents(
        for user: User,
        from events: [Event],
        limit: Int
    ) async -> [Event] {
        let topCategories = user.interests.getTopCategories(limit: 5)

        // If no behavioral data, use preferred categories
        let relevantCategories = topCategories.isEmpty ? user.interests.preferredCategories : topCategories

        if relevantCategories.isEmpty {
            // Cold start: return diverse selection
            return getColdStartRecommendations(from: events, userLocation: user.city, limit: limit)
        }

        let categoryEvents = events.filter { relevantCategories.contains($0.category) }

        let scored = categoryEvents.map { event -> ScoredEvent in
            let (score, reasons) = calculateScore(for: event, user: user)
            return ScoredEvent(event: event, score: score, reasons: reasons)
        }

        return scored.sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.event }
    }

    func getNearbyEvents(
        for user: User,
        from events: [Event],
        limit: Int
    ) async -> [Event] {
        guard let userLocation = user.location else {
            // Fallback to same city
            if let userCity = user.city {
                return events.filter { $0.venue.city.localizedCaseInsensitiveCompare(userCity) == .orderedSame }
                    .prefix(limit)
                    .map { $0 }
            }
            return []
        }

        // Calculate distances and sort
        let eventsWithDistance = events.map { event -> (event: Event, distance: Double) in
            let eventLocation = UserLocation(
                city: event.venue.city,
                country: event.venue.address,
                coordinate: UserLocation.LocationCoordinate(
                    latitude: event.venue.coordinate.latitude,
                    longitude: event.venue.coordinate.longitude
                ),
                lastUpdated: Date()
            )

            return (event, userLocation.distance(to: eventLocation))
        }

        return eventsWithDistance
            .sorted { $0.distance < $1.distance }
            .prefix(limit)
            .map { $0.event }
    }

    func getPopularEvents(
        from events: [Event],
        limit: Int
    ) -> [Event] {
        return events.sorted { event1, event2 in
            let sales1 = Double(event1.ticketTypes.reduce(0) { $0 + $1.sold })
            let total1 = Double(event1.ticketTypes.reduce(0) { $0 + $1.quantity })
            let ratio1 = total1 > 0 ? sales1 / total1 : 0

            let sales2 = Double(event2.ticketTypes.reduce(0) { $0 + $1.sold })
            let total2 = Double(event2.ticketTypes.reduce(0) { $0 + $1.quantity })
            let ratio2 = total2 > 0 ? sales2 / total2 : 0

            // Secondary sort by like count
            if ratio1 == ratio2 {
                return event1.likeCount > event2.likeCount
            }

            return ratio1 > ratio2
        }
        .prefix(limit)
        .map { $0 }
    }

    func getHappeningNowEvents(
        from events: [Event],
        limit: Int
    ) -> [Event] {
        return events.filter { $0.isHappeningNow }
            .prefix(limit)
            .map { $0 }
    }

    func getFreeEvents(
        from events: [Event],
        limit: Int
    ) -> [Event] {
        return events.filter { event in
            let minPrice = event.ticketTypes.map { $0.price }.min() ?? 0
            return minPrice == 0
        }
        .prefix(limit)
        .map { $0 }
    }

    func getWeekendEvents(
        from events: [Event],
        limit: Int
    ) -> [Event] {
        let calendar = Calendar.current

        return events.filter { event in
            let weekday = calendar.component(.weekday, from: event.startDate)
            return weekday == 7 || weekday == 1 // Saturday or Sunday
        }
        .prefix(limit)
        .map { $0 }
    }

    // MARK: - Cold Start Handling

    /// Get recommendations for new users with no preference data
    /// Falls back to popular, recent, and diverse events
    func getColdStartRecommendations(
        from events: [Event],
        userLocation: String?,
        limit: Int = 20
    ) -> [Event] {
        var recommendations: [Event] = []

        // 1. Add some popular events
        let popular = getPopularEvents(from: events, limit: limit / 3)
        recommendations.append(contentsOf: popular)

        // 2. Add events happening soon
        let upcomingSoon = events
            .filter { event in
                if let days = Calendar.current.dateComponents([.day], from: Date(), to: event.startDate).day {
                    return days >= 0 && days <= 3
                }
                return false
            }
            .prefix(limit / 3)

        recommendations.append(contentsOf: upcomingSoon)

        // 3. Add diverse categories to help learn preferences
        var categoryCount: [EventCategory: Int] = [:]
        _ = limit - recommendations.count

        for event in events {
            let count = categoryCount[event.category, default: 0]
            if count < 2 && !recommendations.contains(where: { $0.id == event.id }) {
                recommendations.append(event)
                categoryCount[event.category] = count + 1

                if recommendations.count >= limit {
                    break
                }
            }
        }

        return Array(recommendations.prefix(limit))
    }
}

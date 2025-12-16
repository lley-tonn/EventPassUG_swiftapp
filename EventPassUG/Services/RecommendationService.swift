//
//  RecommendationService.swift
//  EventPassUG
//
//  Personalized event recommendation engine
//  Uses multi-factor scoring: location, categories, interactions, popularity, time
//

import Foundation

// MARK: - Recommendation Result

struct RecommendedEvent: Identifiable {
    let id: UUID
    let event: Event
    let score: Double
    let reason: RecommendationReason

    init(event: Event, score: Double, reason: RecommendationReason) {
        self.id = event.id
        self.event = event
        self.score = score
        self.reason = reason
    }
}

enum RecommendationReason {
    case nearYou(distance: Double)
    case inYourCity(city: String)
    case matchesInterests(categories: [EventCategory])
    case becauseYouLiked(eventTitle: String, category: EventCategory)
    case becauseYouPurchased(eventTitle: String, category: EventCategory)
    case trending
    case popular

    var displayText: String {
        switch self {
        case .nearYou(let distance):
            return String(format: "%.1f km away", distance)
        case .inYourCity(let city):
            return "In \(city)"
        case .matchesInterests(let categories):
            if categories.count == 1 {
                return "You like \(categories[0].rawValue)"
            } else {
                return "Matches your interests"
            }
        case .becauseYouLiked(_, let category):
            return "Because you liked \(category.rawValue) events"
        case .becauseYouPurchased(_, let category):
            return "Because you attended \(category.rawValue) events"
        case .trending:
            return "Trending now"
        case .popular:
            return "Popular event"
        }
    }

    var icon: String {
        switch self {
        case .nearYou, .inYourCity:
            return "location.fill"
        case .matchesInterests:
            return "heart.fill"
        case .becauseYouLiked:
            return "hand.thumbsup.fill"
        case .becauseYouPurchased:
            return "ticket.fill"
        case .trending:
            return "flame.fill"
        case .popular:
            return "star.fill"
        }
    }
}

// MARK: - Recommendation Service

@MainActor
class RecommendationService: ObservableObject {

    // MARK: - Singleton

    static let shared = RecommendationService()

    // MARK: - Published Properties

    @Published var recommendations: [RecommendedEvent] = []
    @Published var isLoading = false

    // MARK: - Private Properties

    private let filterService = EventFilterService.shared

    // MARK: - Configuration

    private struct Config {
        // Scoring weights
        static let sameCityBonus: Double = 50.0
        static let nearbyBonus: Double = 20.0
        static let nearbyRadiusKm: Double = 50.0
        static let categoryMatchBonus: Double = 30.0
        static let likeBonus: Double = 80.0
        static let viewBonus: Double = 20.0
        static let purchaseBonus: Double = 100.0
        static let popularityWeight: Double = 0.1
        static let timeDecayDays: Double = 30.0

        // Minimum scores for inclusion
        static let minimumScore: Double = 10.0
    }

    private init() {}

    // MARK: - Public Methods

    /// Generate personalized recommendations for a user
    func generateRecommendations(
        from events: [Event],
        user: User,
        limit: Int = 20
    ) async -> [RecommendedEvent] {
        isLoading = true
        defer { isLoading = false }

        // Filter eligible events (age, published, upcoming)
        let eligibleEvents = filterService.filterEligibleEvents(events, for: user)
        let publishedEvents = eligibleEvents.filter { $0.status == .published }
        let upcomingEvents = publishedEvents.filter { $0.startDate > Date() }

        // Calculate scores
        let scoredEvents = upcomingEvents.compactMap { event -> RecommendedEvent? in
            let score = calculateScore(for: event, user: user, userLocation: user.location)
            guard score >= Config.minimumScore else { return nil }

            let reason = determineReason(for: event, user: user, score: score)
            return RecommendedEvent(event: event, score: score, reason: reason)
        }

        // Sort by score and limit
        let sortedEvents = scoredEvents.sorted { $0.score > $1.score }
        recommendations = Array(sortedEvents.prefix(limit))

        return recommendations
    }

    /// Get events recommended because user liked similar events
    func getRecommendationsBasedOnLikes(
        from events: [Event],
        user: User,
        limit: Int = 10
    ) -> [RecommendedEvent] {
        // Get categories of liked events
        let likedCategories = getLikedCategories(user: user, from: events)
        guard !likedCategories.isEmpty else { return [] }

        // Filter eligible events
        let eligibleEvents = filterService.filterEligibleEvents(events, for: user)
        let publishedEvents = eligibleEvents.filter { $0.status == .published }
        let upcomingEvents = publishedEvents.filter { $0.startDate > Date() }

        // Find events in liked categories that user hasn't interacted with
        let recommendedEvents = upcomingEvents
            .filter { event in
                likedCategories.contains(event.category) &&
                !user.likedEventIds.contains(event.id) &&
                !user.purchasedEventIds.contains(event.id)
            }
            .map { event in
                let score = calculateScore(for: event, user: user, userLocation: user.location)
                return RecommendedEvent(
                    event: event,
                    score: score,
                    reason: .matchesInterests(categories: [event.category])
                )
            }
            .sorted { $0.score > $1.score }

        return Array(recommendedEvents.prefix(limit))
    }

    /// Get events near the user's location
    func getNearbyRecommendations(
        from events: [Event],
        user: User,
        userLocation: UserLocation,
        limit: Int = 10
    ) -> [RecommendedEvent] {
        // Get nearby events using filter service
        let nearbyEvents = filterService.getNearbyEvents(
            from: events,
            user: user,
            userLocation: userLocation,
            radiusKm: Config.nearbyRadiusKm,
            limit: limit * 2 // Get more to score and filter
        )

        // Calculate scores and create recommendations
        let recommendedEvents = nearbyEvents.compactMap { event -> RecommendedEvent? in
            guard let distance = distanceToEvent(event, from: userLocation) else { return nil }

            let score = calculateScore(for: event, user: user, userLocation: userLocation)
            return RecommendedEvent(
                event: event,
                score: score,
                reason: .nearYou(distance: distance)
            )
        }
        .sorted { $0.score > $1.score }

        return Array(recommendedEvents.prefix(limit))
    }

    /// Get trending events (high engagement recently)
    func getTrendingEvents(
        from events: [Event],
        user: User,
        limit: Int = 10
    ) -> [RecommendedEvent] {
        // Filter eligible events
        let eligibleEvents = filterService.filterEligibleEvents(events, for: user)
        let publishedEvents = eligibleEvents.filter { $0.status == .published }
        let upcomingEvents = publishedEvents.filter { $0.startDate > Date() }

        // Sort by engagement (likes + ratings)
        let trendingEvents = upcomingEvents
            .sorted { event1, event2 in
                let engagement1 = Double(event1.likeCount) + (event1.rating * Double(event1.totalRatings))
                let engagement2 = Double(event2.likeCount) + (event2.rating * Double(event2.totalRatings))
                return engagement1 > engagement2
            }
            .prefix(limit)
            .map { event in
                let score = calculateScore(for: event, user: user, userLocation: user.location)
                return RecommendedEvent(event: event, score: score, reason: .trending)
            }

        return Array(trendingEvents)
    }

    /// Get events in user's city
    func getEventsInCity(
        from events: [Event],
        user: User,
        userLocation: UserLocation,
        limit: Int = 10
    ) -> [RecommendedEvent] {
        // Get city events using filter service
        let cityEvents = filterService.getEventsInCity(
            from: events,
            user: user,
            userLocation: userLocation,
            limit: limit * 2
        )

        // Calculate scores and create recommendations
        let recommendedEvents = cityEvents.map { event in
            let score = calculateScore(for: event, user: user, userLocation: userLocation)
            return RecommendedEvent(
                event: event,
                score: score,
                reason: .inYourCity(city: userLocation.city)
            )
        }
        .sorted { $0.score > $1.score }

        return Array(recommendedEvents.prefix(limit))
    }

    // MARK: - Scoring Algorithm

    /// Calculate recommendation score for an event
    /// Higher score = better recommendation
    private func calculateScore(for event: Event, user: User, userLocation: UserLocation?) -> Double {
        var score: Double = 0.0

        // 1. Location Proximity Score
        if let location = userLocation {
            // Same city bonus
            if event.venue.city.lowercased() == location.city.lowercased() {
                score += Config.sameCityBonus
            }

            // Nearby bonus (within configured radius)
            if let distance = distanceToEvent(event, from: location),
               distance <= Config.nearbyRadiusKm {
                // Closer = higher score (inverse distance)
                let proximityScore = Config.nearbyBonus * (1.0 - (distance / Config.nearbyRadiusKm))
                score += proximityScore
            }
        }

        // 2. Category Match Score
        if user.favoriteEventTypes.contains(event.category.rawValue) {
            score += Config.categoryMatchBonus
        }

        // 3. User Interaction Score
        // Check if user liked events in this category
        let likedCategoriesScore = getLikedCategoryScore(for: event.category, user: user, from: [])
        score += likedCategoriesScore

        // Check if user viewed this specific event
        if user.viewedEventIds.contains(event.id) {
            score += Config.viewBonus
        }

        // Check if user liked this specific event
        if user.likedEventIds.contains(event.id) {
            score += Config.likeBonus
        }

        // 4. Popularity Score
        let popularityScore = event.rating * Double(event.totalRatings) + Double(event.likeCount)
        score += popularityScore * Config.popularityWeight

        // 5. Time Decay (prefer upcoming events, decay for distant events)
        let daysUntilEvent = event.startDate.timeIntervalSinceNow / 86400
        if daysUntilEvent > 0 {
            let timeDecayFactor = max(0, 1.0 - (daysUntilEvent / Config.timeDecayDays))
            score *= (0.5 + 0.5 * timeDecayFactor) // Scale score by time decay
        }

        return max(score, 0)
    }

    /// Determine the primary reason for recommendation
    private func determineReason(for event: Event, user: User, score: Double) -> RecommendationReason {
        // Check location first
        if let location = user.location {
            if event.venue.city.lowercased() == location.city.lowercased() {
                if let distance = distanceToEvent(event, from: location), distance <= 10.0 {
                    return .nearYou(distance: distance)
                }
                return .inYourCity(city: location.city)
            }

            if let distance = distanceToEvent(event, from: location),
               distance <= Config.nearbyRadiusKm {
                return .nearYou(distance: distance)
            }
        }

        // Check if user purchased similar category
        if user.purchasedEventIds.count > 0 {
            // In a real app, you'd fetch the purchased events to check categories
            // For now, just check if user has favorite categories
            if user.favoriteEventTypes.contains(event.category.rawValue) {
                return .matchesInterests(categories: [event.category])
            }
        }

        // Check if user liked similar events
        if user.likedEventIds.count > 0 {
            if user.favoriteEventTypes.contains(event.category.rawValue) {
                return .becauseYouLiked(eventTitle: "similar events", category: event.category)
            }
        }

        // Check category match
        if user.favoriteEventTypes.contains(event.category.rawValue) {
            return .matchesInterests(categories: [event.category])
        }

        // Check popularity
        let popularityScore = event.rating * Double(event.totalRatings) + Double(event.likeCount)
        if popularityScore > 500 {
            return .trending
        }

        if event.rating >= 4.0 && event.totalRatings >= 50 {
            return .popular
        }

        // Default to trending
        return .trending
    }

    // MARK: - Helper Methods

    private func getLikedCategories(user: User, from events: [Event]) -> [EventCategory] {
        // Get categories from user's favorite event types
        let categories = user.favoriteEventTypes.compactMap { EventCategory(rawValue: $0) }
        return Array(Set(categories))
    }

    private func getLikedCategoryScore(for category: EventCategory, user: User, from events: [Event]) -> Double {
        // Check if user has this as a favorite category
        if user.favoriteEventTypes.contains(category.rawValue) {
            return Config.categoryMatchBonus
        }

        // In a real app, you'd check how many events in this category the user liked
        // For simplicity, we return 0 if not in favorites
        return 0
    }

    private func distanceToEvent(_ event: Event, from userLocation: UserLocation) -> Double? {
        let eventLocation = UserLocation.LocationCoordinate(
            latitude: event.venue.coordinate.latitude,
            longitude: event.venue.coordinate.longitude
        )
        let eventUserLocation = UserLocation(
            city: event.venue.city,
            country: userLocation.country,
            coordinate: eventLocation,
            lastUpdated: Date()
        )
        return userLocation.distance(to: eventUserLocation)
    }
}

// MARK: - User Interaction Tracking

extension RecommendationService {
    /// Track that user viewed an event
    func trackEventView(eventId: UUID, userId: UUID) {
        // In a real app, this would update the backend and local user model
        // For now, this is a placeholder
        print("=Ê Tracked view: Event \(eventId) by User \(userId)")
    }

    /// Track that user liked an event
    func trackEventLike(eventId: UUID, userId: UUID) {
        print("=Ê Tracked like: Event \(eventId) by User \(userId)")
    }

    /// Track that user purchased tickets for an event
    func trackEventPurchase(eventId: UUID, userId: UUID) {
        print("=Ê Tracked purchase: Event \(eventId) by User \(userId)")
    }

    /// Track that user shared an event
    func trackEventShare(eventId: UUID, userId: UUID) {
        print("=Ê Tracked share: Event \(eventId) by User \(userId)")
    }
}

//
//  EventFilterService.swift
//  EventPassUG
//
//  Service for filtering and validating events based on user eligibility
//  Handles age restrictions, location-based filtering, and event discovery logic
//

import Foundation

@MainActor
class EventFilterService {

    // MARK: - Singleton

    nonisolated static let shared = EventFilterService()

    nonisolated private init() {}

    // MARK: - Age Validation

    /// Check if user meets age requirement for an event
    nonisolated func canUserAccessEvent(_ event: Event, user: User) -> Bool {
        // No age restriction - everyone can access
        guard event.ageRestriction != .none else { return true }

        // User has no date of birth - allow access (they can set it later)
        guard let userAge = user.age else { return true }

        // Check if user meets minimum age requirement
        return userAge >= event.ageRestriction.rawValue
    }

    /// Get reason why user cannot access an event
    nonisolated func accessDenialReason(for event: Event, user: User) -> String? {
        guard !canUserAccessEvent(event, user: user) else { return nil }

        if user.age != nil {
            return "This event is restricted to ages \(event.ageRestriction.displayName). You must be at least \(event.ageRestriction.rawValue) years old."
        } else {
            return "This event has an age restriction (\(event.ageRestriction.displayName)). Please add your date of birth to verify eligibility."
        }
    }

    // MARK: - Event Filtering

    /// Filter events to only show those the user is eligible to access
    func filterEligibleEvents(_ events: [Event], for user: User) -> [Event] {
        events.filter { canUserAccessEvent($0, user: user) }
    }

    /// Filter events by location proximity
    func filterByLocation(
        _ events: [Event],
        userLocation: UserLocation?,
        sameCity: Bool = false,
        maxDistanceKm: Double? = nil
    ) -> [Event] {
        guard let userLocation = userLocation else { return events }

        return events.filter { event in
            // Same city filter
            if sameCity {
                return event.venue.city.lowercased() == userLocation.city.lowercased()
            }

            // Distance filter
            if let maxDistance = maxDistanceKm {
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
                return userLocation.distance(to: eventUserLocation) <= maxDistance
            }

            return true
        }
    }

    /// Filter events by category
    func filterByCategories(_ events: [Event], categories: [String]) -> [Event] {
        guard !categories.isEmpty else { return events }
        return events.filter { categories.contains($0.category.rawValue) }
    }

    /// Filter events by date range
    func filterByDateRange(_ events: [Event], from startDate: Date, to endDate: Date) -> [Event] {
        events.filter { $0.startDate >= startDate && $0.startDate <= endDate }
    }

    /// Filter events happening today
    func filterToday(_ events: [Event]) -> [Event] {
        let calendar = Calendar.current
        return events.filter { calendar.isDateInToday($0.startDate) }
    }

    /// Filter events happening this week
    func filterThisWeek(_ events: [Event]) -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        return events.filter { calendar.isDate($0.startDate, equalTo: now, toGranularity: .weekOfYear) }
    }

    /// Filter events happening this month
    func filterThisMonth(_ events: [Event]) -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        return events.filter { calendar.isDate($0.startDate, equalTo: now, toGranularity: .month) }
    }

    /// Filter upcoming events (not started yet)
    func filterUpcoming(_ events: [Event]) -> [Event] {
        let now = Date()
        return events.filter { $0.startDate > now }
    }

    /// Filter ongoing events (started but not ended)
    func filterOngoing(_ events: [Event]) -> [Event] {
        events.filter { $0.isHappeningNow }
    }

    // MARK: - Discovery Logic

    /// Sort events by discovery priority for a specific user
    /// Priority: eligible by age  same city  nearby  interests  popularity  upcoming
    func sortByDiscoveryPriority(_ events: [Event], user: User, userLocation: UserLocation?) -> [Event] {
        events.sorted { event1, event2 in
            // 1. Age eligibility (eligible events first)
            let eligible1 = canUserAccessEvent(event1, user: user)
            let eligible2 = canUserAccessEvent(event2, user: user)
            if eligible1 != eligible2 {
                return eligible1
            }

            // 2. Same city (events in user's city first)
            if let location = userLocation {
                let sameCity1 = event1.venue.city.lowercased() == location.city.lowercased()
                let sameCity2 = event2.venue.city.lowercased() == location.city.lowercased()
                if sameCity1 != sameCity2 {
                    return sameCity1
                }

                // 3. Proximity (closer events first)
                let distance1 = distanceToEvent(event1, from: location)
                let distance2 = distanceToEvent(event2, from: location)
                if let d1 = distance1, let d2 = distance2, abs(d1 - d2) > 5.0 {
                    return d1 < d2
                }
            }

            // 4. Category interest (user's favorite categories first)
            let interest1 = user.favoriteEventTypes.contains(event1.category.rawValue)
            let interest2 = user.favoriteEventTypes.contains(event2.category.rawValue)
            if interest1 != interest2 {
                return interest1
            }

            // 5. Popularity (rating and likes)
            let popularity1 = event1.rating * Double(event1.totalRatings) + Double(event1.likeCount)
            let popularity2 = event2.rating * Double(event2.totalRatings) + Double(event2.likeCount)
            if abs(popularity1 - popularity2) > 100 {
                return popularity1 > popularity2
            }

            // 6. Time (upcoming events first, then soonest first)
            return event1.startDate < event2.startDate
        }
    }

    /// Get personalized event discovery feed for a user
    func getDiscoveryFeed(
        from events: [Event],
        user: User,
        userLocation: UserLocation?,
        limit: Int = 20
    ) -> [Event] {
        // Filter by eligibility
        let eligibleEvents = filterEligibleEvents(events, for: user)

        // Filter to only published and upcoming events
        let publishedEvents = eligibleEvents.filter { $0.status == .published }
        let upcomingEvents = filterUpcoming(publishedEvents)

        // Sort by discovery priority
        let sortedEvents = sortByDiscoveryPriority(upcomingEvents, user: user, userLocation: userLocation)

        // Return limited results
        return Array(sortedEvents.prefix(limit))
    }

    /// Get events near the user
    func getNearbyEvents(
        from events: [Event],
        user: User,
        userLocation: UserLocation,
        radiusKm: Double = 50.0,
        limit: Int = 10
    ) -> [Event] {
        // Filter by eligibility and published status
        let eligibleEvents = filterEligibleEvents(events, for: user)
        let publishedEvents = eligibleEvents.filter { $0.status == .published }

        // Filter by location
        let nearbyEvents = filterByLocation(publishedEvents, userLocation: userLocation, maxDistanceKm: radiusKm)

        // Sort by distance
        let sortedEvents = nearbyEvents.sorted { event1, event2 in
            let distance1 = distanceToEvent(event1, from: userLocation) ?? Double.infinity
            let distance2 = distanceToEvent(event2, from: userLocation) ?? Double.infinity
            return distance1 < distance2
        }

        return Array(sortedEvents.prefix(limit))
    }

    /// Get events in the user's city
    func getEventsInCity(
        from events: [Event],
        user: User,
        userLocation: UserLocation,
        limit: Int = 20
    ) -> [Event] {
        // Filter by eligibility and published status
        let eligibleEvents = filterEligibleEvents(events, for: user)
        let publishedEvents = eligibleEvents.filter { $0.status == .published }

        // Filter by same city
        let cityEvents = filterByLocation(publishedEvents, userLocation: userLocation, sameCity: true)

        // Sort by date
        let sortedEvents = cityEvents.sorted { $0.startDate < $1.startDate }

        return Array(sortedEvents.prefix(limit))
    }

    // MARK: - Helper Methods

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

// MARK: - Event Extension for Validation

extension Event {
    /// Check if a specific user can access this event
    func isAccessibleBy(user: User) -> Bool {
        EventFilterService.shared.canUserAccessEvent(self, user: user)
    }

    /// Get access denial reason for a specific user
    func accessDenialReason(for user: User) -> String? {
        EventFilterService.shared.accessDenialReason(for: self, user: user)
    }
}

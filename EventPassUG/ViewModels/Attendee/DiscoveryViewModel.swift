//
//  DiscoveryViewModel.swift
//  EventPassUG
//
//  ViewModel for event discovery, recommendations, and personalized feeds
//  Integrates filtering, recommendations, and location services
//

import Foundation
import Combine

@MainActor
class DiscoveryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var allEvents: [Event] = []
    @Published var recommendedEvents: [ScoredEvent] = []
    @Published var nearbyEvents: [ScoredEvent] = []
    @Published var cityEvents: [ScoredEvent] = []
    @Published var trendingEvents: [ScoredEvent] = []
    @Published var categoryEvents: [Event] = []

    @Published var selectedCategory: EventCategory?
    @Published var selectedTimeFilter: TimeFilter = .all

    @Published var isLoading = false
    @Published var errorMessage: String?

    // User and location
    @Published var currentUser: User?
    @Published var userLocation: UserLocation?

    // MARK: - Services

    private let filterService = EventFilterService.shared
    private let recommendationService = RecommendationService.shared
    private let locationService = UserLocationService.shared

    // MARK: - Cancellables

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe location updates
        locationService.$currentLocation
            .assign(to: &$userLocation)

        // Observe user location changes
        $userLocation
            .sink { [weak self] location in
                if location != nil {
                    Task {
                        await self?.refreshRecommendations()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Load all events and generate recommendations
    func loadEvents(user: User) async {
        isLoading = true
        errorMessage = nil
        currentUser = user

        // In a real app, this would fetch from backend
        // For now, use sample data
        allEvents = Event.samples

        // Generate recommendations
        await refreshRecommendations()

        isLoading = false
    }

    /// Refresh all recommendations
    func refreshRecommendations() async {
        guard let user = currentUser else { return }

        // Get personalized recommendations
        let recommended = await recommendationService.getRecommendedEvents(
            for: user,
            from: allEvents,
            limit: 20
        )

        // Get popular events (trending)
        let trending = recommendationService.getPopularEvents(
            from: allEvents,
            limit: 10
        ).map { ScoredEvent(event: $0, score: 0, reasons: ["Popular event"]) }

        // Only fetch location-based recommendations if location is available
        if let location = userLocation {
            let nearby = await recommendationService.getNearbyEvents(
                for: user,
                from: allEvents,
                limit: 10
            ).map { ScoredEvent(event: $0, score: 0, reasons: ["Near you"]) }

            let inCity = allEvents.filter { $0.venue.city == location.city }
                .prefix(10)
                .map { ScoredEvent(event: $0, score: 0, reasons: ["In \(location.city)"]) }

            recommendedEvents = recommended
            trendingEvents = trending
            nearbyEvents = nearby
            cityEvents = Array(inCity)
        } else {
            recommendedEvents = recommended
            trendingEvents = trending
            nearbyEvents = []
            cityEvents = []
        }
    }

    /// Filter events by category
    func filterByCategory(_ category: EventCategory?) {
        selectedCategory = category

        guard let user = currentUser else { return }

        if let category = category {
            categoryEvents = filterService.filterByCategories(allEvents, categories: [category.rawValue])
            categoryEvents = filterService.filterEligibleEvents(categoryEvents, for: user)
        } else {
            categoryEvents = []
        }
    }

    /// Filter events by time
    func filterByTime(_ timeFilter: TimeFilter) {
        selectedTimeFilter = timeFilter

        guard let user = currentUser else { return }

        var filtered = filterService.filterEligibleEvents(allEvents, for: user)

        switch timeFilter {
        case .all:
            break
        case .today:
            filtered = filterService.filterToday(filtered)
        case .thisWeek:
            filtered = filterService.filterThisWeek(filtered)
        case .thisMonth:
            filtered = filterService.filterThisMonth(filtered)
        }

        categoryEvents = filtered
    }

    /// Get discovery feed for user
    func getDiscoveryFeed() -> [Event] {
        guard let user = currentUser else { return [] }

        return filterService.getDiscoveryFeed(
            from: allEvents,
            user: user,
            userLocation: userLocation,
            limit: 20
        )
    }

    /// Track user interaction with an event
    func trackEventView(event: Event) {
        guard var user = currentUser else { return }
        recommendationService.recordInteraction(user: &user, event: event, type: .view)
        currentUser = user
    }

    func trackEventLike(event: Event) {
        guard var user = currentUser else { return }
        recommendationService.recordInteraction(user: &user, event: event, type: .like)
        currentUser = user
    }

    func trackEventPurchase(event: Event) {
        guard var user = currentUser else { return }
        recommendationService.recordInteraction(user: &user, event: event, type: .purchase)
        currentUser = user
    }

    // MARK: - Search

    /// Search events by query
    func searchEvents(query: String) -> [Event] {
        guard !query.isEmpty else { return [] }
        guard let user = currentUser else { return [] }

        let lowercasedQuery = query.lowercased()

        return allEvents.filter { event in
            // Filter by eligibility first
            guard filterService.canUserAccessEvent(event, user: user) else { return false }

            // Search in title, description, venue, organizer
            return event.title.lowercased().contains(lowercasedQuery) ||
                   event.description.lowercased().contains(lowercasedQuery) ||
                   event.venue.name.lowercased().contains(lowercasedQuery) ||
                   event.venue.city.lowercased().contains(lowercasedQuery) ||
                   event.organizerName.lowercased().contains(lowercasedQuery) ||
                   event.category.rawValue.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Location

    /// Request location permission and update location
    func requestLocationPermission() {
        locationService.requestPermission()
    }

    /// Update user location manually
    func updateLocationManually(city: String, country: String, coordinate: UserLocation.LocationCoordinate) {
        locationService.updateLocation(city: city, country: country, coordinate: coordinate)
    }
}

// MARK: - Time Filter

enum TimeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"

    var id: String { rawValue }
}

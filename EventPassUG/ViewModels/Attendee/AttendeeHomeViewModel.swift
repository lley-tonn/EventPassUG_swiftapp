//
//  AttendeeHomeViewModel.swift
//  EventPassUG
//
//  Enhanced ViewModel for Attendee Home Screen with personalized recommendations
//  Prevents auto-scrolling by managing state changes properly
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AttendeeHomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var events: [Event] = []
    @Published private(set) var recommendedEvents: [ScoredEvent] = []
    @Published private(set) var isLoading = false
    @Published var selectedTimeCategory: TimeCategory? = nil
    @Published var selectedEventCategory: EventCategory? = nil
    @Published var selectedRecommendationCategory: RecommendationCategory? = nil
    @Published var searchText = ""
    @Published var isSearchExpanded = false

    // MARK: - Private Properties

    private(set) var eventService: EventServiceProtocol
    private let recommendationService = RecommendationService.shared
    private var hasLoadedInitialData = false
    private var loadTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredEvents: [Event] {
        var filtered = events

        // Filter out past events
        filtered = filtered.filter { $0.endDate >= Date() }

        // Filter by time category
        if let timeCategory = selectedTimeCategory {
            filtered = filtered.filter { $0.timeCategory == timeCategory }
        }

        // Filter by event category
        if let eventCategory = selectedEventCategory {
            filtered = filtered.filter { $0.category == eventCategory }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.organizerName.localizedCaseInsensitiveContains(searchText) ||
                event.venue.name.localizedCaseInsensitiveContains(searchText) ||
                event.venue.city.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    /// Events ranked by personalized recommendations
    var rankedEvents: [Event] {
        // If user is filtering/searching, don't use recommendations
        if selectedTimeCategory != nil || selectedEventCategory != nil || !searchText.isEmpty {
            return filteredEvents
        }

        // Use recommendation scores to rank events
        if !recommendedEvents.isEmpty {
            return recommendedEvents.map { $0.event }
        }

        // Fallback to filtered events
        return filteredEvents
    }

    /// Events grouped by recommendation categories for intelligent sections
    var eventSections: [RecommendationSection] {
        guard let user = currentUser else {
            return []
        }

        var sections: [RecommendationSection] = []

        // Section 1: Recommended for You (Top scored events)
        let forYou = recommendedEvents.prefix(10).map { $0.event }
        if !forYou.isEmpty {
            sections.append(RecommendationSection(
                category: .forYou,
                events: Array(forYou),
                icon: RecommendationCategory.forYou.icon
            ))
        }

        // Section 2: Happening Now
        let happeningNow = recommendationService.getHappeningNowEvents(from: events, limit: 5)
        if !happeningNow.isEmpty {
            sections.append(RecommendationSection(
                category: .happeningNow,
                events: happeningNow,
                icon: RecommendationCategory.happeningNow.icon
            ))
        }

        // Section 3: Based on Your Interests
        if !user.interests.isNewUser {
            // Only show if user has established interests
            let topCategories = user.interests.getTopCategories(limit: 3)
            if !topCategories.isEmpty {
                let interestEvents = events.filter { topCategories.contains($0.category) }
                    .prefix(8)
                if !interestEvents.isEmpty {
                    sections.append(RecommendationSection(
                        category: .basedOnInterests,
                        events: Array(interestEvents),
                        icon: RecommendationCategory.basedOnInterests.icon
                    ))
                }
            }
        }

        // Section 4: Events Near You (if location available)
        if let userCity = user.city {
            let nearbyEvents = events.filter { $0.venue.city == userCity }
                .prefix(8)
            if !nearbyEvents.isEmpty {
                sections.append(RecommendationSection(
                    category: .nearYou,
                    events: Array(nearbyEvents),
                    icon: RecommendationCategory.nearYou.icon
                ))
            }
        }

        // Section 5: Popular Right Now
        let popular = recommendationService.getPopularEvents(from: events, limit: 8)
        if !popular.isEmpty {
            sections.append(RecommendationSection(
                category: .popularNow,
                events: popular,
                icon: RecommendationCategory.popularNow.icon
            ))
        }

        // Section 6: This Weekend
        let weekend = recommendationService.getWeekendEvents(from: events, limit: 6)
        if !weekend.isEmpty {
            sections.append(RecommendationSection(
                category: .thisWeekend,
                events: weekend,
                icon: RecommendationCategory.thisWeekend.icon
            ))
        }

        // Section 7: Free Events
        if user.interests.prefersFreeEvents || user.interests.isNewUser {
            let freeEvents = recommendationService.getFreeEvents(from: events, limit: 6)
            if !freeEvents.isEmpty {
                sections.append(RecommendationSection(
                    category: .freeEvents,
                    events: freeEvents,
                    icon: RecommendationCategory.freeEvents.icon
                ))
            }
        }

        return sections
    }

    // Reference to current user (injected from AuthService)
    private var currentUser: User?

    // MARK: - Initialization

    init(eventService: EventServiceProtocol) {
        self.eventService = eventService
    }

    // MARK: - Public Methods

    /// Update the event service (used for dependency injection)
    func updateEventService(_ service: EventServiceProtocol) {
        self.eventService = service
    }

    /// Set the current user for personalized recommendations
    func setCurrentUser(_ user: User?) {
        self.currentUser = user
    }

    /// Load events and generate recommendations
    func loadEventsIfNeeded() {
        // Only load once to prevent multiple loads
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true

        // Cancel any existing load task
        loadTask?.cancel()

        // Set loading state immediately (before delay)
        isLoading = true

        // Start load task with slight delay to let view settle
        loadTask = Task {
            // Small delay to allow view to render and settle
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

            guard !Task.isCancelled else { return }

            do {
                let fetchedEvents = try await eventService.fetchEvents()

                guard !Task.isCancelled else { return }

                // Update state WITHOUT animation to prevent scroll jumping
                withAnimation(.none) {
                    self.events = fetchedEvents
                }

                // Generate personalized recommendations if user is available
                if let user = currentUser {
                    await generateRecommendations(for: user)
                }

                withAnimation(.none) {
                    self.isLoading = false
                }
            } catch {
                print("Error loading events: \(error)")
                withAnimation(.none) {
                    self.isLoading = false
                }
            }
        }
    }

    /// Generate personalized recommendations for the current user
    func generateRecommendations(for user: User) async {
        guard !events.isEmpty else { return }

        let scored = await recommendationService.getRecommendedEvents(
            for: user,
            from: events,
            limit: 50 // Get top 50 recommendations
        )

        withAnimation(.none) {
            self.recommendedEvents = scored
        }
    }

    /// Get events for a specific recommendation category
    func getEventsForCategory(_ category: RecommendationCategory) async -> [Event] {
        guard let user = currentUser else { return [] }

        return await recommendationService.getEventsByCategory(
            for: user,
            from: events,
            category: category,
            limit: 20
        )
    }

    /// Record user interaction with an event
    func recordEventInteraction(event: Event, type: UserInteractionType) {
        guard var user = currentUser else { return }

        recommendationService.recordInteraction(
            user: &user,
            event: event,
            type: type
        )

        // Update the user reference
        currentUser = user

        // Regenerate recommendations with updated interests
        Task {
            await generateRecommendations(for: user)
        }
    }

    /// Get explanation for why an event was recommended
    func getRecommendationReason(for event: Event) -> String {
        guard let user = currentUser else {
            return "Popular event"
        }

        return recommendationService.getRecommendationReason(event: event, user: user)
    }

    /// Reset filters
    func clearFilters() {
        selectedTimeCategory = nil
        selectedEventCategory = nil
        selectedRecommendationCategory = nil
        searchText = ""
    }

    /// Refresh events (pull to refresh)
    func refreshEvents() async {
        do {
            let fetchedEvents = try await eventService.fetchEvents()
            withAnimation(.none) {
                self.events = fetchedEvents
            }

            // Regenerate recommendations
            if let user = currentUser {
                await generateRecommendations(for: user)
            }
        } catch {
            print("Error refreshing events: \(error)")
        }
    }

    // MARK: - Cleanup

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - Recommendation Section Model

/// Model for a section of recommended events
struct RecommendationSection: Identifiable {
    let id = UUID()
    let category: RecommendationCategory
    let events: [Event]
    let icon: String

    var title: String {
        category.rawValue
    }
}

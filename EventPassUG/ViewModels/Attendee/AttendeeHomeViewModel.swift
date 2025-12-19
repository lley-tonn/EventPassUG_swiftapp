//
//  AttendeeHomeViewModel.swift
//  EventPassUG
//
//  ViewModel for Attendee Home Screen
//  Prevents auto-scrolling by managing state changes properly
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AttendeeHomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var events: [Event] = []
    @Published private(set) var isLoading = false
    @Published var selectedTimeCategory: TimeCategory? = nil
    @Published var selectedEventCategory: EventCategory? = nil
    @Published var searchText = ""
    @Published var isSearchExpanded = false

    // MARK: - Private Properties

    private(set) var eventService: EventServiceProtocol
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

    // MARK: - Initialization

    init(eventService: EventServiceProtocol) {
        self.eventService = eventService
    }

    // MARK: - Public Methods

    /// Update the event service (used for dependency injection)
    func updateEventService(_ service: EventServiceProtocol) {
        self.eventService = service
    }

    /// Load events - called once on view appear
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

    /// Reset filters
    func clearFilters() {
        selectedTimeCategory = nil
        selectedEventCategory = nil
        searchText = ""
    }

    /// Refresh events (pull to refresh)
    func refreshEvents() async {
        do {
            let fetchedEvents = try await eventService.fetchEvents()
            withAnimation(.none) {
                self.events = fetchedEvents
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

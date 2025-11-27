//
//  EventService.swift
//  EventPassUG
//
//  Event management service protocol and mock implementation
//

import Foundation
import Combine

// MARK: - Protocol

protocol EventServiceProtocol {
    func fetchEvents() async throws -> [Event]
    func fetchEvent(id: UUID) async throws -> Event?
    func createEvent(_ event: Event) async throws -> Event
    func updateEvent(_ event: Event) async throws -> Event
    func deleteEvent(id: UUID) async throws
    func likeEvent(id: UUID) async throws
    func unlikeEvent(id: UUID) async throws
    func rateEvent(id: UUID, rating: Double, review: String?) async throws
    func fetchOrganizerEvents(organizerId: UUID) async throws -> [Event]
}

// MARK: - Mock Implementation

class MockEventService: EventServiceProtocol {
    @Published private var events: [Event] = Event.samples
    private var likedEventIds: Set<UUID> = []

    init() {
        // Load from UserDefaults if available
        loadPersistedEvents()
    }

    func fetchEvents() async throws -> [Event] {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return events.filter { $0.status == .published }
    }

    func fetchEvent(id: UUID) async throws -> Event? {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 300_000_000)
        return events.first { $0.id == id }
    }

    func createEvent(_ event: Event) async throws -> Event {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let newEvent = await MainActor.run { () -> Event in
            var createdEvent = event
            createdEvent.createdAt = Date()
            createdEvent.updatedAt = Date()
            events.append(createdEvent)
            return createdEvent
        }
        persistEvents()
        return newEvent
    }

    func updateEvent(_ event: Event) async throws -> Event {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 800_000_000)

        await MainActor.run {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                var updatedEvent = event
                updatedEvent.updatedAt = Date()
                events[index] = updatedEvent
            }
        }
        persistEvents()
        return event
    }

    func deleteEvent(id: UUID) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            events.removeAll { $0.id == id }
        }
        persistEvents()
    }

    func likeEvent(id: UUID) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 300_000_000)

        await MainActor.run {
            if let index = events.firstIndex(where: { $0.id == id }) {
                events[index].likeCount += 1
                likedEventIds.insert(id)
            }
        }
        persistEvents()
    }

    func unlikeEvent(id: UUID) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 300_000_000)

        await MainActor.run {
            if let index = events.firstIndex(where: { $0.id == id }) {
                events[index].likeCount = max(0, events[index].likeCount - 1)
                likedEventIds.remove(id)
            }
        }
        persistEvents()
    }

    func rateEvent(id: UUID, rating: Double, review: String?) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            if let index = events.firstIndex(where: { $0.id == id }) {
                let currentRating = events[index].rating
                let currentCount = events[index].totalRatings
                let newCount = currentCount + 1
                let newRating = ((currentRating * Double(currentCount)) + rating) / Double(newCount)

                events[index].rating = newRating
                events[index].totalRatings = newCount
            }
        }
        persistEvents()
    }

    func fetchOrganizerEvents(organizerId: UUID) async throws -> [Event] {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return events.filter { $0.organizerId == organizerId }
    }

    // MARK: - Persistence

    private let eventsKey = "com.eventpassug.events"

    private func persistEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }

    private func loadPersistedEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let savedEvents = try? JSONDecoder().decode([Event].self, from: data),
           !savedEvents.isEmpty {
            self.events = savedEvents
        }
    }
}

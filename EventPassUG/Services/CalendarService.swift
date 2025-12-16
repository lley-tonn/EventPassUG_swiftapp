//
//  CalendarService.swift
//  EventPassUG
//
//  Calendar integration service for adding events and detecting conflicts
//  Uses EventKit for seamless calendar integration
//

import Foundation
import EventKit

// MARK: - Calendar Conflict

struct CalendarConflict: Identifiable {
    let id = UUID()
    let event: EKEvent
    let conflictType: ConflictType

    enum ConflictType {
        case exact // Same time
        case partial // Overlapping time
        case adjacent // Back-to-back events
    }

    var displayDescription: String {
        switch conflictType {
        case .exact:
            return "You have '\(event.title ?? "another event")' scheduled at the same time"
        case .partial:
            return "'\(event.title ?? "another event")' overlaps with this event"
        case .adjacent:
            return "'\(event.title ?? "another event")' is scheduled right before/after"
        }
    }
}

// MARK: - Calendar Service

@MainActor
class CalendarService: ObservableObject {

    // MARK: - Singleton

    static let shared = CalendarService()

    // MARK: - Published Properties

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var hasPermission = false

    // MARK: - Private Properties

    private let eventStore = EKEventStore()

    // MARK: - Initialization

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Permission Handling

    /// Check current authorization status
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        hasPermission = authorizationStatus == .authorized
    }

    /// Request calendar access permission
    func requestPermission() async throws -> Bool {
        if #available(iOS 17.0, *) {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                checkAuthorizationStatus()
            }
            return granted
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    Task { @MainActor in
                        self.checkAuthorizationStatus()
                    }

                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    // MARK: - Calendar Event Management

    /// Add event to user's calendar
    func addEventToCalendar(
        event: Event,
        showAlert: Bool = true
    ) async throws -> String? {
        guard hasPermission else {
            throw CalendarError.permissionDenied
        }

        // Create calendar event
        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = event.title
        calendarEvent.notes = event.description
        calendarEvent.location = "\(event.venue.name), \(event.venue.address), \(event.venue.city)"
        calendarEvent.startDate = event.startDate
        calendarEvent.endDate = event.endDate
        calendarEvent.calendar = eventStore.defaultCalendarForNewEvents

        // Add alarm for 2 hours before
        let alarm = EKAlarm(relativeOffset: -2 * 60 * 60) // 2 hours before
        calendarEvent.addAlarm(alarm)

        // Add URL if available
        if let posterURL = event.posterURL, let url = URL(string: posterURL) {
            calendarEvent.url = url
        }

        // Save to calendar
        try eventStore.save(calendarEvent, span: .thisEvent)

        return calendarEvent.eventIdentifier
    }

    /// Remove event from calendar
    func removeEventFromCalendar(calendarEventId: String) throws {
        guard hasPermission else {
            throw CalendarError.permissionDenied
        }

        guard let calendarEvent = eventStore.event(withIdentifier: calendarEventId) else {
            throw CalendarError.eventNotFound
        }

        try eventStore.remove(calendarEvent, span: .thisEvent)
    }

    // MARK: - Conflict Detection

    /// Check for conflicts with existing calendar events
    func checkConflicts(for event: Event, bufferMinutes: Int = 0) async throws -> [CalendarConflict] {
        guard hasPermission else {
            throw CalendarError.permissionDenied
        }

        // Adjust times with buffer
        let bufferInterval = TimeInterval(bufferMinutes * 60)
        let checkStartDate = event.startDate.addingTimeInterval(-bufferInterval)
        let checkEndDate = event.endDate.addingTimeInterval(bufferInterval)

        // Create predicate for events in the same time range
        let predicate = eventStore.predicateForEvents(
            withStart: checkStartDate,
            end: checkEndDate,
            calendars: nil
        )

        // Fetch existing events
        let existingEvents = eventStore.events(matching: predicate)

        // Analyze conflicts
        var conflicts: [CalendarConflict] = []

        for existingEvent in existingEvents {
            if let conflict = analyzeConflict(
                newEvent: event,
                existingEvent: existingEvent,
                bufferMinutes: bufferMinutes
            ) {
                conflicts.append(conflict)
            }
        }

        return conflicts
    }

    /// Check if user has any events during a specific time range
    func hasEventsInTimeRange(from startDate: Date, to endDate: Date) async throws -> Bool {
        guard hasPermission else { return false }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
        return !events.isEmpty
    }

    /// Get all events for a specific day
    func getEventsForDay(_ date: Date) async throws -> [EKEvent] {
        guard hasPermission else {
            throw CalendarError.permissionDenied
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
    }

    /// Check conflicts for organizer creating an event
    /// This helps organizers avoid scheduling events at conflicting times
    func checkOrganizerConflicts(
        startDate: Date,
        endDate: Date,
        bufferMinutes: Int = 30
    ) async throws -> [CalendarConflict] {
        guard hasPermission else {
            throw CalendarError.permissionDenied
        }

        // Create a temporary event for conflict checking
        let tempEvent = Event(
            title: "New Event",
            description: "",
            organizerId: UUID(),
            organizerName: "",
            category: .other,
            startDate: startDate,
            endDate: endDate,
            venue: Venue(
                name: "",
                address: "",
                city: "",
                coordinate: Venue.Coordinate(latitude: 0, longitude: 0)
            )
        )

        return try await checkConflicts(for: tempEvent, bufferMinutes: bufferMinutes)
    }

    // MARK: - Helper Methods

    /// Analyze conflict type between two events
    private func analyzeConflict(
        newEvent: Event,
        existingEvent: EKEvent,
        bufferMinutes: Int
    ) -> CalendarConflict? {
        guard let existingStart = existingEvent.startDate,
              let existingEnd = existingEvent.endDate else {
            return nil
        }

        let newStart = newEvent.startDate
        let newEnd = newEvent.endDate

        // Check for exact time conflict
        if newStart == existingStart && newEnd == existingEnd {
            return CalendarConflict(event: existingEvent, conflictType: .exact)
        }

        // Check for overlapping conflict
        if newStart < existingEnd && newEnd > existingStart {
            return CalendarConflict(event: existingEvent, conflictType: .partial)
        }

        // Check for adjacent events (with buffer)
        if bufferMinutes > 0 {
            let bufferInterval = TimeInterval(bufferMinutes * 60)

            // Check if existing event ends right before new event starts
            if abs(existingEnd.timeIntervalSince(newStart)) <= bufferInterval {
                return CalendarConflict(event: existingEvent, conflictType: .adjacent)
            }

            // Check if existing event starts right after new event ends
            if abs(existingStart.timeIntervalSince(newEnd)) <= bufferInterval {
                return CalendarConflict(event: existingEvent, conflictType: .adjacent)
            }
        }

        return nil
    }

    /// Get user-friendly conflict summary
    func getConflictSummary(conflicts: [CalendarConflict]) -> String {
        if conflicts.isEmpty {
            return "No conflicts found"
        }

        if conflicts.count == 1 {
            return conflicts[0].displayDescription
        }

        return "You have \(conflicts.count) conflicting events in your calendar"
    }

    /// Check if it's safe to add event (no critical conflicts)
    func isSafeToAddEvent(conflicts: [CalendarConflict]) -> Bool {
        // Adjacent conflicts are OK, but exact/partial are not
        let criticalConflicts = conflicts.filter { conflict in
            conflict.conflictType == .exact || conflict.conflictType == .partial
        }
        return criticalConflicts.isEmpty
    }
}

// MARK: - Calendar Error

enum CalendarError: LocalizedError {
    case permissionDenied
    case eventNotFound
    case saveFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar access denied. Please grant permission in Settings to add events to your calendar."
        case .eventNotFound:
            return "Calendar event not found."
        case .saveFailed:
            return "Failed to save event to calendar."
        case .unknown:
            return "An unknown error occurred while accessing the calendar."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy > Calendars and enable access for EventPass."
        case .eventNotFound, .saveFailed, .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Event Extension

extension Event {
    /// Convert to EKEvent for calendar integration
    func toEKEvent(eventStore: EKEventStore) -> EKEvent {
        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = title
        calendarEvent.notes = description
        calendarEvent.location = "\(venue.name), \(venue.address), \(venue.city)"
        calendarEvent.startDate = startDate
        calendarEvent.endDate = endDate
        calendarEvent.calendar = eventStore.defaultCalendarForNewEvents

        return calendarEvent
    }
}

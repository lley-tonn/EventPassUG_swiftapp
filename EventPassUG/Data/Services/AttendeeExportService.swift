//
//  AttendeeExportService.swift
//  EventPassUG
//
//  Service for exporting attendee lists for a specific event
//  CRITICAL: All exports are strictly scoped to a single eventId
//

import Foundation

/// Service responsible for exporting attendee data
/// All exports are scoped to a single event - never exports cross-event data
class AttendeeExportService {

    private let ticketService: TicketRepositoryProtocol

    init(ticketService: TicketRepositoryProtocol = MockTicketRepository()) {
        self.ticketService = ticketService
    }

    // MARK: - Fetch Attendees

    /// Fetches attendees for a SPECIFIC event only
    /// - Parameter eventId: The event ID to fetch attendees for
    /// - Returns: Array of attendees belonging to this event only
    func fetchAttendees(for eventId: UUID) async throws -> [Attendee] {
        // CRITICAL: Fetch ONLY tickets for this specific event
        // This ensures we never accidentally include data from other events
        let eventTickets = try await ticketService.fetchTicketsForEvent(eventId: eventId)

        // Convert tickets to attendees
        // NOTE: Email/phone are intentionally NOT exported for privacy
        let attendees = eventTickets.map { ticket in
            let mockMarketingConsent = Bool.random()

            return Attendee(
                ticket: ticket,
                user: nil, // In production, fetch actual user for name
                marketingConsent: mockMarketingConsent
            )
        }

        // Safety verification: ensure all attendees belong to the requested event
        let allBelongToEvent = attendees.allSatisfy { $0.eventId == eventId }
        guard allBelongToEvent else {
            throw ExportError.eventMismatch
        }

        return attendees
    }

    // MARK: - Export Attendees

    /// Exports attendees for a SPECIFIC event with the given filter
    /// - Parameters:
    ///   - eventId: The event ID to export attendees for
    ///   - eventTitle: Title of the event for the filename
    ///   - filter: The filter to apply to attendees
    /// - Returns: URL to the generated CSV file
    func exportAttendees(
        eventId: UUID,
        eventTitle: String,
        filter: AttendeeExportFilter
    ) async throws -> URL? {
        // Fetch attendees for this specific event
        let attendees = try await fetchAttendees(for: eventId)

        // Apply the selected filter
        let filteredAttendees = filter.filter(attendees)

        guard !filteredAttendees.isEmpty else {
            throw ExportError.noDataToExport
        }

        // Generate CSV
        guard let fileURL = CSVGenerator.generateAttendeeCSV(
            attendees: filteredAttendees,
            eventTitle: eventTitle,
            filter: filter
        ) else {
            throw ExportError.fileGenerationFailed
        }

        // Track analytics
        trackExportAnalytics(
            eventId: eventId,
            attendeeCount: filteredAttendees.count,
            filter: filter
        )

        return fileURL
    }

    // MARK: - Analytics Tracking

    private func trackExportAnalytics(
        eventId: UUID,
        attendeeCount: Int,
        filter: AttendeeExportFilter
    ) {
        let analyticsEvent = ExportAnalyticsEvent(
            name: "attendee_list_exported",
            eventId: eventId,
            format: "csv",
            timestamp: Date(),
            filterType: filter.rawValue,
            attendeeCount: attendeeCount
        )

        print("Analytics: \(analyticsEvent.name) - eventId: \(eventId), count: \(attendeeCount), filter: \(filter.rawValue)")
        // TODO: Send to analytics service
    }
}

// MARK: - Mock Implementation with Sample Data

extension AttendeeExportService {

    /// Provides mock attendees for preview and testing
    func mockAttendees(for eventId: UUID, count: Int = 25) -> [Attendee] {
        return Attendee.mockAttendees(for: eventId, count: count)
    }
}

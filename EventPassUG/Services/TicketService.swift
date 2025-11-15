//
//  TicketService.swift
//  EventPassUG
//
//  Ticket management service protocol and mock implementation
//

import Foundation
import Combine

// MARK: - Protocol

protocol TicketServiceProtocol {
    func purchaseTicket(eventId: UUID, ticketTypeId: UUID, quantity: Int, event: Event, ticketType: TicketType, userId: UUID) async throws -> [Ticket]
    func fetchUserTickets(userId: UUID) async throws -> [Ticket]
    func fetchAllTickets() async throws -> [Ticket]
    func scanTicket(qrCode: String) async throws -> Ticket
    func validateTicket(qrCode: String) async throws -> Bool
    func rateTicket(ticketId: UUID, rating: Double) async throws
}

// MARK: - Mock Implementation

class MockTicketService: TicketServiceProtocol {
    @Published private var tickets: [Ticket] = []

    init() {
        loadPersistedTickets()
    }

    func purchaseTicket(eventId: UUID, ticketTypeId: UUID, quantity: Int, event: Event, ticketType: TicketType, userId: UUID) async throws -> [Ticket] {
        // TODO: Replace with real API call and payment processing
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Generate unique order number for this purchase
        let orderNumber = generateOrderNumber()

        // Generate tickets with full event data
        var newTickets: [Ticket] = []

        for i in 0..<quantity {
            let ticketNumber = generateTicketNumber()

            let ticket = Ticket(
                ticketNumber: ticketNumber,
                orderNumber: orderNumber,
                eventId: event.id,
                eventTitle: event.title,
                eventDate: event.startDate,
                eventEndDate: event.endDate,
                eventVenue: event.venue.name,
                eventVenueAddress: event.venue.address,
                eventVenueCity: event.venue.city,
                venueLatitude: event.venue.coordinate.latitude,
                venueLongitude: event.venue.coordinate.longitude,
                eventDescription: event.description,
                eventOrganizerName: event.organizerName,
                eventPosterURL: event.posterURL,
                ticketType: ticketType,
                userId: userId,
                qrCodeData: "TKT:\(ticketNumber)|ORD:\(orderNumber)|EVT:\(event.id)|USR:\(userId)"
            )
            newTickets.append(ticket)
        }

        await MainActor.run {
            tickets.append(contentsOf: newTickets)
        }
        persistTickets()
        return newTickets
    }

    func fetchUserTickets(userId: UUID) async throws -> [Ticket] {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return tickets.filter { $0.userId == userId }
    }

    func fetchAllTickets() async throws -> [Ticket] {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 300_000_000)
        return tickets
    }

    func scanTicket(qrCode: String) async throws -> Ticket {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 800_000_000)

        guard let ticket = tickets.first(where: { $0.qrCodeData == qrCode }) else {
            throw TicketError.ticketNotFound
        }

        guard ticket.canBeScanned else {
            throw TicketError.ticketAlreadyScanned
        }

        await MainActor.run {
            if let index = tickets.firstIndex(where: { $0.id == ticket.id }) {
                tickets[index].scanStatus = .scanned
                tickets[index].scanDate = Date()
            }
        }
        persistTickets()

        return ticket
    }

    func validateTicket(qrCode: String) async throws -> Bool {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 300_000_000)

        guard let ticket = tickets.first(where: { $0.qrCodeData == qrCode }) else {
            return false
        }

        return ticket.canBeScanned
    }

    func rateTicket(ticketId: UUID, rating: Double) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            if let index = tickets.firstIndex(where: { $0.id == ticketId }) {
                tickets[index].userRating = rating
            }
        }
        persistTickets()
    }

    // MARK: - Persistence

    private let ticketsKey = "com.eventpassug.tickets"

    private func persistTickets() {
        if let encoded = try? JSONEncoder().encode(tickets) {
            UserDefaults.standard.set(encoded, forKey: ticketsKey)
        }
    }

    private func loadPersistedTickets() {
        if let data = UserDefaults.standard.data(forKey: ticketsKey),
           let savedTickets = try? JSONDecoder().decode([Ticket].self, from: data) {
            self.tickets = savedTickets
        }
    }

    // MARK: - Number Generation

    private func generateTicketNumber() -> String {
        // Generate unique 6-digit ticket number
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) % 1000000
        let random = Int.random(in: 0...999)
        let number = (timestamp + random) % 1000000
        return String(format: "TKT-%06d", number)
    }

    private func generateOrderNumber() -> String {
        // Generate unique order number based on timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return String(format: "ORD-%d%04d", timestamp % 100000, random)
    }
}

enum TicketError: LocalizedError {
    case ticketNotFound
    case ticketAlreadyScanned
    case ticketExpired

    var errorDescription: String? {
        switch self {
        case .ticketNotFound:
            return "Ticket not found"
        case .ticketAlreadyScanned:
            return "This ticket has already been scanned"
        case .ticketExpired:
            return "This ticket has expired"
        }
    }
}

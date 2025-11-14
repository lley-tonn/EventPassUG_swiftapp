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
    func purchaseTicket(eventId: UUID, ticketTypeId: UUID, quantity: Int) async throws -> [Ticket]
    func fetchUserTickets(userId: UUID) async throws -> [Ticket]
    func scanTicket(qrCode: String) async throws -> Ticket
    func validateTicket(qrCode: String) async throws -> Bool
}

// MARK: - Mock Implementation

class MockTicketService: TicketServiceProtocol {
    @Published private var tickets: [Ticket] = []

    init() {
        loadPersistedTickets()
    }

    func purchaseTicket(eventId: UUID, ticketTypeId: UUID, quantity: Int) async throws -> [Ticket] {
        // TODO: Replace with real API call and payment processing
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Mock ticket generation
        var newTickets: [Ticket] = []

        for _ in 0..<quantity {
            // In a real implementation, fetch event details from backend
            let mockTicket = Ticket(
                eventId: eventId,
                eventTitle: "Sample Event",
                eventDate: Date().addingTimeInterval(86400),
                eventVenue: "Sample Venue",
                ticketType: TicketType(
                    name: "General Admission",
                    price: 50000,
                    quantity: 100
                ),
                userId: UUID()
            )
            newTickets.append(mockTicket)
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

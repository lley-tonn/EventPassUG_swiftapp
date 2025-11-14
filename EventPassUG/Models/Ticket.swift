//
//  Ticket.swift
//  EventPassUG
//
//  Purchased ticket model with QR code
//

import Foundation

enum TicketScanStatus: String, Codable {
    case unused
    case scanned
    case expired
}

struct Ticket: Identifiable, Codable, Equatable {
    let id: UUID
    let eventId: UUID
    let eventTitle: String
    let eventDate: Date
    let eventVenue: String
    let ticketType: TicketType
    let userId: UUID
    let purchaseDate: Date
    var scanStatus: TicketScanStatus
    var scanDate: Date?
    let qrCodeData: String
    let seatNumber: String?

    var isExpired: Bool {
        eventDate < Date()
    }

    var canBeScanned: Bool {
        scanStatus == .unused && !isExpired
    }

    init(
        id: UUID = UUID(),
        eventId: UUID,
        eventTitle: String,
        eventDate: Date,
        eventVenue: String,
        ticketType: TicketType,
        userId: UUID,
        purchaseDate: Date = Date(),
        scanStatus: TicketScanStatus = .unused,
        scanDate: Date? = nil,
        qrCodeData: String? = nil,
        seatNumber: String? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.eventDate = eventDate
        self.eventVenue = eventVenue
        self.ticketType = ticketType
        self.userId = userId
        self.purchaseDate = purchaseDate
        self.scanStatus = scanStatus
        self.scanDate = scanDate
        self.qrCodeData = qrCodeData ?? "TICKET:\(id.uuidString)"
        self.seatNumber = seatNumber
    }
}

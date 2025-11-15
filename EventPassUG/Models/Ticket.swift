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
    let ticketNumber: String  // Unique ticket number (e.g., "TKT-001234")
    let orderNumber: String   // Order number shared by tickets in same purchase (e.g., "ORD-789012")
    let eventId: UUID
    let eventTitle: String
    let eventDate: Date
    let eventEndDate: Date
    let eventVenue: String
    let eventVenueAddress: String
    let eventVenueCity: String
    let venueLatitude: Double
    let venueLongitude: Double
    let eventDescription: String
    let eventOrganizerName: String
    let eventPosterURL: String?
    let ticketType: TicketType
    let userId: UUID
    let purchaseDate: Date
    var scanStatus: TicketScanStatus
    var scanDate: Date?
    let qrCodeData: String
    let seatNumber: String?
    var userRating: Double?
    var expiredAt: Date?  // Timestamp when ticket expired

    var isExpired: Bool {
        eventEndDate < Date()
    }

    var canBeScanned: Bool {
        scanStatus == .unused && !isExpired
    }

    var shouldBeDeleted: Bool {
        guard let expiredDate = expiredAt else { return false }
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
        return expiredDate < sixtyDaysAgo
    }

    init(
        id: UUID = UUID(),
        ticketNumber: String,
        orderNumber: String,
        eventId: UUID,
        eventTitle: String,
        eventDate: Date,
        eventEndDate: Date,
        eventVenue: String,
        eventVenueAddress: String,
        eventVenueCity: String,
        venueLatitude: Double,
        venueLongitude: Double,
        eventDescription: String,
        eventOrganizerName: String,
        eventPosterURL: String? = nil,
        ticketType: TicketType,
        userId: UUID,
        purchaseDate: Date = Date(),
        scanStatus: TicketScanStatus = .unused,
        scanDate: Date? = nil,
        qrCodeData: String? = nil,
        seatNumber: String? = nil,
        userRating: Double? = nil,
        expiredAt: Date? = nil
    ) {
        self.id = id
        self.ticketNumber = ticketNumber
        self.orderNumber = orderNumber
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.eventDate = eventDate
        self.eventEndDate = eventEndDate
        self.eventVenue = eventVenue
        self.eventVenueAddress = eventVenueAddress
        self.eventVenueCity = eventVenueCity
        self.venueLatitude = venueLatitude
        self.venueLongitude = venueLongitude
        self.eventDescription = eventDescription
        self.eventOrganizerName = eventOrganizerName
        self.eventPosterURL = eventPosterURL
        self.ticketType = ticketType
        self.userId = userId
        self.purchaseDate = purchaseDate
        self.scanStatus = scanStatus
        self.scanDate = scanDate
        self.qrCodeData = qrCodeData ?? "TICKET:\(id.uuidString)"
        self.seatNumber = seatNumber
        self.userRating = userRating
        self.expiredAt = expiredAt
    }
}

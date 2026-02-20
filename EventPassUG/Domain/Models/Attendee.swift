//
//  Attendee.swift
//  EventPassUG
//
//  Attendee model for export functionality
//  Represents a ticket holder for a specific event
//

import Foundation

/// Represents an attendee for export purposes
/// Privacy-conscious model - email/phone are NEVER exported
struct Attendee: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let ticketId: UUID
    let orderId: String
    let fullName: String
    // NOTE: Email and phone are intentionally NOT included for privacy
    let ticketType: String
    let purchaseDate: Date
    let checkInStatus: CheckInStatus
    let attendanceStatus: AttendanceStatus
    let isVIP: Bool
    let marketingConsent: Bool

    enum CheckInStatus: String, Codable {
        case notCheckedIn = "Not Checked In"
        case checkedIn = "Checked In"
        case noShow = "No Show"
    }

    enum AttendanceStatus: String, Codable {
        case expected = "Expected"
        case attended = "Attended"
        case absent = "Absent"
    }

    /// Creates an Attendee from a Ticket and optional User data
    /// NOTE: Email/phone are intentionally NOT captured for privacy
    init(
        ticket: Ticket,
        user: User? = nil,
        marketingConsent: Bool = false
    ) {
        self.id = UUID()
        self.eventId = ticket.eventId
        self.ticketId = ticket.id
        self.orderId = ticket.orderNumber
        self.fullName = user?.fullName ?? "Unknown"
        self.ticketType = ticket.ticketType.name
        self.purchaseDate = ticket.purchaseDate
        self.marketingConsent = marketingConsent

        // Determine check-in status from scan status
        switch ticket.scanStatus {
        case .scanned:
            self.checkInStatus = .checkedIn
        case .unused:
            self.checkInStatus = .notCheckedIn
        case .expired:
            self.checkInStatus = .noShow
        }

        // Determine attendance based on scan and event timing
        if ticket.scanStatus == .scanned {
            self.attendanceStatus = .attended
        } else if ticket.isExpired {
            self.attendanceStatus = .absent
        } else {
            self.attendanceStatus = .expected
        }

        // VIP detection based on ticket type name
        let vipKeywords = ["vip", "vvip", "premium", "platinum", "gold"]
        self.isVIP = vipKeywords.contains { ticket.ticketType.name.lowercased().contains($0) }
    }

    /// Full initializer
    /// NOTE: Email/phone are intentionally NOT included for privacy
    init(
        id: UUID = UUID(),
        eventId: UUID,
        ticketId: UUID,
        orderId: String,
        fullName: String,
        ticketType: String,
        purchaseDate: Date,
        checkInStatus: CheckInStatus,
        attendanceStatus: AttendanceStatus,
        isVIP: Bool,
        marketingConsent: Bool
    ) {
        self.id = id
        self.eventId = eventId
        self.ticketId = ticketId
        self.orderId = orderId
        self.fullName = fullName
        self.ticketType = ticketType
        self.purchaseDate = purchaseDate
        self.checkInStatus = checkInStatus
        self.attendanceStatus = attendanceStatus
        self.isVIP = isVIP
        self.marketingConsent = marketingConsent
    }
}

// MARK: - Export Filter

enum AttendeeExportFilter: String, CaseIterable, Identifiable {
    case all = "All Attendees"
    case checkedIn = "Checked-in Only"
    case vip = "VIP Only"
    case marketingConsented = "Marketing Consented"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "person.3.fill"
        case .checkedIn: return "checkmark.circle.fill"
        case .vip: return "star.fill"
        case .marketingConsented: return "megaphone.fill"
        }
    }

    var description: String {
        switch self {
        case .all:
            return "Export all attendees for this event"
        case .checkedIn:
            return "Only attendees who have checked in"
        case .vip:
            return "VIP/Premium ticket holders only"
        case .marketingConsented:
            return "Attendees who opted into marketing"
        }
    }

    func filter(_ attendees: [Attendee]) -> [Attendee] {
        switch self {
        case .all:
            return attendees
        case .checkedIn:
            return attendees.filter { $0.checkInStatus == .checkedIn }
        case .vip:
            return attendees.filter { $0.isVIP }
        case .marketingConsented:
            return attendees.filter { $0.marketingConsent }
        }
    }
}

// MARK: - Mock Data

extension Attendee {
    static func mockAttendees(for eventId: UUID, count: Int = 20) -> [Attendee] {
        let firstNames = ["John", "Jane", "Michael", "Sarah", "David", "Emily", "James", "Olivia", "Robert", "Emma"]
        let lastNames = ["Mukasa", "Nakamya", "Ochieng", "Atwine", "Kato", "Namutebi", "Ssempala", "Nabatanzi", "Waiswa", "Kirabo"]
        let ticketTypes = ["General Admission", "VIP", "VVIP", "Early Bird", "Regular"]

        return (0..<count).map { _ in
            let firstName = firstNames.randomElement()!
            let lastName = lastNames.randomElement()!
            let ticketType = ticketTypes.randomElement()!
            let checkedIn = Bool.random()

            return Attendee(
                id: UUID(),
                eventId: eventId,
                ticketId: UUID(),
                orderId: String(format: "ORD-%06d", Int.random(in: 100000...999999)),
                fullName: "\(firstName) \(lastName)",
                ticketType: ticketType,
                purchaseDate: Date().addingTimeInterval(-Double.random(in: 86400...604800)),
                checkInStatus: checkedIn ? .checkedIn : .notCheckedIn,
                attendanceStatus: checkedIn ? .attended : .expected,
                isVIP: ticketType.lowercased().contains("vip"),
                marketingConsent: Bool.random()
            )
        }
    }
}

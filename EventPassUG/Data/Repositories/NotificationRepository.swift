//
//  NotificationService.swift
//  EventPassUG
//
//  Service for sending ticket confirmations via email or SMS
//

import Foundation

// MARK: - Protocol

protocol NotificationRepositoryProtocol {
    func sendTicketConfirmation(to user: User, ticket: Ticket) async throws
    func sendTicketConfirmation(to user: User, tickets: [Ticket]) async throws
}

// MARK: - Notification Result

struct NotificationResult {
    let success: Bool
    let method: ContactMethod
    let message: String
}

// MARK: - Mock Implementation

class MockNotificationRepository: NotificationRepositoryProtocol {

    // MARK: - Send Single Ticket Confirmation

    func sendTicketConfirmation(to user: User, ticket: Ticket) async throws {
        try await sendTicketConfirmation(to: user, tickets: [ticket])
    }

    // MARK: - Send Multiple Tickets Confirmation

    func sendTicketConfirmation(to user: User, tickets: [Ticket]) async throws {
        guard !tickets.isEmpty else { return }

        // Determine the contact method based on user's primary preference
        let contactMethod = determineContactMethod(for: user)

        // Build confirmation message
        let message = buildConfirmationMessage(for: tickets)

        // Send notification based on method
        switch contactMethod {
        case .email:
            try await sendEmailConfirmation(to: user, message: message, tickets: tickets)
        case .phone:
            try await sendSMSConfirmation(to: user, message: message, tickets: tickets)
        }
    }

    // MARK: - Private Methods

    private func determineContactMethod(for user: User) -> ContactMethod {
        // Priority: user's primary contact method > verified email > verified phone > any email > any phone
        if let primary = user.primaryContactMethod {
            return primary
        }

        if user.email != nil && user.isEmailVerified {
            return .email
        }

        if user.phoneNumber != nil && user.isPhoneVerified {
            return .phone
        }

        if user.email != nil {
            return .email
        }

        return .phone
    }

    private func buildConfirmationMessage(for tickets: [Ticket]) -> String {
        guard let firstTicket = tickets.first else { return "" }

        let eventName = firstTicket.eventTitle
        let purchaseDate = firstTicket.purchaseDate.formatted(date: .abbreviated, time: .shortened)
        let ticketType = firstTicket.ticketType.name
        let quantity = tickets.count
        let ticketIds = tickets.map { $0.ticketNumber }.joined(separator: ", ")
        let qrCodes = tickets.map { $0.qrCodeData }.joined(separator: "\n")

        return """
        Ticket Purchase Confirmation

        Event: \(eventName)
        Purchase Date: \(purchaseDate)
        Ticket Type: \(ticketType)
        Quantity: \(quantity)

        Ticket ID(s): \(ticketIds)

        QR Code Data:
        \(qrCodes)

        Please present your QR code at the venue entrance.

        Thank you for your purchase!
        - EventPass UG Team
        """
    }

    private func sendEmailConfirmation(to user: User, message: String, tickets: [Ticket]) async throws {
        guard let email = user.email else {
            throw NSError(
                domain: "NotificationService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No email address available"]
            )
        }

        // TODO: Replace with real email API (e.g., SendGrid, Mailgun, Firebase)
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        print("""
        [MOCK EMAIL SERVICE]
        To: \(email)
        Subject: Your EventPass UG Ticket Confirmation
        Body:
        \(message)
        """)

        // In production, this would call an actual email service
        // For example:
        // try await EmailAPI.send(
        //     to: email,
        //     subject: "Your EventPass UG Ticket Confirmation",
        //     body: message,
        //     attachments: tickets.map { generateQRCodePDF($0) }
        // )
    }

    private func sendSMSConfirmation(to user: User, message: String, tickets: [Ticket]) async throws {
        guard let phoneNumber = user.phoneNumber else {
            throw NSError(
                domain: "NotificationService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No phone number available"]
            )
        }

        // TODO: Replace with real SMS API (e.g., Twilio, Firebase, AfricasTalking)
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // SMS messages have character limits, so we send a condensed version
        guard let firstTicket = tickets.first else { return }

        let smsMessage = """
        EventPass UG: Your ticket for \(firstTicket.eventTitle) is confirmed!
        Ticket ID: \(firstTicket.ticketNumber)
        Date: \(firstTicket.eventDate.formatted(date: .abbreviated, time: .shortened))
        Qty: \(tickets.count)
        Show QR code at entrance.
        """

        print("""
        [MOCK SMS SERVICE]
        To: \(phoneNumber)
        Message: \(smsMessage)
        """)

        // In production, this would call an actual SMS service
        // For example:
        // try await SMSAPI.send(
        //     to: phoneNumber,
        //     message: smsMessage
        // )
    }
}

//
//  Event+TicketSales.swift
//  EventPassUG
//
//  Time-based ticket sales logic
//  Automatically stops sales when event starts
//

import Foundation

extension Event {

    // MARK: - Ticket Sales Status

    /// Whether ticket sales are currently open
    /// Sales close when the event starts or if event is not published
    var isTicketSalesOpen: Bool {
        // Must be published
        guard status == .published else { return false }

        // Must not have started
        guard !hasStarted else { return false }

        // Must not have ended
        guard !hasEnded else { return false }

        return true
    }

    /// Whether the event has started
    var hasStarted: Bool {
        Date() >= startDate
    }

    /// Whether the event has ended
    var hasEnded: Bool {
        Date() >= endDate
    }

    /// Time remaining until ticket sales close (in seconds)
    var timeUntilSalesClose: TimeInterval? {
        guard isTicketSalesOpen else { return nil }
        return startDate.timeIntervalSinceNow
    }

    /// User-friendly message about ticket sales status
    var ticketSalesStatusMessage: String {
        if hasEnded {
            return "This event has ended"
        }

        if hasStarted {
            return "Ticket sales have ended (event has started)"
        }

        if status != .published {
            return "This event is not available for ticket purchase"
        }

        return "Tickets available"
    }

    /// Color for ticket sales status
    var ticketSalesStatusColor: String {
        if isTicketSalesOpen {
            return "green"
        }
        return "red"
    }

    // MARK: - Formatted Time Strings

    /// Formatted countdown until sales close
    /// Example: "2 days 5 hours"
    var formattedTimeUntilSalesClose: String? {
        guard let timeRemaining = timeUntilSalesClose, timeRemaining > 0 else {
            return nil
        }

        let days = Int(timeRemaining) / 86400
        let hours = (Int(timeRemaining) % 86400) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60

        if days > 0 {
            if hours > 0 {
                return "\(days)d \(hours)h"
            }
            return "\(days) \(days == 1 ? "day" : "days")"
        }

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours) \(hours == 1 ? "hour" : "hours")"
        }

        return "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
    }

    /// Short countdown format for badges
    /// Example: "2d 5h" or "30m"
    var shortCountdown: String? {
        guard let timeRemaining = timeUntilSalesClose, timeRemaining > 0 else {
            return nil
        }

        let days = Int(timeRemaining) / 86400
        let hours = (Int(timeRemaining) % 86400) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}

// MARK: - TicketType Extensions

extension TicketType {

    /// Whether this ticket type can be purchased
    /// Considers both ticket-specific rules and event start time
    func canPurchase(eventStartDate: Date, eventStatus: EventStatus) -> Bool {
        // Event must be published
        guard eventStatus == .published else { return false }

        // Event must not have started
        guard Date() < eventStartDate else { return false }

        // Ticket must not be sold out
        guard !isSoldOut else { return false }

        // Check ticket-specific sale window
        let now = Date()
        guard now >= saleStartDate && now <= saleEndDate else {
            return false
        }

        return true
    }

    /// User-friendly message about ticket availability
    func availabilityMessage(eventStartDate: Date, eventStatus: EventStatus) -> String {
        if isSoldOut {
            return "Sold Out"
        }

        if Date() >= eventStartDate {
            return "Sales Ended"
        }

        if eventStatus != .published {
            return "Not Available"
        }

        let now = Date()
        if now < saleStartDate {
            return "Sales start \(DateUtilities.formatRelativeDate(saleStartDate))"
        }

        if now > saleEndDate {
            return "Sales window ended"
        }

        return "Available"
    }
}

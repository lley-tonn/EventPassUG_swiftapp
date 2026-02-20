//
//  CSVGenerator.swift
//  EventPassUG
//
//  CSV file generation utility for export functionality
//

import Foundation

class CSVGenerator {

    // MARK: - Attendee Export

    /// Generates a CSV file for attendees of a specific event
    /// - Parameters:
    ///   - attendees: Array of attendees to export (must all belong to same event)
    ///   - eventTitle: Title of the event for the filename
    ///   - filter: Filter type used for filename and header
    /// - Returns: URL to the generated CSV file, or nil if generation fails
    static func generateAttendeeCSV(
        attendees: [Attendee],
        eventTitle: String,
        filter: AttendeeExportFilter
    ) -> URL? {
        // Verify all attendees belong to the same event
        guard let firstEventId = attendees.first?.eventId else {
            return nil
        }

        let allSameEvent = attendees.allSatisfy { $0.eventId == firstEventId }
        guard allSameEvent else {
            print("CSVGenerator Error: Attendees belong to multiple events. Export must be scoped to single event.")
            return nil
        }

        var csvContent = ""

        // Header row - Email/Phone are NEVER exported for privacy
        let headers = [
            "Full Name",
            "Ticket Type",
            "Order ID",
            "Purchase Date",
            "Check-in Status",
            "Attendance Status"
        ]
        csvContent += headers.joined(separator: ",") + "\n"

        // Data rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        for attendee in attendees {
            let row = [
                escapeCSV(attendee.fullName),
                escapeCSV(attendee.ticketType),
                escapeCSV(attendee.orderId),
                escapeCSV(dateFormatter.string(from: attendee.purchaseDate)),
                escapeCSV(attendee.checkInStatus.rawValue),
                escapeCSV(attendee.attendanceStatus.rawValue)
            ]
            csvContent += row.joined(separator: ",") + "\n"
        }

        // Generate filename
        let sanitizedTitle = eventTitle
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let filterSuffix = filter == .all ? "" : "_\(filter.rawValue.replacingOccurrences(of: " ", with: "_"))"
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .prefix(10)
        let fileName = "Attendees_\(sanitizedTitle)\(filterSuffix)_\(timestamp).csv"

        // Save to temporary directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("CSVGenerator Error: Failed to write CSV - \(error)")
            return nil
        }
    }

    // MARK: - Event Report CSV Export

    /// Generates a CSV summary report for a specific event's analytics
    /// - Parameters:
    ///   - analytics: The analytics data for the event
    ///   - event: The event being exported
    /// - Returns: URL to the generated CSV file, or nil if generation fails
    static func generateEventReportCSV(
        analytics: OrganizerAnalytics,
        event: Event
    ) -> URL? {
        // Verify analytics belongs to the correct event
        guard analytics.eventId == event.id else {
            print("CSVGenerator Error: Analytics eventId does not match event.id. Export must be scoped to single event.")
            return nil
        }

        var csvContent = ""

        // Event Summary Section
        csvContent += "Event Report\n"
        csvContent += "Generated,\(ISO8601DateFormatter().string(from: Date()))\n"
        csvContent += "\n"

        // Event Details
        csvContent += "Event Details\n"
        csvContent += "Event Name,\(escapeCSV(event.title))\n"
        csvContent += "Event Date,\(formatDate(event.startDate))\n"
        csvContent += "Venue,\(escapeCSV(event.venue.name))\n"
        csvContent += "Location,\(escapeCSV("\(event.venue.city), \(event.venue.address)"))\n"
        csvContent += "\n"

        // Revenue Metrics
        csvContent += "Revenue Metrics\n"
        csvContent += "Total Revenue,\(formatCurrency(analytics.revenue))\n"
        csvContent += "Gross Revenue,\(formatCurrency(analytics.grossRevenue))\n"
        csvContent += "Net Revenue,\(formatCurrency(analytics.netRevenue))\n"
        csvContent += "Platform Fees,\(formatCurrency(analytics.platformFees))\n"
        csvContent += "Processing Fees,\(formatCurrency(analytics.processingFees))\n"
        csvContent += "\n"

        // Ticket Sales
        csvContent += "Ticket Sales\n"
        csvContent += "Tickets Sold,\(analytics.ticketsSold)\n"
        csvContent += "Total Capacity,\(analytics.totalCapacity)\n"
        csvContent += "Capacity Used,\(String(format: "%.1f%%", analytics.capacityUsed * 100))\n"
        csvContent += "\n"

        // Attendance
        csvContent += "Attendance\n"
        csvContent += "Attendance Rate,\(String(format: "%.1f%%", analytics.attendanceRate * 100))\n"
        csvContent += "Check-in Rate,\(String(format: "%.1f%%", analytics.checkinRate * 100))\n"
        csvContent += "\n"

        // Refunds
        csvContent += "Refunds\n"
        csvContent += "Refund Count,\(analytics.refundsCount)\n"
        csvContent += "Refund Amount,\(formatCurrency(analytics.refundsTotal))\n"
        csvContent += "\n"

        // Payment Methods
        csvContent += "Payment Method Breakdown\n"
        csvContent += "Method,Amount,Count,Percentage\n"
        for payment in analytics.paymentMethodsSplit {
            csvContent += "\(escapeCSV(payment.method)),\(formatCurrency(payment.amount)),\(payment.count),\(String(format: "%.1f%%", payment.percentage * 100))\n"
        }
        csvContent += "\n"

        // Ticket Tier Breakdown
        csvContent += "Ticket Tier Breakdown\n"
        csvContent += "Tier,Sold,Capacity,Revenue,Price\n"
        for tier in analytics.salesByTier {
            csvContent += "\(escapeCSV(tier.tierName)),\(tier.sold),\(tier.capacity),\(formatCurrency(tier.revenue)),\(formatCurrency(tier.price))\n"
        }

        // Generate filename
        let sanitizedTitle = event.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .prefix(10)
        let fileName = "EventReport_\(sanitizedTitle)_\(timestamp).csv"

        // Save to temporary directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("CSVGenerator Error: Failed to write CSV - \(error)")
            return nil
        }
    }

    // MARK: - Helper Functions

    /// Escapes a string value for CSV format
    private static func escapeCSV(_ value: String) -> String {
        // If the value contains commas, quotes, or newlines, wrap in quotes and escape existing quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func formatCurrency(_ amount: Double) -> String {
        return String(format: "UGX %.0f", amount)
    }
}

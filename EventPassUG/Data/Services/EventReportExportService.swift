//
//  EventReportExportService.swift
//  EventPassUG
//
//  Service for exporting event analytics reports
//  CRITICAL: All exports are strictly scoped to a single eventId
//

import Foundation
import UIKit

/// Export format options for event reports
enum EventReportExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case csv = "CSV"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .csv: return "tablecells"
        }
    }

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .csv: return "csv"
        }
    }
}

/// Service responsible for generating event analytics exports
/// All exports are scoped to a single event - never exports cross-event data
class EventReportExportService {

    // MARK: - Export Report

    /// Generates an analytics report for a SPECIFIC event only
    /// - Parameters:
    ///   - event: The event to generate the report for
    ///   - analytics: Analytics data for this specific event
    ///   - format: The export format (PDF or CSV)
    /// - Returns: URL to the generated file, or nil if generation fails
    func exportReport(
        for event: Event,
        analytics: OrganizerAnalytics,
        format: EventReportExportFormat
    ) async throws -> URL? {
        // CRITICAL SAFETY CHECK: Verify analytics belongs to this event
        guard analytics.eventId == event.id else {
            throw ExportError.eventMismatch
        }

        // Track analytics
        trackExportAnalytics(eventId: event.id, format: format)

        switch format {
        case .pdf:
            return generatePDFReport(for: event, analytics: analytics)
        case .csv:
            return CSVGenerator.generateEventReportCSV(analytics: analytics, event: event)
        }
    }

    // MARK: - PDF Generation

    /// Generates a PDF report for the event
    private func generatePDFReport(for event: Event, analytics: OrganizerAnalytics) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "EventPass UG",
            kCGPDFContextAuthor: event.organizerName,
            kCGPDFContextTitle: "Event Report - \(event.title)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        // A4 page size
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            let cgContext = context.cgContext

            let leftMargin: CGFloat = 40
            let rightMargin: CGFloat = pageWidth - 40
            _ = rightMargin - leftMargin // contentWidth available if needed
            var yPosition: CGFloat = 40

            // Header with branding
            yPosition = drawHeader(
                cgContext: cgContext,
                pageWidth: pageWidth,
                leftMargin: leftMargin,
                yPosition: yPosition,
                eventTitle: event.title
            )

            // Event Details Section
            yPosition = drawSection(
                cgContext: cgContext,
                title: "Event Details",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition = drawKeyValue(
                label: "Event Name",
                value: event.title,
                leftMargin: leftMargin,
                yPosition: yPosition
            )
            yPosition = drawKeyValue(
                label: "Event Date",
                value: formatDate(event.startDate),
                leftMargin: leftMargin,
                yPosition: yPosition
            )
            yPosition = drawKeyValue(
                label: "Venue",
                value: "\(event.venue.name), \(event.venue.city)",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition += 20

            // Revenue Section
            yPosition = drawSection(
                cgContext: cgContext,
                title: "Revenue",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition = drawKeyValue(
                label: "Total Revenue",
                value: formatCurrency(analytics.revenue),
                leftMargin: leftMargin,
                yPosition: yPosition,
                valueColor: UIColor.systemGreen
            )
            yPosition = drawKeyValue(
                label: "Net Revenue",
                value: formatCurrency(analytics.netRevenue),
                leftMargin: leftMargin,
                yPosition: yPosition
            )
            yPosition = drawKeyValue(
                label: "Platform Fees",
                value: formatCurrency(analytics.platformFees),
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition += 20

            // Ticket Sales Section
            yPosition = drawSection(
                cgContext: cgContext,
                title: "Ticket Sales",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition = drawKeyValue(
                label: "Tickets Sold",
                value: "\(analytics.ticketsSold)",
                leftMargin: leftMargin,
                yPosition: yPosition
            )
            yPosition = drawKeyValue(
                label: "Total Capacity",
                value: "\(analytics.totalCapacity)",
                leftMargin: leftMargin,
                yPosition: yPosition
            )
            yPosition = drawKeyValue(
                label: "Capacity Used",
                value: String(format: "%.1f%%", analytics.capacityUsed * 100),
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition += 20

            // Attendance Section
            yPosition = drawSection(
                cgContext: cgContext,
                title: "Attendance",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition = drawKeyValue(
                label: "Attendance Rate",
                value: String(format: "%.1f%%", analytics.attendanceRate * 100),
                leftMargin: leftMargin,
                yPosition: yPosition
            )
            yPosition = drawKeyValue(
                label: "Check-in Rate",
                value: String(format: "%.1f%%", analytics.checkinRate * 100),
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition += 20

            // Refunds Section
            yPosition = drawSection(
                cgContext: cgContext,
                title: "Refunds",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            yPosition = drawKeyValue(
                label: "Refund Count",
                value: "\(analytics.refundsCount)",
                leftMargin: leftMargin,
                yPosition: yPosition
            )
            yPosition = drawKeyValue(
                label: "Refund Amount",
                value: formatCurrency(analytics.refundsTotal),
                leftMargin: leftMargin,
                yPosition: yPosition,
                valueColor: UIColor.systemRed
            )

            yPosition += 20

            // Payment Methods Section
            yPosition = drawSection(
                cgContext: cgContext,
                title: "Payment Method Split",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            for payment in analytics.paymentMethodsSplit {
                yPosition = drawKeyValue(
                    label: payment.method,
                    value: "\(formatCurrency(payment.amount)) (\(String(format: "%.0f%%", payment.percentage * 100)))",
                    leftMargin: leftMargin,
                    yPosition: yPosition
                )
            }

            yPosition += 20

            // Check if we need a new page for ticket tier breakdown
            if yPosition > pageHeight - 200 {
                context.beginPage()
                yPosition = 40
            }

            // Ticket Tier Breakdown Section
            yPosition = drawSection(
                cgContext: cgContext,
                title: "Ticket Tier Breakdown",
                leftMargin: leftMargin,
                yPosition: yPosition
            )

            for tier in analytics.salesByTier {
                let tierInfo = "\(tier.sold)/\(tier.capacity) sold - \(formatCurrency(tier.revenue))"
                yPosition = drawKeyValue(
                    label: tier.tierName,
                    value: tierInfo,
                    leftMargin: leftMargin,
                    yPosition: yPosition
                )
            }

            // Footer
            drawFooter(
                cgContext: cgContext,
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                leftMargin: leftMargin
            )
        }

        // Save to temporary directory
        let sanitizedTitle = event.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .prefix(10)
        let fileName = "EventReport_\(sanitizedTitle)_\(timestamp).pdf"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("EventReportExportService Error: Failed to write PDF - \(error)")
            return nil
        }
    }

    // MARK: - Drawing Helpers

    private func drawHeader(
        cgContext: CGContext,
        pageWidth: CGFloat,
        leftMargin: CGFloat,
        yPosition: CGFloat,
        eventTitle: String
    ) -> CGFloat {
        var y = yPosition

        // EventPass UG branding
        let brandAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(red: 1.0, green: 0.48, blue: 0.0, alpha: 1.0) // Organizer primary
        ]
        "EventPass UG".draw(at: CGPoint(x: leftMargin, y: y), withAttributes: brandAttributes)
        y += 35

        // Report Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        "Event Analytics Report".draw(at: CGPoint(x: leftMargin, y: y), withAttributes: titleAttributes)
        y += 30

        // Event Title
        let eventTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        eventTitle.draw(at: CGPoint(x: leftMargin, y: y), withAttributes: eventTitleAttributes)
        y += 25

        // Generated date
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let dateString = "Generated: \(formatDate(Date()))"
        dateString.draw(at: CGPoint(x: leftMargin, y: y), withAttributes: dateAttributes)
        y += 30

        // Divider
        cgContext.setStrokeColor(UIColor.separator.cgColor)
        cgContext.setLineWidth(1)
        cgContext.move(to: CGPoint(x: leftMargin, y: y))
        cgContext.addLine(to: CGPoint(x: pageWidth - 40, y: y))
        cgContext.strokePath()
        y += 20

        return y
    }

    private func drawSection(
        cgContext: CGContext,
        title: String,
        leftMargin: CGFloat,
        yPosition: CGFloat
    ) -> CGFloat {
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor(red: 1.0, green: 0.48, blue: 0.0, alpha: 1.0)
        ]
        title.uppercased().draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionAttributes)
        return yPosition + 25
    }

    private func drawKeyValue(
        label: String,
        value: String,
        leftMargin: CGFloat,
        yPosition: CGFloat,
        valueColor: UIColor = .label
    ) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: valueColor
        ]

        label.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: labelAttributes)
        value.draw(at: CGPoint(x: leftMargin + 150, y: yPosition), withAttributes: valueAttributes)

        return yPosition + 20
    }

    private func drawFooter(
        cgContext: CGContext,
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        leftMargin: CGFloat
    ) {
        let footerY = pageHeight - 40

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.tertiaryLabel
        ]

        "Powered by EventPass UG".draw(at: CGPoint(x: leftMargin, y: footerY), withAttributes: footerAttributes)

        let pageText = "Page 1"
        let pageTextWidth = pageText.size(withAttributes: footerAttributes).width
        pageText.draw(at: CGPoint(x: pageWidth - 40 - pageTextWidth, y: footerY), withAttributes: footerAttributes)
    }

    // MARK: - Analytics Tracking

    private func trackExportAnalytics(eventId: UUID, format: EventReportExportFormat) {
        // Track the export event
        let analyticsEvent = ExportAnalyticsEvent(
            name: "event_report_exported",
            eventId: eventId,
            format: format.rawValue,
            timestamp: Date()
        )

        print("Analytics: \(analyticsEvent.name) - eventId: \(eventId), format: \(format.rawValue)")
        // TODO: Send to analytics service
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "UGX %.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "UGX %.0fK", amount / 1_000)
        }
        return String(format: "UGX %.0f", amount)
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case eventMismatch
    case noDataToExport
    case fileGenerationFailed

    var errorDescription: String? {
        switch self {
        case .eventMismatch:
            return "Export data does not match the specified event"
        case .noDataToExport:
            return "No data available to export"
        case .fileGenerationFailed:
            return "Failed to generate export file"
        }
    }
}

// MARK: - Analytics Event

struct ExportAnalyticsEvent {
    let name: String
    let eventId: UUID
    let format: String
    let timestamp: Date
    var filterType: String?
    var attendeeCount: Int?
}

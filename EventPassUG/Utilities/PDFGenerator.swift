//
//  PDFGenerator.swift
//  EventPassUG
//
//  Enhanced PDF generator with color extraction and beautiful styling
//

import UIKit
import PDFKit

class PDFGenerator {

    static func generateTicketPDF(ticket: Ticket) -> URL? {
        // Extract colors from poster
        let colorScheme: ImageColorExtractor.ColorScheme
        if let posterURL = ticket.eventPosterURL,
           let posterImage = UIImage(named: posterURL) {
            colorScheme = ImageColorExtractor.extractColors(from: posterImage)
        } else {
            colorScheme = .default
        }

        let pdfMetaData = [
            kCGPDFContextCreator: "EventPass UG",
            kCGPDFContextAuthor: ticket.eventOrganizerName,
            kCGPDFContextTitle: "Ticket - \(ticket.eventTitle)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        // Page size (A4)
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            let cgContext = context.cgContext

            var yPosition: CGFloat = 0
            let leftMargin: CGFloat = 40
            let rightMargin: CGFloat = pageWidth - 40
            let contentWidth = rightMargin - leftMargin

            // Gradient Header Background (reduced height)
            drawGradientHeader(
                context: cgContext,
                rect: CGRect(x: 0, y: 0, width: pageWidth, height: 120),
                topColor: colorScheme.primary,
                bottomColor: colorScheme.secondary
            )

            // Header content
            yPosition = 20

            // EventPass UG Logo/Title
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            "EventPass UG".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 35

            // Ticket Number - Large and prominent
            let ticketNumAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            ticket.ticketNumber.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: ticketNumAttributes)
            yPosition += 25

            // Order Number
            let orderNumAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            "Order: \(ticket.orderNumber)".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: orderNumAttributes)

            yPosition = 130  // Move past gradient header

            // Event Title Section with colored background
            let titleBoxRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: 60)
            cgContext.setFillColor(colorScheme.primary.withAlphaComponent(0.1).cgColor)
            cgContext.fill(titleBoxRect)

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: colorScheme.primary
            ]
            let titleRect = CGRect(x: leftMargin + 12, y: yPosition + 12, width: contentWidth - 24, height: 36)
            ticket.eventTitle.draw(in: titleRect, withAttributes: titleAttributes)
            yPosition += 70

            // Organizer
            let organizerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            "Organized by \(ticket.eventOrganizerName)".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: organizerAttributes)
            yPosition += 22

            // Colored divider
            drawColoredDivider(at: yPosition, leftMargin: leftMargin, rightMargin: rightMargin, color: colorScheme.secondary, context: cgContext)
            yPosition += 15

            // Ticket Details in colored box
            let detailsBoxRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: 70)
            cgContext.setFillColor(colorScheme.accent.withAlphaComponent(0.08).cgColor)
            cgContext.fill(detailsBoxRect)

            let detailsY = yPosition + 12
            yPosition = drawStyledLabelValue(
                label: "Ticket Type",
                value: ticket.ticketType.name,
                yPosition: detailsY,
                leftMargin: leftMargin + 12,
                color: colorScheme.accent
            )
            yPosition = drawStyledLabelValue(
                label: "Price",
                value: ticket.ticketType.formattedPrice,
                yPosition: yPosition,
                leftMargin: leftMargin + 12,
                color: colorScheme.accent
            )

            yPosition = detailsBoxRect.maxY + 15

            // Date and Time
            drawColoredDivider(at: yPosition, leftMargin: leftMargin, rightMargin: rightMargin, color: colorScheme.primary, context: cgContext)
            yPosition += 15

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .short

            yPosition = drawStyledLabelValue(
                label: "DATE & TIME",
                value: dateFormatter.string(from: ticket.eventDate),
                yPosition: yPosition,
                leftMargin: leftMargin,
                color: colorScheme.primary
            )

            yPosition = drawStyledLabelValue(
                label: "VENUE",
                value: ticket.eventVenue,
                yPosition: yPosition,
                leftMargin: leftMargin,
                color: colorScheme.primary
            )

            yPosition = drawStyledLabelValue(
                label: "LOCATION",
                value: "\(ticket.eventVenueAddress), \(ticket.eventVenueCity)",
                yPosition: yPosition,
                leftMargin: leftMargin,
                color: colorScheme.primary
            )

            yPosition += 8
            drawColoredDivider(at: yPosition, leftMargin: leftMargin, rightMargin: rightMargin, color: colorScheme.secondary, context: cgContext)
            yPosition += 18

            // QR Code Section with colored background
            let qrSectionLabel: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: colorScheme.primary
            ]
            "ENTRY QR CODE".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: qrSectionLabel)
            yPosition += 28

            // QR Code with colored border (reduced size)
            if let qrImage = QRCodeGenerator.generate(from: ticket.qrCodeData, size: CGSize(width: 180, height: 180)) {
                let qrX = (pageWidth - 180) / 2
                let qrRect = CGRect(x: qrX, y: yPosition, width: 180, height: 180)

                // Colored border around QR
                cgContext.setStrokeColor(colorScheme.primary.cgColor)
                cgContext.setLineWidth(3)
                cgContext.stroke(qrRect.insetBy(dx: -8, dy: -8))

                // White background
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fill(qrRect)

                // Draw QR code
                qrImage.draw(in: qrRect)
                yPosition += 196
            }

            // Scan instruction
            let instructionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: colorScheme.secondary
            ]
            let instruction = "Present this QR code at the venue entrance for verification"
            let instructionWidth = instruction.size(withAttributes: instructionAttributes).width
            instruction.draw(at: CGPoint(x: (pageWidth - instructionWidth) / 2, y: yPosition), withAttributes: instructionAttributes)
            yPosition += 20

            // Ticket ID
            let ticketIdAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            let ticketId = "ID: \(ticket.id.uuidString.prefix(12).uppercased())"
            let ticketIdWidth = ticketId.size(withAttributes: ticketIdAttributes).width
            ticketId.draw(at: CGPoint(x: (pageWidth - ticketIdWidth) / 2, y: yPosition), withAttributes: ticketIdAttributes)
            yPosition += 25

            // Footer with gradient
            drawColoredDivider(at: yPosition, leftMargin: leftMargin, rightMargin: rightMargin, color: colorScheme.accent, context: cgContext)
            yPosition += 12

            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                .foregroundColor: UIColor.gray
            ]

            let purchaseText = "Purchased: \(dateFormatter.string(from: ticket.purchaseDate))"
            purchaseText.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: footerAttributes)

            let footerText = "Powered by EventPass UG"
            let footerWidth = footerText.size(withAttributes: footerAttributes).width
            footerText.draw(at: CGPoint(x: rightMargin - footerWidth, y: yPosition), withAttributes: footerAttributes)
        }

        // Save to temporary directory
        let fileName = "Ticket_\(ticket.ticketNumber)_\(ticket.eventTitle.replacingOccurrences(of: " ", with: "_")).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }

    private static func drawGradientHeader(context: CGContext, rect: CGRect, topColor: UIColor, bottomColor: UIColor) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
            return
        }

        context.saveGState()
        context.clip(to: rect)
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
        context.restoreGState()
    }

    private static func drawColoredDivider(at yPosition: CGFloat, leftMargin: CGFloat, rightMargin: CGFloat, color: UIColor, context: CGContext) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: leftMargin, y: yPosition))
        context.addLine(to: CGPoint(x: rightMargin, y: yPosition))
        context.strokePath()
    }

    private static func drawStyledLabelValue(label: String, value: String, yPosition: CGFloat, leftMargin: CGFloat, color: UIColor) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: color,
            .kern: 1.0
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: UIColor.black
        ]

        label.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: labelAttributes)
        value.draw(at: CGPoint(x: leftMargin, y: yPosition + 15), withAttributes: valueAttributes)

        return yPosition + 40
    }
}

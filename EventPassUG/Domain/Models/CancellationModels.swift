//
//  CancellationModels.swift
//  EventPassUG
//
//  Comprehensive event cancellation models for fintech-grade reliability
//  Ensures all paid tickets are compensated and states remain consistent
//

import Foundation
import SwiftUI

// MARK: - Cancellation Status

/// Tracks the lifecycle of an event cancellation
enum CancellationStatus: String, Codable, CaseIterable {
    case draft = "draft"                 // Cancellation started but not confirmed
    case confirming = "confirming"       // Awaiting final confirmation
    case processing = "processing"       // Cancellation in progress
    case completed = "completed"         // Fully cancelled and compensated
    case failed = "failed"               // Cancellation failed (requires manual intervention)

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .confirming: return "Awaiting Confirmation"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .draft: return .gray
        case .confirming: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    var icon: String {
        switch self {
        case .draft: return "doc.fill"
        case .confirming: return "exclamationmark.triangle.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.seal.fill"
        case .failed: return "xmark.octagon.fill"
        }
    }

    var isReversible: Bool {
        switch self {
        case .draft, .confirming:
            return true
        case .processing, .completed, .failed:
            return false
        }
    }
}

// MARK: - Cancellation Reason

/// Categorizes why an event is being cancelled
enum CancellationReason: String, Codable, CaseIterable, Identifiable {
    case organizerDecision = "organizer_decision"
    case venueIssue = "venue_issue"
    case forceMajeure = "force_majeure"
    case regulation = "regulation"
    case lowSales = "low_sales"
    case duplicate = "duplicate"
    case adminAction = "admin_action"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .organizerDecision: return "Organizer Decision"
        case .venueIssue: return "Venue Issue"
        case .forceMajeure: return "Force Majeure"
        case .regulation: return "Government Regulation"
        case .lowSales: return "Low Ticket Sales"
        case .duplicate: return "Duplicate Event"
        case .adminAction: return "Platform Action"
        }
    }

    var description: String {
        switch self {
        case .organizerDecision:
            return "You have decided to cancel this event"
        case .venueIssue:
            return "The venue is no longer available or suitable"
        case .forceMajeure:
            return "Unforeseeable circumstances (natural disaster, pandemic, etc.)"
        case .regulation:
            return "Government restrictions or regulatory requirements"
        case .lowSales:
            return "Insufficient ticket sales to proceed"
        case .duplicate:
            return "This event was created in error (duplicate)"
        case .adminAction:
            return "EventPass platform administrative action"
        }
    }

    var icon: String {
        switch self {
        case .organizerDecision: return "person.fill.xmark"
        case .venueIssue: return "building.2.fill"
        case .forceMajeure: return "exclamationmark.triangle.fill"
        case .regulation: return "building.columns.fill"
        case .lowSales: return "chart.line.downtrend.xyaxis"
        case .duplicate: return "doc.on.doc.fill"
        case .adminAction: return "shield.fill"
        }
    }

    /// Reasons that typically warrant full refund
    var warrantsFullRefund: Bool {
        switch self {
        case .organizerDecision, .venueIssue, .forceMajeure, .regulation, .duplicate, .adminAction:
            return true
        case .lowSales:
            return true // Still full refund, but might affect organizer payout
        }
    }

    /// Reasons available to organizers (vs admin-only)
    static var organizerReasons: [CancellationReason] {
        [.organizerDecision, .venueIssue, .forceMajeure, .regulation, .lowSales, .duplicate]
    }

    /// Reasons only available to platform admins
    static var adminOnlyReasons: [CancellationReason] {
        [.adminAction]
    }
}

// MARK: - Compensation Type

/// How attendees will be compensated
enum CompensationType: String, Codable, CaseIterable {
    case fullRefund = "full_refund"
    case partialRefund = "partial_refund"
    case eventCredit = "event_credit"

    var displayName: String {
        switch self {
        case .fullRefund: return "Full Refund"
        case .partialRefund: return "Partial Refund"
        case .eventCredit: return "Event Credit"
        }
    }

    var description: String {
        switch self {
        case .fullRefund:
            return "100% of ticket price refunded to original payment method"
        case .partialRefund:
            return "Percentage of ticket price refunded"
        case .eventCredit:
            return "Credit for future EventPass events"
        }
    }

    var icon: String {
        switch self {
        case .fullRefund: return "arrow.uturn.backward.circle.fill"
        case .partialRefund: return "percent"
        case .eventCredit: return "creditcard.fill"
        }
    }
}

// MARK: - Cancellation Impact

/// Calculated impact of cancelling an event
struct CancellationImpact: Codable, Equatable {
    let eventId: UUID
    let calculatedAt: Date

    // Ticket statistics
    let ticketsSold: Int
    let attendeesCount: Int  // Unique attendees (may differ from tickets)
    let vipTickets: Int
    let regularTickets: Int
    let checkInsCompleted: Int
    let pendingPayments: Int
    let transferredTickets: Int
    let partiallyRefundedTickets: Int

    // Financial impact
    let grossRevenue: Double
    let refundTotal: Double
    let platformFeesRetained: Double
    let processingFeesEstimate: Double
    let netRefundAmount: Double
    let organizerPayoutAdjustment: Double

    // Currency
    let currency: String

    // Breakdown by ticket type
    let ticketTypeBreakdown: [TicketTypeImpact]

    // Payment method breakdown
    let paymentMethodBreakdown: [PaymentMethodImpact]

    init(
        eventId: UUID,
        calculatedAt: Date = Date(),
        ticketsSold: Int = 0,
        attendeesCount: Int = 0,
        vipTickets: Int = 0,
        regularTickets: Int = 0,
        checkInsCompleted: Int = 0,
        pendingPayments: Int = 0,
        transferredTickets: Int = 0,
        partiallyRefundedTickets: Int = 0,
        grossRevenue: Double = 0,
        refundTotal: Double = 0,
        platformFeesRetained: Double = 0,
        processingFeesEstimate: Double = 0,
        netRefundAmount: Double = 0,
        organizerPayoutAdjustment: Double = 0,
        currency: String = "UGX",
        ticketTypeBreakdown: [TicketTypeImpact] = [],
        paymentMethodBreakdown: [PaymentMethodImpact] = []
    ) {
        self.eventId = eventId
        self.calculatedAt = calculatedAt
        self.ticketsSold = ticketsSold
        self.attendeesCount = attendeesCount
        self.vipTickets = vipTickets
        self.regularTickets = regularTickets
        self.checkInsCompleted = checkInsCompleted
        self.pendingPayments = pendingPayments
        self.transferredTickets = transferredTickets
        self.partiallyRefundedTickets = partiallyRefundedTickets
        self.grossRevenue = grossRevenue
        self.refundTotal = refundTotal
        self.platformFeesRetained = platformFeesRetained
        self.processingFeesEstimate = processingFeesEstimate
        self.netRefundAmount = netRefundAmount
        self.organizerPayoutAdjustment = organizerPayoutAdjustment
        self.currency = currency
        self.ticketTypeBreakdown = ticketTypeBreakdown
        self.paymentMethodBreakdown = paymentMethodBreakdown
    }

    // Computed properties
    var hasCheckedInAttendees: Bool {
        checkInsCompleted > 0
    }

    var hasPendingPayments: Bool {
        pendingPayments > 0
    }

    var hasTransferredTickets: Bool {
        transferredTickets > 0
    }

    var hasPartialRefunds: Bool {
        partiallyRefundedTickets > 0
    }

    var formattedRefundTotal: String {
        formatCurrency(refundTotal)
    }

    var formattedGrossRevenue: String {
        formatCurrency(grossRevenue)
    }

    var formattedNetRefund: String {
        formatCurrency(netRefundAmount)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "UGX \(Int(amount))"
    }

    // Edge case warnings
    var warnings: [CancellationWarning] {
        var warnings: [CancellationWarning] = []

        if hasCheckedInAttendees {
            warnings.append(.checkedInAttendees(count: checkInsCompleted))
        }
        if hasPendingPayments {
            warnings.append(.pendingPayments(count: pendingPayments))
        }
        if hasTransferredTickets {
            warnings.append(.transferredTickets(count: transferredTickets))
        }
        if hasPartialRefunds {
            warnings.append(.partiallyRefundedTickets(count: partiallyRefundedTickets))
        }

        return warnings
    }
}

/// Impact breakdown by ticket type
struct TicketTypeImpact: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let ticketsSold: Int
    let revenue: Double
    let refundAmount: Double

    var formattedRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: revenue)) ?? "UGX \(Int(revenue))"
    }
}

/// Impact breakdown by payment method
struct PaymentMethodImpact: Codable, Equatable, Identifiable {
    var id: String { paymentMethod.rawValue }
    let paymentMethod: RefundPaymentMethod
    let ticketCount: Int
    let refundAmount: Double
    let estimatedProcessingTime: String
}

// MARK: - Cancellation Warning

/// Warnings about edge cases that need attention
enum CancellationWarning: Identifiable, Equatable {
    case checkedInAttendees(count: Int)
    case pendingPayments(count: Int)
    case transferredTickets(count: Int)
    case partiallyRefundedTickets(count: Int)
    case offlineTickets(count: Int)

    var id: String {
        switch self {
        case .checkedInAttendees: return "checked_in"
        case .pendingPayments: return "pending_payments"
        case .transferredTickets: return "transferred"
        case .partiallyRefundedTickets: return "partial_refunds"
        case .offlineTickets: return "offline"
        }
    }

    var title: String {
        switch self {
        case .checkedInAttendees(let count):
            return "\(count) Attendee\(count == 1 ? "" : "s") Already Checked In"
        case .pendingPayments(let count):
            return "\(count) Pending Payment\(count == 1 ? "" : "s")"
        case .transferredTickets(let count):
            return "\(count) Transferred Ticket\(count == 1 ? "" : "s")"
        case .partiallyRefundedTickets(let count):
            return "\(count) Partially Refunded Ticket\(count == 1 ? "" : "s")"
        case .offlineTickets(let count):
            return "\(count) Offline Ticket\(count == 1 ? "" : "s")"
        }
    }

    var description: String {
        switch self {
        case .checkedInAttendees:
            return "These attendees have already used their tickets. They will still receive refunds."
        case .pendingPayments:
            return "Payments still processing. These will be cancelled and not charged."
        case .transferredTickets:
            return "Tickets transferred to new owners. Refunds go to current ticket holders."
        case .partiallyRefundedTickets:
            return "Tickets with prior partial refunds. Remaining balance will be refunded."
        case .offlineTickets:
            return "Tickets sold offline require manual refund processing."
        }
    }

    var icon: String {
        switch self {
        case .checkedInAttendees: return "checkmark.circle.trianglebadge.exclamationmark"
        case .pendingPayments: return "clock.badge.exclamationmark"
        case .transferredTickets: return "arrow.left.arrow.right"
        case .partiallyRefundedTickets: return "arrow.uturn.backward.badge.clock"
        case .offlineTickets: return "wifi.slash"
        }
    }

    var severity: WarningSeverity {
        switch self {
        case .checkedInAttendees: return .info
        case .pendingPayments: return .warning
        case .transferredTickets: return .info
        case .partiallyRefundedTickets: return .info
        case .offlineTickets: return .warning
        }
    }

    enum WarningSeverity {
        case info, warning, critical

        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - Compensation Plan

/// Defines how attendees will be compensated
struct CompensationPlan: Codable, Equatable {
    let id: UUID
    let eventId: UUID

    // Compensation settings
    let compensationType: CompensationType
    let refundPercentage: Double  // 1.0 for full, 0.5 for 50%, etc.
    let creditMultiplier: Double? // e.g., 1.1 for 110% credit bonus

    // Processing
    let processingMethod: ProcessingMethod
    let processingDeadline: Date

    // Financial
    let totalRefundAmount: Double
    let platformFeeHandling: PlatformFeeHandling
    let estimatedProcessingFees: Double

    // Notes
    let organizerNote: String?
    let internalNote: String?

    // Notification
    let notificationTemplate: NotificationTemplate?

    init(
        id: UUID = UUID(),
        eventId: UUID,
        compensationType: CompensationType = .fullRefund,
        refundPercentage: Double = 1.0,
        creditMultiplier: Double? = nil,
        processingMethod: ProcessingMethod = .automatic,
        processingDeadline: Date = Date().addingTimeInterval(86400 * 5), // 5 days
        totalRefundAmount: Double = 0,
        platformFeeHandling: PlatformFeeHandling = .waive,
        estimatedProcessingFees: Double = 0,
        organizerNote: String? = nil,
        internalNote: String? = nil,
        notificationTemplate: NotificationTemplate? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.compensationType = compensationType
        self.refundPercentage = refundPercentage
        self.creditMultiplier = creditMultiplier
        self.processingMethod = processingMethod
        self.processingDeadline = processingDeadline
        self.totalRefundAmount = totalRefundAmount
        self.platformFeeHandling = platformFeeHandling
        self.estimatedProcessingFees = estimatedProcessingFees
        self.organizerNote = organizerNote
        self.internalNote = internalNote
        self.notificationTemplate = notificationTemplate
    }

    enum ProcessingMethod: String, Codable {
        case automatic = "automatic"      // System processes all refunds
        case manual = "manual"            // Organizer handles refunds
        case hybrid = "hybrid"            // System + manual for exceptions

        var displayName: String {
            switch self {
            case .automatic: return "Automatic Processing"
            case .manual: return "Manual Processing"
            case .hybrid: return "Hybrid (Auto + Manual)"
            }
        }
    }

    enum PlatformFeeHandling: String, Codable {
        case waive = "waive"              // Platform waives fees
        case deduct = "deduct"            // Fees deducted from refund
        case organizerPays = "organizer"  // Organizer covers fees

        var displayName: String {
            switch self {
            case .waive: return "Platform Waives Fees"
            case .deduct: return "Deduct from Refund"
            case .organizerPays: return "Organizer Covers Fees"
            }
        }
    }
}

// MARK: - Notification Template

/// Template for attendee notifications
struct NotificationTemplate: Codable, Equatable {
    let subject: String
    let body: String
    let includeRefundDetails: Bool
    let includeTimeline: Bool
    let includeSupportContact: Bool

    static var defaultCancellation: NotificationTemplate {
        NotificationTemplate(
            subject: "Event Cancelled: {{event_name}}",
            body: """
            We regret to inform you that {{event_name}} scheduled for {{event_date}} has been cancelled.

            {{#refund_details}}
            Refund Details:
            Amount: {{refund_amount}}
            Method: {{refund_method}}
            Timeline: {{refund_timeline}}
            {{/refund_details}}

            We apologize for any inconvenience. If you have questions, please contact our support team.

            - The EventPass Team
            """,
            includeRefundDetails: true,
            includeTimeline: true,
            includeSupportContact: true
        )
    }
}

// MARK: - Event Cancellation

/// Complete record of an event cancellation
struct EventCancellation: Codable, Identifiable, Equatable {
    let id: UUID
    let eventId: UUID
    let eventTitle: String
    let organizerId: UUID

    // Cancellation details
    let reason: CancellationReason
    let reasonNote: String?
    let status: CancellationStatus

    // Impact snapshot
    let impact: CancellationImpact

    // Compensation
    let compensationPlan: CompensationPlan

    // Timestamps
    let createdAt: Date
    var confirmedAt: Date?
    var processingStartedAt: Date?
    var completedAt: Date?

    // Audit
    let initiatedBy: UUID
    var confirmedBy: UUID?
    var confirmationCode: String?  // The typed CONFIRM

    // Processing results
    var refundRequestsCreated: Int
    var refundsProcessed: Int
    var refundsFailed: Int
    var notificationsSent: Int
    var notificationsFailed: Int

    // Errors
    var processingErrors: [CancellationProcessingError]

    init(
        id: UUID = UUID(),
        eventId: UUID,
        eventTitle: String,
        organizerId: UUID,
        reason: CancellationReason,
        reasonNote: String? = nil,
        status: CancellationStatus = .draft,
        impact: CancellationImpact,
        compensationPlan: CompensationPlan,
        createdAt: Date = Date(),
        confirmedAt: Date? = nil,
        processingStartedAt: Date? = nil,
        completedAt: Date? = nil,
        initiatedBy: UUID,
        confirmedBy: UUID? = nil,
        confirmationCode: String? = nil,
        refundRequestsCreated: Int = 0,
        refundsProcessed: Int = 0,
        refundsFailed: Int = 0,
        notificationsSent: Int = 0,
        notificationsFailed: Int = 0,
        processingErrors: [CancellationProcessingError] = []
    ) {
        self.id = id
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.organizerId = organizerId
        self.reason = reason
        self.reasonNote = reasonNote
        self.status = status
        self.impact = impact
        self.compensationPlan = compensationPlan
        self.createdAt = createdAt
        self.confirmedAt = confirmedAt
        self.processingStartedAt = processingStartedAt
        self.completedAt = completedAt
        self.initiatedBy = initiatedBy
        self.confirmedBy = confirmedBy
        self.confirmationCode = confirmationCode
        self.refundRequestsCreated = refundRequestsCreated
        self.refundsProcessed = refundsProcessed
        self.refundsFailed = refundsFailed
        self.notificationsSent = notificationsSent
        self.notificationsFailed = notificationsFailed
        self.processingErrors = processingErrors
    }

    var isReversible: Bool {
        status.isReversible
    }

    var hasErrors: Bool {
        !processingErrors.isEmpty || refundsFailed > 0 || notificationsFailed > 0
    }

    var processingProgress: Double {
        guard impact.ticketsSold > 0 else { return 1.0 }
        return Double(refundsProcessed) / Double(impact.ticketsSold)
    }
}

// MARK: - Cancellation Error

/// Errors that occurred during cancellation processing
struct CancellationProcessingError: Codable, Identifiable, Equatable {
    let id: UUID
    let ticketId: UUID?
    let errorType: ErrorType
    let message: String
    let occurredAt: Date
    var resolved: Bool
    var resolvedAt: Date?
    var resolution: String?

    enum ErrorType: String, Codable {
        case refundFailed = "refund_failed"
        case notificationFailed = "notification_failed"
        case ticketUpdateFailed = "ticket_update_failed"
        case paymentCancellationFailed = "payment_cancellation_failed"
        case unknown = "unknown"

        var displayName: String {
            switch self {
            case .refundFailed: return "Refund Failed"
            case .notificationFailed: return "Notification Failed"
            case .ticketUpdateFailed: return "Ticket Update Failed"
            case .paymentCancellationFailed: return "Payment Cancellation Failed"
            case .unknown: return "Unknown Error"
            }
        }
    }

    init(
        id: UUID = UUID(),
        ticketId: UUID? = nil,
        errorType: ErrorType,
        message: String,
        occurredAt: Date = Date(),
        resolved: Bool = false,
        resolvedAt: Date? = nil,
        resolution: String? = nil
    ) {
        self.id = id
        self.ticketId = ticketId
        self.errorType = errorType
        self.message = message
        self.occurredAt = occurredAt
        self.resolved = resolved
        self.resolvedAt = resolvedAt
        self.resolution = resolution
    }
}

// MARK: - Cancellation Analytics

/// Analytics for cancellation tracking
struct CancellationAnalytics: Codable {
    let eventId: UUID
    let organizerId: UUID
    let period: DateInterval

    let totalCancellations: Int
    let cancellationsByReason: [CancellationReason: Int]
    let totalRefundsIssued: Double
    let averageProcessingTime: TimeInterval
    let successRate: Double

    init(
        eventId: UUID,
        organizerId: UUID,
        period: DateInterval,
        totalCancellations: Int = 0,
        cancellationsByReason: [CancellationReason: Int] = [:],
        totalRefundsIssued: Double = 0,
        averageProcessingTime: TimeInterval = 0,
        successRate: Double = 1.0
    ) {
        self.eventId = eventId
        self.organizerId = organizerId
        self.period = period
        self.totalCancellations = totalCancellations
        self.cancellationsByReason = cancellationsByReason
        self.totalRefundsIssued = totalRefundsIssued
        self.averageProcessingTime = averageProcessingTime
        self.successRate = successRate
    }
}

// MARK: - Sample Data

extension EventCancellation {
    static var sample: EventCancellation {
        let impact = CancellationImpact(
            eventId: UUID(),
            ticketsSold: 150,
            attendeesCount: 142,
            vipTickets: 25,
            regularTickets: 125,
            checkInsCompleted: 0,
            pendingPayments: 3,
            transferredTickets: 5,
            partiallyRefundedTickets: 2,
            grossRevenue: 15_000_000,
            refundTotal: 14_500_000,
            platformFeesRetained: 0,
            processingFeesEstimate: 145_000,
            netRefundAmount: 14_355_000,
            organizerPayoutAdjustment: -14_500_000,
            ticketTypeBreakdown: [
                TicketTypeImpact(id: UUID(), name: "VIP", ticketsSold: 25, revenue: 5_000_000, refundAmount: 5_000_000),
                TicketTypeImpact(id: UUID(), name: "Regular", ticketsSold: 125, revenue: 10_000_000, refundAmount: 9_500_000)
            ],
            paymentMethodBreakdown: [
                PaymentMethodImpact(paymentMethod: .mtnMobileMoney, ticketCount: 100, refundAmount: 10_000_000, estimatedProcessingTime: "1-24 hours"),
                PaymentMethodImpact(paymentMethod: .airtelMoney, ticketCount: 35, refundAmount: 3_500_000, estimatedProcessingTime: "1-24 hours"),
                PaymentMethodImpact(paymentMethod: .card, ticketCount: 15, refundAmount: 1_000_000, estimatedProcessingTime: "3-5 business days")
            ]
        )

        let plan = CompensationPlan(
            eventId: UUID(),
            compensationType: .fullRefund,
            refundPercentage: 1.0,
            totalRefundAmount: 14_500_000,
            notificationTemplate: .defaultCancellation
        )

        return EventCancellation(
            eventId: UUID(),
            eventTitle: "Nyege Nyege Festival 2024",
            organizerId: UUID(),
            reason: .organizerDecision,
            reasonNote: "Due to unforeseen circumstances, we must cancel this event.",
            impact: impact,
            compensationPlan: plan,
            initiatedBy: UUID()
        )
    }
}

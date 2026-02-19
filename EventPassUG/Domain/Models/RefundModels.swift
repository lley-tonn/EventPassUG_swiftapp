//
//  RefundModels.swift
//  EventPassUG
//
//  Comprehensive refund system models for fintech-grade reliability
//  Supports all Uganda ticketing refund scenarios including mobile money
//

import Foundation
import SwiftUI

// MARK: - Refund Status

/// Tracks the lifecycle of a refund request
enum RefundStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .blue
        case .rejected: return .red
        case .processing: return .purple
        case .completed: return .green
        case .failed: return .red
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.seal.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var isFinal: Bool {
        switch self {
        case .completed, .rejected, .failed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Refund Reason

/// Categorizes why a refund is being requested
enum RefundReason: String, Codable, CaseIterable, Identifiable {
    case eventCancelled = "event_cancelled"
    case eventRescheduled = "event_rescheduled"
    case cannotAttend = "cannot_attend"
    case duplicatePurchase = "duplicate_purchase"
    case organizerDecision = "organizer_decision"
    case fraudulent = "fraudulent"
    case ticketDowngrade = "ticket_downgrade"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eventCancelled: return "Event Cancelled"
        case .eventRescheduled: return "Event Rescheduled"
        case .cannotAttend: return "Cannot Attend"
        case .duplicatePurchase: return "Duplicate Purchase"
        case .organizerDecision: return "Organizer Decision"
        case .fraudulent: return "Fraudulent/Invalid Ticket"
        case .ticketDowngrade: return "Ticket Downgrade"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .eventCancelled:
            return "The event has been cancelled by the organizer"
        case .eventRescheduled:
            return "The event date has been changed and I cannot attend"
        case .cannotAttend:
            return "I am unable to attend the event"
        case .duplicatePurchase:
            return "I accidentally purchased multiple tickets"
        case .organizerDecision:
            return "Refund issued by the event organizer"
        case .fraudulent:
            return "The ticket is invalid or fraudulent"
        case .ticketDowngrade:
            return "Downgrading to a lower ticket tier"
        case .other:
            return "Other reason"
        }
    }

    var icon: String {
        switch self {
        case .eventCancelled: return "calendar.badge.minus"
        case .eventRescheduled: return "calendar.badge.clock"
        case .cannotAttend: return "person.crop.circle.badge.xmark"
        case .duplicatePurchase: return "doc.on.doc"
        case .organizerDecision: return "person.badge.shield.checkmark"
        case .fraudulent: return "exclamationmark.shield"
        case .ticketDowngrade: return "arrow.down.circle"
        case .other: return "questionmark.circle"
        }
    }

    /// Reasons that trigger automatic approval
    var isAutoApproved: Bool {
        switch self {
        case .eventCancelled, .duplicatePurchase, .fraudulent:
            return true
        default:
            return false
        }
    }

    /// Reasons available for user selection
    static var userSelectableReasons: [RefundReason] {
        [.cannotAttend, .duplicatePurchase, .eventRescheduled, .other]
    }
}

// MARK: - Ticket Refund State

/// Tracks refund eligibility and state for a ticket
enum TicketRefundState: String, Codable {
    case none = "none"                    // No refund activity
    case eligible = "eligible"            // Can request refund
    case requested = "requested"          // Request submitted
    case approved = "approved"            // Request approved, awaiting processing
    case rejected = "rejected"            // Request denied
    case processing = "processing"        // Refund being processed
    case refunded = "refunded"            // Successfully refunded

    var displayName: String {
        switch self {
        case .none: return "Not Refundable"
        case .eligible: return "Eligible for Refund"
        case .requested: return "Refund Requested"
        case .approved: return "Refund Approved"
        case .rejected: return "Refund Rejected"
        case .processing: return "Processing Refund"
        case .refunded: return "Refunded"
        }
    }

    var canRequestRefund: Bool {
        self == .eligible
    }

    var isRefundActive: Bool {
        switch self {
        case .requested, .approved, .processing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Payment Method

/// Supported payment methods for refunds
enum RefundPaymentMethod: String, Codable, CaseIterable {
    case mtnMobileMoney = "mtn_mobile_money"
    case airtelMoney = "airtel_money"
    case card = "card"
    case bankTransfer = "bank_transfer"
    case wallet = "wallet"

    var displayName: String {
        switch self {
        case .mtnMobileMoney: return "MTN Mobile Money"
        case .airtelMoney: return "Airtel Money"
        case .card: return "Card"
        case .bankTransfer: return "Bank Transfer"
        case .wallet: return "EventPass Wallet"
        }
    }

    var icon: String {
        switch self {
        case .mtnMobileMoney: return "phone.circle.fill"
        case .airtelMoney: return "phone.circle.fill"
        case .card: return "creditcard.fill"
        case .bankTransfer: return "building.columns.fill"
        case .wallet: return "wallet.pass.fill"
        }
    }

    var processingTime: String {
        switch self {
        case .mtnMobileMoney, .airtelMoney:
            return "1-24 hours"
        case .card:
            return "3-5 business days"
        case .bankTransfer:
            return "2-3 business days"
        case .wallet:
            return "Instant"
        }
    }
}

// MARK: - Refund Policy

/// Defines refund rules for an event or ticket type
struct RefundPolicy: Codable, Equatable, Identifiable {
    let id: UUID
    let eventId: UUID
    let ticketTypeId: UUID?  // nil = applies to all ticket types

    // Core policy settings
    let isRefundable: Bool
    let refundDeadlineHours: Int  // Hours before event when refunds are cut off
    let refundPercentage: Double  // 0.0 to 1.0 (percentage of ticket price refunded)
    let processingFeePercentage: Double  // Fee deducted from refund

    // Time-based rules
    let fullRefundDeadlineHours: Int?  // Hours before event for 100% refund
    let partialRefundDeadlineHours: Int?  // Hours before event for partial refund
    let partialRefundPercentage: Double?  // Percentage for partial refund window

    // Special conditions
    let allowRescheduledEventRefund: Bool
    let allowTransfer: Bool  // Can ticket be transferred instead of refunded
    let requiresApproval: Bool  // Manual approval required
    let maxRefundsPerUser: Int?  // Limit on refunds per user per event

    // Policy text
    let policyText: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        eventId: UUID,
        ticketTypeId: UUID? = nil,
        isRefundable: Bool = true,
        refundDeadlineHours: Int = 48,
        refundPercentage: Double = 1.0,
        processingFeePercentage: Double = 0.05,
        fullRefundDeadlineHours: Int? = 72,
        partialRefundDeadlineHours: Int? = 24,
        partialRefundPercentage: Double? = 0.5,
        allowRescheduledEventRefund: Bool = true,
        allowTransfer: Bool = true,
        requiresApproval: Bool = false,
        maxRefundsPerUser: Int? = nil,
        policyText: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.eventId = eventId
        self.ticketTypeId = ticketTypeId
        self.isRefundable = isRefundable
        self.refundDeadlineHours = refundDeadlineHours
        self.refundPercentage = refundPercentage
        self.processingFeePercentage = processingFeePercentage
        self.fullRefundDeadlineHours = fullRefundDeadlineHours
        self.partialRefundDeadlineHours = partialRefundDeadlineHours
        self.partialRefundPercentage = partialRefundPercentage
        self.allowRescheduledEventRefund = allowRescheduledEventRefund
        self.allowTransfer = allowTransfer
        self.requiresApproval = requiresApproval
        self.maxRefundsPerUser = maxRefundsPerUser
        self.policyText = policyText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Default policy for events without custom policy
    static func defaultPolicy(eventId: UUID) -> RefundPolicy {
        RefundPolicy(
            eventId: eventId,
            isRefundable: true,
            refundDeadlineHours: 48,
            refundPercentage: 1.0,
            processingFeePercentage: 0.05,
            fullRefundDeadlineHours: 72,
            partialRefundDeadlineHours: 24,
            partialRefundPercentage: 0.5,
            policyText: "Full refunds available up to 72 hours before the event. 50% refund available 24-72 hours before. No refunds within 24 hours of the event."
        )
    }

    /// Non-refundable policy
    static func nonRefundable(eventId: UUID) -> RefundPolicy {
        RefundPolicy(
            eventId: eventId,
            isRefundable: false,
            refundDeadlineHours: 0,
            refundPercentage: 0,
            processingFeePercentage: 0,
            policyText: "This ticket is non-refundable. In case of event cancellation, a full refund will be processed automatically."
        )
    }
}

// MARK: - Refund Request

/// User's request for a refund
struct RefundRequest: Codable, Identifiable, Equatable {
    let id: UUID
    let ticketId: UUID
    let ticketNumber: String
    let eventId: UUID
    let eventTitle: String
    let userId: UUID
    let userName: String
    let userEmail: String?
    let userPhone: String?

    // Request details
    let reason: RefundReason
    let userNote: String?
    let requestedAmount: Double
    let approvedAmount: Double?
    let currency: String

    // Original payment info
    let originalPaymentMethod: RefundPaymentMethod
    let originalPaymentReference: String
    let originalPurchaseDate: Date

    // Status tracking
    var status: RefundStatus
    let requestedAt: Date
    var reviewedAt: Date?
    var reviewedBy: UUID?
    var reviewerNote: String?
    var processedAt: Date?
    var completedAt: Date?
    var failureReason: String?

    // Audit trail
    var statusHistory: [RefundStatusChange]

    init(
        id: UUID = UUID(),
        ticketId: UUID,
        ticketNumber: String,
        eventId: UUID,
        eventTitle: String,
        userId: UUID,
        userName: String,
        userEmail: String? = nil,
        userPhone: String? = nil,
        reason: RefundReason,
        userNote: String? = nil,
        requestedAmount: Double,
        approvedAmount: Double? = nil,
        currency: String = "UGX",
        originalPaymentMethod: RefundPaymentMethod,
        originalPaymentReference: String,
        originalPurchaseDate: Date,
        status: RefundStatus = .pending,
        requestedAt: Date = Date(),
        reviewedAt: Date? = nil,
        reviewedBy: UUID? = nil,
        reviewerNote: String? = nil,
        processedAt: Date? = nil,
        completedAt: Date? = nil,
        failureReason: String? = nil,
        statusHistory: [RefundStatusChange] = []
    ) {
        self.id = id
        self.ticketId = ticketId
        self.ticketNumber = ticketNumber
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.userPhone = userPhone
        self.reason = reason
        self.userNote = userNote
        self.requestedAmount = requestedAmount
        self.approvedAmount = approvedAmount
        self.currency = currency
        self.originalPaymentMethod = originalPaymentMethod
        self.originalPaymentReference = originalPaymentReference
        self.originalPurchaseDate = originalPurchaseDate
        self.status = status
        self.requestedAt = requestedAt
        self.reviewedAt = reviewedAt
        self.reviewedBy = reviewedBy
        self.reviewerNote = reviewerNote
        self.processedAt = processedAt
        self.completedAt = completedAt
        self.failureReason = failureReason

        // Initialize status history with creation event
        var history = statusHistory
        if history.isEmpty {
            history.append(RefundStatusChange(
                fromStatus: nil,
                toStatus: status,
                changedAt: requestedAt,
                changedBy: userId,
                note: "Refund request submitted"
            ))
        }
        self.statusHistory = history
    }

    /// Formatted refund amount
    var formattedRequestedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: requestedAmount)) ?? "UGX \(Int(requestedAmount))"
    }

    var formattedApprovedAmount: String? {
        guard let amount = approvedAmount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "UGX \(Int(amount))"
    }

    /// Time since request
    var timeSinceRequest: String {
        let interval = Date().timeIntervalSince(requestedAt)
        let hours = Int(interval / 3600)
        if hours < 1 {
            return "Just now"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }
}

// MARK: - Refund Status Change

/// Tracks status changes for audit trail
struct RefundStatusChange: Codable, Identifiable, Equatable {
    let id: UUID
    let fromStatus: RefundStatus?
    let toStatus: RefundStatus
    let changedAt: Date
    let changedBy: UUID?
    let note: String?

    init(
        id: UUID = UUID(),
        fromStatus: RefundStatus?,
        toStatus: RefundStatus,
        changedAt: Date = Date(),
        changedBy: UUID? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.fromStatus = fromStatus
        self.toStatus = toStatus
        self.changedAt = changedAt
        self.changedBy = changedBy
        self.note = note
    }
}

// MARK: - Refund Transaction

/// Financial record of a processed refund
struct RefundTransaction: Codable, Identifiable, Equatable {
    let id: UUID
    let refundRequestId: UUID
    let ticketId: UUID
    let eventId: UUID
    let userId: UUID
    let organizerId: UUID

    // Financial details
    let originalAmount: Double
    let refundAmount: Double
    let processingFee: Double
    let netRefund: Double  // refundAmount - processingFee
    let currency: String

    // Payment details
    let paymentMethod: RefundPaymentMethod
    let paymentReference: String
    let transactionReference: String  // External payment provider reference

    // Status
    var status: RefundStatus
    let reason: RefundReason

    // Timestamps
    let initiatedAt: Date
    var processedAt: Date?
    var completedAt: Date?
    var failedAt: Date?
    var failureReason: String?

    // Audit
    let processedBy: UUID?  // System or admin user
    let notes: String?

    init(
        id: UUID = UUID(),
        refundRequestId: UUID,
        ticketId: UUID,
        eventId: UUID,
        userId: UUID,
        organizerId: UUID,
        originalAmount: Double,
        refundAmount: Double,
        processingFee: Double,
        currency: String = "UGX",
        paymentMethod: RefundPaymentMethod,
        paymentReference: String,
        transactionReference: String = "",
        status: RefundStatus = .processing,
        reason: RefundReason,
        initiatedAt: Date = Date(),
        processedAt: Date? = nil,
        completedAt: Date? = nil,
        failedAt: Date? = nil,
        failureReason: String? = nil,
        processedBy: UUID? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.refundRequestId = refundRequestId
        self.ticketId = ticketId
        self.eventId = eventId
        self.userId = userId
        self.organizerId = organizerId
        self.originalAmount = originalAmount
        self.refundAmount = refundAmount
        self.processingFee = processingFee
        self.netRefund = refundAmount - processingFee
        self.currency = currency
        self.paymentMethod = paymentMethod
        self.paymentReference = paymentReference
        self.transactionReference = transactionReference
        self.status = status
        self.reason = reason
        self.initiatedAt = initiatedAt
        self.processedAt = processedAt
        self.completedAt = completedAt
        self.failedAt = failedAt
        self.failureReason = failureReason
        self.processedBy = processedBy
        self.notes = notes
    }

    var formattedNetRefund: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: netRefund)) ?? "UGX \(Int(netRefund))"
    }
}

// MARK: - Refund Eligibility Result

/// Result of checking refund eligibility
struct RefundEligibilityResult: Equatable {
    let isEligible: Bool
    let reason: String
    let refundableAmount: Double
    let refundPercentage: Double
    let processingFee: Double
    let netRefund: Double
    let deadline: Date?
    let policy: RefundPolicy?

    static func eligible(
        amount: Double,
        percentage: Double,
        fee: Double,
        deadline: Date?,
        policy: RefundPolicy
    ) -> RefundEligibilityResult {
        RefundEligibilityResult(
            isEligible: true,
            reason: "Eligible for refund",
            refundableAmount: amount,
            refundPercentage: percentage,
            processingFee: fee,
            netRefund: amount - fee,
            deadline: deadline,
            policy: policy
        )
    }

    static func notEligible(reason: String) -> RefundEligibilityResult {
        RefundEligibilityResult(
            isEligible: false,
            reason: reason,
            refundableAmount: 0,
            refundPercentage: 0,
            processingFee: 0,
            netRefund: 0,
            deadline: nil,
            policy: nil
        )
    }
}

// MARK: - Refund Analytics

/// Analytics data for refund reporting
struct RefundAnalytics: Codable {
    let eventId: UUID?
    let organizerId: UUID?
    let period: DateInterval

    let totalRequests: Int
    let pendingRequests: Int
    let approvedRequests: Int
    let rejectedRequests: Int
    let completedRefunds: Int
    let failedRefunds: Int

    let totalAmountRequested: Double
    let totalAmountRefunded: Double
    let totalProcessingFees: Double

    let averageProcessingTimeHours: Double
    let refundRate: Double  // Refunds / Total Tickets Sold

    let topReasons: [RefundReason: Int]

    var approvalRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(approvedRequests + completedRefunds) / Double(totalRequests)
    }
}

// MARK: - Sample Data

extension RefundRequest {
    static var samples: [RefundRequest] {
        [
            RefundRequest(
                ticketId: UUID(),
                ticketNumber: "TKT-001234",
                eventId: UUID(),
                eventTitle: "Nyege Nyege Festival 2024",
                userId: UUID(),
                userName: "John Mukasa",
                userEmail: "john@example.com",
                userPhone: "+256700123456",
                reason: .cannotAttend,
                userNote: "I have a family emergency and cannot attend.",
                requestedAmount: 150000,
                currency: "UGX",
                originalPaymentMethod: .mtnMobileMoney,
                originalPaymentReference: "PAY-789012",
                originalPurchaseDate: Date().addingTimeInterval(-86400 * 7)
            ),
            RefundRequest(
                ticketId: UUID(),
                ticketNumber: "TKT-005678",
                eventId: UUID(),
                eventTitle: "Comedy Night at Theatre Labonita",
                userId: UUID(),
                userName: "Sarah Nambi",
                reason: .eventCancelled,
                requestedAmount: 50000,
                currency: "UGX",
                originalPaymentMethod: .airtelMoney,
                originalPaymentReference: "PAY-345678",
                originalPurchaseDate: Date().addingTimeInterval(-86400 * 3),
                status: .approved
            )
        ]
    }
}

extension RefundPolicy {
    static var sample: RefundPolicy {
        RefundPolicy(
            eventId: UUID(),
            isRefundable: true,
            refundDeadlineHours: 48,
            refundPercentage: 1.0,
            processingFeePercentage: 0.05,
            fullRefundDeadlineHours: 72,
            partialRefundDeadlineHours: 24,
            partialRefundPercentage: 0.5,
            policyText: "Full refunds available up to 72 hours before the event. 50% refund available 24-72 hours before. No refunds within 24 hours of the event. Event cancellation results in automatic full refund."
        )
    }
}

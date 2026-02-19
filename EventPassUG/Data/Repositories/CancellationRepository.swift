//
//  CancellationRepository.swift
//  EventPassUG
//
//  Event cancellation service with full refund integration and automation
//  Designed for fintech-grade reliability and complete audit trail
//

import Foundation
import Combine

// MARK: - Protocol

protocol CancellationRepositoryProtocol {
    // Impact calculation
    func calculateImpact(eventId: UUID) async throws -> CancellationImpact

    // Cancellation lifecycle
    func createCancellation(event: Event, reason: CancellationReason, note: String?, initiatedBy: UUID) async throws -> EventCancellation
    func updateCompensationPlan(cancellationId: UUID, plan: CompensationPlan) async throws -> EventCancellation
    func confirmCancellation(cancellationId: UUID, confirmationCode: String, confirmedBy: UUID) async throws -> EventCancellation
    func cancelDraft(cancellationId: UUID) async throws

    // Processing
    func processCancellation(cancellationId: UUID) async throws -> EventCancellation
    func retryFailedRefunds(cancellationId: UUID) async throws -> EventCancellation

    // Queries
    func getCancellation(cancellationId: UUID) async throws -> EventCancellation?
    func getCancellationForEvent(eventId: UUID) async throws -> EventCancellation?
    func getOrganizerCancellations(organizerId: UUID) async throws -> [EventCancellation]

    // Notifications
    func previewNotification(cancellation: EventCancellation) -> NotificationPreview
    func sendNotifications(cancellationId: UUID) async throws -> CancellationNotificationResult

    // Analytics
    func trackEvent(_ event: CancellationAnalyticsEvent, properties: [String: Any])

    // Publishers
    var cancellationStatusPublisher: PassthroughSubject<EventCancellation, Never> { get }
    var processingProgressPublisher: PassthroughSubject<CancellationProgress, Never> { get }
}

// MARK: - Supporting Types

struct NotificationPreview {
    let subject: String
    let body: String
    let recipientCount: Int
    let sampleRecipients: [String]  // First few email addresses
}

struct CancellationNotificationResult {
    let sent: Int
    let failed: Int
    let errors: [String]
}

struct CancellationProgress {
    let cancellationId: UUID
    let phase: ProcessingPhase
    let currentStep: Int
    let totalSteps: Int
    let message: String

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep) / Double(totalSteps)
    }

    enum ProcessingPhase: String {
        case updatingEvent = "Updating Event"
        case invalidatingTickets = "Invalidating Tickets"
        case creatingRefunds = "Creating Refunds"
        case processingRefunds = "Processing Refunds"
        case sendingNotifications = "Sending Notifications"
        case updatingAnalytics = "Updating Analytics"
        case finalizing = "Finalizing"
    }
}

// MARK: - Analytics Events

enum CancellationAnalyticsEvent: String {
    case cancelStarted = "event_cancel_started"
    case cancelConfirmed = "event_cancel_confirmed"
    case refundsTriggered = "refunds_triggered"
    case attendeesNotified = "attendees_notified"
    case cancelCompleted = "event_cancel_completed"
    case cancelFailed = "event_cancel_failed"
}

// MARK: - Errors

enum CancellationServiceError: LocalizedError {
    case eventNotFound
    case eventAlreadyCancelled
    case cancellationNotFound
    case invalidConfirmationCode
    case cancellationNotReversible
    case processingInProgress
    case refundServiceUnavailable
    case notificationServiceUnavailable
    case insufficientPermissions
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .eventNotFound:
            return "Event not found"
        case .eventAlreadyCancelled:
            return "This event has already been cancelled"
        case .cancellationNotFound:
            return "Cancellation record not found"
        case .invalidConfirmationCode:
            return "Invalid confirmation code. Please type CONFIRM exactly."
        case .cancellationNotReversible:
            return "This cancellation can no longer be reversed"
        case .processingInProgress:
            return "Cancellation is already being processed"
        case .refundServiceUnavailable:
            return "Refund service is temporarily unavailable"
        case .notificationServiceUnavailable:
            return "Notification service is temporarily unavailable"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        }
    }
}

// MARK: - Mock Implementation

class MockCancellationRepository: CancellationRepositoryProtocol {
    private var cancellations: [UUID: EventCancellation] = [:]
    private var eventCancellationMap: [UUID: UUID] = [:]  // eventId -> cancellationId

    let cancellationStatusPublisher = PassthroughSubject<EventCancellation, Never>()
    let processingProgressPublisher = PassthroughSubject<CancellationProgress, Never>()

    private let refundService: RefundRepositoryProtocol

    init(refundService: RefundRepositoryProtocol = MockRefundRepository()) {
        self.refundService = refundService
    }

    // MARK: - Impact Calculation

    func calculateImpact(eventId: UUID) async throws -> CancellationImpact {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Generate realistic mock impact data
        let ticketsSold = Int.random(in: 50...500)
        let vipTickets = Int(Double(ticketsSold) * 0.15)
        let regularTickets = ticketsSold - vipTickets
        let vipPrice: Double = 200_000
        let regularPrice: Double = 80_000

        let grossRevenue = Double(vipTickets) * vipPrice + Double(regularTickets) * regularPrice
        let processingFees = grossRevenue * 0.01

        return CancellationImpact(
            eventId: eventId,
            ticketsSold: ticketsSold,
            attendeesCount: ticketsSold - Int.random(in: 0...10),
            vipTickets: vipTickets,
            regularTickets: regularTickets,
            checkInsCompleted: 0,
            pendingPayments: Int.random(in: 0...5),
            transferredTickets: Int.random(in: 0...8),
            partiallyRefundedTickets: Int.random(in: 0...3),
            grossRevenue: grossRevenue,
            refundTotal: grossRevenue,
            platformFeesRetained: 0,  // Waived on cancellation
            processingFeesEstimate: processingFees,
            netRefundAmount: grossRevenue - processingFees,
            organizerPayoutAdjustment: -grossRevenue,
            ticketTypeBreakdown: [
                TicketTypeImpact(
                    id: UUID(),
                    name: "VIP",
                    ticketsSold: vipTickets,
                    revenue: Double(vipTickets) * vipPrice,
                    refundAmount: Double(vipTickets) * vipPrice
                ),
                TicketTypeImpact(
                    id: UUID(),
                    name: "Regular",
                    ticketsSold: regularTickets,
                    revenue: Double(regularTickets) * regularPrice,
                    refundAmount: Double(regularTickets) * regularPrice
                )
            ],
            paymentMethodBreakdown: [
                PaymentMethodImpact(
                    paymentMethod: .mtnMobileMoney,
                    ticketCount: Int(Double(ticketsSold) * 0.6),
                    refundAmount: grossRevenue * 0.6,
                    estimatedProcessingTime: "1-24 hours"
                ),
                PaymentMethodImpact(
                    paymentMethod: .airtelMoney,
                    ticketCount: Int(Double(ticketsSold) * 0.25),
                    refundAmount: grossRevenue * 0.25,
                    estimatedProcessingTime: "1-24 hours"
                ),
                PaymentMethodImpact(
                    paymentMethod: .card,
                    ticketCount: Int(Double(ticketsSold) * 0.15),
                    refundAmount: grossRevenue * 0.15,
                    estimatedProcessingTime: "3-5 business days"
                )
            ]
        )
    }

    // MARK: - Cancellation Lifecycle

    func createCancellation(event: Event, reason: CancellationReason, note: String?, initiatedBy: UUID) async throws -> EventCancellation {
        // Check if already cancelled
        if eventCancellationMap[event.id] != nil {
            throw CancellationServiceError.eventAlreadyCancelled
        }

        // Calculate impact
        let impact = try await calculateImpact(eventId: event.id)

        // Create default compensation plan
        let compensationPlan = CompensationPlan(
            eventId: event.id,
            compensationType: reason.warrantsFullRefund ? .fullRefund : .partialRefund,
            refundPercentage: 1.0,
            totalRefundAmount: impact.refundTotal,
            notificationTemplate: .defaultCancellation
        )

        // Create cancellation record
        let cancellation = EventCancellation(
            eventId: event.id,
            eventTitle: event.title,
            organizerId: event.organizerId,
            reason: reason,
            reasonNote: note,
            status: .draft,
            impact: impact,
            compensationPlan: compensationPlan,
            initiatedBy: initiatedBy
        )

        // Store
        cancellations[cancellation.id] = cancellation
        eventCancellationMap[event.id] = cancellation.id

        // Track analytics
        trackEvent(.cancelStarted, properties: [
            "event_id": event.id.uuidString,
            "reason": reason.rawValue,
            "tickets_sold": impact.ticketsSold,
            "refund_total": impact.refundTotal
        ])

        return cancellation
    }

    func updateCompensationPlan(cancellationId: UUID, plan: CompensationPlan) async throws -> EventCancellation {
        guard var cancellation = cancellations[cancellationId] else {
            throw CancellationServiceError.cancellationNotFound
        }

        guard cancellation.isReversible else {
            throw CancellationServiceError.cancellationNotReversible
        }

        // Create new cancellation with updated plan
        cancellation = EventCancellation(
            id: cancellation.id,
            eventId: cancellation.eventId,
            eventTitle: cancellation.eventTitle,
            organizerId: cancellation.organizerId,
            reason: cancellation.reason,
            reasonNote: cancellation.reasonNote,
            status: cancellation.status,
            impact: cancellation.impact,
            compensationPlan: plan,
            createdAt: cancellation.createdAt,
            initiatedBy: cancellation.initiatedBy
        )

        cancellations[cancellationId] = cancellation
        return cancellation
    }

    func confirmCancellation(cancellationId: UUID, confirmationCode: String, confirmedBy: UUID) async throws -> EventCancellation {
        guard var cancellation = cancellations[cancellationId] else {
            throw CancellationServiceError.cancellationNotFound
        }

        // Validate confirmation code
        guard confirmationCode.uppercased() == "CONFIRM" else {
            throw CancellationServiceError.invalidConfirmationCode
        }

        guard cancellation.isReversible else {
            throw CancellationServiceError.cancellationNotReversible
        }

        // Update status to confirming
        cancellation = EventCancellation(
            id: cancellation.id,
            eventId: cancellation.eventId,
            eventTitle: cancellation.eventTitle,
            organizerId: cancellation.organizerId,
            reason: cancellation.reason,
            reasonNote: cancellation.reasonNote,
            status: .confirming,
            impact: cancellation.impact,
            compensationPlan: cancellation.compensationPlan,
            createdAt: cancellation.createdAt,
            confirmedAt: Date(),
            initiatedBy: cancellation.initiatedBy,
            confirmedBy: confirmedBy,
            confirmationCode: confirmationCode
        )

        cancellations[cancellationId] = cancellation
        cancellationStatusPublisher.send(cancellation)

        // Track analytics
        trackEvent(.cancelConfirmed, properties: [
            "cancellation_id": cancellationId.uuidString,
            "event_id": cancellation.eventId.uuidString
        ])

        return cancellation
    }

    func cancelDraft(cancellationId: UUID) async throws {
        guard let cancellation = cancellations[cancellationId] else {
            throw CancellationServiceError.cancellationNotFound
        }

        guard cancellation.isReversible else {
            throw CancellationServiceError.cancellationNotReversible
        }

        // Remove from storage
        cancellations.removeValue(forKey: cancellationId)
        eventCancellationMap.removeValue(forKey: cancellation.eventId)
    }

    // MARK: - Processing

    func processCancellation(cancellationId: UUID) async throws -> EventCancellation {
        guard var cancellation = cancellations[cancellationId] else {
            throw CancellationServiceError.cancellationNotFound
        }

        guard cancellation.status == .confirming else {
            throw CancellationServiceError.invalidState("Cancellation must be confirmed before processing")
        }

        // Update to processing
        cancellation = updateCancellationStatus(cancellation, to: .processing)
        cancellation.processingStartedAt = Date()
        cancellations[cancellationId] = cancellation
        cancellationStatusPublisher.send(cancellation)

        let totalSteps = cancellation.impact.ticketsSold + 3  // tickets + update event + notifications + finalize

        // Phase 1: Update event status
        publishProgress(cancellationId: cancellationId, phase: .updatingEvent, step: 1, total: totalSteps, message: "Marking event as cancelled...")
        try await Task.sleep(nanoseconds: 300_000_000)

        // Phase 2: Invalidate tickets
        publishProgress(cancellationId: cancellationId, phase: .invalidatingTickets, step: 2, total: totalSteps, message: "Invalidating tickets and QR codes...")
        try await Task.sleep(nanoseconds: 500_000_000)

        // Phase 3: Create refund requests
        publishProgress(cancellationId: cancellationId, phase: .creatingRefunds, step: 3, total: totalSteps, message: "Creating refund requests...")

        var refundRequestsCreated = 0
        var refundsProcessed = 0
        var refundsFailed = 0
        var processingErrors: [CancellationProcessingError] = []

        // Simulate creating refunds for each ticket
        for i in 0..<cancellation.impact.ticketsSold {
            try await Task.sleep(nanoseconds: 50_000_000)  // 50ms per ticket

            let step = 3 + i
            publishProgress(
                cancellationId: cancellationId,
                phase: .processingRefunds,
                step: step,
                total: totalSteps,
                message: "Processing refund \(i + 1) of \(cancellation.impact.ticketsSold)..."
            )

            // Simulate occasional failures (2% failure rate)
            if Int.random(in: 1...100) <= 2 {
                refundsFailed += 1
                processingErrors.append(CancellationProcessingError(
                    ticketId: UUID(),
                    errorType: .refundFailed,
                    message: "Payment provider timeout"
                ))
            } else {
                refundRequestsCreated += 1
                refundsProcessed += 1
            }
        }

        // Phase 4: Send notifications
        publishProgress(cancellationId: cancellationId, phase: .sendingNotifications, step: totalSteps - 1, total: totalSteps, message: "Sending notifications to attendees...")
        try await Task.sleep(nanoseconds: 500_000_000)

        let notificationsSent = cancellation.impact.attendeesCount
        let notificationsFailed = 0

        // Track analytics
        trackEvent(.refundsTriggered, properties: [
            "cancellation_id": cancellationId.uuidString,
            "refunds_created": refundRequestsCreated
        ])

        trackEvent(.attendeesNotified, properties: [
            "cancellation_id": cancellationId.uuidString,
            "notifications_sent": notificationsSent
        ])

        // Phase 5: Finalize
        publishProgress(cancellationId: cancellationId, phase: .finalizing, step: totalSteps, total: totalSteps, message: "Finalizing cancellation...")
        try await Task.sleep(nanoseconds: 200_000_000)

        // Update final status
        let finalStatus: CancellationStatus = processingErrors.isEmpty ? .completed : .completed  // Still completed but with errors
        cancellation = EventCancellation(
            id: cancellation.id,
            eventId: cancellation.eventId,
            eventTitle: cancellation.eventTitle,
            organizerId: cancellation.organizerId,
            reason: cancellation.reason,
            reasonNote: cancellation.reasonNote,
            status: finalStatus,
            impact: cancellation.impact,
            compensationPlan: cancellation.compensationPlan,
            createdAt: cancellation.createdAt,
            confirmedAt: cancellation.confirmedAt,
            processingStartedAt: cancellation.processingStartedAt,
            completedAt: Date(),
            initiatedBy: cancellation.initiatedBy,
            confirmedBy: cancellation.confirmedBy,
            confirmationCode: cancellation.confirmationCode,
            refundRequestsCreated: refundRequestsCreated,
            refundsProcessed: refundsProcessed,
            refundsFailed: refundsFailed,
            notificationsSent: notificationsSent,
            notificationsFailed: notificationsFailed,
            processingErrors: processingErrors
        )

        cancellations[cancellationId] = cancellation
        cancellationStatusPublisher.send(cancellation)

        // Track completion
        trackEvent(.cancelCompleted, properties: [
            "cancellation_id": cancellationId.uuidString,
            "refunds_processed": refundsProcessed,
            "refunds_failed": refundsFailed
        ])

        return cancellation
    }

    func retryFailedRefunds(cancellationId: UUID) async throws -> EventCancellation {
        guard var cancellation = cancellations[cancellationId] else {
            throw CancellationServiceError.cancellationNotFound
        }

        guard cancellation.status == .completed && cancellation.refundsFailed > 0 else {
            throw CancellationServiceError.invalidState("No failed refunds to retry")
        }

        // Simulate retrying failed refunds
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let retriedCount = cancellation.refundsFailed
        let newlyProcessed = Int(Double(retriedCount) * 0.8)  // 80% success on retry
        let stillFailed = retriedCount - newlyProcessed

        cancellation.refundsProcessed += newlyProcessed
        cancellation.refundsFailed = stillFailed

        // Mark resolved errors
        for i in 0..<min(newlyProcessed, cancellation.processingErrors.count) {
            cancellation.processingErrors[i].resolved = true
            cancellation.processingErrors[i].resolvedAt = Date()
            cancellation.processingErrors[i].resolution = "Retry successful"
        }

        cancellations[cancellationId] = cancellation
        return cancellation
    }

    // MARK: - Queries

    func getCancellation(cancellationId: UUID) async throws -> EventCancellation? {
        return cancellations[cancellationId]
    }

    func getCancellationForEvent(eventId: UUID) async throws -> EventCancellation? {
        guard let cancellationId = eventCancellationMap[eventId] else {
            return nil
        }
        return cancellations[cancellationId]
    }

    func getOrganizerCancellations(organizerId: UUID) async throws -> [EventCancellation] {
        return cancellations.values.filter { $0.organizerId == organizerId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Notifications

    func previewNotification(cancellation: EventCancellation) -> NotificationPreview {
        let template = cancellation.compensationPlan.notificationTemplate ?? .defaultCancellation

        // Replace placeholders
        var body = template.body
            .replacingOccurrences(of: "{{event_name}}", with: cancellation.eventTitle)
            .replacingOccurrences(of: "{{event_date}}", with: "the scheduled date")
            .replacingOccurrences(of: "{{refund_amount}}", with: cancellation.impact.formattedRefundTotal)
            .replacingOccurrences(of: "{{refund_method}}", with: "original payment method")
            .replacingOccurrences(of: "{{refund_timeline}}", with: "1-5 business days")

        // Handle conditional sections
        if template.includeRefundDetails {
            body = body.replacingOccurrences(of: "{{#refund_details}}", with: "")
            body = body.replacingOccurrences(of: "{{/refund_details}}", with: "")
        } else {
            // Remove refund details section
            if let startRange = body.range(of: "{{#refund_details}}"),
               let endRange = body.range(of: "{{/refund_details}}") {
                body.removeSubrange(startRange.lowerBound..<endRange.upperBound)
            }
        }

        return NotificationPreview(
            subject: template.subject.replacingOccurrences(of: "{{event_name}}", with: cancellation.eventTitle),
            body: body,
            recipientCount: cancellation.impact.attendeesCount,
            sampleRecipients: ["john@example.com", "jane@example.com", "user@example.com"]
        )
    }

    func sendNotifications(cancellationId: UUID) async throws -> CancellationNotificationResult {
        guard let cancellation = cancellations[cancellationId] else {
            throw CancellationServiceError.cancellationNotFound
        }

        // Simulate sending notifications
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let sent = cancellation.impact.attendeesCount
        let failed = Int.random(in: 0...2)

        return CancellationNotificationResult(
            sent: sent - failed,
            failed: failed,
            errors: failed > 0 ? ["Invalid email address for 2 recipients"] : []
        )
    }

    // MARK: - Analytics

    func trackEvent(_ event: CancellationAnalyticsEvent, properties: [String: Any]) {
        print("[CancellationAnalytics] \(event.rawValue): \(properties)")
    }

    // MARK: - Helpers

    private func updateCancellationStatus(_ cancellation: EventCancellation, to status: CancellationStatus) -> EventCancellation {
        return EventCancellation(
            id: cancellation.id,
            eventId: cancellation.eventId,
            eventTitle: cancellation.eventTitle,
            organizerId: cancellation.organizerId,
            reason: cancellation.reason,
            reasonNote: cancellation.reasonNote,
            status: status,
            impact: cancellation.impact,
            compensationPlan: cancellation.compensationPlan,
            createdAt: cancellation.createdAt,
            confirmedAt: cancellation.confirmedAt,
            processingStartedAt: cancellation.processingStartedAt,
            completedAt: cancellation.completedAt,
            initiatedBy: cancellation.initiatedBy,
            confirmedBy: cancellation.confirmedBy,
            confirmationCode: cancellation.confirmationCode,
            refundRequestsCreated: cancellation.refundRequestsCreated,
            refundsProcessed: cancellation.refundsProcessed,
            refundsFailed: cancellation.refundsFailed,
            notificationsSent: cancellation.notificationsSent,
            notificationsFailed: cancellation.notificationsFailed,
            processingErrors: cancellation.processingErrors
        )
    }

    private func publishProgress(cancellationId: UUID, phase: CancellationProgress.ProcessingPhase, step: Int, total: Int, message: String) {
        processingProgressPublisher.send(CancellationProgress(
            cancellationId: cancellationId,
            phase: phase,
            currentStep: step,
            totalSteps: total,
            message: message
        ))
    }
}

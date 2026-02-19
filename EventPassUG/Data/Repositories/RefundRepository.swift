//
//  RefundRepository.swift
//  EventPassUG
//
//  Refund service with eligibility logic, processing, and automation
//  Designed for fintech-grade reliability and auditability
//

import Foundation
import Combine

// MARK: - Protocol

protocol RefundRepositoryProtocol {
    // Eligibility
    func checkEligibility(ticket: Ticket, event: Event) async throws -> RefundEligibilityResult
    func getRefundPolicy(eventId: UUID, ticketTypeId: UUID?) async throws -> RefundPolicy

    // User actions
    func requestRefund(ticket: Ticket, reason: RefundReason, note: String?) async throws -> RefundRequest
    func cancelRefundRequest(requestId: UUID) async throws
    func getRefundRequest(requestId: UUID) async throws -> RefundRequest?
    func getUserRefundRequests(userId: UUID) async throws -> [RefundRequest]
    func getRefundRequestForTicket(ticketId: UUID) async throws -> RefundRequest?

    // Organizer actions
    func getEventRefundRequests(eventId: UUID, status: RefundStatus?) async throws -> [RefundRequest]
    func getOrganizerRefundRequests(organizerId: UUID, status: RefundStatus?) async throws -> [RefundRequest]
    func approveRefund(requestId: UUID, approvedAmount: Double?, note: String?) async throws -> RefundRequest
    func rejectRefund(requestId: UUID, note: String) async throws -> RefundRequest
    func issueManualRefund(ticket: Ticket, amount: Double, reason: RefundReason, note: String?) async throws -> RefundRequest

    // Processing
    func processRefund(requestId: UUID) async throws -> RefundTransaction
    func getRefundTransaction(transactionId: UUID) async throws -> RefundTransaction?
    func getRefundTransactions(eventId: UUID) async throws -> [RefundTransaction]

    // Automation
    func processEventCancellationRefunds(eventId: UUID) async throws -> [RefundRequest]
    func markTicketsRefundableForReschedule(eventId: UUID, deadline: Date) async throws

    // Analytics
    func getRefundAnalytics(eventId: UUID?, organizerId: UUID?, period: DateInterval) async throws -> RefundAnalytics

    // Publishers
    var refundStatusPublisher: PassthroughSubject<RefundRequest, Never> { get }
}

// MARK: - Refund Errors

enum RefundError: LocalizedError {
    case notEligible(String)
    case requestNotFound
    case alreadyRequested
    case alreadyProcessed
    case policyNotFound
    case processingFailed(String)
    case invalidAmount
    case ticketAlreadyRefunded
    case ticketAlreadyUsed
    case refundDeadlinePassed
    case maxRefundsExceeded

    var errorDescription: String? {
        switch self {
        case .notEligible(let reason):
            return "Not eligible for refund: \(reason)"
        case .requestNotFound:
            return "Refund request not found"
        case .alreadyRequested:
            return "A refund has already been requested for this ticket"
        case .alreadyProcessed:
            return "This refund has already been processed"
        case .policyNotFound:
            return "Refund policy not found"
        case .processingFailed(let reason):
            return "Refund processing failed: \(reason)"
        case .invalidAmount:
            return "Invalid refund amount"
        case .ticketAlreadyRefunded:
            return "This ticket has already been refunded"
        case .ticketAlreadyUsed:
            return "Used tickets cannot be refunded"
        case .refundDeadlinePassed:
            return "The refund deadline has passed"
        case .maxRefundsExceeded:
            return "Maximum number of refunds exceeded"
        }
    }
}

// MARK: - Refund Processor Protocol (Payment Integration Abstraction)

protocol RefundProcessorProtocol {
    func processMobileMoneyRefund(
        phoneNumber: String,
        amount: Double,
        currency: String,
        reference: String,
        provider: RefundPaymentMethod
    ) async throws -> String  // Returns transaction reference

    func processCardRefund(
        originalTransactionRef: String,
        amount: Double,
        currency: String
    ) async throws -> String

    func processWalletRefund(
        userId: UUID,
        amount: Double,
        currency: String
    ) async throws -> String
}

// MARK: - Mock Refund Processor

class MockRefundProcessor: RefundProcessorProtocol {
    func processMobileMoneyRefund(
        phoneNumber: String,
        amount: Double,
        currency: String,
        reference: String,
        provider: RefundPaymentMethod
    ) async throws -> String {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Simulate occasional failures (5% failure rate)
        if Int.random(in: 1...20) == 1 {
            throw RefundError.processingFailed("Mobile money service temporarily unavailable")
        }

        return "MM-REF-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 1000...9999))"
    }

    func processCardRefund(
        originalTransactionRef: String,
        amount: Double,
        currency: String
    ) async throws -> String {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return "CARD-REF-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 1000...9999))"
    }

    func processWalletRefund(
        userId: UUID,
        amount: Double,
        currency: String
    ) async throws -> String {
        try await Task.sleep(nanoseconds: 500_000_000)
        return "WALLET-REF-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 1000...9999))"
    }
}

// MARK: - Mock Implementation

class MockRefundRepository: RefundRepositoryProtocol {
    @Published private var refundRequests: [RefundRequest] = []
    @Published private var refundTransactions: [RefundTransaction] = []
    @Published private var refundPolicies: [UUID: RefundPolicy] = [:]  // eventId -> policy

    let refundStatusPublisher = PassthroughSubject<RefundRequest, Never>()
    private let refundProcessor: RefundProcessorProtocol

    private let persistenceKey = "com.eventpassug.refunds"
    private let transactionsKey = "com.eventpassug.refund_transactions"

    init(refundProcessor: RefundProcessorProtocol = MockRefundProcessor()) {
        self.refundProcessor = refundProcessor
        loadPersistedData()
    }

    // MARK: - Eligibility

    func checkEligibility(ticket: Ticket, event: Event) async throws -> RefundEligibilityResult {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Check if ticket already used
        if ticket.scanStatus == .scanned {
            return .notEligible(reason: "This ticket has already been used")
        }

        // Check if ticket already refunded
        if let existingRequest = refundRequests.first(where: {
            $0.ticketId == ticket.id && !$0.status.isFinal
        }) {
            return .notEligible(reason: "A refund request is already pending for this ticket")
        }

        if refundRequests.first(where: {
            $0.ticketId == ticket.id && $0.status == .completed
        }) != nil {
            return .notEligible(reason: "This ticket has already been refunded")
        }

        // Check event status
        if event.status == .cancelled {
            let policy = RefundPolicy.defaultPolicy(eventId: event.id)
            return .eligible(
                amount: ticket.ticketType.price,
                percentage: 1.0,
                fee: 0,  // No fee for cancelled events
                deadline: nil,
                policy: policy
            )
        }

        if event.status == .completed {
            return .notEligible(reason: "The event has already ended")
        }

        // Get policy
        let policy = refundPolicies[event.id] ?? RefundPolicy.defaultPolicy(eventId: event.id)

        if !policy.isRefundable {
            return .notEligible(reason: "This ticket type is non-refundable")
        }

        // Check deadline
        let hoursUntilEvent = event.startDate.timeIntervalSince(Date()) / 3600
        if hoursUntilEvent < Double(policy.refundDeadlineHours) {
            return .notEligible(reason: "Refund deadline has passed (must be \(policy.refundDeadlineHours)+ hours before event)")
        }

        // Calculate refund amount based on time windows
        var refundPercentage = policy.refundPercentage
        let ticketPrice = ticket.ticketType.price

        if let fullDeadline = policy.fullRefundDeadlineHours, hoursUntilEvent >= Double(fullDeadline) {
            refundPercentage = 1.0
        } else if let partialDeadline = policy.partialRefundDeadlineHours,
                  let partialPercentage = policy.partialRefundPercentage,
                  hoursUntilEvent >= Double(partialDeadline) {
            refundPercentage = partialPercentage
        }

        let refundAmount = ticketPrice * refundPercentage
        let processingFee = refundAmount * policy.processingFeePercentage
        let deadline = Calendar.current.date(
            byAdding: .hour,
            value: -policy.refundDeadlineHours,
            to: event.startDate
        )

        return .eligible(
            amount: refundAmount,
            percentage: refundPercentage,
            fee: processingFee,
            deadline: deadline,
            policy: policy
        )
    }

    func getRefundPolicy(eventId: UUID, ticketTypeId: UUID?) async throws -> RefundPolicy {
        try await Task.sleep(nanoseconds: 200_000_000)

        if let policy = refundPolicies[eventId] {
            return policy
        }

        return RefundPolicy.defaultPolicy(eventId: eventId)
    }

    // MARK: - User Actions

    func requestRefund(ticket: Ticket, reason: RefundReason, note: String?) async throws -> RefundRequest {
        try await Task.sleep(nanoseconds: 500_000_000)

        // Check for existing request
        if refundRequests.contains(where: {
            $0.ticketId == ticket.id && !$0.status.isFinal
        }) {
            throw RefundError.alreadyRequested
        }

        // Check if ticket used
        if ticket.scanStatus == .scanned {
            throw RefundError.ticketAlreadyUsed
        }

        let request = RefundRequest(
            ticketId: ticket.id,
            ticketNumber: ticket.ticketNumber,
            eventId: ticket.eventId,
            eventTitle: ticket.eventTitle,
            userId: ticket.userId,
            userName: "User",  // Would come from user service
            reason: reason,
            userNote: note,
            requestedAmount: ticket.ticketType.price,
            currency: "UGX",
            originalPaymentMethod: .mtnMobileMoney,  // Would come from original payment
            originalPaymentReference: "PAY-\(ticket.orderNumber)",
            originalPurchaseDate: ticket.purchaseDate,
            status: reason.isAutoApproved ? .approved : .pending
        )

        await MainActor.run {
            refundRequests.append(request)
        }
        persistData()

        refundStatusPublisher.send(request)

        // Auto-process approved requests
        if request.status == .approved {
            Task {
                try? await processRefund(requestId: request.id)
            }
        }

        return request
    }

    func cancelRefundRequest(requestId: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard let index = refundRequests.firstIndex(where: { $0.id == requestId }) else {
            throw RefundError.requestNotFound
        }

        guard refundRequests[index].status == .pending else {
            throw RefundError.alreadyProcessed
        }

        await MainActor.run {
            var request = refundRequests[index]
            request.status = .rejected
            request.statusHistory.append(RefundStatusChange(
                fromStatus: .pending,
                toStatus: .rejected,
                note: "Cancelled by user"
            ))
            refundRequests[index] = request
        }
        persistData()
    }

    func getRefundRequest(requestId: UUID) async throws -> RefundRequest? {
        try await Task.sleep(nanoseconds: 200_000_000)
        return refundRequests.first(where: { $0.id == requestId })
    }

    func getUserRefundRequests(userId: UUID) async throws -> [RefundRequest] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return refundRequests
            .filter { $0.userId == userId }
            .sorted { $0.requestedAt > $1.requestedAt }
    }

    func getRefundRequestForTicket(ticketId: UUID) async throws -> RefundRequest? {
        try await Task.sleep(nanoseconds: 200_000_000)
        return refundRequests.first(where: { $0.ticketId == ticketId })
    }

    // MARK: - Organizer Actions

    func getEventRefundRequests(eventId: UUID, status: RefundStatus?) async throws -> [RefundRequest] {
        try await Task.sleep(nanoseconds: 300_000_000)

        var requests = refundRequests.filter { $0.eventId == eventId }

        if let status = status {
            requests = requests.filter { $0.status == status }
        }

        return requests.sorted { $0.requestedAt > $1.requestedAt }
    }

    func getOrganizerRefundRequests(organizerId: UUID, status: RefundStatus?) async throws -> [RefundRequest] {
        try await Task.sleep(nanoseconds: 400_000_000)

        // In real implementation, would filter by organizer's events
        var requests = refundRequests

        if let status = status {
            requests = requests.filter { $0.status == status }
        }

        return requests.sorted { $0.requestedAt > $1.requestedAt }
    }

    func approveRefund(requestId: UUID, approvedAmount: Double?, note: String?) async throws -> RefundRequest {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard let index = refundRequests.firstIndex(where: { $0.id == requestId }) else {
            throw RefundError.requestNotFound
        }

        guard refundRequests[index].status == .pending else {
            throw RefundError.alreadyProcessed
        }

        await MainActor.run {
            var request = refundRequests[index]
            let previousStatus = request.status
            request.status = .approved
            request.reviewedAt = Date()
            request.reviewerNote = note

            if let amount = approvedAmount {
                // Validate amount
                guard amount > 0 && amount <= request.requestedAmount else {
                    return
                }
            }

            request.statusHistory.append(RefundStatusChange(
                fromStatus: previousStatus,
                toStatus: .approved,
                note: note ?? "Approved by organizer"
            ))

            refundRequests[index] = request
        }
        persistData()

        let updatedRequest = refundRequests[index]
        refundStatusPublisher.send(updatedRequest)

        // Trigger processing
        Task {
            try? await processRefund(requestId: requestId)
        }

        return updatedRequest
    }

    func rejectRefund(requestId: UUID, note: String) async throws -> RefundRequest {
        try await Task.sleep(nanoseconds: 400_000_000)

        guard let index = refundRequests.firstIndex(where: { $0.id == requestId }) else {
            throw RefundError.requestNotFound
        }

        guard refundRequests[index].status == .pending else {
            throw RefundError.alreadyProcessed
        }

        await MainActor.run {
            var request = refundRequests[index]
            let previousStatus = request.status
            request.status = .rejected
            request.reviewedAt = Date()
            request.reviewerNote = note
            request.statusHistory.append(RefundStatusChange(
                fromStatus: previousStatus,
                toStatus: .rejected,
                note: note
            ))
            refundRequests[index] = request
        }
        persistData()

        let updatedRequest = refundRequests[index]
        refundStatusPublisher.send(updatedRequest)

        return updatedRequest
    }

    func issueManualRefund(ticket: Ticket, amount: Double, reason: RefundReason, note: String?) async throws -> RefundRequest {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard amount > 0 && amount <= ticket.ticketType.price else {
            throw RefundError.invalidAmount
        }

        let request = RefundRequest(
            ticketId: ticket.id,
            ticketNumber: ticket.ticketNumber,
            eventId: ticket.eventId,
            eventTitle: ticket.eventTitle,
            userId: ticket.userId,
            userName: "User",
            reason: reason,
            userNote: note,
            requestedAmount: amount,
            approvedAmount: amount,
            currency: "UGX",
            originalPaymentMethod: .mtnMobileMoney,
            originalPaymentReference: "PAY-\(ticket.orderNumber)",
            originalPurchaseDate: ticket.purchaseDate,
            status: .approved,
            reviewedAt: Date(),
            reviewerNote: "Manual refund issued by organizer"
        )

        await MainActor.run {
            refundRequests.append(request)
        }
        persistData()

        refundStatusPublisher.send(request)

        // Process immediately
        Task {
            try? await processRefund(requestId: request.id)
        }

        return request
    }

    // MARK: - Processing

    func processRefund(requestId: UUID) async throws -> RefundTransaction {
        guard let index = refundRequests.firstIndex(where: { $0.id == requestId }) else {
            throw RefundError.requestNotFound
        }

        let request = refundRequests[index]

        guard request.status == .approved else {
            throw RefundError.notEligible("Refund not approved")
        }

        // Update status to processing
        await MainActor.run {
            var updated = refundRequests[index]
            updated.status = .processing
            updated.statusHistory.append(RefundStatusChange(
                fromStatus: .approved,
                toStatus: .processing,
                note: "Processing refund"
            ))
            refundRequests[index] = updated
        }
        persistData()

        let processingFee = request.requestedAmount * 0.05
        let refundAmount = request.approvedAmount ?? request.requestedAmount

        // Create transaction
        var transaction = RefundTransaction(
            refundRequestId: request.id,
            ticketId: request.ticketId,
            eventId: request.eventId,
            userId: request.userId,
            organizerId: UUID(),  // Would come from event
            originalAmount: request.requestedAmount,
            refundAmount: refundAmount,
            processingFee: processingFee,
            currency: request.currency,
            paymentMethod: request.originalPaymentMethod,
            paymentReference: request.originalPaymentReference,
            status: .processing,
            reason: request.reason
        )

        // Process through payment provider
        do {
            let transactionRef: String

            switch request.originalPaymentMethod {
            case .mtnMobileMoney, .airtelMoney:
                transactionRef = try await refundProcessor.processMobileMoneyRefund(
                    phoneNumber: request.userPhone ?? "",
                    amount: refundAmount - processingFee,
                    currency: request.currency,
                    reference: request.originalPaymentReference,
                    provider: request.originalPaymentMethod
                )
            case .card:
                transactionRef = try await refundProcessor.processCardRefund(
                    originalTransactionRef: request.originalPaymentReference,
                    amount: refundAmount - processingFee,
                    currency: request.currency
                )
            case .wallet, .bankTransfer:
                transactionRef = try await refundProcessor.processWalletRefund(
                    userId: request.userId,
                    amount: refundAmount - processingFee,
                    currency: request.currency
                )
            }

            // Update transaction as completed
            transaction.status = .completed
            transaction.processedAt = Date()
            transaction.completedAt = Date()

            await MainActor.run {
                refundTransactions.append(transaction)

                // Update request
                var updated = refundRequests[index]
                updated.status = .completed
                updated.processedAt = Date()
                updated.completedAt = Date()
                updated.statusHistory.append(RefundStatusChange(
                    fromStatus: .processing,
                    toStatus: .completed,
                    note: "Refund completed. Reference: \(transactionRef)"
                ))
                refundRequests[index] = updated
            }
            persistData()

            let finalRequest = refundRequests[index]
            refundStatusPublisher.send(finalRequest)

            return transaction

        } catch {
            // Handle failure
            transaction.status = .failed
            transaction.failedAt = Date()
            transaction.failureReason = error.localizedDescription

            await MainActor.run {
                refundTransactions.append(transaction)

                var updated = refundRequests[index]
                updated.status = .failed
                updated.failureReason = error.localizedDescription
                updated.statusHistory.append(RefundStatusChange(
                    fromStatus: .processing,
                    toStatus: .failed,
                    note: "Refund failed: \(error.localizedDescription)"
                ))
                refundRequests[index] = updated
            }
            persistData()

            throw RefundError.processingFailed(error.localizedDescription)
        }
    }

    func getRefundTransaction(transactionId: UUID) async throws -> RefundTransaction? {
        try await Task.sleep(nanoseconds: 200_000_000)
        return refundTransactions.first(where: { $0.id == transactionId })
    }

    func getRefundTransactions(eventId: UUID) async throws -> [RefundTransaction] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return refundTransactions
            .filter { $0.eventId == eventId }
            .sorted { $0.initiatedAt > $1.initiatedAt }
    }

    // MARK: - Automation

    func processEventCancellationRefunds(eventId: UUID) async throws -> [RefundRequest] {
        try await Task.sleep(nanoseconds: 500_000_000)

        // In real implementation, would fetch all tickets for the event
        // and create refund requests for each
        var createdRequests: [RefundRequest] = []

        // For now, mark any existing requests as auto-approved
        for index in refundRequests.indices {
            if refundRequests[index].eventId == eventId && refundRequests[index].status == .pending {
                await MainActor.run {
                    var request = refundRequests[index]
                    request.status = .approved
                    request.reviewerNote = "Auto-approved due to event cancellation"
                    request.statusHistory.append(RefundStatusChange(
                        fromStatus: .pending,
                        toStatus: .approved,
                        note: "Auto-approved: Event cancelled"
                    ))
                    refundRequests[index] = request
                    createdRequests.append(request)
                }
            }
        }

        persistData()
        return createdRequests
    }

    func markTicketsRefundableForReschedule(eventId: UUID, deadline: Date) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Update policy to allow refunds until the new deadline
        var policy = refundPolicies[eventId] ?? RefundPolicy.defaultPolicy(eventId: eventId)
        let hoursUntilDeadline = Int(deadline.timeIntervalSince(Date()) / 3600)

        policy = RefundPolicy(
            id: policy.id,
            eventId: eventId,
            ticketTypeId: nil,
            isRefundable: true,
            refundDeadlineHours: max(0, hoursUntilDeadline),
            refundPercentage: 1.0,
            processingFeePercentage: 0,
            allowRescheduledEventRefund: true,
            policyText: "Full refunds available due to event reschedule. Deadline: \(deadline.formatted())"
        )

        await MainActor.run {
            refundPolicies[eventId] = policy
        }
    }

    // MARK: - Analytics

    func getRefundAnalytics(eventId: UUID?, organizerId: UUID?, period: DateInterval) async throws -> RefundAnalytics {
        try await Task.sleep(nanoseconds: 400_000_000)

        var filteredRequests = refundRequests.filter {
            $0.requestedAt >= period.start && $0.requestedAt <= period.end
        }

        if let eventId = eventId {
            filteredRequests = filteredRequests.filter { $0.eventId == eventId }
        }

        let pendingCount = filteredRequests.filter { $0.status == .pending }.count
        let approvedCount = filteredRequests.filter { $0.status == .approved }.count
        let rejectedCount = filteredRequests.filter { $0.status == .rejected }.count
        let completedCount = filteredRequests.filter { $0.status == .completed }.count
        let failedCount = filteredRequests.filter { $0.status == .failed }.count

        let totalRequested = filteredRequests.reduce(0.0) { $0 + $1.requestedAmount }
        let totalRefunded = filteredRequests
            .filter { $0.status == .completed }
            .reduce(0.0) { $0 + ($1.approvedAmount ?? $1.requestedAmount) }

        // Calculate top reasons
        var reasonCounts: [RefundReason: Int] = [:]
        for request in filteredRequests {
            reasonCounts[request.reason, default: 0] += 1
        }

        return RefundAnalytics(
            eventId: eventId,
            organizerId: organizerId,
            period: period,
            totalRequests: filteredRequests.count,
            pendingRequests: pendingCount,
            approvedRequests: approvedCount,
            rejectedRequests: rejectedCount,
            completedRefunds: completedCount,
            failedRefunds: failedCount,
            totalAmountRequested: totalRequested,
            totalAmountRefunded: totalRefunded,
            totalProcessingFees: totalRefunded * 0.05,
            averageProcessingTimeHours: 4.5,  // Mock average
            refundRate: 0.03,  // 3% refund rate mock
            topReasons: reasonCounts
        )
    }

    // MARK: - Persistence

    private func persistData() {
        if let requestsData = try? JSONEncoder().encode(refundRequests) {
            UserDefaults.standard.set(requestsData, forKey: persistenceKey)
        }
        if let transactionsData = try? JSONEncoder().encode(refundTransactions) {
            UserDefaults.standard.set(transactionsData, forKey: transactionsKey)
        }
    }

    private func loadPersistedData() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let requests = try? JSONDecoder().decode([RefundRequest].self, from: data) {
            self.refundRequests = requests
        }
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let transactions = try? JSONDecoder().decode([RefundTransaction].self, from: data) {
            self.refundTransactions = transactions
        }
    }

    // MARK: - Debug Helpers

    func addSampleData() {
        refundRequests = RefundRequest.samples
        persistData()
    }

    func clearAllData() {
        refundRequests = []
        refundTransactions = []
        refundPolicies = [:]
        UserDefaults.standard.removeObject(forKey: persistenceKey)
        UserDefaults.standard.removeObject(forKey: transactionsKey)
    }
}

//
//  PaymentService.swift
//  EventPassUG
//
//  Payment processing service protocol and mock implementation
//

import Foundation

// MARK: - Models

enum PaymentMethod: String, Codable, CaseIterable {
    case mtnMomo = "MTN MoMo"
    case airtelMoney = "Airtel Money"
    case card = "Card (Visa/Mastercard)"

    var iconName: String {
        switch self {
        case .mtnMomo: return "phone.circle.fill"
        case .airtelMoney: return "antenna.radiowaves.left.and.right"
        case .card: return "creditcard.fill"
        }
    }

    var color: String {
        switch self {
        case .mtnMomo: return "FFC000" // MTN Yellow
        case .airtelMoney: return "ED1C24" // Airtel Red
        case .card: return "007AFF" // Blue
        }
    }
}

enum PaymentStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
    case refunded
}

struct Payment: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let currency: String
    let method: PaymentMethod
    var status: PaymentStatus
    let userId: UUID
    let eventId: UUID
    let ticketIds: [UUID]
    let timestamp: Date

    // Mobile Money specific fields
    let mobileMoneyNumber: String?

    init(
        id: UUID = UUID(),
        amount: Double,
        currency: String = "UGX",
        method: PaymentMethod,
        status: PaymentStatus = .pending,
        userId: UUID,
        eventId: UUID,
        ticketIds: [UUID],
        timestamp: Date = Date(),
        mobileMoneyNumber: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.method = method
        self.status = status
        self.userId = userId
        self.eventId = eventId
        self.ticketIds = ticketIds
        self.timestamp = timestamp
        self.mobileMoneyNumber = mobileMoneyNumber
    }
}

// MARK: - Protocol

protocol PaymentRepositoryProtocol {
    func initiatePayment(
        amount: Double,
        method: PaymentMethod,
        userId: UUID,
        eventId: UUID,
        mobileMoneyNumber: String?
    ) async throws -> Payment

    func processPayment(paymentId: UUID) async throws -> PaymentStatus
    func fetchPaymentHistory(userId: UUID) async throws -> [Payment]
    func requestRefund(paymentId: UUID) async throws -> Bool
    func calculateRevenue(organizerId: UUID) async throws -> Double
}

// MARK: - Mock Implementation

class MockPaymentRepository: PaymentRepositoryProtocol {
    @Published private var payments: [Payment] = []

    func initiatePayment(
        amount: Double,
        method: PaymentMethod,
        userId: UUID,
        eventId: UUID,
        mobileMoneyNumber: String?
    ) async throws -> Payment {
        // TODO: Replace with real payment gateway integration (e.g., Flutterwave, Paystack)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let payment = Payment(
            amount: amount,
            method: method,
            status: .processing,
            userId: userId,
            eventId: eventId,
            ticketIds: [],
            mobileMoneyNumber: mobileMoneyNumber
        )

        await MainActor.run {
            payments.append(payment)
        }

        return payment
    }

    func processPayment(paymentId: UUID) async throws -> PaymentStatus {
        // TODO: Replace with real payment processing
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Simulate successful payment 90% of the time
        let success = Int.random(in: 1...10) <= 9

        await MainActor.run {
            if let index = payments.firstIndex(where: { $0.id == paymentId }) {
                payments[index].status = success ? .completed : .failed
            }
        }

        return success ? .completed : .failed
    }

    func fetchPaymentHistory(userId: UUID) async throws -> [Payment] {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return payments.filter { $0.userId == userId }
    }

    func requestRefund(paymentId: UUID) async throws -> Bool {
        // TODO: Replace with real refund processing
        try await Task.sleep(nanoseconds: 1_500_000_000)

        await MainActor.run {
            if let index = payments.firstIndex(where: { $0.id == paymentId }) {
                payments[index].status = .refunded
            }
        }

        return true
    }

    func calculateRevenue(organizerId: UUID) async throws -> Double {
        // TODO: Replace with real API call to fetch organizer's revenue
        try await Task.sleep(nanoseconds: 500_000_000)

        // Mock calculation
        let completedPayments = payments.filter { $0.status == .completed }
        return completedPayments.reduce(0) { $0 + $1.amount }
    }
}

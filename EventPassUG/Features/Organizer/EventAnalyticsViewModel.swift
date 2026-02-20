//
//  EventAnalyticsViewModel.swift
//  EventPassUG
//
//  ViewModel for event analytics with Firebase integration structure
//

import Foundation
import SwiftUI

@MainActor
class EventAnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var event: Event
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Analytics Data

    @Published var impressions: Int = 0
    @Published var uniqueViews: Int = 0
    @Published var shareCount: Int = 0
    @Published var analytics: OrganizerAnalytics?

    // MARK: - Computed Properties

    var totalTicketsSold: Int {
        event.ticketTypes.reduce(0) { $0 + $1.sold }
    }

    var totalRevenue: Double {
        event.ticketTypes.reduce(0.0) { $0 + (Double($1.sold) * $1.price) }
    }

    var totalCapacity: Int {
        event.ticketTypes.filter { !$0.isUnlimitedQuantity }.reduce(0) { $0 + $1.quantity }
    }

    var overallSalesPercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(totalTicketsSold) / Double(totalCapacity)
    }

    var conversionRate: Double {
        guard impressions > 0 else { return 0 }
        return (Double(totalTicketsSold) / Double(impressions)) * 100
    }

    var averageTicketPrice: Double {
        guard totalTicketsSold > 0 else { return 0 }
        return totalRevenue / Double(totalTicketsSold)
    }

    // MARK: - Initialization

    init(event: Event) {
        self.event = event
        // Simulate impressions (in production, fetch from Firebase)
        self.impressions = event.likeCount * 5 // Example: 5 views per like
        self.uniqueViews = event.likeCount * 3
        self.shareCount = event.likeCount / 2
    }

    // MARK: - Firebase Integration Structure

    /// Load analytics from Firebase
    /// - Note: In production, this would fetch from Firestore/Analytics
    func loadAnalytics() async {
        isLoading = true
        error = nil

        do {
            // TODO: Replace with actual Firebase call
            // Example:
            // let analytics = try await FirebaseService.shared.getEventAnalytics(eventId: event.id)
            // self.impressions = analytics.impressions
            // self.uniqueViews = analytics.uniqueViews

            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)

            // Mock data for development
            await MainActor.run {
                self.impressions = event.likeCount * 5
                self.uniqueViews = event.likeCount * 3
                self.shareCount = event.likeCount / 2
                // Generate analytics for export support
                self.analytics = self.generateAnalyticsFromEvent()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// Refresh event data
    func refreshEvent() async {
        // TODO: Fetch latest event data from Firebase
        await loadAnalytics()
    }

    // MARK: - Helper Methods

    func salesPercentage(for ticketType: TicketType) -> Double {
        guard !ticketType.isUnlimitedQuantity, ticketType.quantity > 0 else { return 0 }
        return Double(ticketType.sold) / Double(ticketType.quantity)
    }

    func revenue(for ticketType: TicketType) -> Double {
        return Double(ticketType.sold) * ticketType.price
    }

    // MARK: - Export Support

    /// Generates OrganizerAnalytics from current event data for export
    /// Used when analytics haven't been loaded from the server
    func generateAnalyticsFromEvent() -> OrganizerAnalytics {
        let calendar = Calendar.current
        let now = Date()

        // Generate sales data points from event data
        var salesOverTime: [SalesDataPoint] = []
        for i in (0..<14).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let baseSales = max(1, totalTicketsSold / 14)
            let sales = baseSales + Int.random(in: -2...5)
            salesOverTime.append(SalesDataPoint(
                date: date,
                sales: max(0, sales),
                revenue: Double(max(0, sales)) * averageTicketPrice
            ))
        }

        // Generate tier sales data
        let colors = ["34C759", "FF7A00", "FFD700", "AF52DE", "007AFF"]
        let salesByTier = event.ticketTypes.enumerated().map { (index, ticketType) in
            TierSalesData(
                tierName: ticketType.name,
                sold: ticketType.sold,
                capacity: ticketType.isUnlimitedQuantity ? ticketType.sold : ticketType.quantity,
                revenue: Double(ticketType.sold) * ticketType.price,
                price: ticketType.price,
                color: colors[index % colors.count]
            )
        }

        // Generate payment methods (mock distribution)
        let paymentMethods = [
            PaymentMethodData(
                method: "MTN MoMo",
                amount: totalRevenue * 0.60,
                count: Int(Double(totalTicketsSold) * 0.60),
                percentage: 0.60,
                color: "FFCC00",
                icon: "phone.fill"
            ),
            PaymentMethodData(
                method: "Airtel Money",
                amount: totalRevenue * 0.30,
                count: Int(Double(totalTicketsSold) * 0.30),
                percentage: 0.30,
                color: "ED1C24",
                icon: "phone.fill"
            ),
            PaymentMethodData(
                method: "Card",
                amount: totalRevenue * 0.10,
                count: Int(Double(totalTicketsSold) * 0.10),
                percentage: 0.10,
                color: "007AFF",
                icon: "creditcard.fill"
            )
        ]

        // Calculate fees (5% platform fee)
        let platformFees = totalRevenue * 0.05
        let processingFees = totalRevenue * 0.03

        return OrganizerAnalytics(
            id: UUID(),
            eventId: event.id,
            eventTitle: event.title,
            lastUpdated: Date(),

            // Overview
            revenue: totalRevenue,
            ticketsSold: totalTicketsSold,
            totalCapacity: totalCapacity,
            attendanceRate: Double(totalTicketsSold) * 0.75 / max(1, Double(totalCapacity)),
            capacityUsed: overallSalesPercentage,
            salesTarget: totalRevenue * 1.2,
            salesProgress: 0.8,

            // Sales Performance
            salesOverTime: salesOverTime,
            salesByTier: salesByTier,
            ticketVelocity: Double(totalTicketsSold) / 24.0,
            sellOutForecast: nil,
            dailySalesAverage: Double(totalTicketsSold) / 14.0,
            peakSalesDay: "Saturday",

            // Audience Insights
            totalAttendees: totalTicketsSold,
            repeatAttendees: Int(Double(totalTicketsSold) * 0.26),
            repeatRate: 0.26,
            vipShare: Double(event.ticketTypes.filter { $0.name.lowercased().contains("vip") }.reduce(0) { $0 + $1.sold }) / max(1, Double(totalTicketsSold)),
            demographics: nil,
            newVsReturning: NewVsReturningData(
                newAttendees: Int(Double(totalTicketsSold) * 0.74),
                returningAttendees: Int(Double(totalTicketsSold) * 0.26)
            ),

            // Marketing & Conversion
            eventViews: impressions,
            uniqueViews: uniqueViews,
            conversionRate: conversionRate / 100.0,
            trafficSources: [],
            promoPerformance: [],
            shareCount: shareCount,
            saveCount: event.likeCount,

            // Operations
            checkinRate: 0.72,
            peakArrivalTime: "7:30 PM",
            averageArrivalTime: "6:45 PM",
            queueEstimate: 8,
            checkinsByHour: [],

            // Financial
            paymentMethodsSplit: paymentMethods,
            grossRevenue: totalRevenue,
            netRevenue: totalRevenue - platformFees - processingFees,
            platformFees: platformFees,
            processingFees: processingFees,
            refundsTotal: 0,
            refundsCount: 0,

            // Insights & Alerts
            alerts: [],
            revenueForecast: totalRevenue * 1.15,
            healthScore: min(100, Int(overallSalesPercentage * 100) + 20)
        )
    }
}

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
}

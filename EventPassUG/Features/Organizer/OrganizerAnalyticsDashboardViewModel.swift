//
//  OrganizerAnalyticsDashboardViewModel.swift
//  EventPassUG
//
//  ViewModel for loading and managing analytics data
//

import SwiftUI
import Combine

@MainActor
class OrganizerAnalyticsDashboardViewModel: ObservableObject {
    // MARK: - Published State

    @Published var analytics: OrganizerAnalytics?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedTimeRange: TimeRange = .last7Days

    // MARK: - Dependencies

    private let eventId: UUID
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Time Range Options

    enum TimeRange: String, CaseIterable {
        case last24Hours = "24h"
        case last7Days = "7d"
        case last30Days = "30d"
        case allTime = "All"

        var title: String {
            switch self {
            case .last24Hours: return "Last 24 Hours"
            case .last7Days: return "Last 7 Days"
            case .last30Days: return "Last 30 Days"
            case .allTime: return "All Time"
            }
        }
    }

    // MARK: - Initialization

    init(eventId: UUID) {
        self.eventId = eventId
    }

    // MARK: - Data Loading

    func loadAnalytics() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // TODO: Replace with real API call
            // let analytics = try await analyticsService.fetchAnalytics(eventId: eventId, timeRange: selectedTimeRange)

            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // Use mock data for now
            await MainActor.run {
                self.analytics = OrganizerAnalytics.mock
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func refreshAnalytics() async {
        await loadAnalytics()
    }

    func updateTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        Task {
            await loadAnalytics()
        }
    }

    // MARK: - Computed Properties

    var hasData: Bool {
        analytics != nil
    }

    var revenueGrowth: Double {
        // TODO: Calculate actual growth from historical data
        return 0.12
    }

    var isPerformingWell: Bool {
        guard let analytics = analytics else { return false }
        return analytics.healthScore >= 70
    }
}

// MARK: - Analytics Service Protocol (for future implementation)

protocol AnalyticsServiceProtocol {
    func fetchAnalytics(eventId: UUID, timeRange: OrganizerAnalyticsDashboardViewModel.TimeRange) async throws -> OrganizerAnalytics
    func fetchHistoricalData(eventId: UUID, metric: String, days: Int) async throws -> [SalesDataPoint]
}

// MARK: - Mock Analytics Service

class MockAnalyticsService: AnalyticsServiceProtocol {
    func fetchAnalytics(eventId: UUID, timeRange: OrganizerAnalyticsDashboardViewModel.TimeRange) async throws -> OrganizerAnalytics {
        try await Task.sleep(nanoseconds: 500_000_000)
        return OrganizerAnalytics.mock
    }

    func fetchHistoricalData(eventId: UUID, metric: String, days: Int) async throws -> [SalesDataPoint] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return OrganizerAnalytics.mock.salesOverTime
    }
}

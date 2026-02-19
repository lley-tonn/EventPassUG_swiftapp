//
//  TicketAnalyticsDetailView.swift
//  EventPassUG
//
//  Detailed ticket sales analytics with velocity, trends, and forecasts
//

import SwiftUI

struct TicketAnalyticsDetailView: View {
    let totalSold: Int
    let totalCapacity: Int
    let events: [Event]
    let salesData: [SalesDataPoint]

    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedView: ViewMode = .overview

    enum TimeRange: String, CaseIterable {
        case last7Days = "7D"
        case last30Days = "30D"
        case allTime = "All"
    }

    enum ViewMode: String, CaseIterable {
        case overview = "Overview"
        case byEvent = "By Event"
        case byTier = "By Tier"
    }

    // Computed properties
    private var capacityPercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(totalSold) / Double(totalCapacity)
    }

    private var remainingTickets: Int {
        totalCapacity - totalSold
    }

    private var dailySalesAverage: Double {
        guard !salesData.isEmpty else { return 0 }
        let totalSales = salesData.reduce(0) { $0 + $1.sales }
        return Double(totalSales) / Double(salesData.count)
    }

    private var ticketVelocity: Double {
        // Tickets sold per hour (assuming 12 hours of active sales per day)
        return dailySalesAverage / 12
    }

    private var estimatedSellOutDays: Int? {
        guard dailySalesAverage > 0, remainingTickets > 0 else { return nil }
        return Int(ceil(Double(remainingTickets) / dailySalesAverage))
    }

    private var salesByTier: [(name: String, sold: Int, capacity: Int, percentage: Double, color: String)] {
        var tierMap: [String: (sold: Int, capacity: Int)] = [:]
        let colors = ["34C759", "FF7A00", "FFD700", "AF52DE", "007AFF", "FF3B30"]

        for event in events {
            for tier in event.ticketTypes {
                let existing = tierMap[tier.name] ?? (0, 0)
                tierMap[tier.name] = (existing.0 + tier.sold, existing.1 + tier.quantity)
            }
        }

        return tierMap.enumerated().map { index, item in
            let percentage = item.value.1 > 0 ? Double(item.value.0) / Double(item.value.1) : 0
            return (item.key, item.value.0, item.value.1, percentage, colors[index % colors.count])
        }.sorted { $0.1 > $1.1 }
    }

    private var salesByEvent: [(event: Event, sold: Int, capacity: Int, percentage: Double)] {
        events.map { event in
            let sold = event.ticketTypes.reduce(0) { $0 + $1.sold }
            let capacity = event.ticketTypes.reduce(0) { $0 + $1.quantity }
            let percentage = capacity > 0 ? Double(sold) / Double(capacity) : 0
            return (event, sold, capacity, percentage)
        }.sorted { $0.1 > $1.1 }
    }

    private var peakSalesDay: (day: String, sales: Int)? {
        guard let maxDay = salesData.max(by: { $0.sales < $1.sales }) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return (formatter.string(from: maxDay.date), maxDay.sales)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Header Stats
                headerSection

                // View Mode Picker
                viewModePicker

                // Content based on selected view
                switch selectedView {
                case .overview:
                    overviewContent
                case .byEvent:
                    byEventContent
                case .byTier:
                    byTierContent
                }
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Ticket Analytics")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Main stats display
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                // Total sold
                VStack(spacing: 4) {
                    Text("\(totalSold)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Tickets Sold")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Capacity ring
                VStack(spacing: 4) {
                    ProgressRingView(
                        progress: capacityPercentage,
                        size: 80,
                        lineWidth: 10,
                        color: capacityColor
                    )

                    Text("of \(totalCapacity)")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(AppSpacing.lg)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.lg)

            // Quick metrics
            HStack(spacing: AppSpacing.sm) {
                QuickMetricPill(
                    icon: "arrow.up.right",
                    value: String(format: "%.1f/hr", ticketVelocity),
                    label: "Velocity",
                    color: .green
                )

                QuickMetricPill(
                    icon: "ticket",
                    value: "\(remainingTickets)",
                    label: "Remaining",
                    color: remainingTickets < 50 ? .orange : .blue
                )

                if let sellOutDays = estimatedSellOutDays {
                    QuickMetricPill(
                        icon: "calendar",
                        value: "\(sellOutDays)d",
                        label: "To Sell Out",
                        color: .purple
                    )
                }
            }
        }
    }

    // MARK: - View Mode Picker

    @ViewBuilder
    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(AppAnimation.standard) {
                        selectedView = mode
                    }
                    HapticFeedback.selection()
                }) {
                    Text(mode.rawValue)
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(selectedView == mode ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(selectedView == mode ? RoleConfig.organizerPrimary : Color.clear)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }

    // MARK: - Overview Content

    @ViewBuilder
    private var overviewContent: some View {
        VStack(spacing: AppSpacing.md) {
            // Sales trend chart
            ChartCard(title: "Sales Trend", subtitle: "Daily ticket sales") {
                if salesData.isEmpty {
                    emptyStatePlaceholder
                } else {
                    LineChartView(
                        dataPoints: salesData.suffix(14).map {
                            LineChartDataPoint(label: formatShortDate($0.date), value: Double($0.sales))
                        },
                        lineColor: RoleConfig.organizerPrimary,
                        height: 180
                    )
                }
            }

            // Velocity & Performance
            velocitySection

            // Peak times
            peakTimesSection

            // Sell-out forecast
            if estimatedSellOutDays != nil {
                sellOutForecastSection
            }
        }
    }

    // MARK: - By Event Content

    @ViewBuilder
    private var byEventContent: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(salesByEvent, id: \.event.id) { item in
                EventTicketCard(
                    event: item.event,
                    sold: item.sold,
                    capacity: item.capacity,
                    percentage: item.percentage
                )
            }

            if salesByEvent.isEmpty {
                emptyStatePlaceholder
            }
        }
    }

    // MARK: - By Tier Content

    @ViewBuilder
    private var byTierContent: some View {
        VStack(spacing: AppSpacing.md) {
            // Donut chart
            ChartCard(title: "Distribution by Tier") {
                if salesByTier.isEmpty {
                    emptyStatePlaceholder
                } else {
                    DonutChartView(
                        segments: salesByTier.map { tier in
                            DonutSegment(
                                label: tier.name,
                                value: Double(tier.sold),
                                percentage: Double(tier.sold) / Double(max(1, totalSold)),
                                color: tier.color
                            )
                        },
                        size: 140,
                        lineWidth: 24,
                        centerText: "\(totalSold)",
                        centerSubtext: "Total Sold"
                    )
                }
            }

            // Tier breakdown list
            ForEach(salesByTier, id: \.name) { tier in
                TierTicketCard(
                    name: tier.name,
                    sold: tier.sold,
                    capacity: tier.capacity,
                    percentage: tier.percentage,
                    color: tier.color
                )
            }
        }
    }

    // MARK: - Velocity Section

    @ViewBuilder
    private var velocitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.green)
                Text("Sales Velocity")
                    .font(AppTypography.cardTitle)
            }

            HStack(spacing: AppSpacing.md) {
                VelocityMetric(
                    title: "Per Hour",
                    value: String(format: "%.1f", ticketVelocity),
                    trend: .up
                )

                VelocityMetric(
                    title: "Per Day",
                    value: String(format: "%.0f", dailySalesAverage),
                    trend: dailySalesAverage > 10 ? .up : .neutral
                )

                VelocityMetric(
                    title: "Per Week",
                    value: String(format: "%.0f", dailySalesAverage * 7),
                    trend: .neutral
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Peak Times Section

    @ViewBuilder
    private var peakTimesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("Peak Sales")
                    .font(AppTypography.cardTitle)
            }

            if let peak = peakSalesDay {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Best Day")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Text(peak.day)
                            .font(AppTypography.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Sales")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Text("\(peak.sales)")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                Text("Not enough data")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Sell-out Forecast Section

    @ViewBuilder
    private var sellOutForecastSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                Text("Sell-out Forecast")
                    .font(AppTypography.cardTitle)
            }

            if let days = estimatedSellOutDays {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated sell-out in")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(days)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                            Text("days")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Progress to sell-out
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Progress")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        ProgressRingView(
                            progress: capacityPercentage,
                            size: 50,
                            lineWidth: 6,
                            color: .purple
                        )
                    }
                }
            }

            Text("* Based on current sales velocity of \(String(format: "%.1f", dailySalesAverage)) tickets/day")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(AppSpacing.md)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStatePlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "ticket")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No ticket data available")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }

    // MARK: - Helpers

    private var capacityColor: Color {
        switch capacityPercentage {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .blue
        }
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Components

struct QuickMetricPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AppTypography.captionEmphasized)
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(color.opacity(0.15))
        .cornerRadius(AppCornerRadius.pill)
    }
}

struct EventTicketCard: View {
    let event: Event
    let sold: Int
    let capacity: Int
    let percentage: Double

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(AppTypography.calloutEmphasized)
                        .lineLimit(1)

                    Text(event.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(sold)/\(capacity)")
                        .font(AppTypography.calloutEmphasized)

                    Text("\(Int(percentage * 100))%")
                        .font(AppTypography.caption)
                        .foregroundColor(percentage > 0.8 ? .green : .secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(percentage > 0.8 ? Color.green : RoleConfig.organizerPrimary)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)

            // Tier breakdown
            HStack(spacing: AppSpacing.sm) {
                ForEach(event.ticketTypes.prefix(3)) { tier in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Text("\(tier.name): \(tier.sold)")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

struct TierTicketCard: View {
    let name: String
    let sold: Int
    let capacity: Int
    let percentage: Double
    let color: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(AppTypography.calloutEmphasized)

                Text("\(sold) of \(capacity) sold")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(percentage * 100))%")
                    .font(AppTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: color))

                if capacity - sold == 0 {
                    Text("SOLD OUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

struct VelocityMetric: View {
    let title: String
    let value: String
    let trend: Trend

    enum Trend {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: 2) {
                Text(value)
                    .font(AppTypography.title2)
                    .fontWeight(.bold)

                Image(systemName: trend.icon)
                    .font(.system(size: 10))
                    .foregroundColor(trend.color)
            }

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        TicketAnalyticsDetailView(
            totalSold: 342,
            totalCapacity: 500,
            events: Event.samples,
            salesData: OrganizerAnalytics.mock.salesOverTime
        )
    }
}

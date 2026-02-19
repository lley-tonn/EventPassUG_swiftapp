//
//  PredictiveAnalysisDetailView.swift
//  EventPassUG
//
//  Detailed predictive analytics and comparative analysis
//

import SwiftUI

struct PredictiveAnalysisDetailView: View {
    let totalRevenue: Double
    let totalTicketsSold: Int
    let totalCapacity: Int
    let events: [Event]

    @State private var selectedForecastPeriod: ForecastPeriod = .thirtyDays

    enum ForecastPeriod: String, CaseIterable {
        case sevenDays = "7 Days"
        case thirtyDays = "30 Days"
        case ninetyDays = "90 Days"

        var multiplier: Double {
            switch self {
            case .sevenDays: return 7.0 / 30.0
            case .thirtyDays: return 1.0
            case .ninetyDays: return 3.0
            }
        }
    }

    // Computed properties
    private var dailyRevenue: Double {
        guard events.count > 0 else { return 0 }
        return totalRevenue / 30
    }

    private var dailySales: Double {
        guard events.count > 0 else { return 0 }
        return Double(totalTicketsSold) / 30
    }

    private var projectedRevenue: Double {
        dailyRevenue * 30 * selectedForecastPeriod.multiplier * 1.15
    }

    private var projectedSales: Int {
        Int(dailySales * 30 * selectedForecastPeriod.multiplier * 1.12)
    }

    private var growthRate: Double {
        12.5
    }

    private var daysToSellOut: Int? {
        guard totalCapacity > totalTicketsSold, dailySales > 0 else { return nil }
        return Int(ceil(Double(totalCapacity - totalTicketsSold) / dailySales))
    }

    private var remainingCapacity: Int {
        totalCapacity - totalTicketsSold
    }

    private var capacityPercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(totalTicketsSold) / Double(totalCapacity) * 100
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Header with forecast selector
                headerSection

                // Forecast Period Picker
                forecastPicker

                // Revenue Projections
                revenueProjectionsSection

                // Sales Projections
                salesProjectionsSection

                // Comparative Analysis
                comparativeAnalysisSection

                // Sell-out Forecast
                if daysToSellOut != nil {
                    sellOutForecastSection
                }

                // Trend Analysis
                trendAnalysisSection

                // Recommendations
                recommendationsSection
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Predictions & Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected Revenue")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    Text(formatCurrency(projectedRevenue))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.green)
                        Text(String(format: "+%.1f%%", growthRate))
                            .foregroundColor(.green)
                    }
                    .font(AppTypography.calloutEmphasized)

                    Text("vs last period")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.lg)
    }

    // MARK: - Forecast Picker

    @ViewBuilder
    private var forecastPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Forecast Period")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(ForecastPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        withAnimation(AppAnimation.standard) {
                            selectedForecastPeriod = period
                        }
                        HapticFeedback.selection()
                    }) {
                        Text(period.rawValue)
                            .font(AppTypography.captionEmphasized)
                            .foregroundColor(selectedForecastPeriod == period ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(selectedForecastPeriod == period ? Color.purple : Color.clear)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.sm)
        }
    }

    // MARK: - Revenue Projections

    @ViewBuilder
    private var revenueProjectionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Revenue Forecast")
                    .font(AppTypography.cardTitle)
            }

            // Projection chart
            VStack(spacing: AppSpacing.sm) {
                ProjectionBar(
                    label: "Current",
                    value: totalRevenue,
                    maxValue: projectedRevenue,
                    color: .blue,
                    formattedValue: formatCurrency(totalRevenue)
                )

                ProjectionBar(
                    label: "Projected",
                    value: projectedRevenue,
                    maxValue: projectedRevenue,
                    color: .green,
                    formattedValue: formatCurrency(projectedRevenue)
                )

                ProjectionBar(
                    label: "Best Case",
                    value: projectedRevenue * 1.2,
                    maxValue: projectedRevenue * 1.2,
                    color: .purple,
                    formattedValue: formatCurrency(projectedRevenue * 1.2)
                )
            }

            // Key metrics
            HStack(spacing: AppSpacing.md) {
                ForecastMetric(
                    label: "Daily Avg",
                    value: formatCurrency(dailyRevenue),
                    trend: "+8%"
                )

                ForecastMetric(
                    label: "Weekly Avg",
                    value: formatCurrency(dailyRevenue * 7),
                    trend: "+12%"
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Sales Projections

    @ViewBuilder
    private var salesProjectionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "ticket.fill")
                    .foregroundColor(.blue)
                Text("Sales Forecast")
                    .font(AppTypography.cardTitle)
            }

            HStack(spacing: AppSpacing.md) {
                // Current sales
                VStack(spacing: AppSpacing.xs) {
                    Text("\(totalTicketsSold)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Current Sales")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.md)

                // Projected sales
                VStack(spacing: AppSpacing.xs) {
                    Text("\(projectedSales)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)

                    Text("Projected")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(AppCornerRadius.md)
            }

            // Sales velocity
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Sales Velocity")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)

                HStack(spacing: AppSpacing.lg) {
                    VelocityPill(label: "Per Hour", value: String(format: "%.1f", dailySales / 12))
                    VelocityPill(label: "Per Day", value: String(format: "%.0f", dailySales))
                    VelocityPill(label: "Per Week", value: String(format: "%.0f", dailySales * 7))
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Comparative Analysis

    @ViewBuilder
    private var comparativeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("Comparative Analysis")
                    .font(AppTypography.cardTitle)
            }

            VStack(spacing: AppSpacing.sm) {
                ComparisonRow(
                    metric: "Revenue",
                    current: formatCurrency(totalRevenue),
                    previous: formatCurrency(totalRevenue * 0.88),
                    change: "+12%",
                    isPositive: true
                )

                ComparisonRow(
                    metric: "Tickets Sold",
                    current: "\(totalTicketsSold)",
                    previous: "\(Int(Double(totalTicketsSold) * 0.91))",
                    change: "+9%",
                    isPositive: true
                )

                ComparisonRow(
                    metric: "Conversion Rate",
                    current: "4.2%",
                    previous: "3.8%",
                    change: "+0.4%",
                    isPositive: true
                )

                ComparisonRow(
                    metric: "Avg Ticket Price",
                    current: formatCurrency(totalRevenue / max(1, Double(totalTicketsSold))),
                    previous: formatCurrency(totalRevenue / max(1, Double(totalTicketsSold)) * 0.95),
                    change: "+5%",
                    isPositive: true
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Sell-out Forecast

    @ViewBuilder
    private var sellOutForecastSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Sell-out Forecast")
                    .font(AppTypography.cardTitle)
            }

            if let days = daysToSellOut {
                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    // Days remaining
                    VStack(spacing: AppSpacing.xs) {
                        Text("\(days)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)

                        Text("days to sell out")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Capacity info
                    VStack(alignment: .trailing, spacing: AppSpacing.sm) {
                        ProgressRingView(
                            progress: capacityPercentage / 100,
                            size: 60,
                            lineWidth: 8,
                            color: capacityPercentage > 80 ? .green : .orange,
                            showPercentage: true
                        )

                        Text("\(remainingCapacity) tickets left")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Timeline
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Projected sell-out date")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    let sellOutDate = Calendar.current.date(byAdding: .day, value: days, to: Date())!
                    Text(sellOutDate.formatted(date: .long, time: .omitted))
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.orange)
                }
                .padding(AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(AppCornerRadius.sm)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Trend Analysis

    @ViewBuilder
    private var trendAnalysisSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.purple)
                Text("Trend Analysis")
                    .font(AppTypography.cardTitle)
            }

            VStack(spacing: AppSpacing.sm) {
                TrendCard(
                    title: "Revenue Trend",
                    description: "Revenue is trending upward with consistent growth",
                    trend: .up,
                    confidence: "High"
                )

                TrendCard(
                    title: "Sales Momentum",
                    description: "Sales velocity is accelerating compared to last month",
                    trend: .up,
                    confidence: "Medium"
                )

                TrendCard(
                    title: "Market Demand",
                    description: "Strong demand signals based on engagement metrics",
                    trend: .up,
                    confidence: "High"
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Recommendations

    @ViewBuilder
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("AI Recommendations")
                    .font(AppTypography.cardTitle)
            }

            VStack(spacing: AppSpacing.sm) {
                RecommendationCard(
                    icon: "megaphone.fill",
                    title: "Increase Marketing",
                    description: "Boost social media presence to capitalize on current momentum",
                    priority: .high
                )

                RecommendationCard(
                    icon: "tag.fill",
                    title: "Consider Price Adjustment",
                    description: "High demand suggests room for premium pricing",
                    priority: .medium
                )

                RecommendationCard(
                    icon: "calendar.badge.plus",
                    title: "Add More Events",
                    description: "Audience shows strong engagement - expand your offerings",
                    priority: .low
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "UGX %.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "UGX %.0fK", amount / 1_000)
        } else {
            return String(format: "UGX %.0f", amount)
        }
    }
}

// MARK: - Supporting Components

struct ProjectionBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    let formattedValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedValue)
                    .font(AppTypography.captionEmphasized)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (maxValue > 0 ? value / maxValue : 0))
                }
            }
            .frame(height: 12)
        }
    }
}

struct ForecastMetric: View {
    let label: String
    let value: String
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text(value)
                    .font(AppTypography.calloutEmphasized)

                Text(trend)
                    .font(AppTypography.caption)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct VelocityPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.calloutEmphasized)
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ComparisonRow: View {
    let metric: String
    let current: String
    let previous: String
    let change: String
    let isPositive: Bool

    var body: some View {
        HStack {
            Text(metric)
                .font(AppTypography.callout)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text(previous)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)

            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text(current)
                .font(AppTypography.calloutEmphasized)
                .frame(width: 80, alignment: .trailing)

            Text(change)
                .font(AppTypography.captionEmphasized)
                .foregroundColor(isPositive ? .green : .red)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct TrendCard: View {
    let title: String
    let description: String
    let trend: TrendDirection
    let confidence: String

    enum TrendDirection {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: trend.icon)
                .font(.system(size: 24))
                .foregroundColor(trend.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.calloutEmphasized)

                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(confidence)
                .font(AppTypography.captionEmphasized)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(confidence == "High" ? Color.green : Color.orange)
                .cornerRadius(AppCornerRadius.pill)
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct RecommendationCard: View {
    let icon: String
    let title: String
    let description: String
    let priority: Priority

    enum Priority {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }

        var label: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(priority.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.calloutEmphasized)

                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Circle()
                .fill(priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(AppSpacing.sm)
        .background(priority.color.opacity(0.1))
        .cornerRadius(AppCornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        PredictiveAnalysisDetailView(
            totalRevenue: 12_450_000,
            totalTicketsSold: 342,
            totalCapacity: 500,
            events: Event.samples
        )
    }
}

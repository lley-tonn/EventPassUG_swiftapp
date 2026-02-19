//
//  RevenueAnalyticsDetailView.swift
//  EventPassUG
//
//  Detailed revenue analytics with breakdowns, trends, and projections
//

import SwiftUI

struct RevenueAnalyticsDetailView: View {
    let totalRevenue: Double
    let events: [Event]
    let dailyData: [SalesDataPoint]

    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedChartType: ChartType = .line
    @State private var showingExportSheet = false

    enum TimeRange: String, CaseIterable {
        case last7Days = "7D"
        case last30Days = "30D"
        case last90Days = "90D"
        case allTime = "All"

        var title: String {
            switch self {
            case .last7Days: return "Last 7 Days"
            case .last30Days: return "Last 30 Days"
            case .last90Days: return "Last 90 Days"
            case .allTime: return "All Time"
            }
        }
    }

    enum ChartType: String, CaseIterable {
        case line = "Line"
        case bar = "Bar"
    }

    // Computed properties
    private var filteredData: [SalesDataPoint] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedTimeRange {
        case .last7Days:
            let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            return dailyData.filter { $0.date >= startDate }
        case .last30Days:
            let startDate = calendar.date(byAdding: .day, value: -30, to: now)!
            return dailyData.filter { $0.date >= startDate }
        case .last90Days:
            let startDate = calendar.date(byAdding: .day, value: -90, to: now)!
            return dailyData.filter { $0.date >= startDate }
        case .allTime:
            return dailyData
        }
    }

    private var periodRevenue: Double {
        filteredData.reduce(0) { $0 + $1.revenue }
    }

    private var periodSales: Int {
        filteredData.reduce(0) { $0 + $1.sales }
    }

    private var averageDailyRevenue: Double {
        guard !filteredData.isEmpty else { return 0 }
        return periodRevenue / Double(filteredData.count)
    }

    private var revenueGrowth: Double {
        guard filteredData.count >= 2 else { return 0 }
        let midpoint = filteredData.count / 2
        let firstHalf = filteredData.prefix(midpoint).reduce(0) { $0 + $1.revenue }
        let secondHalf = filteredData.suffix(midpoint).reduce(0) { $0 + $1.revenue }
        guard firstHalf > 0 else { return 0 }
        return (secondHalf - firstHalf) / firstHalf
    }

    private var revenueByEvent: [(event: Event, revenue: Double, percentage: Double)] {
        let eventRevenue = events.map { event -> (Event, Double) in
            let revenue = event.ticketTypes.reduce(0.0) { $0 + (Double($1.sold) * $1.price) }
            return (event, revenue)
        }.sorted { $0.1 > $1.1 }

        let total = eventRevenue.reduce(0) { $0 + $1.1 }
        return eventRevenue.map { ($0.0, $0.1, total > 0 ? $0.1 / total : 0) }
    }

    private var revenueByTier: [(name: String, revenue: Double, color: String)] {
        var tierMap: [String: Double] = [:]
        let colors = ["34C759", "FF7A00", "FFD700", "AF52DE", "007AFF"]

        for event in events {
            for tier in event.ticketTypes {
                let revenue = Double(tier.sold) * tier.price
                tierMap[tier.name, default: 0] += revenue
            }
        }

        return tierMap.enumerated().map { index, item in
            (item.key, item.value, colors[index % colors.count])
        }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Header Stats
                headerStatsSection

                // Time Range Picker
                timeRangePicker

                // Revenue Chart
                revenueChartSection

                // Revenue Breakdown
                revenueBreakdownSection

                // Revenue by Event
                revenueByEventSection

                // Revenue by Tier
                revenueByTierSection

                // Projections
                projectionsSection
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Revenue Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingExportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportOptionsSheet(dataType: "Revenue")
        }
    }

    // MARK: - Header Stats

    @ViewBuilder
    private var headerStatsSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Main revenue display
            VStack(spacing: AppSpacing.xs) {
                Text("Total Revenue")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Text(formatCurrency(totalRevenue))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                // Growth indicator
                HStack(spacing: 4) {
                    Image(systemName: revenueGrowth >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%+.1f%%", revenueGrowth * 100))
                }
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(revenueGrowth >= 0 ? .green : .red)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background((revenueGrowth >= 0 ? Color.green : Color.red).opacity(0.15))
                .cornerRadius(AppCornerRadius.pill)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.lg)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.lg)

            // Quick stats row
            HStack(spacing: AppSpacing.sm) {
                QuickStatCard(
                    title: "Period Revenue",
                    value: formatCurrency(periodRevenue),
                    icon: "calendar",
                    color: .blue
                )

                QuickStatCard(
                    title: "Daily Average",
                    value: formatCurrency(averageDailyRevenue),
                    icon: "chart.bar",
                    color: .green
                )

                QuickStatCard(
                    title: "Tickets Sold",
                    value: "\(periodSales)",
                    icon: "ticket",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Time Range Picker

    @ViewBuilder
    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(AppAnimation.standard) {
                        selectedTimeRange = range
                    }
                    HapticFeedback.selection()
                }) {
                    Text(range.rawValue)
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(selectedTimeRange == range ? RoleConfig.organizerPrimary : Color.clear)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }

    // MARK: - Revenue Chart

    @ViewBuilder
    private var revenueChartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Revenue Over Time")
                    .font(AppTypography.cardTitle)

                Spacer()

                // Chart type picker
                Picker("Chart Type", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            if filteredData.isEmpty {
                emptyChartPlaceholder
            } else {
                Group {
                    if selectedChartType == .line {
                        LineChartView(
                            dataPoints: filteredData.map {
                                LineChartDataPoint(label: formatShortDate($0.date), value: $0.revenue)
                            },
                            lineColor: RoleConfig.organizerPrimary,
                            height: 200,
                            showYLabels: true
                        )
                    } else {
                        BarChartView(
                            bars: filteredData.suffix(14).map {
                                BarChartData(label: formatShortDate($0.date), value: $0.revenue)
                            },
                            barColor: RoleConfig.organizerPrimary,
                            height: 200
                        )
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Revenue Breakdown

    @ViewBuilder
    private var revenueBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Revenue Breakdown")
                .font(AppTypography.cardTitle)

            // Gross vs Net
            VStack(spacing: AppSpacing.sm) {
                RevenueBreakdownRow(
                    label: "Gross Revenue",
                    amount: totalRevenue,
                    percentage: 1.0,
                    color: .blue
                )

                RevenueBreakdownRow(
                    label: "Platform Fees (5%)",
                    amount: -totalRevenue * 0.05,
                    percentage: 0.05,
                    color: .orange,
                    isDeduction: true
                )

                RevenueBreakdownRow(
                    label: "Processing Fees (3%)",
                    amount: -totalRevenue * 0.03,
                    percentage: 0.03,
                    color: .red,
                    isDeduction: true
                )

                Divider()

                HStack {
                    Text("Net Revenue")
                        .font(AppTypography.calloutEmphasized)
                    Spacer()
                    Text(formatCurrency(totalRevenue * 0.92))
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Revenue by Event

    @ViewBuilder
    private var revenueByEventSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Revenue by Event")
                .font(AppTypography.cardTitle)

            if revenueByEvent.isEmpty {
                Text("No events with revenue")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(revenueByEvent.prefix(5), id: \.event.id) { item in
                    EventRevenueRow(
                        eventTitle: item.event.title,
                        revenue: item.revenue,
                        percentage: item.percentage,
                        ticketsSold: item.event.ticketTypes.reduce(0) { $0 + $1.sold }
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Revenue by Tier

    @ViewBuilder
    private var revenueByTierSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Revenue by Ticket Type")
                .font(AppTypography.cardTitle)

            if revenueByTier.isEmpty {
                Text("No tier data available")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            } else {
                DonutChartView(
                    segments: revenueByTier.map { tier in
                        DonutSegment(
                            label: tier.name,
                            value: tier.revenue,
                            percentage: tier.revenue / totalRevenue,
                            color: tier.color
                        )
                    },
                    size: 140,
                    lineWidth: 24,
                    centerText: formatCurrency(totalRevenue),
                    centerSubtext: "Total"
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Projections

    @ViewBuilder
    private var projectionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                Text("Projections")
                    .font(AppTypography.cardTitle)
            }

            let projectedMonthly = averageDailyRevenue * 30
            let projectedYearly = averageDailyRevenue * 365

            HStack(spacing: AppSpacing.md) {
                ProjectionCard(
                    title: "Monthly Projection",
                    value: formatCurrency(projectedMonthly),
                    subtitle: "Based on daily average",
                    color: .purple
                )

                ProjectionCard(
                    title: "Yearly Projection",
                    value: formatCurrency(projectedYearly),
                    subtitle: "If trend continues",
                    color: .blue
                )
            }

            Text("* Projections are estimates based on current performance trends")
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
    private var emptyChartPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No data for this period")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
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

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Components

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct RevenueBreakdownRow: View {
    let label: String
    let amount: Double
    let percentage: Double
    let color: Color
    var isDeduction: Bool = false

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(AppTypography.callout)
                .foregroundColor(isDeduction ? .secondary : .primary)

            Spacer()

            Text(formatCurrency(amount))
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(isDeduction ? .red : .primary)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let absAmount = abs(amount)
        let prefix = amount < 0 ? "-" : ""
        if absAmount >= 1_000_000 {
            return String(format: "%@UGX %.1fM", prefix, absAmount / 1_000_000)
        } else if absAmount >= 1_000 {
            return String(format: "%@UGX %.0fK", prefix, absAmount / 1_000)
        } else {
            return String(format: "%@UGX %.0f", prefix, absAmount)
        }
    }
}

struct EventRevenueRow: View {
    let eventTitle: String
    let revenue: Double
    let percentage: Double
    let ticketsSold: Int

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text(eventTitle)
                    .font(AppTypography.callout)
                    .lineLimit(1)

                Spacer()

                Text(formatCurrency(revenue))
                    .font(AppTypography.calloutEmphasized)
            }

            HStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(RoleConfig.organizerPrimary)
                            .frame(width: geometry.size.width * percentage)
                    }
                }
                .frame(height: 6)

                Text("\(Int(percentage * 100))%")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }

            HStack {
                Text("\(ticketsSold) tickets sold")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }

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

struct ProjectionCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(AppTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }
}

struct ExportOptionsSheet: View {
    let dataType: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Export Format") {
                    Button(action: { dismiss() }) {
                        Label("Export as PDF", systemImage: "doc.fill")
                    }
                    Button(action: { dismiss() }) {
                        Label("Export as CSV", systemImage: "tablecells")
                    }
                    Button(action: { dismiss() }) {
                        Label("Share Summary", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Export \(dataType)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RevenueAnalyticsDetailView(
            totalRevenue: 12_450_000,
            events: Event.samples,
            dailyData: OrganizerAnalytics.mock.salesOverTime
        )
    }
}

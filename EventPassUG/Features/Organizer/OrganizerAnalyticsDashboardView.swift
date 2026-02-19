//
//  OrganizerAnalyticsDashboardView.swift
//  EventPassUG
//
//  Responsive analytics dashboard for event organizers
//  Adapts layout based on device size: compact on small phones, rich on large devices
//

import SwiftUI

// MARK: - Main Dashboard View

struct OrganizerAnalyticsDashboardView: View {
    let analytics: OrganizerAnalytics

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var selectedSection: DashboardSection = .overview
    @State private var scrollOffset: CGFloat = 0
    @State private var dismissedAlerts: Set<UUID> = []

    // MARK: - Layout Configuration

    private var layoutConfig: LayoutConfig {
        LayoutConfig(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if layoutConfig.useSidebar {
                    // iPad / Large landscape - Sidebar layout
                    sidebarLayout(geometry: geometry)
                } else {
                    // iPhone / Compact - Scrolling layout
                    compactLayout(geometry: geometry)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(analytics.eventTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Refresh", systemImage: "arrow.clockwise") {}
                    Button("Export Report", systemImage: "square.and.arrow.up") {}
                    Button("Settings", systemImage: "gearshape") {}
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Compact Layout (Small/Medium Phones)

    @ViewBuilder
    private func compactLayout(geometry: GeometryProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: layoutConfig.sectionSpacing) {
                // Quick stats header
                quickStatsSection

                // Section picker for small screens
                if layoutConfig.isSmallDevice {
                    sectionPicker
                        .padding(.horizontal, layoutConfig.horizontalPadding)
                }

                // Alerts (dismissible)
                alertsSection
                    .padding(.horizontal, layoutConfig.horizontalPadding)

                // Main content sections
                if layoutConfig.isSmallDevice {
                    // Show only selected section on small devices
                    sectionContent(for: selectedSection)
                        .padding(.horizontal, layoutConfig.horizontalPadding)
                } else {
                    // Show all sections on medium+ devices
                    allSectionsContent
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
        .coordinateSpace(name: "scroll")
    }

    // MARK: - Sidebar Layout (iPad/Large Devices)

    @ViewBuilder
    private func sidebarLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Sidebar navigation
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Health score
                HealthScoreBadge(score: analytics.healthScore)
                    .padding(.bottom, AppSpacing.md)

                // Section navigation
                ForEach(DashboardSection.allCases, id: \.self) { section in
                    sidebarButton(for: section)
                }

                Spacer()

                // Quick actions
                VStack(spacing: AppSpacing.sm) {
                    sidebarActionButton(title: "Export", icon: "square.and.arrow.up")
                    sidebarActionButton(title: "Settings", icon: "gearshape")
                }
            }
            .padding(AppSpacing.md)
            .frame(width: min(220, geometry.size.width * 0.25))
            .background(Color(UIColor.secondarySystemBackground))

            // Main content
            ScrollView {
                LazyVStack(spacing: layoutConfig.sectionSpacing) {
                    // Quick stats in grid
                    quickStatsGrid(columns: 4)

                    // Alerts
                    alertsSection

                    // Selected section content
                    sectionContent(for: selectedSection)
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    // MARK: - Quick Stats

    @ViewBuilder
    private var quickStatsSection: some View {
        let columns = layoutConfig.metricsPerRow
        quickStatsGrid(columns: columns)
            .padding(.horizontal, layoutConfig.horizontalPadding)
    }

    @ViewBuilder
    private func quickStatsGrid(columns: Int) -> some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: columns)

        LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
            MetricCard(
                title: "Revenue",
                value: analytics.formattedRevenue,
                icon: "banknote",
                subtitle: "\(Int(analytics.salesProgress * 100))% of target",
                trend: TrendData(value: 0.12, isPositive: true),
                color: .green,
                size: layoutConfig.metricCardSize
            )

            MetricCard(
                title: "Tickets Sold",
                value: "\(analytics.ticketsSold)",
                icon: "ticket",
                subtitle: "\(analytics.remainingCapacity) remaining",
                color: AppColors.primary,
                size: layoutConfig.metricCardSize
            )

            if columns >= 3 {
                MetricCard(
                    title: "Capacity",
                    value: "\(analytics.capacityPercentage)%",
                    icon: "person.3",
                    color: analytics.capacityUsed > 0.8 ? .green : .blue,
                    size: layoutConfig.metricCardSize
                )
            }

            if columns >= 4 {
                MetricCard(
                    title: "Conversion",
                    value: String(format: "%.1f%%", analytics.conversionPercentage),
                    icon: "arrow.triangle.2.circlepath",
                    color: .purple,
                    size: layoutConfig.metricCardSize
                )
            }
        }
    }

    // MARK: - Section Picker (Small Screens)

    @ViewBuilder
    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(DashboardSection.allCases, id: \.self) { section in
                    Button(action: {
                        withAnimation(AppAnimation.standard) {
                            selectedSection = section
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: section.icon)
                                .font(.system(size: 12))
                            Text(section.title)
                                .font(AppTypography.captionEmphasized)
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(selectedSection == section ? AppColors.primary : Color.gray.opacity(0.15))
                        .foregroundColor(selectedSection == section ? .white : .primary)
                        .cornerRadius(AppCornerRadius.pill)
                    }
                }
            }
        }
    }

    // MARK: - Alerts Section

    @ViewBuilder
    private var alertsSection: some View {
        let visibleAlerts = analytics.alerts.filter { !dismissedAlerts.contains($0.id) }

        if !visibleAlerts.isEmpty {
            VStack(spacing: AppSpacing.sm) {
                ForEach(visibleAlerts.prefix(layoutConfig.isSmallDevice ? 2 : 3)) { alert in
                    InsightAlertCard(
                        alert: alert,
                        onAction: {
                            // Handle action
                        },
                        onDismiss: {
                            withAnimation {
                                dismissedAlerts.insert(alert.id)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - All Sections Content (Medium+ Screens)

    @ViewBuilder
    private var allSectionsContent: some View {
        // Sales Performance
        SectionContainer(title: "Sales Performance", icon: "chart.line.uptrend.xyaxis", iconColor: .blue) {
            salesPerformanceContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)

        // Audience Insights
        SectionContainer(title: "Audience Insights", icon: "person.2", iconColor: .purple) {
            audienceInsightsContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)

        // Marketing & Conversion
        SectionContainer(title: "Marketing", icon: "megaphone", iconColor: .orange) {
            marketingContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)

        // Financial
        SectionContainer(title: "Financial", icon: "dollarsign.circle", iconColor: .green) {
            financialContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)

        // Operations
        SectionContainer(title: "Operations", icon: "gearshape.2", iconColor: .gray) {
            operationsContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)
    }

    // MARK: - Section Content Router

    @ViewBuilder
    private func sectionContent(for section: DashboardSection) -> some View {
        switch section {
        case .overview:
            overviewContent
        case .sales:
            SectionContainer(title: "Sales Performance", icon: "chart.line.uptrend.xyaxis", iconColor: .blue, isCollapsible: false) {
                salesPerformanceContent
            }
        case .audience:
            SectionContainer(title: "Audience Insights", icon: "person.2", iconColor: .purple, isCollapsible: false) {
                audienceInsightsContent
            }
        case .marketing:
            SectionContainer(title: "Marketing", icon: "megaphone", iconColor: .orange, isCollapsible: false) {
                marketingContent
            }
        case .financial:
            SectionContainer(title: "Financial", icon: "dollarsign.circle", iconColor: .green, isCollapsible: false) {
                financialContent
            }
        case .operations:
            SectionContainer(title: "Operations", icon: "gearshape.2", iconColor: .gray, isCollapsible: false) {
                operationsContent
            }
        }
    }

    // MARK: - Overview Content

    @ViewBuilder
    private var overviewContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            // Health score
            HealthScoreBadge(score: analytics.healthScore)

            // Forecast
            if let forecast = analytics.sellOutForecast, forecast.willSellOut {
                forecastCard(forecast: forecast)
            }

            // Top metrics
            StatsRow(stats: [
                StatItem(label: "Daily Avg", value: String(format: "%.0f", analytics.dailySalesAverage)),
                StatItem(label: "Velocity", value: String(format: "%.1f/hr", analytics.ticketVelocity)),
                StatItem(label: "Views", value: formatNumber(analytics.eventViews))
            ])
        }
    }

    // MARK: - Sales Performance Content

    @ViewBuilder
    private var salesPerformanceContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            // Sales over time chart
            ChartCard(title: "Sales Over Time", subtitle: "Last 14 days") {
                let dataPoints = analytics.salesOverTime.map { point in
                    LineChartDataPoint(
                        label: formatShortDate(point.date),
                        value: Double(point.sales)
                    )
                }
                LineChartView(
                    dataPoints: dataPoints,
                    height: layoutConfig.chartHeight
                )
            }

            // Sales by tier
            ChartCard(title: "Ticket Sales by Tier") {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(analytics.salesByTier) { tier in
                        TierSalesRow(tier: tier)
                    }
                }
            }

            // Sell-out forecast
            if let forecast = analytics.sellOutForecast {
                forecastCard(forecast: forecast)
            }
        }
    }

    // MARK: - Audience Insights Content

    @ViewBuilder
    private var audienceInsightsContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            // Audience stats
            let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: layoutConfig.isSmallDevice ? 2 : 3)

            LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
                MetricCard(
                    title: "Attendees",
                    value: "\(analytics.totalAttendees)",
                    icon: "person.fill",
                    color: .blue,
                    size: .compact
                )

                MetricCard(
                    title: "Repeat",
                    value: "\(Int(analytics.repeatRate * 100))%",
                    icon: "arrow.counterclockwise",
                    color: .purple,
                    size: .compact
                )

                MetricCard(
                    title: "VIP Share",
                    value: "\(Int(analytics.vipShare * 100))%",
                    icon: "star.fill",
                    color: Color(hex: "FFD700"),
                    size: .compact
                )
            }

            // New vs Returning
            ChartCard(title: "New vs Returning") {
                DonutChartView(
                    segments: [
                        DonutSegment(
                            label: "New",
                            value: Double(analytics.newVsReturning.newAttendees),
                            percentage: analytics.newVsReturning.newPercentage,
                            color: "007AFF"
                        ),
                        DonutSegment(
                            label: "Returning",
                            value: Double(analytics.newVsReturning.returningAttendees),
                            percentage: analytics.newVsReturning.returningPercentage,
                            color: "34C759"
                        )
                    ],
                    size: layoutConfig.isSmallDevice ? 100 : 120,
                    lineWidth: layoutConfig.isSmallDevice ? 16 : 20,
                    centerText: "\(analytics.totalAttendees)",
                    centerSubtext: "Total"
                )
            }

            // Demographics (if available)
            if let demographics = analytics.demographics {
                ChartCard(title: "Top Cities") {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(demographics.topCities.prefix(4)) { city in
                            HStack {
                                Text(city.city)
                                    .font(AppTypography.callout)
                                Spacer()
                                Text("\(city.count)")
                                    .font(AppTypography.calloutEmphasized)
                                    .foregroundColor(.secondary)
                                Text("\(Int(city.percentage * 100))%")
                                    .font(AppTypography.captionEmphasized)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Marketing Content

    @ViewBuilder
    private var marketingContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            // Key metrics
            let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2)

            LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
                MetricCard(
                    title: "Event Views",
                    value: formatNumber(analytics.eventViews),
                    icon: "eye",
                    color: .blue,
                    size: .compact
                )

                MetricCard(
                    title: "Conversion",
                    value: String(format: "%.1f%%", analytics.conversionPercentage),
                    icon: "arrow.triangle.2.circlepath",
                    color: .green,
                    size: .compact
                )

                MetricCard(
                    title: "Shares",
                    value: "\(analytics.shareCount)",
                    icon: "arrowshape.turn.up.right",
                    color: .purple,
                    size: .compact
                )

                MetricCard(
                    title: "Saves",
                    value: "\(analytics.saveCount)",
                    icon: "heart",
                    color: .pink,
                    size: .compact
                )
            }

            // Traffic sources
            ChartCard(title: "Traffic Sources") {
                VStack(spacing: 0) {
                    ForEach(analytics.trafficSources) { source in
                        TrafficSourceRow(source: source)
                        if source.id != analytics.trafficSources.last?.id {
                            Divider()
                        }
                    }
                }
            }

            // Promo performance
            if !analytics.promoPerformance.isEmpty {
                ChartCard(title: "Promo Codes") {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(analytics.promoPerformance) { promo in
                            HStack {
                                Text(promo.promoCode)
                                    .font(AppTypography.calloutEmphasized)
                                    .foregroundColor(.primary)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(promo.usageCount) uses")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatCurrency(promo.revenue))
                                        .font(AppTypography.captionEmphasized)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Financial Content

    @ViewBuilder
    private var financialContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            // Revenue breakdown
            StatsRow(stats: [
                StatItem(label: "Gross", value: formatCurrency(analytics.grossRevenue)),
                StatItem(label: "Net", value: formatCurrency(analytics.netRevenue)),
                StatItem(label: "Fees", value: formatCurrency(analytics.totalFees))
            ])

            // Payment methods chart
            ChartCard(title: "Payment Methods") {
                DonutChartView(
                    segments: analytics.paymentMethodsSplit.map { method in
                        DonutSegment(
                            label: method.method,
                            value: method.amount,
                            percentage: method.percentage,
                            color: method.color
                        )
                    },
                    size: layoutConfig.isSmallDevice ? 100 : 120,
                    lineWidth: layoutConfig.isSmallDevice ? 16 : 20,
                    centerText: formatCurrency(analytics.revenue),
                    centerSubtext: "Total"
                )
            }

            // Refunds
            if analytics.refundsCount > 0 {
                HStack {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundColor(.red)
                    Text("Refunds")
                        .font(AppTypography.callout)
                    Spacer()
                    Text("\(analytics.refundsCount)")
                        .font(AppTypography.calloutEmphasized)
                    Text(formatCurrency(analytics.refundsTotal))
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
                .padding(AppSpacing.md)
                .background(Color.red.opacity(0.1))
                .cornerRadius(AppCornerRadius.md)
            }

            // Revenue forecast
            if let forecast = analytics.revenueForecast {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Revenue Forecast")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(forecast))
                            .font(AppTypography.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(Color.green.opacity(0.1))
                .cornerRadius(AppCornerRadius.md)
            }
        }
    }

    // MARK: - Operations Content

    @ViewBuilder
    private var operationsContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            // Check-in stats
            let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2)

            LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
                TimeBadge(
                    time: analytics.peakArrivalTime ?? "N/A",
                    label: "Peak Arrival",
                    icon: "clock.arrow.circlepath"
                )

                TimeBadge(
                    time: "\(analytics.queueEstimate) min",
                    label: "Est. Queue",
                    icon: "person.3.sequence"
                )
            }

            // Check-in rate
            MetricCard(
                title: "Check-in Rate",
                value: "\(Int(analytics.checkinRate * 100))%",
                icon: "checkmark.circle",
                subtitle: "\(analytics.totalAttendees) of \(analytics.ticketsSold) checked in",
                color: .green
            )

            // Check-ins by hour
            if !analytics.checkinsByHour.isEmpty {
                ChartCard(title: "Check-ins by Hour") {
                    BarChartView(
                        bars: analytics.checkinsByHour.map { point in
                            BarChartData(
                                label: point.formattedHour,
                                value: Double(point.checkins),
                                color: point.hour >= 17 && point.hour <= 20 ? AppColors.primary : Color.gray.opacity(0.5)
                            )
                        },
                        height: layoutConfig.chartHeight
                    )
                }
            }
        }
    }

    // MARK: - Sidebar Components

    @ViewBuilder
    private func sidebarButton(for section: DashboardSection) -> some View {
        Button(action: {
            withAnimation(AppAnimation.standard) {
                selectedSection = section
            }
            HapticFeedback.selection()
        }) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: section.icon)
                    .font(.system(size: 16))
                    .frame(width: 24)

                Text(section.title)
                    .font(AppTypography.callout)

                Spacer()

                if selectedSection == section {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.sm)
            .background(selectedSection == section ? AppColors.primary.opacity(0.15) : Color.clear)
            .foregroundColor(selectedSection == section ? AppColors.primary : .primary)
            .cornerRadius(AppCornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sidebarActionButton(title: String, icon: String) -> some View {
        Button(action: {}) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(AppTypography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.secondary)
            .cornerRadius(AppCornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func forecastCard(forecast: SellOutForecast) -> some View {
        HStack(spacing: AppSpacing.md) {
            ProgressRingView(
                progress: forecast.confidence,
                size: 50,
                lineWidth: 6,
                color: forecast.confidence > 0.7 ? .green : .orange
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Sell-out Forecast")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                if let days = forecast.daysRemaining {
                    Text("\(days) days")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                }

                Text("\(forecast.confidenceLevel) confidence")
                    .font(AppTypography.caption)
                    .foregroundColor(forecast.confidence > 0.7 ? .green : .orange)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.green.opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Helper Functions

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "UGX %.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "UGX %.0fK", amount / 1_000)
        } else {
            return String(format: "UGX %.0f", amount)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
}

// MARK: - Dashboard Sections

enum DashboardSection: String, CaseIterable {
    case overview
    case sales
    case audience
    case marketing
    case financial
    case operations

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .sales: return "Sales"
        case .audience: return "Audience"
        case .marketing: return "Marketing"
        case .financial: return "Financial"
        case .operations: return "Operations"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "chart.pie"
        case .sales: return "chart.line.uptrend.xyaxis"
        case .audience: return "person.2"
        case .marketing: return "megaphone"
        case .financial: return "dollarsign.circle"
        case .operations: return "gearshape.2"
        }
    }
}

// MARK: - Layout Configuration

struct LayoutConfig {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?

    var isSmallDevice: Bool {
        ScreenSize.isSmallDevice
    }

    var isRegularDevice: Bool {
        ScreenSize.isRegularDevice
    }

    var isLargeDevice: Bool {
        ScreenSize.isLargeDevice || ScreenSize.isPad
    }

    var useSidebar: Bool {
        horizontalSizeClass == .regular && !ScreenSize.isSmallDevice
    }

    var horizontalPadding: CGFloat {
        switch ScreenSize.DeviceSize.current {
        case .small: return AppSpacing.sm
        case .regular: return AppSpacing.md
        case .large, .iPad: return AppSpacing.lg
        }
    }

    var sectionSpacing: CGFloat {
        switch ScreenSize.DeviceSize.current {
        case .small: return AppSpacing.md
        case .regular: return AppSpacing.lg
        case .large, .iPad: return AppSpacing.xl
        }
    }

    var itemSpacing: CGFloat {
        switch ScreenSize.DeviceSize.current {
        case .small: return AppSpacing.sm
        case .regular: return AppSpacing.md
        case .large, .iPad: return AppSpacing.md
        }
    }

    var metricsPerRow: Int {
        switch ScreenSize.DeviceSize.current {
        case .small: return 2
        case .regular: return 2
        case .large: return 3
        case .iPad: return 4
        }
    }

    var chartHeight: CGFloat {
        switch ScreenSize.DeviceSize.current {
        case .small: return 120
        case .regular: return 150
        case .large, .iPad: return 180
        }
    }

    var metricCardSize: MetricCard.MetricCardSize {
        switch ScreenSize.DeviceSize.current {
        case .small: return .compact
        case .regular: return .regular
        case .large, .iPad: return .regular
        }
    }
}

// MARK: - Previews

#Preview("iPhone SE (Small)") {
    NavigationStack {
        OrganizerAnalyticsDashboardView(analytics: .mock)
    }
    .previewDevice("iPhone SE (3rd generation)")
}

#Preview("iPhone 15 (Regular)") {
    NavigationStack {
        OrganizerAnalyticsDashboardView(analytics: .mock)
    }
    .previewDevice("iPhone 15")
}

#Preview("iPhone 15 Pro Max (Large)") {
    NavigationStack {
        OrganizerAnalyticsDashboardView(analytics: .mock)
    }
    .previewDevice("iPhone 15 Pro Max")
}

#Preview("iPad Pro") {
    NavigationStack {
        OrganizerAnalyticsDashboardView(analytics: .mock)
    }
    .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}

#Preview("Dark Mode") {
    NavigationStack {
        OrganizerAnalyticsDashboardView(analytics: .mock)
    }
    .preferredColorScheme(.dark)
}

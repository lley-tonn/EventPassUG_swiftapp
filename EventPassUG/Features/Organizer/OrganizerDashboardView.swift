//
//  OrganizerDashboardView.swift
//  EventPassUG
//
//  Modern responsive analytics dashboard for organizers
//  Adapts layout based on device size: compact on small phones, rich on large devices
//

import SwiftUI
import Combine

struct OrganizerDashboardView: View {
    @EnvironmentObject var authService: MockAuthRepository
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var followManager = FollowManager.shared

    // MARK: - State

    @State private var totalRevenue: Double = 0
    @State private var totalTicketsSold: Int = 0
    @State private var activeEvents: Int = 0
    @State private var totalCapacity: Int = 0
    @State private var isLoading = true
    @State private var events: [Event] = []
    @State private var showingVerificationSheet = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedSection: DashboardSection = .overview
    @State private var dismissedAlerts: Set<UUID> = []

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Layout Configuration

    private var layoutConfig: DashboardLayoutConfig {
        DashboardLayoutConfig(horizontalSizeClass: horizontalSizeClass)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                mainContent
                    .blur(radius: authService.currentUser?.needsVerificationForOrganizerActions == true ? 10 : 0)

                // Verification overlay
                if authService.currentUser?.needsVerificationForOrganizerActions == true {
                    VerificationRequiredOverlay(showingVerificationSheet: $showingVerificationSheet)
                }

                // Loading overlay
                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { Task { await refreshData() } }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button(action: {}) {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            loadAnalytics()
            subscribeToTicketSales()
        }
        .sheet(isPresented: $showingVerificationSheet) {
            NationalIDVerificationView()
                .environmentObject(authService)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ScrollView {
                LazyVStack(spacing: layoutConfig.sectionSpacing) {
                    // Health Score & Quick Stats
                    headerSection(isLandscape: isLandscape)

                    // Section picker for small screens
                    if layoutConfig.isSmallDevice {
                        sectionPicker
                            .padding(.horizontal, layoutConfig.horizontalPadding)
                    }

                    // Alerts
                    alertsSection
                        .padding(.horizontal, layoutConfig.horizontalPadding)

                    // Content based on device size
                    if layoutConfig.isSmallDevice {
                        // Show selected section only on small devices
                        sectionContent(for: selectedSection, isLandscape: isLandscape)
                            .padding(.horizontal, layoutConfig.horizontalPadding)
                    } else {
                        // Show all sections on larger devices
                        allSectionsContent(isLandscape: isLandscape)
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .refreshable {
                await refreshData()
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(isLandscape: Bool) -> some View {
        VStack(spacing: layoutConfig.sectionSpacing) {
            // Health Score Row
            HStack(spacing: AppSpacing.md) {
                healthScoreView

                Spacer()

                // Quick summary
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(totalRevenue))
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Total Revenue")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
            .cardShadow()

            // Overview Stats Grid (4 cards)
            quickStatsGrid(isLandscape: isLandscape)

            // Marketing & Engagement Insights
            marketingEngagementSection(isLandscape: isLandscape)

            // Event Operations Metrics
            operationsMetricsSection(isLandscape: isLandscape)

            // Comparative & Predictive Analysis
            predictiveAnalysisSection(isLandscape: isLandscape)
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)
    }

    @ViewBuilder
    private var healthScoreView: some View {
        let score = calculateHealthScore()

        HStack(spacing: AppSpacing.sm) {
            ProgressRingView(
                progress: Double(score) / 100.0,
                size: 50,
                lineWidth: 6,
                color: healthScoreColor(score)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Health Score")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Text(healthScoreLabel(score))
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(healthScoreColor(score))
            }
        }
    }

    @ViewBuilder
    private func quickStatsGrid(isLandscape: Bool) -> some View {
        // Always show 2 columns on portrait, 4 on landscape/iPad
        let columns = isLandscape || horizontalSizeClass == .regular ? 4 : 2
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: columns)

        LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
            // 1. Revenue Card - Tappable
            NavigationLink(destination: RevenueAnalyticsDetailView(
                totalRevenue: totalRevenue,
                events: events,
                dailyData: generateSalesDataPoints()
            )) {
                MetricCard(
                    title: "Revenue",
                    value: formatCurrency(totalRevenue),
                    icon: "banknote",
                    trend: TrendData(value: 0.12, isPositive: true),
                    color: .green,
                    size: layoutConfig.metricCardSize
                )
            }
            .buttonStyle(.plain)

            // 2. Tickets Sold Card - Tappable
            NavigationLink(destination: TicketAnalyticsDetailView(
                totalSold: totalTicketsSold,
                totalCapacity: totalCapacity,
                events: events,
                salesData: generateSalesDataPoints()
            )) {
                MetricCard(
                    title: "Tickets Sold",
                    value: "\(totalTicketsSold)",
                    icon: "ticket",
                    subtitle: capacityText,
                    color: RoleConfig.organizerPrimary,
                    size: layoutConfig.metricCardSize
                )
            }
            .buttonStyle(.plain)

            // 3. Active Events Card - Tappable
            NavigationLink(destination: OrganizerHomeView()) {
                MetricCard(
                    title: "Active Events",
                    value: "\(activeEvents)",
                    icon: "calendar",
                    subtitle: events.count > activeEvents ? "\(events.count) total" : nil,
                    color: .blue,
                    size: layoutConfig.metricCardSize
                )
            }
            .buttonStyle(.plain)

            // 4. Attendee Insights Card - Tappable
            NavigationLink(destination: AudienceAnalyticsDetailView(
                totalAttendees: totalTicketsSold,
                repeatAttendees: Int(Double(totalTicketsSold) * 0.26),
                followers: 0, // Followers shown in profile only
                events: events
            )) {
                MetricCard(
                    title: "Attendees",
                    value: "\(totalTicketsSold)",
                    icon: "person.2.fill",
                    subtitle: "View insights",
                    color: .purple,
                    size: layoutConfig.metricCardSize
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Marketing & Engagement Section

    @ViewBuilder
    private func marketingEngagementSection(isLandscape: Bool) -> some View {
        let totalLikes = events.reduce(0) { $0 + $1.likeCount }
        let totalViews = totalLikes * 5
        let shareCount = Int(Double(totalTicketsSold) * 0.15)
        let conversionRate = totalViews > 0 ? Double(totalTicketsSold) / Double(totalViews) * 100 : 0

        NavigationLink(destination: MarketingInsightsDetailView(
            totalViews: totalViews,
            totalLikes: totalLikes,
            totalShares: shareCount,
            totalTicketsSold: totalTicketsSold,
            events: events
        )) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Section Header
                HStack {
                    Image(systemName: "megaphone.fill")
                        .foregroundColor(.orange)
                    Text("Marketing & Engagement")
                        .font(AppTypography.cardTitle)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                let columns = isLandscape || horizontalSizeClass == .regular ? 4 : 2
                let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: columns)

                LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
                    MetricCard(
                        title: "Impressions",
                        value: formatNumber(totalViews),
                        icon: "eye.fill",
                        color: .blue,
                        size: .compact
                    )

                    MetricCard(
                        title: "Likes",
                        value: "\(totalLikes)",
                        icon: "heart.fill",
                        color: .pink,
                        size: .compact
                    )

                    MetricCard(
                        title: "Shares",
                        value: "\(shareCount)",
                        icon: "square.and.arrow.up.fill",
                        color: .green,
                        size: .compact
                    )

                    MetricCard(
                        title: "Conversion",
                        value: String(format: "%.1f%%", conversionRate),
                        icon: "arrow.right.circle.fill",
                        color: .purple,
                        size: .compact
                    )
                }

                // Engagement insights row
                HStack(spacing: AppSpacing.md) {
                    engagementInsightPill(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Engagement Rate",
                        value: String(format: "%.1f%%", Double(totalLikes + shareCount) / max(1, Double(totalViews)) * 100),
                        color: .blue
                    )

                    engagementInsightPill(
                        icon: "person.badge.plus",
                        label: "Avg. per Event",
                        value: events.count > 0 ? "\(totalTicketsSold / max(1, events.count))" : "0",
                        color: .green
                    )
                }
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func engagementInsightPill(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(.primary)
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(AppCornerRadius.sm)
    }

    // MARK: - Operations Metrics Section

    @ViewBuilder
    private func operationsMetricsSection(isLandscape: Bool) -> some View {
        let checkedInCount = Int(Double(totalTicketsSold) * 0.72)
        let checkinRate = totalTicketsSold > 0 ? Double(checkedInCount) / Double(totalTicketsSold) * 100 : 0
        let avgResponseTime = 2.4 // hours
        let satisfactionScore = 4.2

        NavigationLink(destination: OperationsDetailView(
            totalTicketsSold: totalTicketsSold,
            totalCapacity: totalCapacity,
            events: events
        )) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Section Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.gray)
                    Text("Event Operations")
                        .font(AppTypography.cardTitle)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                let columns = isLandscape || horizontalSizeClass == .regular ? 4 : 2
                let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: columns)

                LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
                    MetricCard(
                        title: "Check-ins",
                        value: "\(checkedInCount)",
                        icon: "checkmark.circle.fill",
                        subtitle: String(format: "%.0f%% rate", checkinRate),
                        color: .green,
                        size: .compact
                    )

                    MetricCard(
                        title: "Pending",
                        value: "\(totalTicketsSold - checkedInCount)",
                        icon: "clock.fill",
                        color: .orange,
                        size: .compact
                    )

                    MetricCard(
                        title: "Response Time",
                        value: String(format: "%.1fh", avgResponseTime),
                        icon: "bubble.left.fill",
                        subtitle: "avg",
                        color: .blue,
                        size: .compact
                    )

                    MetricCard(
                        title: "Satisfaction",
                        value: String(format: "%.1f", satisfactionScore),
                        icon: "star.fill",
                        subtitle: "out of 5",
                        color: .yellow,
                        size: .compact
                    )
                }

                // Operations status bar
                HStack(spacing: AppSpacing.sm) {
                    operationStatusBadge(label: "Scanner", status: .active)
                    operationStatusBadge(label: "Support", status: .active)
                    operationStatusBadge(label: "Payments", status: .active)
                }
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func operationStatusBadge(label: String, status: OperationStatus) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.pill)
    }

    // MARK: - Predictive Analysis Section

    @ViewBuilder
    private func predictiveAnalysisSection(isLandscape: Bool) -> some View {
        let projectedRevenue = totalRevenue * 1.15
        let projectedTickets = Int(Double(totalTicketsSold) * 1.12)
        let daysToSellOut = totalCapacity > totalTicketsSold && totalTicketsSold > 0
            ? Int(ceil(Double(totalCapacity - totalTicketsSold) / max(1, Double(totalTicketsSold) / 30)))
            : nil
        let growthRate = 12.5

        NavigationLink(destination: PredictiveAnalysisDetailView(
            totalRevenue: totalRevenue,
            totalTicketsSold: totalTicketsSold,
            totalCapacity: totalCapacity,
            events: events
        )) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Section Header
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.purple)
                    Text("Insights & Predictions")
                        .font(AppTypography.cardTitle)
                    Spacer()

                    Text("Next 30 days")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(AppCornerRadius.pill)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Projections
                HStack(spacing: AppSpacing.md) {
                    // Projected Revenue
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text("Projected Revenue")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(formatCurrency(projectedRevenue))
                            .font(AppTypography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.md)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(AppCornerRadius.md)

                    // Projected Sales
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            Text("Projected Sales")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(projectedTickets)")
                            .font(AppTypography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.md)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(AppCornerRadius.md)
                }

                // Comparative insights
                VStack(spacing: AppSpacing.sm) {
                    comparativeInsightRow(
                        icon: "chart.bar.fill",
                        title: "Growth Rate",
                        value: String(format: "+%.1f%%", growthRate),
                        comparison: "vs last month",
                        isPositive: true
                    )

                    if let days = daysToSellOut {
                        comparativeInsightRow(
                            icon: "calendar.badge.clock",
                            title: "Est. Sell-out",
                            value: "\(days) days",
                            comparison: "at current pace",
                            isPositive: true
                        )
                    }

                    comparativeInsightRow(
                        icon: "person.2.fill",
                        title: "Audience Growth",
                        value: "+\(Int(Double(totalTicketsSold) * 0.08))",
                        comparison: "new attendees this month",
                        isPositive: true
                    )
                }
                .padding(AppSpacing.sm)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.md)
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func comparativeInsightRow(icon: String, title: String, value: String, comparison: String, isPositive: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isPositive ? .green : .red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.callout)
                    .foregroundColor(.primary)
                Text(comparison)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(isPositive ? .green : .red)
        }
    }

    // MARK: - Section Picker

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
                        .background(selectedSection == section ? RoleConfig.organizerPrimary : Color.gray.opacity(0.15))
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
        let alerts = generateAlerts()
        let visibleAlerts = alerts.filter { !dismissedAlerts.contains($0.id) }

        if !visibleAlerts.isEmpty {
            VStack(spacing: AppSpacing.sm) {
                ForEach(visibleAlerts.prefix(layoutConfig.isSmallDevice ? 2 : 3)) { alert in
                    InsightAlertCard(
                        alert: alert,
                        onAction: nil,
                        onDismiss: {
                            withAnimation {
                                _ = dismissedAlerts.insert(alert.id)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - All Sections Content

    @ViewBuilder
    private func allSectionsContent(isLandscape: Bool) -> some View {
        // Events Section
        SectionContainer(title: "Your Events", icon: "calendar", iconColor: .blue) {
            eventsContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)

        // Sales Performance
        SectionContainer(title: "Sales Performance", icon: "chart.line.uptrend.xyaxis", iconColor: .green) {
            salesPerformanceContent(isLandscape: isLandscape)
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)

        // Earnings
        SectionContainer(title: "Earnings", icon: "dollarsign.circle", iconColor: RoleConfig.organizerPrimary) {
            earningsContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)

        // Quick Actions
        SectionContainer(title: "Quick Actions", icon: "bolt", iconColor: .purple) {
            quickActionsContent
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)
    }

    // MARK: - Section Content Router

    @ViewBuilder
    private func sectionContent(for section: DashboardSection, isLandscape: Bool) -> some View {
        switch section {
        case .overview:
            VStack(spacing: layoutConfig.itemSpacing) {
                eventsContent
                earningsContent
            }
        case .sales:
            SectionContainer(title: "Sales Performance", icon: "chart.line.uptrend.xyaxis", iconColor: .green, isCollapsible: false) {
                salesPerformanceContent(isLandscape: isLandscape)
            }
        case .audience:
            SectionContainer(title: "Audience", icon: "person.2", iconColor: .purple, isCollapsible: false) {
                audienceContent
            }
        case .marketing:
            SectionContainer(title: "Engagement", icon: "megaphone", iconColor: .orange, isCollapsible: false) {
                marketingContent
            }
        case .financial:
            SectionContainer(title: "Earnings", icon: "dollarsign.circle", iconColor: .green, isCollapsible: false) {
                earningsContent
            }
        case .operations:
            SectionContainer(title: "Quick Actions", icon: "bolt", iconColor: .purple, isCollapsible: false) {
                quickActionsContent
            }
        }
    }

    // MARK: - Events Content

    @ViewBuilder
    private var eventsContent: some View {
        VStack(spacing: AppSpacing.sm) {
            if events.isEmpty {
                emptyEventsView
            } else {
                ForEach(events.prefix(5)) { event in
                    NavigationLink(destination: EventAnalyticsView(event: event)) {
                        eventCard(event: event)
                    }
                    .buttonStyle(.plain)
                }

                if events.count > 5 {
                    NavigationLink(destination: OrganizerHomeView()) {
                        HStack {
                            Text("View All \(events.count) Events")
                                .font(AppTypography.callout)
                                .foregroundColor(RoleConfig.organizerPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(RoleConfig.organizerPrimary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func eventCard(event: Event) -> some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusBadge(for: event.status)
            }

            // Ticket sales progress
            let ticketsSold = event.ticketTypes.reduce(0) { $0 + $1.sold }
            let totalCapacity = event.ticketTypes.reduce(0) { $0 + $1.quantity }
            let progress = totalCapacity > 0 ? Double(ticketsSold) / Double(totalCapacity) : 0

            VStack(spacing: 4) {
                HStack {
                    Text("Tickets")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(ticketsSold)/\(totalCapacity)")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.primary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor(progress))
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    @ViewBuilder
    private var emptyEventsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Events Yet")
                .font(AppTypography.cardTitle)
                .foregroundColor(.primary)

            Text("Create your first event to start selling tickets")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: CreateEventWizard()) {
                Text("Create Event")
                    .font(AppTypography.buttonSecondary)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.md)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Sales Performance Content

    @ViewBuilder
    private func salesPerformanceContent(isLandscape: Bool) -> some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            // Sales by tier chart - Tappable to see ticket analytics
            if !events.isEmpty {
                NavigationLink(destination: TicketAnalyticsDetailView(
                    totalSold: totalTicketsSold,
                    totalCapacity: totalCapacity,
                    events: events,
                    salesData: generateSalesDataPoints()
                )) {
                    ChartCard(title: "Sales by Ticket Type", showChevron: true) {
                        let tierData = aggregateTierSales()

                        if tierData.isEmpty {
                            Text("No sales data yet")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 100)
                        } else {
                            BarChartView(
                                bars: tierData.map { tier in
                                    BarChartData(
                                        label: tier.name,
                                        value: Double(tier.sold),
                                        color: Color(hex: tier.color)
                                    )
                                },
                                height: layoutConfig.chartHeight
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Stats row - Tappable
            NavigationLink(destination: TicketAnalyticsDetailView(
                totalSold: totalTicketsSold,
                totalCapacity: totalCapacity,
                events: events,
                salesData: generateSalesDataPoints()
            )) {
                StatsRow(stats: [
                    StatItem(label: "Total Sold", value: "\(totalTicketsSold)"),
                    StatItem(label: "Avg Price", value: formatCurrency(averageTicketPrice)),
                    StatItem(label: "Capacity", value: "\(capacityPercentage)%")
                ])
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Audience Content

    @ViewBuilder
    private var audienceContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2)
            let repeatAttendees = Int(Double(totalTicketsSold) * 0.26)

            LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
                NavigationLink(destination: AudienceAnalyticsDetailView(
                    totalAttendees: totalTicketsSold,
                    repeatAttendees: repeatAttendees,
                    followers: 0,
                    events: events
                )) {
                    MetricCard(
                        title: "Total Attendees",
                        value: "\(totalTicketsSold)",
                        icon: "person.fill",
                        color: .blue,
                        size: .compact
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: AudienceAnalyticsDetailView(
                    totalAttendees: totalTicketsSold,
                    repeatAttendees: repeatAttendees,
                    followers: 0,
                    events: events
                )) {
                    MetricCard(
                        title: "Returning",
                        value: "\(repeatAttendees)",
                        icon: "arrow.counterclockwise",
                        subtitle: totalTicketsSold > 0 ? "\(Int(Double(repeatAttendees) / Double(totalTicketsSold) * 100))%" : "0%",
                        color: .purple,
                        size: .compact
                    )
                }
                .buttonStyle(.plain)
            }

            // Tap to see more audience insights
            NavigationLink(destination: AudienceAnalyticsDetailView(
                totalAttendees: totalTicketsSold,
                repeatAttendees: repeatAttendees,
                followers: 0,
                events: events
            )) {
                HStack {
                    Image(systemName: "chart.pie")
                        .foregroundColor(RoleConfig.organizerPrimary)
                    Text("View detailed audience analytics")
                        .font(AppTypography.caption)
                        .foregroundColor(RoleConfig.organizerPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.md)
            }
        }
    }

    // MARK: - Marketing Content

    @ViewBuilder
    private var marketingContent: some View {
        VStack(spacing: layoutConfig.itemSpacing) {
            let totalLikes = events.reduce(0) { $0 + $1.likeCount }
            let totalViews = totalLikes * 5 // Estimated views

            let gridItems = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2)

            LazyVGrid(columns: gridItems, spacing: AppSpacing.sm) {
                NavigationLink(destination: AudienceAnalyticsDetailView(
                    totalAttendees: totalTicketsSold,
                    repeatAttendees: Int(Double(totalTicketsSold) * 0.26),
                    followers: 0,
                    events: events
                )) {
                    MetricCard(
                        title: "Est. Views",
                        value: formatNumber(totalViews),
                        icon: "eye",
                        color: .blue,
                        size: .compact
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: AudienceAnalyticsDetailView(
                    totalAttendees: totalTicketsSold,
                    repeatAttendees: Int(Double(totalTicketsSold) * 0.26),
                    followers: 0,
                    events: events
                )) {
                    MetricCard(
                        title: "Likes",
                        value: "\(totalLikes)",
                        icon: "heart",
                        color: .pink,
                        size: .compact
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Earnings Content

    @ViewBuilder
    private var earningsContent: some View {
        VStack(spacing: AppSpacing.md) {
            // Balance display - Tappable to see revenue details
            NavigationLink(destination: RevenueAnalyticsDetailView(
                totalRevenue: totalRevenue,
                events: events,
                dailyData: generateSalesDataPoints()
            )) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available Balance")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        Text(formatCurrency(totalRevenue))
                            .font(AppTypography.title)
                            .fontWeight(.bold)
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }

                    Spacer()

                    // Earnings breakdown
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Net:")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(totalRevenue * 0.95))
                                .font(AppTypography.captionEmphasized)
                                .foregroundColor(.green)
                        }

                        HStack(spacing: 4) {
                            Text("Fees:")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(totalRevenue * 0.05))
                                .font(AppTypography.captionEmphasized)
                                .foregroundColor(.orange)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, AppSpacing.sm)
                }
            }
            .buttonStyle(.plain)

            // Withdraw button
            Button(action: {}) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Withdraw Funds")
                }
                .font(AppTypography.buttonSecondary)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(totalRevenue > 0 ? RoleConfig.organizerPrimary : Color.gray)
                .cornerRadius(AppCornerRadius.md)
            }
            .disabled(totalRevenue <= 0)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Quick Actions Content

    @ViewBuilder
    private var quickActionsContent: some View {
        VStack(spacing: AppSpacing.sm) {
            NavigationLink(destination: CreateEventWizard()) {
                quickActionRow(icon: "plus.circle.fill", title: "Create Event", subtitle: "Launch a new event", color: .green)
            }

            NavigationLink(destination: QRScannerView()) {
                quickActionRow(icon: "qrcode.viewfinder", title: "Scan Tickets", subtitle: "Validate attendee tickets", color: .blue)
            }

            NavigationLink(destination: Text("Scanner Device Management - Coming Soon").navigationTitle("Scanner Devices")) {
                quickActionRow(icon: "iphone.and.arrow.forward", title: "Manage Scanners", subtitle: "Authorize scanning devices", color: .purple)
            }
        }
    }

    @ViewBuilder
    private func quickActionRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .cornerRadius(AppCornerRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Loading Overlay

    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color(UIColor.systemBackground).opacity(0.8)

            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)

                Text("Loading dashboard...")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func statusBadge(for status: EventStatus) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .draft: return ("Draft", .gray)
            case .published: return ("Live", .green)
            case .ongoing: return ("Ongoing", .blue)
            case .completed: return ("Ended", .secondary)
            case .cancelled: return ("Cancelled", .red)
            }
        }()

        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(AppCornerRadius.xs)
    }

    // MARK: - Helper Functions

    private func loadAnalytics() {
        Task {
            do {
                guard let organizerId = authService.currentUser?.id else { return }

                let fetchedEvents = try await services.eventService.fetchOrganizerEvents(organizerId: organizerId)
                let revenue = try await services.paymentService.calculateRevenue(organizerId: organizerId)

                let ticketsSold = fetchedEvents.reduce(0) { total, event in
                    total + event.ticketTypes.reduce(0) { $0 + $1.sold }
                }

                let capacity = fetchedEvents.reduce(0) { total, event in
                    total + event.ticketTypes.reduce(0) { $0 + $1.quantity }
                }

                let active = fetchedEvents.filter { $0.status == .published || $0.status == .ongoing }.count

                await MainActor.run {
                    self.events = fetchedEvents
                    self.totalRevenue = revenue
                    self.totalTicketsSold = ticketsSold
                    self.totalCapacity = capacity
                    self.activeEvents = active
                    self.isLoading = false
                }
            } catch {
                print("Error loading analytics: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func refreshData() async {
        isLoading = true
        loadAnalytics()
    }

    private func subscribeToTicketSales() {
        services.ticketService.ticketSalesPublisher
            .receive(on: DispatchQueue.main)
            .sink { saleEvent in
                if let index = events.firstIndex(where: { $0.id == saleEvent.eventId }) {
                    for (typeIndex, ticketType) in events[index].ticketTypes.enumerated() {
                        if ticketType.name == saleEvent.ticketType {
                            events[index].ticketTypes[typeIndex].sold += saleEvent.quantity
                        }
                    }
                }

                totalTicketsSold += saleEvent.quantity
                totalRevenue += saleEvent.totalAmount

                HapticFeedback.success()
            }
            .store(in: &cancellables)
    }

    private func generateAlerts() -> [AnalyticsAlert] {
        var alerts: [AnalyticsAlert] = []

        // Low sales alert
        if activeEvents > 0 && totalTicketsSold < 10 {
            alerts.append(AnalyticsAlert(
                type: .lowSales,
                title: "Boost Your Sales",
                message: "Consider sharing your events on social media to increase visibility.",
                severity: .info
            ))
        }

        // Near capacity alert
        if totalCapacity > 0 && Double(totalTicketsSold) / Double(totalCapacity) > 0.8 {
            alerts.append(AnalyticsAlert(
                type: .nearSellOut,
                title: "Almost Sold Out!",
                message: "Your events are nearly at capacity. Great job!",
                severity: .success
            ))
        }

        return alerts
    }

    private func aggregateTierSales() -> [(name: String, sold: Int, color: String)] {
        var tierMap: [String: (sold: Int, color: String)] = [:]
        let colors = ["34C759", "FF7A00", "FFD700", "AF52DE", "007AFF"]

        for event in events {
            for (index, tier) in event.ticketTypes.enumerated() {
                let colorIndex = index % colors.count
                if let existing = tierMap[tier.name] {
                    tierMap[tier.name] = (existing.sold + tier.sold, existing.color)
                } else {
                    tierMap[tier.name] = (tier.sold, colors[colorIndex])
                }
            }
        }

        return tierMap.map { (name: $0.key, sold: $0.value.sold, color: $0.value.color) }
            .sorted { $0.sold > $1.sold }
    }

    private func calculateHealthScore() -> Int {
        var score = 50 // Base score

        // Active events bonus
        if activeEvents > 0 { score += 15 }
        if activeEvents > 3 { score += 10 }

        // Sales performance
        if totalCapacity > 0 {
            let salesRate = Double(totalTicketsSold) / Double(totalCapacity)
            score += Int(salesRate * 25)
        }

        return min(100, max(0, score))
    }

    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    private func healthScoreLabel(_ score: Int) -> String {
        switch score {
        case 80...: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Work"
        }
    }

    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 0.8...: return .green
        case 0.5..<0.8: return RoleConfig.organizerPrimary
        default: return .blue
        }
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

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }

    private var capacityText: String {
        guard totalCapacity > 0 else { return "" }
        return "\(Int(Double(totalTicketsSold) / Double(totalCapacity) * 100))% capacity"
    }

    private var capacityPercentage: Int {
        guard totalCapacity > 0 else { return 0 }
        return Int(Double(totalTicketsSold) / Double(totalCapacity) * 100)
    }

    private var averageTicketPrice: Double {
        guard totalTicketsSold > 0 else { return 0 }
        return totalRevenue / Double(totalTicketsSold)
    }

    private func generateSalesDataPoints() -> [SalesDataPoint] {
        // Generate mock sales data for the last 30 days
        let calendar = Calendar.current
        var dataPoints: [SalesDataPoint] = []

        for dayOffset in (0..<30).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let baseSales = totalTicketsSold > 0 ? max(1, totalTicketsSold / 30) : 0
                let variance = Int.random(in: -2...5)
                let sales = max(0, baseSales + variance)
                let revenue = Double(sales) * averageTicketPrice

                dataPoints.append(SalesDataPoint(
                    date: date,
                    sales: sales,
                    revenue: revenue
                ))
            }
        }

        return dataPoints
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
        case .marketing: return "Engagement"
        case .financial: return "Earnings"
        case .operations: return "Actions"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "chart.pie"
        case .sales: return "chart.line.uptrend.xyaxis"
        case .audience: return "person.2"
        case .marketing: return "megaphone"
        case .financial: return "dollarsign.circle"
        case .operations: return "bolt"
        }
    }
}

// MARK: - Operation Status

enum OperationStatus {
    case active
    case warning
    case inactive

    var color: Color {
        switch self {
        case .active: return .green
        case .warning: return .orange
        case .inactive: return .red
        }
    }
}

// MARK: - Layout Configuration

struct DashboardLayoutConfig {
    let horizontalSizeClass: UserInterfaceSizeClass?

    var isSmallDevice: Bool {
        ScreenSize.isSmallDevice
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

    var metricCardSize: MetricCardSize {
        switch ScreenSize.DeviceSize.current {
        case .small: return .compact
        case .regular: return .regular
        case .large, .iPad: return .regular
        }
    }
}

// Type alias for convenience
typealias MetricCardSize = MetricCard.MetricCardSize

// MARK: - Preview

#Preview {
    OrganizerDashboardView()
        .environmentObject(MockAuthRepository())
        .environmentObject(ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        ))
}

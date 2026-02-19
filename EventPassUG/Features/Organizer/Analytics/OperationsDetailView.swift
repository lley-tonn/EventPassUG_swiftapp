//
//  OperationsDetailView.swift
//  EventPassUG
//
//  Detailed event operations metrics and management
//

import SwiftUI

struct OperationsDetailView: View {
    let totalTicketsSold: Int
    let totalCapacity: Int
    let events: [Event]

    @State private var selectedTab: OperationsTab = .overview

    enum OperationsTab: String, CaseIterable {
        case overview = "Overview"
        case checkins = "Check-ins"
        case support = "Support"
    }

    // Computed properties
    private var checkedInCount: Int {
        Int(Double(totalTicketsSold) * 0.72)
    }

    private var pendingCheckins: Int {
        totalTicketsSold - checkedInCount
    }

    private var checkinRate: Double {
        guard totalTicketsSold > 0 else { return 0 }
        return Double(checkedInCount) / Double(totalTicketsSold) * 100
    }

    private var avgCheckinTime: String {
        "2.3 min"
    }

    private var peakCheckinHour: String {
        "7:00 PM"
    }

    private var supportTickets: Int {
        Int(Double(totalTicketsSold) * 0.03)
    }

    private var resolvedTickets: Int {
        Int(Double(supportTickets) * 0.85)
    }

    private var avgResponseTime: Double {
        2.4 // hours
    }

    private var satisfactionScore: Double {
        4.2
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Header Stats
                headerSection

                // Tab Picker
                tabPicker

                // Content
                switch selectedTab {
                case .overview:
                    overviewContent
                case .checkins:
                    checkinsContent
                case .support:
                    supportContent
                }
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Operations")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: AppSpacing.lg) {
            // Check-in progress
            VStack(spacing: AppSpacing.xs) {
                ProgressRingView(
                    progress: checkinRate / 100,
                    size: 80,
                    lineWidth: 10,
                    color: .green,
                    showPercentage: true
                )

                Text("Checked In")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            // Stats
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                OperationStatRow(label: "Total Tickets", value: "\(totalTicketsSold)")
                OperationStatRow(label: "Checked In", value: "\(checkedInCount)", color: .green)
                OperationStatRow(label: "Pending", value: "\(pendingCheckins)", color: .orange)
                OperationStatRow(label: "No-shows", value: "\(Int(Double(totalTicketsSold) * 0.05))", color: .red)
            }
        }
        .padding(AppSpacing.lg)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.lg)
    }

    // MARK: - Tab Picker

    @ViewBuilder
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(OperationsTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(AppAnimation.standard) {
                        selectedTab = tab
                    }
                    HapticFeedback.selection()
                }) {
                    Text(tab.rawValue)
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(selectedTab == tab ? RoleConfig.organizerPrimary : Color.clear)
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
            // Quick metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                OperationsMetricCard(
                    title: "Avg Check-in Time",
                    value: avgCheckinTime,
                    icon: "clock.fill",
                    color: .blue
                )

                OperationsMetricCard(
                    title: "Peak Hour",
                    value: peakCheckinHour,
                    icon: "chart.bar.fill",
                    color: .orange
                )

                OperationsMetricCard(
                    title: "Support Tickets",
                    value: "\(supportTickets)",
                    icon: "ticket.fill",
                    color: .purple
                )

                OperationsMetricCard(
                    title: "Satisfaction",
                    value: String(format: "%.1f/5", satisfactionScore),
                    icon: "star.fill",
                    color: .yellow
                )
            }

            // System status
            systemStatusSection

            // Active events
            activeEventsSection
        }
    }

    // MARK: - Check-ins Content

    @ViewBuilder
    private var checkinsContent: some View {
        VStack(spacing: AppSpacing.md) {
            // Check-in timeline
            checkinTimelineSection

            // Check-in by event
            checkinByEventSection

            // Check-in methods
            checkinMethodsSection
        }
    }

    // MARK: - Support Content

    @ViewBuilder
    private var supportContent: some View {
        VStack(spacing: AppSpacing.md) {
            // Support overview
            supportOverviewSection

            // Recent tickets
            recentTicketsSection

            // FAQ performance
            faqPerformanceSection
        }
    }

    // MARK: - System Status Section

    @ViewBuilder
    private var systemStatusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("System Status")
                .font(AppTypography.cardTitle)

            VStack(spacing: AppSpacing.sm) {
                SystemStatusRow(name: "QR Scanner", status: .operational, latency: "45ms")
                SystemStatusRow(name: "Payment Gateway", status: .operational, latency: "120ms")
                SystemStatusRow(name: "Ticket Validation", status: .operational, latency: "30ms")
                SystemStatusRow(name: "Notification Service", status: .operational, latency: "80ms")
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Active Events Section

    @ViewBuilder
    private var activeEventsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Active Events")
                .font(AppTypography.cardTitle)

            let activeEvents = events.filter { $0.status == .ongoing || $0.status == .published }

            if activeEvents.isEmpty {
                Text("No active events")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.lg)
            } else {
                ForEach(activeEvents.prefix(3)) { event in
                    ActiveEventCard(event: event)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Check-in Timeline

    @ViewBuilder
    private var checkinTimelineSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Check-in Timeline")
                .font(AppTypography.cardTitle)

            // Hourly breakdown
            let hourlyData = generateHourlyData()

            BarChartView(
                bars: hourlyData.map { hour in
                    BarChartData(label: hour.label, value: Double(hour.count))
                },
                barColor: RoleConfig.organizerPrimary,
                height: 150
            )

            HStack {
                Text("Peak: \(peakCheckinHour)")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Avg: \(Int(Double(checkedInCount) / 6))/hour")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Check-in by Event

    @ViewBuilder
    private var checkinByEventSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Check-ins by Event")
                .font(AppTypography.cardTitle)

            ForEach(events.prefix(5)) { event in
                let soldTickets = event.ticketTypes.reduce(0) { $0 + $1.sold }
                let checkedIn = Int(Double(soldTickets) * 0.72)

                EventCheckinRow(
                    title: event.title,
                    checkedIn: checkedIn,
                    total: soldTickets
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Check-in Methods

    @ViewBuilder
    private var checkinMethodsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Check-in Methods")
                .font(AppTypography.cardTitle)

            let methods = [
                ("QR Code Scan", 0.75, Color.blue),
                ("Manual Entry", 0.15, Color.orange),
                ("NFC Tap", 0.10, Color.green)
            ]

            DonutChartView(
                segments: methods.map { method in
                    DonutSegment(
                        label: method.0,
                        value: Double(checkedInCount) * method.1,
                        percentage: method.1,
                        color: method.2 == .blue ? "007AFF" : method.2 == .orange ? "FF9500" : "34C759"
                    )
                },
                size: 120,
                lineWidth: 20,
                centerText: "\(checkedInCount)",
                centerSubtext: "Total"
            )
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Support Overview

    @ViewBuilder
    private var supportOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Support Overview")
                .font(AppTypography.cardTitle)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                SupportMetricCard(
                    title: "Open Tickets",
                    value: "\(supportTickets - resolvedTickets)",
                    color: .orange
                )

                SupportMetricCard(
                    title: "Resolved",
                    value: "\(resolvedTickets)",
                    color: .green
                )

                SupportMetricCard(
                    title: "Avg Response",
                    value: String(format: "%.1fh", avgResponseTime),
                    color: .blue
                )

                SupportMetricCard(
                    title: "CSAT Score",
                    value: String(format: "%.1f", satisfactionScore),
                    color: .yellow
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Recent Tickets

    @ViewBuilder
    private var recentTicketsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Tickets")
                .font(AppTypography.cardTitle)

            let tickets: [(String, String, TicketStatus, String)] = [
                ("Ticket not received", "Payment", TicketStatus.resolved, "2h ago"),
                ("Unable to check-in", "Check-in", TicketStatus.open, "4h ago"),
                ("Refund request", "Payment", TicketStatus.inProgress, "6h ago")
            ]

            ForEach(tickets.indices, id: \.self) { index in
                let ticket = tickets[index]
                SupportTicketRow(
                    title: ticket.0,
                    category: ticket.1,
                    status: ticket.2,
                    time: ticket.3
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - FAQ Performance

    @ViewBuilder
    private var faqPerformanceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Self-Service Stats")
                .font(AppTypography.cardTitle)

            VStack(spacing: AppSpacing.sm) {
                FAQStatRow(label: "FAQ Views", value: "\(Int(Double(totalTicketsSold) * 0.4))")
                FAQStatRow(label: "Issues Resolved via FAQ", value: "68%")
                FAQStatRow(label: "Avg. Time to Resolution", value: "1.2h")
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Helpers

    private func generateHourlyData() -> [(label: String, count: Int)] {
        let hours = ["4PM", "5PM", "6PM", "7PM", "8PM", "9PM"]
        let distribution = [0.08, 0.15, 0.25, 0.28, 0.18, 0.06]

        return zip(hours, distribution).map { (hour, pct) in
            (hour, Int(Double(checkedInCount) * pct))
        }
    }
}

// MARK: - Supporting Components

struct OperationStatRow: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(color)
        }
    }
}

struct OperationsMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(AppTypography.title3)
                .fontWeight(.bold)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

struct SystemStatusRow: View {
    let name: String
    let status: SystemStatus
    let latency: String

    enum SystemStatus {
        case operational, degraded, down

        var color: Color {
            switch self {
            case .operational: return .green
            case .degraded: return .orange
            case .down: return .red
            }
        }

        var label: String {
            switch self {
            case .operational: return "Operational"
            case .degraded: return "Degraded"
            case .down: return "Down"
            }
        }
    }

    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(name)
                .font(AppTypography.callout)

            Spacer()

            Text(latency)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            Text(status.label)
                .font(AppTypography.captionEmphasized)
                .foregroundColor(status.color)
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct ActiveEventCard: View {
    let event: Event

    var body: some View {
        let soldTickets = event.ticketTypes.reduce(0) { $0 + $1.sold }
        let checkedIn = Int(Double(soldTickets) * 0.72)

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppTypography.callout)
                    .lineLimit(1)

                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(checkedIn)/\(soldTickets)")
                    .font(AppTypography.calloutEmphasized)

                Text("checked in")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct EventCheckinRow: View {
    let title: String
    let checkedIn: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(checkedIn) / Double(total)
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppTypography.callout)
                    .lineLimit(1)
                Spacer()
                Text("\(checkedIn)/\(total)")
                    .font(AppTypography.captionEmphasized)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)
        }
    }
}

struct SupportMetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }
}

enum TicketStatus {
    case open, inProgress, resolved

    var color: Color {
        switch self {
        case .open: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        }
    }

    var label: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        }
    }
}

struct SupportTicketRow: View {
    let title: String
    let category: String
    let status: TicketStatus
    let time: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.callout)

                HStack(spacing: AppSpacing.sm) {
                    Text(category)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(time)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(status.label)
                .font(AppTypography.captionEmphasized)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(status.color)
                .cornerRadius(AppCornerRadius.pill)
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct FAQStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.callout)
            Spacer()
            Text(value)
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(RoleConfig.organizerPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        OperationsDetailView(
            totalTicketsSold: 342,
            totalCapacity: 500,
            events: Event.samples
        )
    }
}

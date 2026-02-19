//
//  AudienceAnalyticsDetailView.swift
//  EventPassUG
//
//  Detailed audience analytics with demographics, engagement, and retention
//

import SwiftUI

struct AudienceAnalyticsDetailView: View {
    let totalAttendees: Int
    let repeatAttendees: Int
    let followers: Int
    let events: [Event]

    @State private var selectedTab: AudienceTab = .overview

    enum AudienceTab: String, CaseIterable {
        case overview = "Overview"
        case demographics = "Demographics"
        case engagement = "Engagement"
    }

    // Computed properties
    private var repeatRate: Double {
        guard totalAttendees > 0 else { return 0 }
        return Double(repeatAttendees) / Double(totalAttendees)
    }

    private var newAttendees: Int {
        totalAttendees - repeatAttendees
    }

    private var vipAttendees: Int {
        events.reduce(0) { total, event in
            total + event.ticketTypes.filter { $0.name.lowercased().contains("vip") }.reduce(0) { $0 + $1.sold }
        }
    }

    private var vipPercentage: Double {
        guard totalAttendees > 0 else { return 0 }
        return Double(vipAttendees) / Double(totalAttendees)
    }

    // Mock demographic data
    private var ageGroups: [(range: String, percentage: Double, count: Int)] {
        [
            ("18-24", 0.35, Int(Double(totalAttendees) * 0.35)),
            ("25-34", 0.42, Int(Double(totalAttendees) * 0.42)),
            ("35-44", 0.15, Int(Double(totalAttendees) * 0.15)),
            ("45+", 0.08, Int(Double(totalAttendees) * 0.08))
        ]
    }

    private var topCities: [(city: String, count: Int, percentage: Double)] {
        [
            ("Kampala", Int(Double(totalAttendees) * 0.72), 0.72),
            ("Entebbe", Int(Double(totalAttendees) * 0.14), 0.14),
            ("Jinja", Int(Double(totalAttendees) * 0.08), 0.08),
            ("Other", Int(Double(totalAttendees) * 0.06), 0.06)
        ]
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Header stats
                headerSection

                // Tab picker
                tabPicker

                // Content based on selected tab
                switch selectedTab {
                case .overview:
                    overviewContent
                case .demographics:
                    demographicsContent
                case .engagement:
                    engagementContent
                }
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Audience Analytics")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Main metric
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalAttendees)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Total Attendees")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Retention ring
                VStack(spacing: 4) {
                    ProgressRingView(
                        progress: repeatRate,
                        size: 70,
                        lineWidth: 8,
                        color: .purple,
                        showPercentage: true
                    )

                    Text("Retention")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Quick stats
            HStack(spacing: AppSpacing.sm) {
                AudienceStatPill(
                    value: "\(newAttendees)",
                    label: "New",
                    color: .blue
                )

                AudienceStatPill(
                    value: "\(repeatAttendees)",
                    label: "Returning",
                    color: .purple
                )

                AudienceStatPill(
                    value: "\(followers)",
                    label: "Followers",
                    color: .pink
                )

                AudienceStatPill(
                    value: "\(Int(vipPercentage * 100))%",
                    label: "VIP",
                    color: Color(hex: "FFD700")
                )
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
            ForEach(AudienceTab.allCases, id: \.self) { tab in
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
                        .background(selectedTab == tab ? Color.purple : Color.clear)
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
            // New vs Returning chart
            ChartCard(title: "New vs Returning", subtitle: "Attendee breakdown") {
                DonutChartView(
                    segments: [
                        DonutSegment(label: "New", value: Double(newAttendees), percentage: 1 - repeatRate, color: "007AFF"),
                        DonutSegment(label: "Returning", value: Double(repeatAttendees), percentage: repeatRate, color: "AF52DE")
                    ],
                    size: 140,
                    lineWidth: 24,
                    centerText: "\(totalAttendees)",
                    centerSubtext: "Total"
                )
            }

            // Retention insights
            retentionInsightsCard

            // Growth trends
            growthTrendsCard
        }
    }

    // MARK: - Demographics Content

    @ViewBuilder
    private var demographicsContent: some View {
        VStack(spacing: AppSpacing.md) {
            // Age distribution
            ChartCard(title: "Age Distribution") {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(ageGroups, id: \.range) { group in
                        DemographicBar(
                            label: group.range,
                            count: group.count,
                            percentage: group.percentage,
                            color: .blue
                        )
                    }
                }
            }

            // Location distribution
            ChartCard(title: "Top Locations") {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(topCities, id: \.city) { city in
                        LocationRow(
                            city: city.city,
                            count: city.count,
                            percentage: city.percentage
                        )
                    }
                }
            }

            // Premium attendees
            premiumAttendeesCard
        }
    }

    // MARK: - Engagement Content

    @ViewBuilder
    private var engagementContent: some View {
        VStack(spacing: AppSpacing.md) {
            // Engagement metrics
            engagementMetricsCard

            // Event participation
            eventParticipationCard

            // Social engagement
            socialEngagementCard
        }
    }

    // MARK: - Component Cards

    @ViewBuilder
    private var retentionInsightsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(.purple)
                Text("Retention Insights")
                    .font(AppTypography.cardTitle)
            }

            VStack(spacing: AppSpacing.sm) {
                InsightRow(
                    icon: "person.badge.clock",
                    title: "Average Events Attended",
                    value: "2.4",
                    subtitle: "per returning customer"
                )

                InsightRow(
                    icon: "calendar.badge.plus",
                    title: "Re-engagement Rate",
                    value: "\(Int(repeatRate * 100))%",
                    subtitle: "attend multiple events"
                )

                InsightRow(
                    icon: "star.fill",
                    title: "Loyalty Score",
                    value: repeatRate > 0.3 ? "High" : repeatRate > 0.15 ? "Medium" : "Low",
                    subtitle: "based on repeat attendance",
                    valueColor: repeatRate > 0.3 ? .green : repeatRate > 0.15 ? .orange : .red
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    @ViewBuilder
    private var growthTrendsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Growth Trends")
                    .font(AppTypography.cardTitle)
            }

            HStack(spacing: AppSpacing.md) {
                GrowthMetric(
                    title: "Monthly Growth",
                    value: "+23%",
                    isPositive: true
                )

                GrowthMetric(
                    title: "Follower Growth",
                    value: "+\(Int(Double(followers) * 0.12))",
                    isPositive: true
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color.green.opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }

    @ViewBuilder
    private var premiumAttendeesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(hex: "FFD700"))
                Text("Premium Attendees")
                    .font(AppTypography.cardTitle)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vipAttendees)")
                        .font(AppTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FFD700"))

                    Text("VIP ticket holders")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ProgressRingView(
                    progress: vipPercentage,
                    size: 60,
                    lineWidth: 8,
                    color: Color(hex: "FFD700")
                )
            }

            Text("VIP attendees typically have 3x higher lifetime value")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(AppSpacing.md)
        .background(Color(hex: "FFD700").opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }

    @ViewBuilder
    private var engagementMetricsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Engagement Metrics")
                .font(AppTypography.cardTitle)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                EngagementMetricCard(
                    icon: "eye",
                    title: "Avg. Page Views",
                    value: "3.2",
                    subtitle: "per visitor",
                    color: .blue
                )

                EngagementMetricCard(
                    icon: "clock",
                    title: "Avg. Time",
                    value: "4:32",
                    subtitle: "on event page",
                    color: .green
                )

                EngagementMetricCard(
                    icon: "heart",
                    title: "Like Rate",
                    value: "24%",
                    subtitle: "of viewers",
                    color: .pink
                )

                EngagementMetricCard(
                    icon: "square.and.arrow.up",
                    title: "Share Rate",
                    value: "8%",
                    subtitle: "of attendees",
                    color: .purple
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    @ViewBuilder
    private var eventParticipationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Event Participation")
                .font(AppTypography.cardTitle)

            if events.isEmpty {
                Text("No event data available")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(events.prefix(3)) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(AppTypography.callout)
                                .lineLimit(1)

                            let attendees = event.ticketTypes.reduce(0) { $0 + $1.sold }
                            Text("\(attendees) attendees")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(AppSpacing.sm)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(AppCornerRadius.sm)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    @ViewBuilder
    private var socialEngagementCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(.pink)
                Text("Social Engagement")
                    .font(AppTypography.cardTitle)
            }

            HStack(spacing: AppSpacing.md) {
                SocialMetric(platform: "Followers", value: "\(followers)", icon: "heart.fill", color: .pink)
                SocialMetric(platform: "Shares", value: "\(Int(Double(totalAttendees) * 0.12))", icon: "square.and.arrow.up", color: .blue)
                SocialMetric(platform: "Reviews", value: "\(Int(Double(totalAttendees) * 0.08))", icon: "star.fill", color: .orange)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Supporting Components

struct AudienceStatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(color.opacity(0.15))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct DemographicBar: View {
    let label: String
    let count: Int
    let percentage: Double
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(label)
                .font(AppTypography.callout)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 24)

            Text("\(count)")
                .font(AppTypography.captionEmphasized)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct LocationRow: View {
    let city: String
    let count: Int
    let percentage: Double

    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.red)

            Text(city)
                .font(AppTypography.callout)

            Spacer()

            Text("\(count)")
                .font(AppTypography.calloutEmphasized)

            Text("(\(Int(percentage * 100))%)")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.callout)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(valueColor)
        }
    }
}

struct GrowthMetric: View {
    let title: String
    let value: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12))
                Text(value)
                    .font(AppTypography.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct EngagementMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(AppTypography.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct SocialMetric: View {
    let platform: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(AppTypography.calloutEmphasized)

            Text(platform)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        AudienceAnalyticsDetailView(
            totalAttendees: 342,
            repeatAttendees: 89,
            followers: 156,
            events: Event.samples
        )
    }
}

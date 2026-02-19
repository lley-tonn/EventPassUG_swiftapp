//
//  MarketingInsightsDetailView.swift
//  EventPassUG
//
//  Detailed marketing and engagement analytics
//

import SwiftUI

struct MarketingInsightsDetailView: View {
    let totalViews: Int
    let totalLikes: Int
    let totalShares: Int
    let totalTicketsSold: Int
    let events: [Event]

    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedMetric: MarketingMetric = .impressions

    enum TimeRange: String, CaseIterable {
        case last7Days = "7D"
        case last30Days = "30D"
        case last90Days = "90D"
        case allTime = "All"
    }

    enum MarketingMetric: String, CaseIterable {
        case impressions = "Impressions"
        case engagement = "Engagement"
        case conversion = "Conversion"
    }

    // Computed properties
    private var conversionRate: Double {
        guard totalViews > 0 else { return 0 }
        return Double(totalTicketsSold) / Double(totalViews) * 100
    }

    private var engagementRate: Double {
        guard totalViews > 0 else { return 0 }
        return Double(totalLikes + totalShares) / Double(totalViews) * 100
    }

    private var clickThroughRate: Double {
        guard totalViews > 0 else { return 0 }
        return Double(totalLikes) / Double(totalViews) * 100
    }

    private var avgViewsPerEvent: Int {
        guard events.count > 0 else { return 0 }
        return totalViews / events.count
    }

    private var topPerformingEvents: [(event: Event, views: Int, likes: Int)] {
        events.map { event in
            let views = event.likeCount * 5
            return (event, views, event.likeCount)
        }.sorted { $0.views > $1.views }
    }

    private var trafficSources: [(source: String, percentage: Double, count: Int, color: String)] {
        [
            ("Direct", 0.35, Int(Double(totalViews) * 0.35), "007AFF"),
            ("Social Media", 0.28, Int(Double(totalViews) * 0.28), "FF2D55"),
            ("Search", 0.22, Int(Double(totalViews) * 0.22), "34C759"),
            ("Referral", 0.10, Int(Double(totalViews) * 0.10), "FF9500"),
            ("Other", 0.05, Int(Double(totalViews) * 0.05), "8E8E93")
        ]
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Header Stats
                headerSection

                // Time Range Picker
                timeRangePicker

                // Key Metrics Grid
                keyMetricsGrid

                // Engagement Funnel
                engagementFunnelSection

                // Traffic Sources
                trafficSourcesSection

                // Top Performing Events
                topEventsSection

                // Engagement Trends
                engagementTrendsSection
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Marketing Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Main metric
            VStack(spacing: AppSpacing.xs) {
                Text("\(totalViews)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Total Impressions")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                // Conversion indicator
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                    Text(String(format: "%.1f%% conversion", conversionRate))
                }
                .font(AppTypography.captionEmphasized)
                .foregroundColor(.green)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.green.opacity(0.15))
                .cornerRadius(AppCornerRadius.pill)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.lg)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.lg)
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

    // MARK: - Key Metrics Grid

    @ViewBuilder
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            MarketingMetricCard(
                title: "Impressions",
                value: "\(totalViews)",
                icon: "eye.fill",
                trend: "+12%",
                isPositive: true,
                color: .blue
            )

            MarketingMetricCard(
                title: "Engagement Rate",
                value: String(format: "%.1f%%", engagementRate),
                icon: "hand.tap.fill",
                trend: "+5%",
                isPositive: true,
                color: .purple
            )

            MarketingMetricCard(
                title: "Likes",
                value: "\(totalLikes)",
                icon: "heart.fill",
                trend: "+18%",
                isPositive: true,
                color: .pink
            )

            MarketingMetricCard(
                title: "Shares",
                value: "\(totalShares)",
                icon: "square.and.arrow.up.fill",
                trend: "+8%",
                isPositive: true,
                color: .green
            )
        }
    }

    // MARK: - Engagement Funnel

    @ViewBuilder
    private var engagementFunnelSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Conversion Funnel")
                .font(AppTypography.cardTitle)

            VStack(spacing: AppSpacing.sm) {
                FunnelStep(
                    label: "Impressions",
                    value: totalViews,
                    percentage: 100,
                    color: .blue
                )

                FunnelStep(
                    label: "Engaged (Liked/Shared)",
                    value: totalLikes + totalShares,
                    percentage: engagementRate,
                    color: .purple
                )

                FunnelStep(
                    label: "Clicked Through",
                    value: Int(Double(totalViews) * clickThroughRate / 100),
                    percentage: clickThroughRate,
                    color: .orange
                )

                FunnelStep(
                    label: "Purchased",
                    value: totalTicketsSold,
                    percentage: conversionRate,
                    color: .green
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Traffic Sources

    @ViewBuilder
    private var trafficSourcesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Traffic Sources")
                .font(AppTypography.cardTitle)

            // Donut chart
            DonutChartView(
                segments: trafficSources.map { source in
                    DonutSegment(
                        label: source.source,
                        value: Double(source.count),
                        percentage: source.percentage,
                        color: source.color
                    )
                },
                size: 140,
                lineWidth: 24,
                centerText: "\(totalViews)",
                centerSubtext: "Total"
            )

            // Source breakdown
            VStack(spacing: AppSpacing.sm) {
                ForEach(trafficSources, id: \.source) { source in
                    HStack {
                        Circle()
                            .fill(Color(hex: source.color))
                            .frame(width: 10, height: 10)

                        Text(source.source)
                            .font(AppTypography.callout)

                        Spacer()

                        Text("\(source.count)")
                            .font(AppTypography.calloutEmphasized)

                        Text("(\(Int(source.percentage * 100))%)")
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

    // MARK: - Top Events

    @ViewBuilder
    private var topEventsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Top Performing Events")
                .font(AppTypography.cardTitle)

            if topPerformingEvents.isEmpty {
                Text("No events to display")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(topPerformingEvents.prefix(5), id: \.event.id) { item in
                    TopEventRow(
                        title: item.event.title,
                        views: item.views,
                        likes: item.likes,
                        rank: topPerformingEvents.firstIndex(where: { $0.event.id == item.event.id })! + 1
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Engagement Trends

    @ViewBuilder
    private var engagementTrendsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Engagement Insights")
                .font(AppTypography.cardTitle)

            VStack(spacing: AppSpacing.sm) {
                InsightCard(
                    icon: "clock.fill",
                    title: "Best Time to Post",
                    value: "6-8 PM",
                    subtitle: "Highest engagement window",
                    color: .orange
                )

                InsightCard(
                    icon: "calendar",
                    title: "Best Day",
                    value: "Friday",
                    subtitle: "30% more engagement",
                    color: .blue
                )

                InsightCard(
                    icon: "person.2.fill",
                    title: "Audience Growth",
                    value: "+\(Int(Double(totalViews) * 0.08))",
                    subtitle: "New viewers this month",
                    color: .green
                )
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Supporting Components

struct MarketingMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: String
    let isPositive: Bool
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10))
                    Text(trend)
                        .font(AppTypography.caption)
                }
                .foregroundColor(isPositive ? .green : .red)
            }

            Text(value)
                .font(AppTypography.title2)
                .fontWeight(.bold)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

struct FunnelStep: View {
    let label: String
    let value: Int
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text(label)
                    .font(AppTypography.callout)
                Spacer()
                Text("\(value)")
                    .font(AppTypography.calloutEmphasized)
                Text("(\(Int(percentage))%)")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

struct TopEventRow: View {
    let title: String
    let views: Int
    let likes: Int
    let rank: Int

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text("\(rank)")
                .font(AppTypography.title3)
                .fontWeight(.bold)
                .foregroundColor(rank <= 3 ? .orange : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.callout)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.md) {
                    Label("\(views)", systemImage: "eye")
                    Label("\(likes)", systemImage: "heart")
                }
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(AppTypography.calloutEmphasized)
            }

            Spacer()

            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(AppSpacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(AppCornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        MarketingInsightsDetailView(
            totalViews: 12500,
            totalLikes: 890,
            totalShares: 156,
            totalTicketsSold: 342,
            events: Event.samples
        )
    }
}

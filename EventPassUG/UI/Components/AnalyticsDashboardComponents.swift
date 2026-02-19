//
//  AnalyticsDashboardComponents.swift
//  EventPassUG
//
//  Reusable components for the analytics dashboard
//  Designed for responsive layouts across device sizes
//

import SwiftUI

// MARK: - Metric Card

/// A card displaying a single metric with icon, value, label, and optional trend
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var subtitle: String?
    var trend: TrendData?
    var color: Color = AppColors.primary
    var size: MetricCardSize = .regular

    enum MetricCardSize {
        case compact
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .compact: return 14
            case .regular: return 18
            case .large: return 22
            }
        }

        var valueFont: Font {
            switch self {
            case .compact: return AppTypography.calloutEmphasized
            case .regular: return AppTypography.title2
            case .large: return AppTypography.title
            }
        }

        var padding: CGFloat {
            switch self {
            case .compact: return AppSpacing.sm
            case .regular: return AppSpacing.md
            case .large: return AppSpacing.lg
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: size == .compact ? AppSpacing.xs : AppSpacing.sm) {
            // Header with icon
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(size == .compact ? AppTypography.caption : AppTypography.secondary)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                if let trend = trend {
                    TrendBadge(trend: trend, compact: size == .compact)
                }
            }

            // Value
            Text(value)
                .font(size.valueFont)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(size.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
        .cardShadow()
    }
}

struct TrendData {
    let value: Double // e.g., 0.15 for +15%
    let isPositive: Bool

    var formattedValue: String {
        let prefix = isPositive ? "+" : ""
        return "\(prefix)\(Int(value * 100))%"
    }

    var color: Color {
        isPositive ? .green : .red
    }

    var icon: String {
        isPositive ? "arrow.up.right" : "arrow.down.right"
    }
}

struct TrendBadge: View {
    let trend: TrendData
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.system(size: compact ? 8 : 10, weight: .bold))
            Text(trend.formattedValue)
                .font(compact ? .system(size: 10, weight: .semibold) : AppTypography.captionEmphasized)
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, compact ? 2 : 3)
        .background(trend.color.opacity(0.15))
        .cornerRadius(AppCornerRadius.xs)
    }
}

// MARK: - Chart Card

/// A container for charts with title and optional actions
struct ChartCard<Content: View>: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(AppTypography.captionEmphasized)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }

            // Chart content
            content()
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
        .cardShadow()
    }
}

// MARK: - Section Container

/// A collapsible section container for grouping related content
struct SectionContainer<Content: View>: View {
    let title: String
    var icon: String?
    var iconColor: Color = AppColors.primary
    var isCollapsible: Bool = true
    @State private var isExpanded: Bool = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section header
            Button(action: {
                if isCollapsible {
                    withAnimation(AppAnimation.standard) {
                        isExpanded.toggle()
                    }
                    HapticFeedback.light()
                }
            }) {
                HStack(spacing: AppSpacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(iconColor)
                            .frame(width: 24, height: 24)
                            .background(iconColor.opacity(0.15))
                            .cornerRadius(AppCornerRadius.xs)
                    }

                    Text(title)
                        .font(AppTypography.section)
                        .foregroundColor(.primary)

                    Spacer()

                    if isCollapsible {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    }
                }
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Insight Alert Card

/// A card for displaying alerts and insights
struct InsightAlertCard: View {
    let alert: AnalyticsAlert
    var onAction: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Severity icon
            Image(systemName: alert.severity.icon)
                .font(.system(size: 20))
                .foregroundColor(alert.severity.color)
                .frame(width: 36, height: 36)
                .background(alert.severity.color.opacity(0.15))
                .cornerRadius(AppCornerRadius.sm)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(alert.title)
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(.primary)

                Text(alert.message)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Action button
                if let actionTitle = alert.actionTitle, let onAction = onAction {
                    Button(action: onAction) {
                        Text(actionTitle)
                            .font(AppTypography.captionEmphasized)
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.top, AppSpacing.xxs)
                }
            }

            Spacer()

            // Dismiss button
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(AppSpacing.xs)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(alert.severity.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(alert.severity.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Stats Row

/// A horizontal row of quick stats
struct StatsRow: View {
    let stats: [StatItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                VStack(spacing: AppSpacing.xxs) {
                    Text(stat.value)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(stat.label)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                if index < stats.count - 1 {
                    Divider()
                        .frame(height: 40)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
        .cardShadow()
    }
}

struct StatItem: Identifiable {
    let id: UUID
    let label: String
    let value: String

    init(id: UUID = UUID(), label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

// MARK: - Health Score Badge

struct HealthScoreBadge: View {
    let score: Int // 0-100

    private var color: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    private var label: String {
        switch score {
        case 80...: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Attention"
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressRingView(
                progress: Double(score) / 100.0,
                size: 50,
                lineWidth: 6,
                color: color
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Health Score")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Text(label)
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(color)
            }
        }
        .padding(AppSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Traffic Source Row

struct TrafficSourceRow: View {
    let source: TrafficSourceData

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: source.icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(AppCornerRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.source)
                    .font(AppTypography.callout)
                    .foregroundColor(.primary)

                Text("\(source.visits) visits")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(source.percentage * 100))%")
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(.primary)

                Text("\(source.conversions) sales")
                    .font(AppTypography.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Tier Sales Row

struct TierSalesRow: View {
    let tier: TierSalesData

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Circle()
                    .fill(Color(hex: tier.color))
                    .frame(width: 10, height: 10)

                Text(tier.tierName)
                    .font(AppTypography.callout)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(tier.sold)/\(tier.capacity)")
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(.primary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                        .fill(Color(hex: tier.color))
                        .frame(width: geometry.size.width * CGFloat(tier.percentage))
                }
            }
            .frame(height: 6)

            HStack {
                Text(formatCurrency(tier.revenue))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if tier.isSoldOut {
                    Text("SOLD OUT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(AppCornerRadius.xs)
                } else {
                    Text("\(tier.remainingTickets) left")
                        .font(AppTypography.caption)
                        .foregroundColor(tier.remainingTickets < 20 ? .orange : .secondary)
                }
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

// MARK: - Time Badge

struct TimeBadge: View {
    let time: String
    let label: String
    var icon: String = "clock"

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)

            Text(time)
                .font(AppTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Previews

#Preview("Metric Card") {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            MetricCard(
                title: "Revenue",
                value: "UGX 12.4M",
                icon: "banknote",
                trend: TrendData(value: 0.15, isPositive: true),
                color: .green
            )

            MetricCard(
                title: "Tickets Sold",
                value: "342",
                icon: "ticket",
                subtitle: "68% of capacity",
                color: .orange
            )
        }

        MetricCard(
            title: "Views",
            value: "4,850",
            icon: "eye",
            trend: TrendData(value: -0.05, isPositive: false),
            color: .blue,
            size: .compact
        )
    }
    .padding()
}

#Preview("Section Container") {
    SectionContainer(title: "Sales Performance", icon: "chart.line.uptrend.xyaxis", iconColor: .blue) {
        VStack {
            Text("Chart would go here")
            Text("More content")
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
}

#Preview("Insight Alert") {
    VStack(spacing: 12) {
        InsightAlertCard(
            alert: AnalyticsAlert(
                type: .nearSellOut,
                title: "Near Sell-out",
                message: "Early Bird tickets are sold out! Consider adding more.",
                severity: .success,
                actionTitle: "Manage Tickets"
            ),
            onAction: {},
            onDismiss: {}
        )

        InsightAlertCard(
            alert: AnalyticsAlert(
                type: .lowSales,
                title: "Sales Slow Down",
                message: "Sales velocity dropped 30% this week.",
                severity: .warning
            )
        )
    }
    .padding()
}

#Preview("Health Score") {
    HStack(spacing: 16) {
        HealthScoreBadge(score: 82)
        HealthScoreBadge(score: 65)
        HealthScoreBadge(score: 35)
    }
    .padding()
}

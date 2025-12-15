//
//  DashboardComponents.swift
//  EventPassUG
//
//  Compact, reusable dashboard components for organizer views
//  Optimized for information density and readability
//

import SwiftUI

// MARK: - Compact Metric Card

/// Compact metric card for dashboard statistics
/// Reduced height and tighter spacing for improved density
struct CompactMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppDesign.Typography.cardTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(AppDesign.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppDesign.CornerRadius.card)
        .subtleShadow()
    }
}

// MARK: - Progress Bar View

/// Reusable horizontal progress bar with label and value
/// Animates smoothly and adapts to container width
struct ProgressBarView: View {
    let label: String
    let current: Int
    let total: Int
    let color: Color
    let backgroundColor: Color
    let showPercentage: Bool

    init(
        label: String,
        current: Int,
        total: Int,
        color: Color = AppDesign.Colors.primary,
        backgroundColor: Color = Color(UIColor.systemGray6),
        showPercentage: Bool = true
    ) {
        self.label = label
        self.current = current
        self.total = total
        self.color = color
        self.backgroundColor = backgroundColor
        self.showPercentage = showPercentage
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(current) / Double(total), 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label and value
            HStack {
                Text(label)
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(current) / \(total)")
                        .font(AppDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if showPercentage {
                        Text("(\(percentage)%)")
                            .font(AppDesign.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(backgroundColor)
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(0, geometry.size.width * progress), height: 6)
                        .animation(AppDesign.Animation.spring, value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Currency Progress Bar View

/// Progress bar for currency/revenue with formatted values
struct CurrencyProgressBarView: View {
    let label: String
    let current: Double
    let total: Double
    let currency: String
    let color: Color
    let backgroundColor: Color
    let showPercentage: Bool

    init(
        label: String,
        current: Double,
        total: Double,
        currency: String = "UGX",
        color: Color = Color.green,
        backgroundColor: Color = Color(UIColor.systemGray6),
        showPercentage: Bool = true
    ) {
        self.label = label
        self.current = current
        self.total = total
        self.currency = currency
        self.color = color
        self.backgroundColor = backgroundColor
        self.showPercentage = showPercentage
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(current / total, 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return "\(Int(value))"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label and value
            HStack {
                Text(label)
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(currency) \(formatCurrency(current)) / \(formatCurrency(total))")
                        .font(AppDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if showPercentage {
                        Text("(\(percentage)%)")
                            .font(AppDesign.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(backgroundColor)
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(0, geometry.size.width * progress), height: 6)
                        .animation(AppDesign.Animation.spring, value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Event Dashboard Card

/// Event card with dual progress bars (tickets & revenue)
/// Compact layout with clear visual hierarchy
struct EventDashboardCard: View {
    let event: Event

    private var totalTickets: Int {
        event.ticketTypes.reduce(0) { $0 + $1.quantity }
    }

    private var soldTickets: Int {
        event.ticketTypes.reduce(0) { $0 + $1.sold }
    }

    private var totalRevenue: Double {
        event.ticketTypes.reduce(0.0) { $0 + (Double($1.sold) * $1.price) }
    }

    private var potentialRevenue: Double {
        event.ticketTypes.reduce(0.0) { $0 + (Double($1.quantity) * $1.price) }
    }

    private var statusColor: Color {
        switch event.status {
        case .published: return AppDesign.Colors.success
        case .ongoing: return AppDesign.Colors.primary
        case .draft: return AppDesign.Colors.warning
        case .completed: return Color.gray
        case .cancelled: return AppDesign.Colors.error
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            // Header: Title and status
            HStack(alignment: .top, spacing: AppDesign.Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(AppDesign.Typography.cardTitle)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(DateUtilities.formatEventDateTime(event.startDate))
                        .font(AppDesign.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(event.status.rawValue.capitalized)
                        .font(AppDesign.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(AppDesign.CornerRadius.badge)
            }

            Divider()
                .padding(.vertical, 2)

            // Progress bars
            VStack(spacing: AppDesign.Spacing.sm) {
                // Tickets sold progress
                ProgressBarView(
                    label: "Tickets Sold",
                    current: soldTickets,
                    total: totalTickets,
                    color: AppDesign.Colors.primary
                )

                // Revenue progress
                CurrencyProgressBarView(
                    label: "Revenue",
                    current: totalRevenue,
                    total: potentialRevenue,
                    color: AppDesign.Colors.success
                )
            }
        }
        .padding(AppDesign.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppDesign.CornerRadius.card)
        .subtleShadow()
    }
}

// MARK: - Previews

#Preview("Compact Metric Card") {
    VStack(spacing: 16) {
        CompactMetricCard(
            title: "Total Revenue",
            value: "UGX 5.2M",
            icon: "dollarsign.circle.fill",
            color: .green
        )

        CompactMetricCard(
            title: "Tickets Sold",
            value: "1,234",
            icon: "ticket.fill",
            color: AppDesign.Colors.primary
        )

        CompactMetricCard(
            title: "Active Events",
            value: "8",
            icon: "calendar",
            color: .blue
        )
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Progress Bars") {
    VStack(spacing: 20) {
        ProgressBarView(
            label: "Tickets Sold",
            current: 320,
            total: 500
        )

        ProgressBarView(
            label: "Tickets Sold",
            current: 480,
            total: 500
        )

        CurrencyProgressBarView(
            label: "Revenue",
            current: 3_200_000,
            total: 5_000_000
        )

        CurrencyProgressBarView(
            label: "Revenue",
            current: 4_750_000,
            total: 5_000_000
        )
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Event Dashboard Card") {
    EventDashboardCard(event: Event.samples[0])
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
}

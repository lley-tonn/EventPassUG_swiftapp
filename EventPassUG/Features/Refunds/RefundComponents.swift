//
//  RefundComponents.swift
//  EventPassUG
//
//  Reusable UI components for the refund system
//

import SwiftUI

// MARK: - Refund Status Badge

struct RefundStatusBadge: View {
    let status: RefundStatus
    var size: BadgeSize = .regular

    enum BadgeSize {
        case small
        case regular
        case large

        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .regular: return .caption
            case .large: return .subheadline
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .regular: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(size.fontSize)

            Text(status.displayName)
                .font(size.fontSize)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(size.padding)
        .background(status.color)
        .cornerRadius(AppCornerRadius.pill)
    }
}

// MARK: - Refund Reason Picker

struct RefundReasonPicker: View {
    @Binding var selectedReason: RefundReason?
    var availableReasons: [RefundReason] = RefundReason.userSelectableReasons

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Select Reason")
                .font(AppTypography.cardTitle)
                .foregroundColor(.primary)

            VStack(spacing: AppSpacing.xs) {
                ForEach(availableReasons) { reason in
                    ReasonOptionRow(
                        reason: reason,
                        isSelected: selectedReason == reason,
                        onSelect: { selectedReason = reason }
                    )
                }
            }
        }
    }
}

struct ReasonOptionRow: View {
    let reason: RefundReason
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: reason.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : RoleConfig.attendeePrimary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(reason.description)
                        .font(AppTypography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(AppSpacing.md)
            .background(isSelected ? RoleConfig.attendeePrimary : Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Refund Policy View

struct RefundPolicyView: View {
    let policy: RefundPolicy
    var isCompact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(RoleConfig.attendeePrimary)
                Text("Refund Policy")
                    .font(AppTypography.cardTitle)
            }

            if isCompact {
                compactView
            } else {
                fullView
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var compactView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if policy.isRefundable {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Refundable up to \(policy.refundDeadlineHours) hours before event")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Non-refundable")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var fullView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Refundable status
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: policy.isRefundable ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(policy.isRefundable ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(policy.isRefundable ? "Refundable" : "Non-Refundable")
                        .font(AppTypography.calloutEmphasized)
                    if policy.isRefundable {
                        Text("Up to \(policy.refundDeadlineHours) hours before event")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if policy.isRefundable {
                Divider()

                // Time windows
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if let fullDeadline = policy.fullRefundDeadlineHours {
                        PolicyRuleRow(
                            icon: "clock.fill",
                            title: "Full refund",
                            subtitle: "\(fullDeadline)+ hours before event",
                            color: .green
                        )
                    }

                    if let partialDeadline = policy.partialRefundDeadlineHours,
                       let partialPercent = policy.partialRefundPercentage {
                        PolicyRuleRow(
                            icon: "clock",
                            title: "\(Int(partialPercent * 100))% refund",
                            subtitle: "\(partialDeadline)-\(policy.fullRefundDeadlineHours ?? partialDeadline) hours before",
                            color: .orange
                        )
                    }

                    PolicyRuleRow(
                        icon: "xmark.circle",
                        title: "No refund",
                        subtitle: "Less than \(policy.refundDeadlineHours) hours before",
                        color: .red
                    )
                }

                // Processing fee
                if policy.processingFeePercentage > 0 {
                    Divider()
                    HStack {
                        Image(systemName: "percent")
                            .foregroundColor(.secondary)
                        Text("Processing fee: \(Int(policy.processingFeePercentage * 100))%")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Policy text
            if !policy.policyText.isEmpty {
                Divider()
                Text(policy.policyText)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PolicyRuleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppTypography.captionEmphasized)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Refund Timeline View

struct RefundTimelineView: View {
    let statusHistory: [RefundStatusChange]
    var isCompact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(RoleConfig.attendeePrimary)
                Text("Timeline")
                    .font(AppTypography.cardTitle)
            }

            VStack(alignment: .leading, spacing: 0) {
                let displayHistory = isCompact ? Array(statusHistory.suffix(3)) : statusHistory

                ForEach(Array(displayHistory.enumerated()), id: \.element.id) { index, change in
                    TimelineEntry(
                        change: change,
                        isFirst: index == 0,
                        isLast: index == displayHistory.count - 1
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

struct TimelineEntry: View {
    let change: RefundStatusChange
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Timeline line and dot
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 12)
                }

                Circle()
                    .fill(change.toStatus.color)
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 24)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(change.toStatus.displayName)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(change.changedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                if let note = change.note {
                    Text(note)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, isLast ? 0 : AppSpacing.sm)
        }
    }
}

// MARK: - Refund Amount Card

struct RefundAmountCard: View {
    let eligibility: RefundEligibilityResult

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Refund amount
            VStack(spacing: AppSpacing.xs) {
                Text("Refund Amount")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Text(formatCurrency(eligibility.netRefund))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }

            // Breakdown
            VStack(spacing: AppSpacing.xs) {
                HStack {
                    Text("Ticket Price")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(eligibility.refundableAmount))
                        .font(AppTypography.captionEmphasized)
                }

                if eligibility.refundPercentage < 1.0 {
                    HStack {
                        Text("Refund Rate")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(eligibility.refundPercentage * 100))%")
                            .font(AppTypography.captionEmphasized)
                            .foregroundColor(.orange)
                    }
                }

                if eligibility.processingFee > 0 {
                    HStack {
                        Text("Processing Fee")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("-\(formatCurrency(eligibility.processingFee))")
                            .font(AppTypography.captionEmphasized)
                            .foregroundColor(.red)
                    }
                }

                Divider()

                HStack {
                    Text("You'll Receive")
                        .font(AppTypography.calloutEmphasized)
                    Spacer()
                    Text(formatCurrency(eligibility.netRefund))
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.green)
                }
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(AppCornerRadius.sm)

            // Deadline warning
            if let deadline = eligibility.deadline {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Request by \(deadline.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppTypography.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "UGX \(Int(amount))"
    }
}

// MARK: - Refund Request Card

struct RefundRequestCard: View {
    let request: RefundRequest
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.eventTitle)
                            .font(AppTypography.calloutEmphasized)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("Ticket: \(request.ticketNumber)")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    RefundStatusBadge(status: request.status, size: .small)
                }

                Divider()

                // Details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.reason.displayName)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        Text(request.formattedRequestedAmount)
                            .font(AppTypography.calloutEmphasized)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(request.timeSinceRequest)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        if let onTap = onTap {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    VStack(spacing: 20) {
        ForEach(RefundStatus.allCases, id: \.self) { status in
            RefundStatusBadge(status: status)
        }
    }
    .padding()
}

#Preview("Reason Picker") {
    struct PreviewWrapper: View {
        @State private var reason: RefundReason?

        var body: some View {
            RefundReasonPicker(selectedReason: $reason)
                .padding()
        }
    }
    return PreviewWrapper()
}

#Preview("Policy View") {
    VStack(spacing: 20) {
        RefundPolicyView(policy: .sample)
        RefundPolicyView(policy: .sample, isCompact: true)
    }
    .padding()
}

#Preview("Timeline") {
    RefundTimelineView(statusHistory: [
        RefundStatusChange(fromStatus: nil, toStatus: .pending, note: "Request submitted"),
        RefundStatusChange(fromStatus: .pending, toStatus: .approved, changedAt: Date().addingTimeInterval(-3600), note: "Approved by organizer"),
        RefundStatusChange(fromStatus: .approved, toStatus: .processing, changedAt: Date().addingTimeInterval(-1800)),
        RefundStatusChange(fromStatus: .processing, toStatus: .completed, changedAt: Date(), note: "Refund sent to MTN Mobile Money")
    ])
    .padding()
}

#Preview("Request Card") {
    RefundRequestCard(request: RefundRequest.samples[0])
        .padding()
}

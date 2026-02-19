//
//  CancellationComponents.swift
//  EventPassUG
//
//  Reusable UI components for the event cancellation system
//

import SwiftUI

// MARK: - Cancellation Reason Picker

struct CancellationReasonPicker: View {
    @Binding var selectedReason: CancellationReason?
    var availableReasons: [CancellationReason] = CancellationReason.organizerReasons

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Why are you cancelling this event?")
                .font(AppTypography.cardTitle)
                .foregroundColor(.primary)

            VStack(spacing: AppSpacing.xs) {
                ForEach(availableReasons) { reason in
                    CancellationReasonRow(
                        reason: reason,
                        isSelected: selectedReason == reason,
                        onSelect: { selectedReason = reason }
                    )
                }
            }
        }
    }
}

struct CancellationReasonRow: View {
    let reason: CancellationReason
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
                    .foregroundColor(isSelected ? .white : .red)
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
            .background(isSelected ? Color.red : Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cancellation Impact Card

struct CancellationImpactCard: View {
    let impact: CancellationImpact
    var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .foregroundColor(.red)
                Text("Cancellation Impact")
                    .font(AppTypography.cardTitle)
            }

            Divider()

            // Key metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                ImpactMetricView(
                    title: "Tickets Sold",
                    value: "\(impact.ticketsSold)",
                    icon: "ticket.fill",
                    color: .blue
                )

                ImpactMetricView(
                    title: "Attendees",
                    value: "\(impact.attendeesCount)",
                    icon: "person.2.fill",
                    color: .purple
                )

                ImpactMetricView(
                    title: "VIP Tickets",
                    value: "\(impact.vipTickets)",
                    icon: "star.fill",
                    color: .orange
                )

                ImpactMetricView(
                    title: "Refund Total",
                    value: impact.formattedRefundTotal,
                    icon: "ugandishilling.circle.fill",
                    color: .green,
                    isLarge: true
                )
            }

            // Warnings
            if !impact.warnings.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Attention Required")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.orange)

                    ForEach(impact.warnings) { warning in
                        WarningBadge(warning: warning)
                    }
                }
            }

            // Expanded breakdown
            if isExpanded {
                Divider()

                // Ticket type breakdown
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("By Ticket Type")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.secondary)

                    ForEach(impact.ticketTypeBreakdown) { type in
                        HStack {
                            Text(type.name)
                                .font(AppTypography.callout)
                            Spacer()
                            Text("\(type.ticketsSold) tickets")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                            Text(type.formattedRevenue)
                                .font(AppTypography.captionEmphasized)
                        }
                    }
                }

                Divider()

                // Payment method breakdown
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("By Payment Method")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.secondary)

                    ForEach(impact.paymentMethodBreakdown) { method in
                        HStack {
                            Image(systemName: method.paymentMethod.icon)
                                .foregroundColor(.secondary)
                            Text(method.paymentMethod.displayName)
                                .font(AppTypography.callout)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(method.ticketCount) tickets")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                                Text(method.estimatedProcessingTime)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

struct ImpactMetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isLarge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(isLarge ? .system(size: 18, weight: .bold, design: .rounded) : AppTypography.calloutEmphasized)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.sm)
    }
}

struct WarningBadge: View {
    let warning: CancellationWarning

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: warning.icon)
                .foregroundColor(warning.severity.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(warning.title)
                    .font(AppTypography.captionEmphasized)
                    .foregroundColor(.primary)

                Text(warning.description)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(warning.severity.color.opacity(0.1))
        .cornerRadius(AppCornerRadius.sm)
    }
}

// MARK: - Compensation Selector

struct CompensationSelector: View {
    @Binding var compensationType: CompensationType
    @Binding var refundPercentage: Double
    @Binding var creditMultiplier: Double
    let impact: CancellationImpact

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Compensation Plan")
                .font(AppTypography.cardTitle)

            // Compensation type options
            VStack(spacing: AppSpacing.xs) {
                CompensationOption(
                    type: .fullRefund,
                    isSelected: compensationType == .fullRefund,
                    amount: impact.refundTotal,
                    onSelect: {
                        compensationType = .fullRefund
                        refundPercentage = 1.0
                    }
                )

                CompensationOption(
                    type: .partialRefund,
                    isSelected: compensationType == .partialRefund,
                    amount: impact.refundTotal * refundPercentage,
                    onSelect: {
                        compensationType = .partialRefund
                    }
                )

                CompensationOption(
                    type: .eventCredit,
                    isSelected: compensationType == .eventCredit,
                    amount: impact.refundTotal * creditMultiplier,
                    onSelect: {
                        compensationType = .eventCredit
                    }
                )
            }

            // Percentage slider for partial refund
            if compensationType == .partialRefund {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Refund Percentage")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(refundPercentage * 100))%")
                            .font(AppTypography.calloutEmphasized)
                    }

                    Slider(value: $refundPercentage, in: 0.1...1.0, step: 0.1)
                        .tint(.red)

                    Text("Attendees will receive \(formatCurrency(impact.refundTotal * refundPercentage))")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(AppSpacing.md)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.sm)
            }

            // Credit multiplier for event credit
            if compensationType == .eventCredit {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Credit Bonus")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int((creditMultiplier - 1) * 100))% bonus")
                            .font(AppTypography.calloutEmphasized)
                            .foregroundColor(.green)
                    }

                    Slider(value: $creditMultiplier, in: 1.0...1.5, step: 0.05)
                        .tint(.green)

                    Text("Attendees will receive \(formatCurrency(impact.refundTotal * creditMultiplier)) in event credit")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(AppSpacing.md)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.sm)
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

struct CompensationOption: View {
    let type: CompensationType
    let isSelected: Bool
    let amount: Double
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .green)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(type.description)
                        .font(AppTypography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(formatCurrency(amount))
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(isSelected ? .white : .green)
            }
            .padding(AppSpacing.md)
            .background(isSelected ? Color.green : Color(UIColor.tertiarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "UGX \(Int(amount))"
    }
}

// MARK: - Notification Preview Card

struct NotificationPreviewCard: View {
    let preview: NotificationPreview

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.blue)
                Text("Notification Preview")
                    .font(AppTypography.cardTitle)
            }

            Divider()

            // Recipients
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.secondary)
                Text("\(preview.recipientCount) attendees will be notified")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
            }

            // Email preview
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Subject
                HStack {
                    Text("Subject:")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.secondary)
                    Text(preview.subject)
                        .font(AppTypography.callout)
                }

                Divider()

                // Body
                Text(preview.body)
                    .font(AppTypography.caption)
                    .foregroundColor(.primary)
                    .lineLimit(10)
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(AppCornerRadius.sm)

            // Sample recipients
            HStack {
                Text("Sample recipients:")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                Text(preview.sampleRecipients.prefix(3).joined(separator: ", "))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Financial Impact View

struct FinancialImpactView: View {
    let impact: CancellationImpact
    let compensationPlan: CompensationPlan

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "ugandishilling.circle.fill")
                    .foregroundColor(.green)
                Text("Financial Summary")
                    .font(AppTypography.cardTitle)
            }

            Divider()

            // Revenue breakdown
            VStack(spacing: AppSpacing.sm) {
                FinancialRow(title: "Gross Revenue", amount: impact.grossRevenue, isPositive: true)
                FinancialRow(title: "Platform Fees (Waived)", amount: impact.platformFeesRetained, isPositive: false, isWaived: true)
                FinancialRow(title: "Processing Fees", amount: impact.processingFeesEstimate, isPositive: false)

                Divider()

                FinancialRow(title: "Total Refund to Attendees", amount: impact.netRefundAmount, isPositive: false, isTotal: true)

                Divider()

                // Organizer impact
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Payout Adjustment")
                            .font(AppTypography.callout)
                            .foregroundColor(.primary)
                        Text("Amount deducted from your earnings")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(formatCurrency(impact.organizerPayoutAdjustment))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                }
                .padding(AppSpacing.md)
                .background(Color.red.opacity(0.1))
                .cornerRadius(AppCornerRadius.sm)
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

struct FinancialRow: View {
    let title: String
    let amount: Double
    var isPositive: Bool = true
    var isWaived: Bool = false
    var isTotal: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? AppTypography.calloutEmphasized : AppTypography.callout)
                .foregroundColor(isTotal ? .primary : .secondary)
                .strikethrough(isWaived)

            Spacer()

            Text(formatCurrency(amount, showSign: !isPositive && !isWaived))
                .font(isTotal ? AppTypography.calloutEmphasized : AppTypography.callout)
                .foregroundColor(isWaived ? .secondary : (isPositive ? .green : .red))
                .strikethrough(isWaived)
        }
    }

    private func formatCurrency(_ amount: Double, showSign: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "UGX \(Int(abs(amount)))"
        return showSign && amount != 0 ? "-\(formatted)" : formatted
    }
}

// MARK: - Cancellation Confirm View

struct CancellationConfirmView: View {
    @Binding var confirmationText: String
    let isValid: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Warning header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Final Confirmation Required")
                        .font(AppTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    Text("This action cannot be undone")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Confirmation instructions
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("To confirm cancellation, type CONFIRM below:")
                    .font(AppTypography.callout)
                    .foregroundColor(.primary)

                TextField("Type CONFIRM", text: $confirmationText)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(AppCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .stroke(isValid ? Color.red : Color.gray.opacity(0.3), lineWidth: isValid ? 2 : 1)
                    )

                if !confirmationText.isEmpty && !isValid {
                    Text("Please type CONFIRM exactly")
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
            }

            // Confirm button
            Button(action: onConfirm) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel Event Permanently")
                }
                .font(AppTypography.buttonPrimary)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(isValid ? Color.red : Color.gray)
                .cornerRadius(AppCornerRadius.md)
            }
            .disabled(!isValid)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(Color.red.opacity(0.5), lineWidth: 2)
        )
    }
}

// MARK: - Cancellation Status Badge

struct CancellationStatusBadge: View {
    let status: CancellationStatus
    var size: BadgeSize = .regular

    enum BadgeSize {
        case small, regular, large

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

// MARK: - Processing Progress View

struct CancellationProgressView: View {
    let progress: CancellationProgress

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress.progress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress.progress)

                VStack {
                    Text("\(Int(progress.progress * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text(progress.phase.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)

            // Status message
            Text(progress.message)
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Step indicator
            Text("Step \(progress.currentStep) of \(progress.totalSteps)")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Previews

#Preview("Reason Picker") {
    struct PreviewWrapper: View {
        @State private var reason: CancellationReason?

        var body: some View {
            CancellationReasonPicker(selectedReason: $reason)
                .padding()
        }
    }
    return PreviewWrapper()
}

#Preview("Impact Card") {
    CancellationImpactCard(impact: EventCancellation.sample.impact, isExpanded: true)
        .padding()
}

#Preview("Compensation Selector") {
    struct PreviewWrapper: View {
        @State private var type: CompensationType = .fullRefund
        @State private var percentage: Double = 1.0
        @State private var multiplier: Double = 1.1

        var body: some View {
            CompensationSelector(
                compensationType: $type,
                refundPercentage: $percentage,
                creditMultiplier: $multiplier,
                impact: EventCancellation.sample.impact
            )
            .padding()
        }
    }
    return PreviewWrapper()
}

#Preview("Confirm View") {
    struct PreviewWrapper: View {
        @State private var text = ""

        var body: some View {
            CancellationConfirmView(
                confirmationText: $text,
                isValid: text.uppercased() == "CONFIRM",
                onConfirm: {}
            )
            .padding()
        }
    }
    return PreviewWrapper()
}

#Preview("Status Badges") {
    VStack(spacing: 20) {
        ForEach(CancellationStatus.allCases, id: \.self) { status in
            CancellationStatusBadge(status: status)
        }
    }
    .padding()
}

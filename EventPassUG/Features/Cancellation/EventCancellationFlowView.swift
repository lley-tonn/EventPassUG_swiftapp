//
//  EventCancellationFlowView.swift
//  EventPassUG
//
//  Multi-step wizard for event cancellation with safety confirmations
//

import SwiftUI
import Combine

// MARK: - Cancellation Flow View

struct EventCancellationFlowView: View {
    let event: Event

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EventCancellationViewModel

    init(event: Event) {
        self.event = event
        _viewModel = StateObject(wrappedValue: EventCancellationViewModel(event: event))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isProcessing {
                    processingView
                } else if let cancellation = viewModel.completedCancellation {
                    completionView(cancellation: cancellation)
                } else {
                    stepContent
                }
            }
            .navigationTitle("Cancel Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !viewModel.isProcessing && viewModel.completedCancellation == nil {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .interactiveDismissDisabled(viewModel.isProcessing)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 0) {
            // Progress indicator
            stepProgressBar

            // Content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    switch viewModel.currentStep {
                    case .reason:
                        reasonStep
                    case .impact:
                        impactStep
                    case .compensation:
                        compensationStep
                    case .notification:
                        notificationStep
                    case .financial:
                        financialStep
                    case .confirm:
                        confirmStep
                    }
                }
                .padding(AppSpacing.md)
            }

            // Navigation buttons
            navigationButtons
        }
    }

    // MARK: - Progress Bar

    private var stepProgressBar: some View {
        VStack(spacing: AppSpacing.sm) {
            // Step indicators
            HStack(spacing: 4) {
                ForEach(CancellationStep.allCases, id: \.self) { step in
                    Rectangle()
                        .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.red : Color.gray.opacity(0.3))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, AppSpacing.md)

            // Step label
            Text("Step \(viewModel.currentStep.rawValue + 1) of \(CancellationStep.allCases.count): \(viewModel.currentStep.title)")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, AppSpacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
    }

    // MARK: - Step 1: Reason

    private var reasonStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Event info
            eventInfoCard

            // Reason picker
            CancellationReasonPicker(selectedReason: $viewModel.selectedReason)

            // Optional note
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Additional Details (Optional)")
                    .font(AppTypography.cardTitle)

                TextEditor(text: $viewModel.reasonNote)
                    .frame(minHeight: 80)
                    .padding(AppSpacing.sm)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(AppCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
    }

    private var eventInfoCard: some View {
        HStack(spacing: AppSpacing.md) {
            // Event poster
            if let posterURL = event.posterURL, let url = URL(string: posterURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(AppCornerRadius.sm)
            } else {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title)
                            .foregroundColor(.red)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppTypography.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Text(event.venue.name)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Step 2: Impact

    private var impactStep: some View {
        VStack(spacing: AppSpacing.lg) {
            // Warning banner
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Review the impact of cancelling this event")
                    .font(AppTypography.callout)
                    .foregroundColor(.primary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(AppCornerRadius.md)

            // Impact card
            if let impact = viewModel.impact {
                CancellationImpactCard(impact: impact, isExpanded: true)
            }
        }
    }

    // MARK: - Step 3: Compensation

    private var compensationStep: some View {
        VStack(spacing: AppSpacing.lg) {
            // Info text
            Text("Choose how attendees will be compensated")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Compensation selector
            if let impact = viewModel.impact {
                CompensationSelector(
                    compensationType: $viewModel.compensationType,
                    refundPercentage: $viewModel.refundPercentage,
                    creditMultiplier: $viewModel.creditMultiplier,
                    impact: impact
                )
            }

            // Processing method
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Processing Method")
                    .font(AppTypography.cardTitle)

                Picker("Processing", selection: $viewModel.processingMethod) {
                    Text("Automatic").tag(CompensationPlan.ProcessingMethod.automatic)
                    Text("Manual").tag(CompensationPlan.ProcessingMethod.manual)
                    Text("Hybrid").tag(CompensationPlan.ProcessingMethod.hybrid)
                }
                .pickerStyle(.segmented)

                Text(processingMethodDescription)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
    }

    private var processingMethodDescription: String {
        switch viewModel.processingMethod {
        case .automatic:
            return "The system will automatically process all refunds. This is the fastest option."
        case .manual:
            return "You will manually process each refund. Choose this if you need custom handling."
        case .hybrid:
            return "System processes standard refunds; you handle exceptions manually."
        }
    }

    // MARK: - Step 4: Notification

    private var notificationStep: some View {
        VStack(spacing: AppSpacing.lg) {
            // Info
            Text("Review the notification that will be sent to all attendees")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Preview
            if let preview = viewModel.notificationPreview {
                NotificationPreviewCard(preview: preview)
            }

            // Custom message option
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Add Personal Message (Optional)")
                    .font(AppTypography.cardTitle)

                TextEditor(text: $viewModel.customNotificationMessage)
                    .frame(minHeight: 60)
                    .padding(AppSpacing.sm)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(AppCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                Text("This message will be appended to the standard notification")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
    }

    // MARK: - Step 5: Financial

    private var financialStep: some View {
        VStack(spacing: AppSpacing.lg) {
            // Info
            Text("Review the financial impact of this cancellation")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Financial summary
            if let impact = viewModel.impact {
                FinancialImpactView(
                    impact: impact,
                    compensationPlan: viewModel.buildCompensationPlan()
                )
            }

            // Acknowledgement
            Toggle(isOn: $viewModel.acknowledgedFinancialImpact) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I understand the financial impact")
                        .font(AppTypography.calloutEmphasized)
                    Text("I acknowledge that refunds will be deducted from my earnings")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
    }

    // MARK: - Step 6: Confirm

    private var confirmStep: some View {
        VStack(spacing: AppSpacing.lg) {
            // Summary
            summaryCard

            // Final confirmation
            CancellationConfirmView(
                confirmationText: $viewModel.confirmationText,
                isValid: viewModel.isConfirmationValid,
                onConfirm: {
                    Task {
                        await viewModel.confirmCancellation()
                    }
                }
            )
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Cancellation Summary")
                .font(AppTypography.cardTitle)

            Divider()

            // Event
            SummaryRow(label: "Event", value: event.title)

            // Reason
            if let reason = viewModel.selectedReason {
                SummaryRow(label: "Reason", value: reason.displayName)
            }

            // Tickets affected
            if let impact = viewModel.impact {
                SummaryRow(label: "Tickets Affected", value: "\(impact.ticketsSold)")
                SummaryRow(label: "Attendees to Notify", value: "\(impact.attendeesCount)")
            }

            // Compensation
            SummaryRow(label: "Compensation", value: viewModel.compensationType.displayName)

            // Refund amount
            if let impact = viewModel.impact {
                SummaryRow(label: "Total Refunds", value: impact.formattedRefundTotal, valueColor: .red)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: AppSpacing.md) {
            // Back button
            if viewModel.currentStep != .reason {
                Button(action: {
                    viewModel.previousStep()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(AppTypography.buttonSecondary)
                    .foregroundColor(.primary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.md)
                }
            }

            Spacer()

            // Next/Continue button
            if viewModel.currentStep != .confirm {
                Button(action: {
                    Task {
                        await viewModel.nextStep()
                    }
                }) {
                    HStack {
                        Text(viewModel.currentStep == .financial ? "Review & Confirm" : "Continue")
                        Image(systemName: "chevron.right")
                    }
                    .font(AppTypography.buttonPrimary)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(viewModel.canProceed ? Color.red : Color.gray)
                    .cornerRadius(AppCornerRadius.md)
                }
                .disabled(!viewModel.canProceed)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Calculating impact...")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: AppSpacing.xl) {
            if let progress = viewModel.processingProgress {
                CancellationProgressView(progress: progress)
            } else {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Processing cancellation...")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
            }

            Text("Please do not close this screen")
                .font(AppTypography.caption)
                .foregroundColor(.orange)
        }
    }

    // MARK: - Completion View

    private func completionView(cancellation: EventCancellation) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                // Success icon
                Image(systemName: cancellation.hasErrors ? "checkmark.circle.trianglebadge.exclamationmark" : "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(cancellation.hasErrors ? .orange : .green)

                // Title
                VStack(spacing: AppSpacing.sm) {
                    Text("Event Cancelled")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    if cancellation.hasErrors {
                        Text("Completed with some errors")
                            .font(AppTypography.callout)
                            .foregroundColor(.orange)
                    } else {
                        Text("All attendees have been notified and refunds initiated")
                            .font(AppTypography.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Stats
                HStack(spacing: AppSpacing.lg) {
                    CompletionStat(
                        icon: "ticket.fill",
                        value: "\(cancellation.refundsProcessed)",
                        label: "Refunds Processed",
                        color: .green
                    )

                    CompletionStat(
                        icon: "bell.fill",
                        value: "\(cancellation.notificationsSent)",
                        label: "Notifications Sent",
                        color: .blue
                    )
                }

                // Errors if any
                if cancellation.refundsFailed > 0 {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(cancellation.refundsFailed) refunds failed")
                                .font(AppTypography.calloutEmphasized)
                        }

                        Text("You can retry these from the dashboard")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(AppCornerRadius.md)
                }

                // Done button
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(AppTypography.buttonPrimary)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.md)
                        .background(Color.green)
                        .cornerRadius(AppCornerRadius.md)
                }
                .padding(.top, AppSpacing.lg)

                Spacer()
            }
            .padding(AppSpacing.md)
        }
    }
}

// MARK: - Supporting Views

struct SummaryRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(AppTypography.calloutEmphasized)
                .foregroundColor(valueColor)
        }
    }
}

struct CompletionStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Cancellation Steps

enum CancellationStep: Int, CaseIterable {
    case reason = 0
    case impact = 1
    case compensation = 2
    case notification = 3
    case financial = 4
    case confirm = 5

    var title: String {
        switch self {
        case .reason: return "Select Reason"
        case .impact: return "Review Impact"
        case .compensation: return "Compensation Plan"
        case .notification: return "Notification Preview"
        case .financial: return "Financial Summary"
        case .confirm: return "Confirm Cancellation"
        }
    }
}

// MARK: - View Model

@MainActor
class EventCancellationViewModel: ObservableObject {
    let event: Event

    // Current state
    @Published var currentStep: CancellationStep = .reason
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage: String?

    // Step 1: Reason
    @Published var selectedReason: CancellationReason?
    @Published var reasonNote: String = ""

    // Step 2: Impact
    @Published var impact: CancellationImpact?

    // Step 3: Compensation
    @Published var compensationType: CompensationType = .fullRefund
    @Published var refundPercentage: Double = 1.0
    @Published var creditMultiplier: Double = 1.1
    @Published var processingMethod: CompensationPlan.ProcessingMethod = .automatic

    // Step 4: Notification
    @Published var notificationPreview: NotificationPreview?
    @Published var customNotificationMessage: String = ""

    // Step 5: Financial
    @Published var acknowledgedFinancialImpact = false

    // Step 6: Confirm
    @Published var confirmationText: String = ""

    // Processing
    @Published var processingProgress: CancellationProgress?
    @Published var completedCancellation: EventCancellation?

    // Internal
    private var cancellation: EventCancellation?
    private var cancellationService: CancellationRepositoryProtocol?
    private var cancellables = Set<AnyCancellable>()

    var canProceed: Bool {
        switch currentStep {
        case .reason:
            return selectedReason != nil
        case .impact:
            return impact != nil
        case .compensation:
            return true
        case .notification:
            return true
        case .financial:
            return acknowledgedFinancialImpact
        case .confirm:
            return isConfirmationValid
        }
    }

    var isConfirmationValid: Bool {
        confirmationText.uppercased() == "CONFIRM"
    }

    init(event: Event) {
        self.event = event
    }

    func nextStep() async {
        guard canProceed else { return }

        switch currentStep {
        case .reason:
            await calculateImpact()
            if impact != nil {
                currentStep = .impact
            }

        case .impact:
            currentStep = .compensation

        case .compensation:
            generateNotificationPreview()
            currentStep = .notification

        case .notification:
            currentStep = .financial

        case .financial:
            currentStep = .confirm

        case .confirm:
            break
        }
    }

    func previousStep() {
        guard let previousIndex = CancellationStep.allCases.firstIndex(of: currentStep),
              previousIndex > 0 else { return }

        currentStep = CancellationStep.allCases[previousIndex - 1]
    }

    private func calculateImpact() async {
        isLoading = true

        let service = await getService()

        do {
            impact = try await service.calculateImpact(eventId: event.id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    private func generateNotificationPreview() {
        guard let impact = impact else { return }

        // Build temporary cancellation for preview
        let plan = buildCompensationPlan()
        let tempCancellation = EventCancellation(
            eventId: event.id,
            eventTitle: event.title,
            organizerId: event.organizerId,
            reason: selectedReason ?? .organizerDecision,
            reasonNote: reasonNote,
            impact: impact,
            compensationPlan: plan,
            initiatedBy: UUID()
        )

        Task {
            let service = await getService()
            notificationPreview = service.previewNotification(cancellation: tempCancellation)
        }
    }

    func buildCompensationPlan() -> CompensationPlan {
        CompensationPlan(
            eventId: event.id,
            compensationType: compensationType,
            refundPercentage: refundPercentage,
            creditMultiplier: compensationType == .eventCredit ? creditMultiplier : nil,
            processingMethod: processingMethod,
            totalRefundAmount: (impact?.refundTotal ?? 0) * refundPercentage,
            organizerNote: customNotificationMessage.isEmpty ? nil : customNotificationMessage,
            notificationTemplate: .defaultCancellation
        )
    }

    func confirmCancellation() async {
        guard isConfirmationValid, let reason = selectedReason, impact != nil else { return }

        isProcessing = true

        let service = await getService()

        // Subscribe to progress updates
        service.processingProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.processingProgress = progress
            }
            .store(in: &cancellables)

        do {
            // Create cancellation
            var cancellation = try await service.createCancellation(
                event: event,
                reason: reason,
                note: reasonNote.isEmpty ? nil : reasonNote,
                initiatedBy: UUID()
            )

            // Update compensation plan
            let plan = buildCompensationPlan()
            cancellation = try await service.updateCompensationPlan(
                cancellationId: cancellation.id,
                plan: plan
            )

            // Confirm
            cancellation = try await service.confirmCancellation(
                cancellationId: cancellation.id,
                confirmationCode: confirmationText,
                confirmedBy: UUID()
            )

            // Process
            cancellation = try await service.processCancellation(cancellationId: cancellation.id)

            completedCancellation = cancellation

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isProcessing = false
    }

    private func getService() async -> CancellationRepositoryProtocol {
        if let service = cancellationService {
            return service
        }
        let service = MockCancellationRepository()
        cancellationService = service
        return service
    }
}

// MARK: - Previews

#Preview("Cancellation Flow") {
    EventCancellationFlowView(event: Event.samples[0])
}

#Preview("Completion View") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Event Cancelled")
                    .font(.title)
                    .fontWeight(.bold)

                HStack(spacing: 20) {
                    CompletionStat(icon: "ticket.fill", value: "142", label: "Refunds Processed", color: .green)
                    CompletionStat(icon: "bell.fill", value: "142", label: "Notifications Sent", color: .blue)
                }
            }
            .padding()
        }
    }
}

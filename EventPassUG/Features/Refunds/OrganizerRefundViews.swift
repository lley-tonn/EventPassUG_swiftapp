//
//  OrganizerRefundViews.swift
//  EventPassUG
//
//  Organizer-facing views for managing refund requests
//

import SwiftUI

// MARK: - Organizer Refund List View

struct OrganizerRefundListView: View {
    let eventId: UUID?

    @EnvironmentObject var services: ServiceContainer
    @StateObject private var viewModel = OrganizerRefundListViewModel()
    @State private var selectedRequest: RefundRequest?
    @State private var showDecisionSheet = false

    init(eventId: UUID? = nil) {
        self.eventId = eventId
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.requests.isEmpty {
                loadingView
            } else if viewModel.requests.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("Refund Requests")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(RefundFilterOption.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel.selectedFilter = option
                        }) {
                            HStack {
                                Text(option.displayName)
                                if viewModel.selectedFilter == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showDecisionSheet) {
            if let request = selectedRequest {
                RefundDecisionSheet(request: request, viewModel: viewModel)
            }
        }
        .refreshable {
            await viewModel.loadRequests(eventId: eventId)
        }
        .onAppear {
            Task {
                await viewModel.loadRequests(eventId: eventId)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading refund requests...")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "arrow.uturn.backward.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Refund Requests")
                .font(AppTypography.title3)
                .fontWeight(.semibold)

            Text(viewModel.selectedFilter == .all
                 ? "You haven't received any refund requests yet."
                 : "No requests match the selected filter.")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                // Summary cards
                summaryCards

                // Filter indicator
                if viewModel.selectedFilter != .all {
                    filterIndicator
                }

                // Request list
                ForEach(viewModel.filteredRequests) { request in
                    OrganizerRefundRequestCard(request: request) {
                        selectedRequest = request
                        showDecisionSheet = true
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.sm) {
            SummaryStatCard(
                title: "Pending",
                value: "\(viewModel.pendingCount)",
                icon: "clock.fill",
                color: .orange
            )

            SummaryStatCard(
                title: "This Month",
                value: viewModel.formattedMonthlyRefunds,
                icon: "ugandishilling.circle.fill",
                color: .blue
            )

            SummaryStatCard(
                title: "Approved",
                value: "\(viewModel.approvedCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            SummaryStatCard(
                title: "Rejected",
                value: "\(viewModel.rejectedCount)",
                icon: "xmark.circle.fill",
                color: .red
            )
        }
    }

    private var filterIndicator: some View {
        HStack {
            Text("Showing: \(viewModel.selectedFilter.displayName)")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Clear") {
                viewModel.selectedFilter = .all
            }
            .font(AppTypography.caption)
            .foregroundColor(RoleConfig.organizerPrimary)
        }
        .padding(.horizontal, AppSpacing.sm)
    }
}

// MARK: - Summary Stat Card

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Organizer Refund Request Card

struct OrganizerRefundRequestCard: View {
    let request: RefundRequest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
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

                // User info
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.userName ?? "Unknown User")
                            .font(AppTypography.captionEmphasized)
                            .foregroundColor(.primary)

                        Text(request.userEmail ?? "No email")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Reason and amount
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

                        if request.status == .pending {
                            Text("Action Required")
                                .font(AppTypography.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                // User note preview
                if let note = request.userNote, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Customer Note:")
                            .font(AppTypography.captionEmphasized)
                            .foregroundColor(.secondary)

                        Text(note)
                            .font(AppTypography.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    .padding(AppSpacing.sm)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(AppCornerRadius.sm)
                }

                // Action indicator
                HStack {
                    Spacer()

                    HStack(spacing: 4) {
                        Text("Review")
                            .font(AppTypography.caption)
                            .foregroundColor(RoleConfig.organizerPrimary)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Refund Decision Sheet

struct RefundDecisionSheet: View {
    let request: RefundRequest
    @ObservedObject var viewModel: OrganizerRefundListViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAction: RefundDecision = .approve
    @State private var reviewerNote: String = ""
    @State private var approvedAmount: Double = 0
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    enum RefundDecision: String, CaseIterable {
        case approve = "Approve"
        case partialApprove = "Partial Approve"
        case reject = "Reject"

        var color: Color {
            switch self {
            case .approve: return .green
            case .partialApprove: return .orange
            case .reject: return .red
            }
        }

        var icon: String {
            switch self {
            case .approve: return "checkmark.circle.fill"
            case .partialApprove: return "minus.circle.fill"
            case .reject: return "xmark.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Request summary
                    requestSummary

                    // Decision options
                    if request.status == .pending {
                        decisionSection

                        // Partial amount (if applicable)
                        if selectedAction == .partialApprove {
                            partialAmountSection
                        }

                        // Reviewer note
                        noteSection

                        // Action button
                        actionButton
                    } else {
                        currentStatusSection
                    }

                    // Timeline
                    if !request.statusHistory.isEmpty {
                        RefundTimelineView(statusHistory: request.statusHistory)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Review Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Decision", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button(selectedAction.rawValue, role: selectedAction == .reject ? .destructive : nil) {
                    Task {
                        await submitDecision()
                    }
                }
            } message: {
                Text(confirmationMessage)
            }
        }
        .onAppear {
            approvedAmount = request.requestedAmount
        }
    }

    private var requestSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.eventTitle)
                        .font(AppTypography.title3)
                        .fontWeight(.semibold)

                    Text("Ticket: \(request.ticketNumber)")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                RefundStatusBadge(status: request.status)
            }

            Divider()

            // User info
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.userName ?? "Unknown User")
                        .font(AppTypography.calloutEmphasized)

                    Text(request.userEmail ?? "No email")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    if let phone = request.userPhone {
                        Text(phone)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Divider()

            // Request details
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Text("Reason")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(request.reason.displayName)
                        .font(AppTypography.calloutEmphasized)
                }

                HStack {
                    Text("Requested Amount")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(request.formattedRequestedAmount)
                        .font(AppTypography.calloutEmphasized)
                }

                HStack {
                    Text("Original Purchase Date")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(request.originalPurchaseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTypography.calloutEmphasized)
                }

                HStack {
                    Text("Requested On")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(request.requestedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.callout)
                }
            }

            // User note
            if let note = request.userNote, !note.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Customer's Note")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.secondary)

                    Text(note)
                        .font(AppTypography.callout)
                        .foregroundColor(.primary)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.sm)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var decisionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your Decision")
                .font(AppTypography.cardTitle)

            VStack(spacing: AppSpacing.xs) {
                ForEach(RefundDecision.allCases, id: \.self) { decision in
                    Button(action: {
                        HapticFeedback.selection()
                        selectedAction = decision
                    }) {
                        HStack {
                            Image(systemName: decision.icon)
                                .foregroundColor(selectedAction == decision ? .white : decision.color)

                            Text(decision.rawValue)
                                .font(AppTypography.calloutEmphasized)
                                .foregroundColor(selectedAction == decision ? .white : .primary)

                            Spacer()

                            if selectedAction == decision {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(selectedAction == decision ? decision.color : Color(UIColor.secondarySystemBackground))
                        .cornerRadius(AppCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var partialAmountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Approved Amount")
                .font(AppTypography.cardTitle)

            HStack {
                Text("UGX")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)

                TextField("Amount", value: $approvedAmount, format: .number)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .textFieldStyle(.roundedBorder)
            }

            Text("Maximum: \(formatCurrency(request.requestedAmount))")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Note to Customer (Optional)")
                .font(AppTypography.cardTitle)

            TextEditor(text: $reviewerNote)
                .frame(minHeight: 80)
                .padding(AppSpacing.sm)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            Text("This note will be visible to the customer")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var actionButton: some View {
        Button(action: {
            showConfirmation = true
        }) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: selectedAction.icon)
                    Text("Submit Decision")
                }
            }
            .font(AppTypography.buttonPrimary)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(selectedAction.color)
            .cornerRadius(AppCornerRadius.md)
        }
        .disabled(isSubmitting)
    }

    private var currentStatusSection: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: request.status.icon)
                .font(.system(size: 50))
                .foregroundColor(request.status.color)

            Text("Request is \(request.status.displayName)")
                .font(AppTypography.title3)
                .fontWeight(.semibold)

            if let reviewerNote = request.reviewerNote {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Reviewer Note")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.secondary)

                    Text(reviewerNote)
                        .font(AppTypography.callout)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.sm)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var confirmationMessage: String {
        switch selectedAction {
        case .approve:
            return "Approve full refund of \(formatCurrency(request.requestedAmount))?"
        case .partialApprove:
            return "Approve partial refund of \(formatCurrency(approvedAmount))?"
        case .reject:
            return "Reject this refund request? This action cannot be undone."
        }
    }

    private func submitDecision() async {
        isSubmitting = true

        switch selectedAction {
        case .approve:
            await viewModel.approveRequest(request.id, note: reviewerNote.isEmpty ? nil : reviewerNote)
        case .partialApprove:
            await viewModel.approveRequest(request.id, amount: approvedAmount, note: reviewerNote.isEmpty ? nil : reviewerNote)
        case .reject:
            await viewModel.rejectRequest(request.id, reason: reviewerNote.isEmpty ? "Request rejected by organizer" : reviewerNote)
        }

        isSubmitting = false
        dismiss()
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "UGX \(Int(amount))"
    }
}

// MARK: - Filter Options

enum RefundFilterOption: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    case processing = "Processing"
    case completed = "Completed"

    var displayName: String { rawValue }

    var status: RefundStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        case .approved: return .approved
        case .rejected: return .rejected
        case .processing: return .processing
        case .completed: return .completed
        }
    }
}

// MARK: - View Model

@MainActor
class OrganizerRefundListViewModel: ObservableObject {
    @Published var requests: [RefundRequest] = []
    @Published var selectedFilter: RefundFilterOption = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var refundService: RefundRepositoryProtocol?

    var filteredRequests: [RefundRequest] {
        guard let status = selectedFilter.status else {
            return requests
        }
        return requests.filter { $0.status == status }
    }

    var pendingCount: Int {
        requests.filter { $0.status == .pending }.count
    }

    var approvedCount: Int {
        requests.filter { $0.status == .approved || $0.status == .completed }.count
    }

    var rejectedCount: Int {
        requests.filter { $0.status == .rejected }.count
    }

    var monthlyRefunds: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        return requests
            .filter { $0.requestedAt >= startOfMonth && ($0.status == .completed || $0.status == .approved) }
            .reduce(0) { $0 + ($1.approvedAmount ?? $1.requestedAmount) }
    }

    var formattedMonthlyRefunds: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: monthlyRefunds)) ?? "UGX 0"
    }

    func loadRequests(eventId: UUID?) async {
        let service: RefundRepositoryProtocol
        if let existing = refundService {
            service = existing
        } else if let created = try? await getRefundService() {
            service = created
        } else {
            errorMessage = "Service unavailable"
            return
        }

        isLoading = true

        do {
            if let eventId = eventId {
                requests = try await service.getEventRefundRequests(eventId: eventId, status: nil)
            } else {
                requests = try await service.getOrganizerRefundRequests(organizerId: UUID(), status: nil)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func approveRequest(_ requestId: UUID, amount: Double? = nil, note: String?) async {
        let service: RefundRepositoryProtocol
        if let existing = refundService {
            service = existing
        } else if let created = try? await getRefundService() {
            service = created
        } else {
            return
        }

        do {
            _ = try await service.approveRefund(
                requestId: requestId,
                approvedAmount: amount,
                note: note
            )

            // Refresh list
            await loadRequests(eventId: nil)

            // Track analytics
            RefundAnalyticsTracker.shared.track(.refundApproved, properties: [
                "request_id": requestId.uuidString,
                "amount": amount ?? 0
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rejectRequest(_ requestId: UUID, reason: String) async {
        let service: RefundRepositoryProtocol
        if let existing = refundService {
            service = existing
        } else if let created = try? await getRefundService() {
            service = created
        } else {
            return
        }

        do {
            _ = try await service.rejectRefund(
                requestId: requestId,
                note: reason
            )

            // Refresh list
            await loadRequests(eventId: nil)

            // Track analytics
            RefundAnalyticsTracker.shared.track(.refundRejected, properties: [
                "request_id": requestId.uuidString,
                "reason": reason
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func getRefundService() async throws -> RefundRepositoryProtocol {
        return MockRefundRepository()
    }
}

// MARK: - Manual Refund View

struct ManualRefundView: View {
    let ticket: Ticket
    let event: Event

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: RefundReason = .organizerDecision
    @State private var refundAmount: Double = 0
    @State private var note: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Ticket info
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Ticket Information")
                            .font(AppTypography.cardTitle)

                        HStack {
                            Text("Event")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(ticket.eventTitle)
                                .fontWeight(.medium)
                        }
                        .font(AppTypography.callout)

                        HStack {
                            Text("Ticket")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(ticket.ticketNumber)
                                .fontWeight(.medium)
                        }
                        .font(AppTypography.callout)

                        HStack {
                            Text("Original Price")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(ticket.ticketType.price))
                                .fontWeight(.medium)
                        }
                        .font(AppTypography.callout)
                    }
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.md)

                    // Refund amount
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Refund Amount")
                            .font(AppTypography.cardTitle)

                        HStack {
                            Text("UGX")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)

                            TextField("Amount", value: $refundAmount, format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .textFieldStyle(.roundedBorder)
                        }

                        Button("Set to full amount") {
                            refundAmount = ticket.ticketType.price
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(RoleConfig.organizerPrimary)
                    }
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.md)

                    // Reason
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Reason")
                            .font(AppTypography.cardTitle)

                        Picker("Reason", selection: $selectedReason) {
                            ForEach([RefundReason.organizerDecision, .eventCancelled, .eventRescheduled, .other], id: \.self) { reason in
                                Text(reason.displayName).tag(reason)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.md)

                    // Note
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Internal Note")
                            .font(AppTypography.cardTitle)

                        TextEditor(text: $note)
                            .frame(minHeight: 80)
                            .padding(AppSpacing.sm)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(AppCornerRadius.sm)
                    }
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.md)

                    // Submit
                    Button(action: {
                        Task {
                            await issueRefund()
                        }
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Issue Refund")
                            }
                        }
                        .font(AppTypography.buttonPrimary)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.md)
                        .background(refundAmount > 0 ? RoleConfig.organizerPrimary : Color.gray)
                        .cornerRadius(AppCornerRadius.md)
                    }
                    .disabled(refundAmount <= 0 || isSubmitting)
                }
                .padding(AppSpacing.md)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Issue Manual Refund")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Refund Issued", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("The refund of \(formatCurrency(refundAmount)) has been issued successfully.")
            }
        }
        .onAppear {
            refundAmount = ticket.ticketType.price
        }
    }

    private func issueRefund() async {
        isSubmitting = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        isSubmitting = false
        showSuccess = true
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "UGX "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "UGX \(Int(amount))"
    }
}

// MARK: - Previews

#Preview("Organizer Refund List") {
    NavigationStack {
        OrganizerRefundListView()
    }
}

#Preview("Decision Sheet") {
    RefundDecisionSheet(
        request: RefundRequest.samples[0],
        viewModel: OrganizerRefundListViewModel()
    )
}

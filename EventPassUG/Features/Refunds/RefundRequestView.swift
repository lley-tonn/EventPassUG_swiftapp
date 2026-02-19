//
//  RefundRequestView.swift
//  EventPassUG
//
//  User flow for requesting a refund on a ticket
//

import SwiftUI

struct RefundRequestView: View {
    let ticket: Ticket
    let event: Event

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var viewModel: RefundRequestViewModel

    init(ticket: Ticket, event: Event) {
        self.ticket = ticket
        self.event = event
        _viewModel = StateObject(wrappedValue: RefundRequestViewModel(ticket: ticket, event: event))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if let eligibility = viewModel.eligibility {
                    if eligibility.isEligible {
                        eligibleContent(eligibility: eligibility)
                    } else {
                        notEligibleContent(reason: eligibility.reason)
                    }
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                }
            }
            .navigationTitle("Request Refund")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Refund Requested", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your refund request has been submitted. You will be notified when it's processed.")
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .onAppear {
            Task {
                await viewModel.checkEligibility()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Checking refund eligibility...")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Eligible Content

    private func eligibleContent(eligibility: RefundEligibilityResult) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Ticket info
                ticketInfoCard

                // Refund amount
                RefundAmountCard(eligibility: eligibility)

                // Reason selection
                RefundReasonPicker(selectedReason: $viewModel.selectedReason)
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.md)

                // Additional note
                noteInput

                // Policy info
                if let policy = eligibility.policy {
                    RefundPolicyView(policy: policy, isCompact: true)
                }

                // Submit button
                submitButton

                // Disclaimer
                disclaimerText
            }
            .padding(AppSpacing.md)
        }
    }

    private var ticketInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                if let posterURL = ticket.eventPosterURL,
                   let url = URL(string: posterURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(AppCornerRadius.sm)
                } else {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(RoleConfig.attendeePrimary.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "ticket.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.eventTitle)
                        .font(AppTypography.calloutEmphasized)
                        .lineLimit(2)

                    Text(ticket.ticketType.name)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    Text("Ticket #\(ticket.ticketNumber)")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var noteInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Additional Details (Optional)")
                .font(AppTypography.cardTitle)
                .foregroundColor(.primary)

            TextEditor(text: $viewModel.additionalNote)
                .frame(minHeight: 80)
                .padding(AppSpacing.sm)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            Text("Provide any additional context for your refund request")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submitRefundRequest()
            }
        }) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text("Request Refund")
                }
            }
            .font(AppTypography.buttonPrimary)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(viewModel.canSubmit ? RoleConfig.attendeePrimary : Color.gray)
            .cornerRadius(AppCornerRadius.md)
        }
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
    }

    private var disclaimerText: some View {
        Text("By submitting this request, you agree to the refund policy. Refunds are typically processed within 1-5 business days depending on your payment method.")
            .font(AppTypography.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Not Eligible Content

    private func notEligibleContent(reason: String) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            VStack(spacing: AppSpacing.sm) {
                Text("Not Eligible for Refund")
                    .font(AppTypography.title2)
                    .fontWeight(.bold)

                Text(reason)
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            // Contact support option
            Button(action: {
                // Navigate to support
            }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Contact Support")
                }
                .font(AppTypography.buttonSecondary)
                .foregroundColor(RoleConfig.attendeePrimary)
                .padding(AppSpacing.md)
                .background(RoleConfig.attendeePrimary.opacity(0.1))
                .cornerRadius(AppCornerRadius.md)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(AppTypography.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.checkEligibility()
                }
            }
            .font(AppTypography.buttonSecondary)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(RoleConfig.attendeePrimary)
            .cornerRadius(AppCornerRadius.md)

            Spacer()
        }
        .padding(AppSpacing.md)
    }
}

// MARK: - View Model

@MainActor
class RefundRequestViewModel: ObservableObject {
    let ticket: Ticket
    let event: Event

    @Published var eligibility: RefundEligibilityResult?
    @Published var selectedReason: RefundReason?
    @Published var additionalNote: String = ""
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false

    private var refundService: RefundRepositoryProtocol?

    var canSubmit: Bool {
        selectedReason != nil && !isSubmitting
    }

    init(ticket: Ticket, event: Event) {
        self.ticket = ticket
        self.event = event
    }

    func setRefundService(_ service: RefundRepositoryProtocol) {
        self.refundService = service
    }

    func checkEligibility() async {
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
        errorMessage = nil

        do {
            eligibility = try await service.checkEligibility(ticket: ticket, event: event)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func submitRefundRequest() async {
        guard let reason = selectedReason else { return }

        let service: RefundRepositoryProtocol
        if let existing = refundService {
            service = existing
        } else if let created = try? await getRefundService() {
            service = created
        } else {
            errorMessage = "Service unavailable"
            showErrorAlert = true
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let note = additionalNote.isEmpty ? nil : additionalNote
            _ = try await service.requestRefund(ticket: ticket, reason: reason, note: note)

            // Track analytics
            RefundAnalyticsTracker.shared.track(.refundRequested, properties: [
                "ticket_id": ticket.id.uuidString,
                "event_id": event.id.uuidString,
                "reason": reason.rawValue,
                "amount": ticket.ticketType.price
            ])

            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true

            RefundAnalyticsTracker.shared.track(.refundFailed, properties: [
                "error": error.localizedDescription
            ])
        }

        isSubmitting = false
    }

    private func getRefundService() async throws -> RefundRepositoryProtocol {
        // In production, get from ServiceContainer
        return MockRefundRepository()
    }
}

// MARK: - Refund Status View

struct RefundStatusView: View {
    let request: RefundRequest
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Refund Request")
                        .font(AppTypography.cardTitle)

                    Text(request.ticketNumber)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                RefundStatusBadge(status: request.status)
            }

            Divider()

            // Amount
            HStack {
                Text("Requested Amount")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)

                Spacer()

                Text(request.formattedRequestedAmount)
                    .font(AppTypography.calloutEmphasized)
            }

            if let approved = request.formattedApprovedAmount {
                HStack {
                    Text("Approved Amount")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(approved)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.green)
                }
            }

            // Reason
            HStack {
                Text("Reason")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)

                Spacer()

                Text(request.reason.displayName)
                    .font(AppTypography.captionEmphasized)
            }

            // Timeline (expandable)
            if !request.statusHistory.isEmpty {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("View Timeline")
                            .font(AppTypography.caption)
                            .foregroundColor(RoleConfig.attendeePrimary)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(RoleConfig.attendeePrimary)
                    }
                }

                if isExpanded {
                    RefundTimelineView(statusHistory: request.statusHistory, isCompact: true)
                }
            }

            // Reviewer note
            if let note = request.reviewerNote {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Organizer Note")
                        .font(AppTypography.captionEmphasized)
                        .foregroundColor(.secondary)

                    Text(note)
                        .font(AppTypography.caption)
                        .foregroundColor(.primary)
                }
                .padding(AppSpacing.sm)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(AppCornerRadius.sm)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Analytics Tracker

class RefundAnalyticsTracker {
    static let shared = RefundAnalyticsTracker()

    enum Event: String {
        case refundRequested = "refund_requested"
        case refundApproved = "refund_approved"
        case refundRejected = "refund_rejected"
        case refundProcessed = "refund_processed"
        case refundFailed = "refund_failed"
    }

    func track(_ event: Event, properties: [String: Any] = [:]) {
        // In production, send to analytics service
        print("[RefundAnalytics] \(event.rawValue): \(properties)")
    }
}

// MARK: - Preview

#Preview("Refund Request") {
    let ticket = Ticket(
        ticketNumber: "TKT-001234",
        orderNumber: "ORD-789012",
        eventId: UUID(),
        eventTitle: "Nyege Nyege Festival 2024",
        eventDate: Date().addingTimeInterval(86400 * 7),
        eventEndDate: Date().addingTimeInterval(86400 * 10),
        eventVenue: "Jinja, Uganda",
        eventVenueAddress: "Discovery Beach",
        eventVenueCity: "Jinja",
        venueLatitude: 0.4478,
        venueLongitude: 33.2026,
        eventDescription: "Africa's premier electronic music festival",
        eventOrganizerName: "Nyege Nyege",
        ticketType: TicketType(name: "VIP", price: 500000, quantity: 100, sold: 50, description: "VIP access"),
        userId: UUID()
    )

    let event = Event.samples[0]

    RefundRequestView(ticket: ticket, event: event)
}

#Preview("Refund Status") {
    RefundStatusView(request: RefundRequest.samples[0])
        .padding()
}

//
//  TicketPurchaseView.swift
//  EventPassUG
//
//  Ticket purchase flow with payment methods
//

import SwiftUI

struct TicketPurchaseView: View {
    let event: Event
    let ticketType: TicketType

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var services: ServiceContainer
    @EnvironmentObject var authService: MockAuthService

    @State private var quantity = 1
    @State private var selectedPaymentMethod: PaymentMethod = .mtnMomo
    @State private var isProcessing = false
    @State private var purchaseComplete = false
    @State private var purchasedTickets: [Ticket] = []
    @State private var errorMessage: String?

    var totalAmount: Double {
        ticketType.price * Double(quantity)
    }

    var body: some View {
        NavigationView {
            if purchaseComplete {
                // Show success view with QR codes
                TicketSuccessView(
                    event: event,
                    ticketType: ticketType,
                    quantity: quantity,
                    tickets: purchasedTickets
                )
            } else {
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            // Event summary
                            HStack(spacing: AppSpacing.md) {
                                EventPosterImage(posterURL: event.posterURL, height: 80, cornerRadius: 0)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(AppDesign.Typography.cardTitle)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)

                                    Text(DateUtilities.formatEventDateTime(event.startDate))
                                        .font(AppDesign.Typography.secondary)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .frame(maxWidth: geometry.size.width - (AppSpacing.md * 2))
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)

                            // Ticket type
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Ticket Type")
                                    .font(AppDesign.Typography.section)

                                VStack(spacing: AppSpacing.md) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ticketType.name)
                                            .font(AppDesign.Typography.body)

                                        Text(ticketType.formattedPrice)
                                            .font(AppDesign.Typography.cardTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppDesign.Colors.primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    // Quantity selector
                                    HStack(spacing: AppSpacing.md) {
                                        Button(action: {
                                            if quantity > 1 {
                                                quantity -= 1
                                                HapticFeedback.light()
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(quantity > 1 ? AppDesign.Colors.primary : .gray)
                                        }
                                        .disabled(quantity <= 1)

                                        Text("\(quantity)")
                                            .font(AppDesign.Typography.hero)
                                            .fontWeight(.semibold)
                                            .frame(minWidth: 50)

                                        Button(action: {
                                            if quantity < min(ticketType.remaining, 10) {
                                                quantity += 1
                                                HapticFeedback.light()
                                            }
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(
                                                    quantity < min(ticketType.remaining, 10)
                                                        ? AppDesign.Colors.primary
                                                        : .gray
                                                )
                                        }
                                        .disabled(quantity >= min(ticketType.remaining, 10))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            Divider()

                            // Payment method
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text("Payment Method")
                                    .font(AppDesign.Typography.section)

                                VStack(spacing: AppSpacing.sm) {
                                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                                        PaymentMethodCard(
                                            method: method,
                                            isSelected: selectedPaymentMethod == method,
                                            onTap: {
                                                selectedPaymentMethod = method
                                                HapticFeedback.selection()
                                            }
                                        )
                                    }
                                }
                            }

                            Divider()

                            // Order summary
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Order Summary")
                                    .font(AppDesign.Typography.section)

                                HStack {
                                    Text("Subtotal (\(quantity) ticket\(quantity > 1 ? "s" : ""))")
                                    Spacer()
                                    Text("UGX \(Int(totalAmount).formatted())")
                                }
                                .font(AppDesign.Typography.body)

                                HStack {
                                    Text("Service fee")
                                    Spacer()
                                    Text("UGX 0")
                                }
                                .font(AppDesign.Typography.secondary)
                                .foregroundColor(.secondary)

                                Divider()

                                HStack {
                                    Text("Total")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("UGX \(Int(totalAmount).formatted())")
                                        .fontWeight(.bold)
                                        .foregroundColor(AppDesign.Colors.primary)
                                }
                                .font(AppDesign.Typography.cardTitle)
                            }

                            if let error = errorMessage {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                        .font(AppDesign.Typography.caption)
                                }
                                .foregroundColor(AppDesign.Colors.error)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppDesign.Colors.error.opacity(0.1))
                                .cornerRadius(AppCornerRadius.small)
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                }
                .navigationTitle("Purchase Tickets")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        Divider()

                        Button(action: processPurchase) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "creditcard.fill")
                                    Text("Pay UGX \(Int(totalAmount).formatted())")
                                        .font(AppDesign.Typography.buttonPrimary)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppDesign.Colors.primary)
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(AppSpacing.md)
                        .disabled(isProcessing)
                    }
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
    }

    private func processPurchase() {
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                guard let userId = authService.currentUser?.id else {
                    throw NSError(domain: "User not authenticated", code: 401)
                }

                // Validate ticket availability before purchase (including event start check)
                guard ticketType.isPurchasable(eventStartDate: event.startDate) else {
                    throw NSError(
                        domain: "EventPassUG",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "This ticket is no longer available for purchase. The event has started, the sale window has ended, or tickets are sold out."]
                    )
                }

                // Initiate payment
                let payment = try await services.paymentService.initiatePayment(
                    amount: totalAmount,
                    method: selectedPaymentMethod,
                    userId: userId,
                    eventId: event.id
                )

                // Process payment
                let status = try await services.paymentService.processPayment(paymentId: payment.id)

                if status == .completed {
                    // Purchase tickets
                    let tickets = try await services.ticketService.purchaseTicket(
                        eventId: event.id,
                        ticketTypeId: ticketType.id,
                        quantity: quantity,
                        event: event,
                        ticketType: ticketType,
                        userId: userId
                    )

                    // Send ticket confirmation notification
                    if let user = authService.currentUser {
                        try? await services.notificationService.sendTicketConfirmation(to: user, tickets: tickets)
                    }

                    await MainActor.run {
                        HapticFeedback.success()
                        purchasedTickets = tickets
                        purchaseComplete = true
                        isProcessing = false
                    }
                } else {
                    throw NSError(domain: "Payment failed", code: 500)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    HapticFeedback.error()
                    isProcessing = false
                }
            }
        }
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? AppDesign.Colors.primary.opacity(0.1) : Color(UIColor.systemGray6))
                        .frame(width: 44, height: 44)

                    Image(systemName: method.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppDesign.Colors.primary : .secondary)
                }

                // Label
                Text(method.rawValue)
                    .font(AppDesign.Typography.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: AppSpacing.sm)

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppDesign.Colors.primary)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.card)
                    .fill(isSelected ? AppDesign.Colors.primary.opacity(0.05) : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.card)
                    .stroke(
                        isSelected ? AppDesign.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TicketPurchaseView(event: Event.samples[0], ticketType: Event.samples[0].ticketTypes[0])
        .environmentObject(MockAuthService())
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

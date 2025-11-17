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
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Event summary
                        HStack(spacing: AppSpacing.md) {
                            if let posterURL = event.posterURL {
                                Image(posterURL)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(AppCornerRadius.small)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(AppTypography.headline)
                                    .lineLimit(2)

                                Text(DateUtilities.formatEventDateTime(event.startDate))
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)

                        // Ticket type
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Ticket Type")
                                .font(AppTypography.headline)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ticketType.name)
                                        .font(AppTypography.body)

                                    Text(ticketType.formattedPrice)
                                        .font(AppTypography.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(RoleConfig.attendeePrimary)
                                }

                                Spacer()

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
                                            .foregroundColor(quantity > 1 ? RoleConfig.attendeePrimary : .gray)
                                    }
                                    .disabled(quantity <= 1)

                                    Text("\(quantity)")
                                        .font(AppTypography.title2)
                                        .fontWeight(.semibold)
                                        .frame(minWidth: 40)

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
                                                    ? RoleConfig.attendeePrimary
                                                    : .gray
                                            )
                                    }
                                    .disabled(quantity >= min(ticketType.remaining, 10))
                                }
                            }
                        }

                        Divider()

                        // Payment method
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Payment Method")
                                .font(AppTypography.headline)

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

                        Divider()

                        // Order summary
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Order Summary")
                                .font(AppTypography.headline)

                            HStack {
                                Text("Subtotal (\(quantity) ticket\(quantity > 1 ? "s" : ""))")
                                Spacer()
                                Text("UGX \(Int(totalAmount).formatted())")
                            }
                            .font(AppTypography.body)

                            HStack {
                                Text("Service fee")
                                Spacer()
                                Text("UGX 0")
                            }
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)

                            Divider()

                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("UGX \(Int(totalAmount).formatted())")
                                    .fontWeight(.bold)
                                    .foregroundColor(RoleConfig.attendeePrimary)
                            }
                            .font(AppTypography.title3)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(AppCornerRadius.small)
                        }
                    }
                    .padding(AppSpacing.md)
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
                                Text("Pay UGX \(Int(totalAmount).formatted())")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoleConfig.attendeePrimary)
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

                // Validate ticket availability before purchase
                guard ticketType.isPurchasable else {
                    throw NSError(
                        domain: "EventPassUG",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "This ticket is no longer available for purchase. The sale window may have ended or tickets are sold out."]
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
            HStack {
                Image(systemName: method.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? RoleConfig.attendeePrimary : .primary)
                    .frame(width: 40)

                Text(method.rawValue)
                    .font(AppTypography.body)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(RoleConfig.attendeePrimary)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(
                        isSelected ? RoleConfig.attendeePrimary : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
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

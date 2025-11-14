//
//  TicketsView.swift
//  EventPassUG
//
//  User's purchased tickets with QR codes
//

import SwiftUI

struct TicketsView: View {
    @EnvironmentObject var authService: MockAuthService
    @EnvironmentObject var services: ServiceContainer

    @State private var tickets: [Ticket] = []
    @State private var isLoading = true
    @State private var selectedTicket: Ticket?
    @State private var showingQRCode = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    LoadingView()
                } else if tickets.isEmpty {
                    EmptyTicketsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(tickets) { ticket in
                                TicketCard(ticket: ticket) {
                                    selectedTicket = ticket
                                    showingQRCode = true
                                    HapticFeedback.light()
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                }
            }
            .navigationTitle("My Tickets")
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onAppear {
            loadTickets()
        }
        .sheet(item: $selectedTicket) { ticket in
            TicketQRView(ticket: ticket)
        }
    }

    private func loadTickets() {
        Task {
            do {
                guard let userId = authService.currentUser?.id else { return }

                let fetchedTickets = try await services.ticketService.fetchUserTickets(userId: userId)
                await MainActor.run {
                    tickets = fetchedTickets.sorted { $0.eventDate > $1.eventDate }
                    isLoading = false
                }
            } catch {
                print("Error loading tickets: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct TicketCard: View {
    let ticket: Ticket
    let onViewQR: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status banner
            if ticket.scanStatus == .scanned {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Scanned")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.green)
            } else if ticket.isExpired {
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Expired")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.gray)
            }

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Event title
                Text(ticket.eventTitle)
                    .font(AppTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Ticket type and price
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ticket Type")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        Text(ticket.ticketType.name)
                            .font(AppTypography.callout)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Price")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        Text(ticket.ticketType.formattedPrice)
                            .font(AppTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(RoleConfig.attendeePrimary)
                    }
                }

                Divider()

                // Event details
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(DateUtilities.formatEventDateTime(ticket.eventDate))
                            .font(AppTypography.subheadline)
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(ticket.eventVenue)
                            .font(AppTypography.subheadline)
                    }
                    .foregroundColor(.secondary)

                    if let seatNumber = ticket.seatNumber {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                            Text("Seat: \(seatNumber)")
                                .font(AppTypography.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // View QR button
                if ticket.canBeScanned {
                    Button(action: onViewQR) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("View QR Code")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoleConfig.attendeePrimary)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .opacity(ticket.isExpired ? 0.7 : 1.0)
    }
}

struct EmptyTicketsView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "ticket")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No Tickets Yet")
                .font(AppTypography.title2)
                .fontWeight(.bold)

            Text("When you purchase tickets, they will appear here")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .frame(maxHeight: .infinity)
    }
}

struct TicketQRView: View {
    let ticket: Ticket
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                VStack(spacing: AppSpacing.md) {
                    Text(ticket.eventTitle)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(ticket.ticketType.name)
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)
                }

                // QR Code
                QRCodeView(data: ticket.qrCodeData, size: 250)
                    .padding(AppSpacing.lg)
                    .background(Color.white)
                    .cornerRadius(AppCornerRadius.large)
                    .shadow(color: Color.black.opacity(0.1), radius: 10)

                VStack(spacing: AppSpacing.sm) {
                    Text("Show this code at the entrance")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)

                    Text(ticket.qrCodeData.suffix(8))
                        .font(AppTypography.caption)
                        .monospaced()
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action buttons
                VStack(spacing: AppSpacing.md) {
                    Button(action: shareTicket) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Ticket")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(RoleConfig.attendeePrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(RoleConfig.attendeePrimary, lineWidth: 2)
                        )
                    }

                    // TODO: Add to Wallet button (PassKit integration)
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "wallet.pass")
                            Text("Add to Wallet")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(true) // Enable when PassKit is implemented
                }
                .padding(.horizontal, AppSpacing.xl)
            }
            .padding(AppSpacing.md)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareTicket() {
        // TODO: Implement share sheet with UIActivityViewController
        HapticFeedback.light()
    }
}

#Preview {
    TicketsView()
        .environmentObject(MockAuthService())
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

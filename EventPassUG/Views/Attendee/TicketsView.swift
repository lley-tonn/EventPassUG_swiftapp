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
    @State private var showingTicketDetail = false
    @State private var selectedFilter: TicketFilter = .active
    @State private var showingShareSheet = false
    @State private var shareTicket: Ticket?
    @State private var sharePdfURL: URL?
    @State private var scrollOffset: CGFloat = 0

    enum TicketFilter {
        case all
        case active
        case expired
    }

    var activeTickets: [Ticket] {
        tickets.filter { !$0.isExpired && $0.scanStatus == .unused }
    }

    var expiredTickets: [Ticket] {
        tickets.filter { $0.isExpired || $0.scanStatus == .scanned }
    }

    var filteredTickets: [Ticket] {
        switch selectedFilter {
        case .all:
            return tickets.sorted { $0.eventDate > $1.eventDate }
        case .active:
            return activeTickets.sorted { $0.eventDate < $1.eventDate }
        case .expired:
            return expiredTickets.sorted { $0.eventDate > $1.eventDate }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    LoadingView()
                } else if tickets.isEmpty {
                    EmptyTicketsView()
                } else {
                    // Collapsible header with filters
                    CollapsibleHeader(title: "My Tickets", scrollOffset: scrollOffset) {
                        VStack(spacing: AppSpacing.md) {
                            Text("My Tickets")
                                .font(AppTypography.largeTitle)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Filter buttons
                            HStack(spacing: AppSpacing.md) {
                                TicketFilterButton(
                                    title: "All",
                                    count: tickets.count,
                                    isSelected: selectedFilter == .all,
                                    color: .gray,
                                    onTap: {
                                        selectedFilter = .all
                                        HapticFeedback.selection()
                                    }
                                )

                                TicketFilterButton(
                                    title: "Active",
                                    count: activeTickets.count,
                                    isSelected: selectedFilter == .active,
                                    color: .green,
                                    onTap: {
                                        selectedFilter = .active
                                        HapticFeedback.selection()
                                    }
                                )

                                TicketFilterButton(
                                    title: "Expired",
                                    count: expiredTickets.count,
                                    isSelected: selectedFilter == .expired,
                                    color: .red,
                                    onTap: {
                                        selectedFilter = .expired
                                        HapticFeedback.selection()
                                    }
                                )
                            }
                        }
                    }

                    // Tickets list with scroll tracking
                    ScrollOffsetReader(content: {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(filteredTickets) { ticket in
                                TicketCard(
                                    ticket: ticket,
                                    onTap: {
                                        selectedTicket = ticket
                                        showingTicketDetail = true
                                        HapticFeedback.light()
                                    },
                                    onShare: {
                                        shareTicketAsPDF(ticket)
                                    }
                                )
                            }
                        }
                        .padding(AppSpacing.md)
                    }, onOffsetChange: { offset in
                        scrollOffset = offset
                    })
                }
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onAppear {
            loadTickets()
        }
        .sheet(item: $selectedTicket) { ticket in
            TicketDetailView(ticket: ticket)
                .environmentObject(services)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = sharePdfURL {
                ShareSheet(items: [url]) { completed in
                    if completed {
                        HapticFeedback.success()
                    }
                }
            }
        }
    }

    private func loadTickets() {
        Task {
            do {
                guard let userId = authService.currentUser?.id else { return }

                let fetchedTickets = try await services.ticketService.fetchUserTickets(userId: userId)
                await MainActor.run {
                    // Mark newly expired tickets
                    tickets = markExpiredTickets(fetchedTickets)

                    // Auto-delete tickets older than 60 days
                    cleanupOldTickets()

                    tickets = tickets.sorted { $0.eventDate > $1.eventDate }
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

    private func markExpiredTickets(_ ticketList: [Ticket]) -> [Ticket] {
        var updatedTickets = ticketList
        for (index, ticket) in updatedTickets.enumerated() {
            if ticket.isExpired && updatedTickets[index].expiredAt == nil {
                updatedTickets[index].expiredAt = Date()
            }
        }
        return updatedTickets
    }

    private func cleanupOldTickets() {
        let ticketsToKeep = tickets.filter { !$0.shouldBeDeleted }
        if ticketsToKeep.count != tickets.count {
            tickets = ticketsToKeep
            print("🗑️ Cleaned up \(tickets.count - ticketsToKeep.count) expired tickets older than 60 days")
        }
    }

    private func shareTicketAsPDF(_ ticket: Ticket) {
        HapticFeedback.light()

        Task {
            let url = await Task.detached(priority: .userInitiated) {
                PDFGenerator.generateTicketPDF(ticket: ticket)
            }.value

            await MainActor.run {
                if let url = url {
                    sharePdfURL = url
                    showingShareSheet = true
                } else {
                    HapticFeedback.error()
                }
            }
        }
    }
}

struct TicketFilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(title)
                    .font(AppTypography.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                Text("\(count)")
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? color : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .foregroundColor(isSelected ? color : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.15) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .frame(height: 36)
    }
}

struct TicketCard: View {
    let ticket: Ticket
    let onTap: () -> Void
    let onShare: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                    // Status banner
                    if ticket.scanStatus == .scanned {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Scanned")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green)
                    } else if ticket.isExpired {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text("Event Ended")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                            Text("Active")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoleConfig.attendeePrimary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // Event title
                        Text(ticket.eventTitle)
                            .font(AppTypography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)

                        // Ticket type and price
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ticket Type")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.85)

                                Text(ticket.ticketType.name)
                                    .font(AppTypography.callout)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Price")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.85)

                                Text(ticket.ticketType.formattedPrice)
                                    .font(AppTypography.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(RoleConfig.attendeePrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                    }
                    .padding(12)

                    Divider()

                    // Event details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(DateUtilities.formatEventDateTime(ticket.eventDate))
                                .font(AppTypography.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(ticket.eventVenue)
                                .font(AppTypography.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, AppSpacing.sm)

                    // Bottom actions
                    HStack {
                        Button(action: onShare) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                Text("Share")
                                    .font(AppTypography.caption)
                                    .minimumScaleFactor(0.85)
                            }
                            .foregroundColor(RoleConfig.attendeePrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(RoleConfig.attendeePrimary.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .opacity(ticket.isExpired ? 0.85 : 1.0)
        .buttonStyle(.plain)
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

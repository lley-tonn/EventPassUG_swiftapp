//
//  OrganizerDashboardView.swift
//  EventPassUG
//
//  Organizer dashboard with analytics and QR scanner
//

import SwiftUI

struct OrganizerDashboardView: View {
    @EnvironmentObject var authService: MockAuthService
    @EnvironmentObject var services: ServiceContainer

    @State private var totalRevenue: Double = 0
    @State private var totalTicketsSold: Int = 0
    @State private var activeEvents: Int = 0
    @State private var isLoading = true
    @State private var showingQRScanner = false
    @State private var events: [Event] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Analytics cards
                    VStack(spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.md) {
                            AnalyticsCard(
                                title: "Total Revenue",
                                value: "UGX \(Int(totalRevenue).formatted())",
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )

                            AnalyticsCard(
                                title: "Tickets Sold",
                                value: "\(totalTicketsSold)",
                                icon: "ticket.fill",
                                color: RoleConfig.organizerPrimary
                            )
                        }

                        HStack(spacing: AppSpacing.md) {
                            AnalyticsCard(
                                title: "Active Events",
                                value: "\(activeEvents)",
                                icon: "calendar",
                                color: .blue
                            )

                            AnalyticsCard(
                                title: "Total Events",
                                value: "\(events.count)",
                                icon: "chart.bar.fill",
                                color: .purple
                            )
                        }
                    }

                    // QR Scanner button
                    Button(action: {
                        showingQRScanner = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 24))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scan Ticket")
                                    .font(AppTypography.headline)

                                Text("Check in attendees with QR code scanner")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(AppSpacing.md)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(AppCornerRadius.medium)
                        .shadow(color: Color.black.opacity(0.05), radius: 4)
                    }

                    Divider()

                    // Recent events
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Your Events")
                            .font(AppTypography.title3)
                            .fontWeight(.semibold)

                        ForEach(events.prefix(5)) { event in
                            EventAnalyticsRow(event: event)
                        }
                    }

                    // Withdraw earnings section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Earnings")
                            .font(AppTypography.title3)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Text("Available Balance")
                                    .font(AppTypography.callout)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("UGX \(Int(totalRevenue).formatted())")
                                    .font(AppTypography.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(RoleConfig.organizerPrimary)
                            }

                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Withdraw Funds")
                                }
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoleConfig.organizerPrimary)
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .disabled(totalRevenue <= 0)
                            .opacity(totalRevenue > 0 ? 1.0 : 0.5)
                        }
                        .padding(AppSpacing.md)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
        .onAppear {
            loadAnalytics()
        }
        .sheet(isPresented: $showingQRScanner) {
            QRScannerView()
        }
    }

    private func loadAnalytics() {
        Task {
            do {
                guard let organizerId = authService.currentUser?.id else { return }

                // Fetch organizer events
                let fetchedEvents = try await services.eventService.fetchOrganizerEvents(organizerId: organizerId)

                // Calculate revenue
                let revenue = try await services.paymentService.calculateRevenue(organizerId: organizerId)

                // Calculate statistics
                let ticketsSold = fetchedEvents.reduce(0) { total, event in
                    total + event.ticketTypes.reduce(0) { $0 + $1.sold }
                }

                let active = fetchedEvents.filter { $0.status == .published || $0.status == .ongoing }.count

                await MainActor.run {
                    self.events = fetchedEvents
                    self.totalRevenue = revenue
                    self.totalTicketsSold = ticketsSold
                    self.activeEvents = active
                    self.isLoading = false
                }
            } catch {
                print("Error loading analytics: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(AppTypography.title2)
                .fontWeight(.bold)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

struct EventAnalyticsRow: View {
    let event: Event

    private var soldPercentage: Double {
        let totalCapacity = event.ticketTypes.reduce(0) { $0 + $1.quantity }
        let totalSold = event.ticketTypes.reduce(0) { $0 + $1.sold }
        guard totalCapacity > 0 else { return 0 }
        return Double(totalSold) / Double(totalCapacity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(event.title)
                    .font(AppTypography.callout)
                    .fontWeight(.semibold)
                Spacer()
                Text(event.status.rawValue.capitalized)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sold")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    Text("\(event.ticketTypes.reduce(0) { $0 + $1.sold })")
                        .font(AppTypography.callout)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Revenue")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    Text("UGX \(Int(event.ticketTypes.reduce(0) { $0 + ($1.price * Double($1.sold)) }).formatted())")
                        .font(AppTypography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(RoleConfig.organizerPrimary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(RoleConfig.organizerPrimary)
                        .frame(width: geometry.size.width * soldPercentage, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(Int(soldPercentage * 100))% sold")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

#Preview {
    OrganizerDashboardView()
        .environmentObject(MockAuthService())
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

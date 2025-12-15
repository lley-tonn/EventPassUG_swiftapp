//
//  OrganizerDashboardView.swift
//  EventPassUG
//
//  Organizer dashboard with analytics and QR scanner
//

import SwiftUI
import Combine

struct OrganizerDashboardView: View {
    @EnvironmentObject var authService: MockAuthService
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var followManager = FollowManager.shared

    @State private var totalRevenue: Double = 0
    @State private var totalTicketsSold: Int = 0
    @State private var activeEvents: Int = 0
    @State private var isLoading = true
    @State private var showingQRScanner = false
    @State private var events: [Event] = []
    @State private var showingVerification = false
    @State private var showingVerificationSheet = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Collapsible header
                    CollapsibleHeader(title: "Dashboard", scrollOffset: scrollOffset) {
                        VStack(spacing: AppSpacing.md) {
                            Text("Dashboard")
                                .font(AppTypography.largeTitle)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Track your events and earnings")
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Content with scroll tracking
                    GeometryReader { geometry in
                        let isLandscape = geometry.size.width > geometry.size.height
                        let _ = ResponsiveGrid.columns(isLandscape: isLandscape, baseColumns: 2)

                        ScrollOffsetReader(content: {
                            VStack(alignment: .leading, spacing: ResponsiveSpacing.lg(geometry)) {
                        // Analytics cards - compact 2-column grid
                        LazyVGrid(columns: ResponsiveGrid.gridItems(isLandscape: isLandscape, baseColumns: 2, spacing: ResponsiveSpacing.sm(geometry)), spacing: ResponsiveSpacing.sm(geometry)) {
                            CompactMetricCard(
                                title: "Total Revenue",
                                value: "UGX \(formatCompactCurrency(totalRevenue))",
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )

                            CompactMetricCard(
                                title: "Tickets Sold",
                                value: "\(totalTicketsSold)",
                                icon: "ticket.fill",
                                color: RoleConfig.organizerPrimary
                            )

                            CompactMetricCard(
                                title: "Active Events",
                                value: "\(activeEvents)",
                                icon: "calendar",
                                color: .blue
                            )

                            CompactMetricCard(
                                title: "Total Events",
                                value: "\(events.count)",
                                icon: "chart.bar.fill",
                                color: .purple
                            )

                            CompactMetricCard(
                                title: "Followers",
                                value: "\(followManager.getFollowerCount(for: authService.currentUser?.id ?? UUID()))",
                                icon: "person.2.fill",
                                color: .orange
                            )
                        }

                    // Manage Scanner Devices button
                    NavigationLink(destination: Text("Scanner Device Management - Coming Soon").navigationTitle("Scanner Devices")) {
                        HStack {
                            Image(systemName: "iphone.and.arrow.forward")
                                .font(.system(size: 24))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Manage Scanner Devices")
                                    .font(AppTypography.headline)

                                Text("Authorize devices for ticket scanning")
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

                    // Recent events with progress indicators
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Your Events")
                            .font(AppTypography.title3)
                            .fontWeight(.semibold)
                            .padding(.bottom, AppSpacing.xs)

                        ForEach(events.prefix(5)) { event in
                            NavigationLink(destination: EventAnalyticsView(event: event)) {
                                EventDashboardCard(event: event)
                            }
                            .buttonStyle(.plain)
                        }

                        if events.count > 5 {
                            Button(action: {}) {
                                HStack {
                                    Text("View All Events")
                                        .font(AppDesign.Typography.callout)
                                        .foregroundColor(RoleConfig.organizerPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(RoleConfig.organizerPrimary)
                                }
                                .padding(.vertical, AppSpacing.sm)
                            }
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
                .padding(.horizontal, ResponsiveSpacing.md(geometry))
                .padding(.vertical, ResponsiveSpacing.sm(geometry))
                        }, onOffsetChange: { offset in
                            scrollOffset = offset
                        })
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                }
                .navigationBarHidden(true)
                .blur(radius: authService.currentUser?.needsVerificationForOrganizerActions == true ? 10 : 0)

                // Verification Required Overlay
                if authService.currentUser?.needsVerificationForOrganizerActions == true {
                    VStack(spacing: AppSpacing.lg) {
                        Spacer()

                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.orange)

                            Text("Verification Required")
                                .font(AppTypography.title2)
                                .fontWeight(.bold)

                            Text("You must verify your National ID before accessing organizer features.")
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.xl)

                            Button(action: {
                                showingVerification = true
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.shield")
                                    Text("Verify Now")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoleConfig.organizerPrimary)
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .padding(.horizontal, AppSpacing.xl)
                        }
                        .padding(AppSpacing.xl)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(AppCornerRadius.large)
                        .shadow(radius: 10)
                        .padding(AppSpacing.md)

                        Spacer()
                    }
                    .background(Color.black.opacity(0.3))
                }

                // Verification Required Overlay
                if authService.currentUser?.needsVerificationForOrganizerActions == true {
                    VerificationRequiredOverlay(
                        showingVerificationSheet: $showingVerificationSheet
                    )
                }
            }
            }
            .onAppear {
                loadAnalytics()
                subscribeToTicketSales()
            }
            .sheet(isPresented: $showingQRScanner) {
                QRScannerView()
            }
            .sheet(isPresented: $showingVerification) {
                NationalIDVerificationView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingVerificationSheet) {
                NationalIDVerificationView()
                    .environmentObject(authService)
            }
    }

    private func formatCompactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return "\(Int(value))"
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

    private func subscribeToTicketSales() {
        services.ticketService.ticketSalesPublisher
            .receive(on: DispatchQueue.main)
            .sink { saleEvent in
                // Update event sold count
                if let index = events.firstIndex(where: { $0.id == saleEvent.eventId }) {
                    for (typeIndex, ticketType) in events[index].ticketTypes.enumerated() {
                        if ticketType.name == saleEvent.ticketType {
                            events[index].ticketTypes[typeIndex].sold += saleEvent.quantity
                        }
                    }
                }

                // Update total stats
                totalTicketsSold += saleEvent.quantity
                totalRevenue += saleEvent.totalAmount

                HapticFeedback.success()
            }
            .store(in: &cancellables)
    }
}

// Old components removed - replaced with CompactMetricCard and EventDashboardCard
// See DashboardComponents.swift for the new implementations

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

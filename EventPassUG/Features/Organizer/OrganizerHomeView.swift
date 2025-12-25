//
//  OrganizerHomeView.swift
//  EventPassUG
//
//  Organizer home screen with event list and create button
//

import SwiftUI
import Combine

struct OrganizerHomeView: View {
    @EnvironmentObject var authService: MockAuthRepository
    @EnvironmentObject var services: ServiceContainer

    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var showingCreateEvent = false
    @State private var selectedFilter: EventStatus = .published
    @State private var unreadNotifications = 2
    @State private var showingVerificationSheet = false
    @State private var showingNotifications = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var editingDraft: Event?

    var body: some View {
        NavigationView {
            ZStack {
                mainContent

                // Verification Required Overlay
                if authService.currentUser?.needsVerificationForOrganizerActions == true {
                    VerificationRequiredOverlay(
                        showingVerificationSheet: $showingVerificationSheet
                    )
                }
            }
            .sheet(isPresented: $showingVerificationSheet) {
                NationalIDVerificationView()
                    .environmentObject(authService)
            }
        }
        .onAppear {
            loadEvents()
            subscribeToTicketSales()
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventWizard()
                .environmentObject(authService)
                .environmentObject(services)
        }
        .sheet(isPresented: Binding(
            get: { editingDraft != nil },
            set: { if !$0 { editingDraft = nil } }
        )) {
            if let draft = editingDraft {
                CreateEventWizard(existingDraft: draft)
                    .environmentObject(authService)
                    .environmentObject(services)
            }
        }
    }

    // MARK: - Real-time Ticket Sales Subscription

    private func subscribeToTicketSales() {
        services.ticketService.ticketSalesPublisher
            .receive(on: DispatchQueue.main)
            .sink { saleEvent in
                // Update the event's sold count in real-time
                if let index = events.firstIndex(where: { $0.id == saleEvent.eventId }) {
                    // Find the ticket type and update its sold count
                    for (typeIndex, ticketType) in events[index].ticketTypes.enumerated() {
                        if ticketType.name == saleEvent.ticketType {
                            events[index].ticketTypes[typeIndex].sold += saleEvent.quantity
                        }
                    }
                }
                // Increment notification count for new sale
                unreadNotifications += 1
                HapticFeedback.success()
            }
            .store(in: &cancellables)
    }

    private var mainContent: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            VStack(spacing: 0) {
                // Header with greeting, date, search and notifications
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DateUtilities.formatHeaderDate(Date()))
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        Text("\(DateUtilities.getGreeting()), \(authService.currentUser?.firstName ?? "Organizer")!")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    // Search button
                    AppIconButton(
                        icon: "magnifyingglass",
                        action: {
                            showingSearch = true
                            HapticFeedback.light()
                        }
                    )

                    // Notifications button
                    AppIconButton(
                        icon: "bell.fill",
                        badge: unreadNotifications > 0 ? unreadNotifications : nil,
                        action: {
                            showingNotifications = true
                            HapticFeedback.light()
                        }
                    )
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)

                // Search bar (when active)
                if showingSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search your events...", text: $searchText)
                            .font(AppTypography.body)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: { showingSearch = false; searchText = "" }) {
                            Text("Cancel")
                                .font(AppTypography.subheadline)
                                .foregroundColor(RoleConfig.organizerPrimary)
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(AppCornerRadius.small)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                }

                // Create Event Button
                Button(action: {
                    showingCreateEvent = true
                    HapticFeedback.light()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Create New Event")
                            .font(AppTypography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)

                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach([EventStatus.published, .draft, .ongoing, .completed], id: \.self) { status in
                            FilterChip(
                                title: status.rawValue.capitalized,
                                count: eventsWithAutoStatus.filter { $0.status == status }.count,
                                isSelected: selectedFilter == status,
                                onTap: {
                                    selectedFilter = status
                                    HapticFeedback.selection()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .padding(.bottom, AppSpacing.md)

                // Events list
                if isLoading {
                    LoadingView()
                } else if filteredEvents.isEmpty {
                    EmptyEventsView(status: selectedFilter) {
                        showingCreateEvent = true
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: ResponsiveGrid.gridItems(isLandscape: isLandscape, baseColumns: 1, spacing: ResponsiveSpacing.md(geometry)), spacing: ResponsiveSpacing.md(geometry)) {
                            ForEach(filteredEvents) { event in
                                if event.status == .draft {
                                    Button(action: {
                                        editingDraft = event
                                        HapticFeedback.light()
                                    }) {
                                        OrganizerEventCard(event: event)
                                    }
                                } else {
                                    NavigationLink(destination: EventAnalyticsView(event: event)) {
                                        OrganizerEventCard(event: event)
                                    }
                                }
                            }
                        }
                        .padding(ResponsiveSpacing.md(geometry))
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNotifications) {
                OrganizerNotificationCenterView()
                    .environmentObject(authService)
                    .environmentObject(services)
            }
            }
    }

    // Auto-detect event status based on current date
    private var eventsWithAutoStatus: [Event] {
        events.map { event in
            var modifiedEvent = event
            let now = Date()

            // Auto-update status based on date and current status
            if event.status == .draft {
                // Drafts that have passed should be marked as completed
                if now > event.endDate {
                    modifiedEvent.status = .completed
                }
                // Keep drafts as drafts if not expired
            } else if event.status == .published {
                // Check if event should be ongoing
                if now >= event.startDate && now <= event.endDate {
                    modifiedEvent.status = .ongoing
                }
                // Check if event should be completed
                else if now > event.endDate {
                    modifiedEvent.status = .completed
                }
                // Otherwise keep as published (upcoming)
            } else if event.status == .ongoing {
                // Check if ongoing event has ended
                if now > event.endDate {
                    modifiedEvent.status = .completed
                }
            }
            // Completed and cancelled events stay as-is

            return modifiedEvent
        }
    }

    private var filteredEvents: [Event] {
        let statusFiltered = eventsWithAutoStatus.filter { $0.status == selectedFilter }

        // Apply search filter if active
        if searchText.isEmpty {
            return statusFiltered
        } else {
            return statusFiltered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.venue.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func loadEvents() {
        Task {
            do {
                guard let organizerId = authService.currentUser?.id else { return }

                let fetchedEvents = try await services.eventService.fetchOrganizerEvents(organizerId: organizerId)
                await MainActor.run {
                    events = fetchedEvents.sorted { $0.createdAt > $1.createdAt }
                    isLoading = false
                }
            } catch {
                print("Error loading events: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(title)
                    .font(AppTypography.callout)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected
                            ? Color.white.opacity(0.3)
                            : Color(UIColor.secondarySystemBackground)
                    )
                    .cornerRadius(10)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? RoleConfig.organizerPrimary
                    : Color(UIColor.secondarySystemGroupedBackground)
            )
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

struct OrganizerEventCard: View {
    let event: Event

    private var isOngoing: Bool {
        let now = Date()
        return now >= event.startDate && now <= event.endDate
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.md) {
                // Poster thumbnail
                EventPosterImage(posterURL: event.posterURL, height: 80, cornerRadius: 0)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(DateUtilities.formatEventDateTime(event.startDate))
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "ticket")
                                    .font(.caption)
                                Text("\(event.ticketTypes.reduce(0) { $0 + $1.sold })")
                                    .font(AppTypography.caption)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .font(.caption)
                                Text("\(event.likeCount)")
                                    .font(AppTypography.caption)
                            }
                    }
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, AppSpacing.md)

            // Scan Tickets button - only for ongoing events
            if isOngoing {
                Divider()

                NavigationLink(destination: QRScannerView()) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 16))
                        Text("Scan Tickets")
                            .font(AppTypography.subheadline)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.85)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(RoleConfig.organizerPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, AppSpacing.sm)
                    .background(RoleConfig.organizerPrimary.opacity(0.1))
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct EmptyEventsView: View {
    let status: EventStatus
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text(title)
                .font(AppTypography.title2)
                .fontWeight(.bold)

            Text(message)
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            if status == .draft || status == .published {
                Button(action: onCreate) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Event")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var iconName: String {
        switch status {
        case .draft: return "doc.text"
        case .published: return "calendar.badge.clock"
        case .ongoing: return "play.circle"
        case .completed: return "checkmark.circle"
        default: return "calendar"
        }
    }

    private var title: String {
        switch status {
        case .draft: return "No Drafts"
        case .published: return "No Published Events"
        case .ongoing: return "No Ongoing Events"
        case .completed: return "No Completed Events"
        default: return "No Events"
        }
    }

    private var message: String {
        switch status {
        case .draft: return "Start creating an event and save it as a draft"
        case .published: return "Create and publish your first event"
        case .ongoing: return "No events are currently happening"
        case .completed: return "No completed events yet"
        default: return "You haven't created any events yet"
        }
    }
}

struct OrganizerEventDetailView: View {
    let event: Event

    private var totalTicketsSold: Int {
        event.ticketTypes.reduce(0) { $0 + $1.sold }
    }

    private var totalRevenue: Double {
        event.ticketTypes.reduce(0.0) { $0 + (Double($1.sold) * $1.price) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Event poster
                EventPosterImage(posterURL: event.posterURL, height: 240, cornerRadius: AppCornerRadius.medium)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 240)
                    .clipped()
                    .shadow(
                        color: Color.black.opacity(0.12),
                        radius: 10,
                        x: 0,
                        y: 5
                    )

                // Event title and status
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(event.title)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                        Text(event.status.rawValue.capitalized)
                            .font(AppTypography.callout)
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small)
                }

                Divider()

                // Event details
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Event Details")
                        .font(AppTypography.headline)

                    InfoRow(
                        icon: "calendar",
                        title: "Start",
                        value: DateUtilities.formatEventDateTime(event.startDate)
                    )

                    InfoRow(
                        icon: "calendar.badge.clock",
                        title: "End",
                        value: DateUtilities.formatEventDateTime(event.endDate)
                    )

                    InfoRow(
                        icon: "location.fill",
                        title: "Venue",
                        value: "\(event.venue.name)\n\(event.venue.address), \(event.venue.city)"
                    )
                }

                Divider()

                // Analytics Overview
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Analytics")
                        .font(AppTypography.headline)

                    // Stats cards
                    HStack(spacing: AppSpacing.md) {
                        StatCard(
                            icon: "heart.fill",
                            title: "Impressions",
                            value: "\(event.likeCount)",
                            color: .pink
                        )

                        StatCard(
                            icon: "ticket.fill",
                            title: "Tickets Sold",
                            value: "\(totalTicketsSold)",
                            color: RoleConfig.organizerPrimary
                        )
                    }

                    StatCard(
                        icon: "dollarsign.circle.fill",
                        title: "Total Revenue",
                        value: "UGX \(Int(totalRevenue).formatted())",
                        color: .green
                    )
                }

                Divider()

                // Ticket sales breakdown
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Ticket Sales Breakdown")
                        .font(AppTypography.headline)

                    ForEach(event.ticketTypes) { ticketType in
                        TicketSalesRow(ticketType: ticketType)
                    }
                }

                Divider()

                // Additional metrics
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Engagement")
                        .font(AppTypography.headline)

                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Average Rating:")
                            .font(AppTypography.body)
                        Spacer()
                        if event.totalRatings > 0 {
                            Text(String(format: "%.1f (%d reviews)", event.rating, event.totalRatings))
                                .font(AppTypography.body)
                                .fontWeight(.semibold)
                        } else {
                            Text("No ratings yet")
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    if totalTicketsSold > 0 {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.blue)
                            Text("Conversion Rate:")
                                .font(AppTypography.body)
                            Spacer()
                            let conversionRate = (Double(totalTicketsSold) / Double(event.likeCount > 0 ? event.likeCount : 1)) * 100
                            Text(String(format: "%.1f%%", min(conversionRate, 100)))
                                .font(AppTypography.body)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Event Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusIcon: String {
        switch event.status {
        case .draft: return "doc.text"
        case .published: return "checkmark.circle.fill"
        case .ongoing: return "play.circle.fill"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    private var statusColor: Color {
        switch event.status {
        case .draft: return .orange
        case .published: return .green
        case .ongoing: return .blue
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(AppTypography.title3)
                .fontWeight(.bold)

            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct TicketSalesRow: View {
    let ticketType: TicketType

    private var salesPercentage: Double {
        guard ticketType.quantity > 0 else { return 0 }
        return Double(ticketType.sold) / Double(ticketType.quantity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticketType.name)
                        .font(AppTypography.callout)
                        .fontWeight(.semibold)

                    Text(ticketType.formattedPrice)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket.fill")
                            .font(.caption)
                            .foregroundColor(RoleConfig.organizerPrimary)
                        Text("\(ticketType.sold)")
                            .font(AppTypography.callout)
                            .fontWeight(.bold)
                    }

                    if ticketType.isUnlimitedQuantity {
                        Text("Unlimited")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(ticketType.sold) / \(ticketType.quantity)")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress bar
            if !ticketType.isUnlimitedQuantity {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(RoleConfig.organizerPrimary)
                            .frame(width: geometry.size.width * salesPercentage, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Revenue for this ticket type
            HStack {
                Text("Revenue:")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("UGX \(Int(Double(ticketType.sold) * ticketType.price).formatted())")
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.small)
    }
}

#Preview {
    OrganizerHomeView()
        .environmentObject(MockAuthRepository())
        .environmentObject(ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        ))
}

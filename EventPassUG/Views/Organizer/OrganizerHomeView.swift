//
//  OrganizerHomeView.swift
//  EventPassUG
//
//  Organizer home screen with event list and create button
//

import SwiftUI
import Combine

struct OrganizerHomeView: View {
    @EnvironmentObject var authService: MockAuthService
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
                        ForEach([EventStatus.published, .draft, .ongoing], id: \.self) { status in
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
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(filteredEvents) { event in
                                if event.status == .draft {
                                    Button(action: {
                                        editingDraft = event
                                        HapticFeedback.light()
                                    }) {
                                        OrganizerEventCard(event: event)
                                    }
                                } else {
                                    NavigationLink(destination: OrganizerEventDetailView(event: event)) {
                                        OrganizerEventCard(event: event)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.md)
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

    // Auto-detect ongoing events based on current date
    private var eventsWithAutoStatus: [Event] {
        events.map { event in
            var modifiedEvent = event
            let now = Date()

            // Auto-update status based on date
            if event.status == .published {
                if now >= event.startDate && now <= event.endDate {
                    modifiedEvent.status = .ongoing
                }
            }

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
                if let posterURL = event.posterURL {
                    Image(posterURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(AppCornerRadius.small)
                } else {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 80, height: 80)
                        .cornerRadius(AppCornerRadius.small)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(DateUtilities.formatEventDateTime(event.startDate))
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: AppSpacing.md) {
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

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.md)

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
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(RoleConfig.organizerPrimary)
                    .padding(.horizontal, AppSpacing.md)
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
        default: return "calendar"
        }
    }

    private var title: String {
        switch status {
        case .draft: return "No Drafts"
        case .published: return "No Published Events"
        case .ongoing: return "No Ongoing Events"
        default: return "No Events"
        }
    }

    private var message: String {
        switch status {
        case .draft: return "Start creating an event and save it as a draft"
        case .published: return "Create and publish your first event"
        case .ongoing: return "No events are currently happening"
        default: return "You haven't created any events yet"
        }
    }
}

struct OrganizerEventDetailView: View {
    let event: Event

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Event detail view - TODO")
                    .font(AppTypography.title2)

                Text(event.title)
                    .font(AppTypography.headline)
            }
            .padding()
        }
        .navigationTitle("Event Details")
    }
}

#Preview {
    OrganizerHomeView()
        .environmentObject(MockAuthService())
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

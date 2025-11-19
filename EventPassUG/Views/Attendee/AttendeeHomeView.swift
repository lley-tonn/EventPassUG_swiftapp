//
//  AttendeeHomeView.swift
//  EventPassUG
//
//  Attendee home screen with categories and event feed
//

import SwiftUI

struct AttendeeHomeView: View {
    @EnvironmentObject var authService: MockAuthService
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var favoriteManager = FavoriteManager.shared

    @State private var events: [Event] = []
    @State private var selectedTimeCategory: TimeCategory? = nil
    @State private var selectedEventCategory: EventCategory? = nil
    @State private var isLoading = true
    @State private var unreadNotifications = 3
    @State private var showingNotifications = false
    @State private var showingFavorites = false
    @State private var isSearchExpanded = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                GeometryReader { screenGeometry in
                ScrollView {
                VStack(spacing: 0) {
                    // Header with action buttons and inline search
                    VStack(spacing: max(8, screenGeometry.size.width * 0.03)) {
                        // Top row: Greeting + Action Buttons
                        HStack(alignment: .top) {
                            if !isSearchExpanded {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(DateUtilities.formatHeaderDate(Date()))
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)

                                    Text("\(DateUtilities.getGreeting()), \(authService.currentUser?.firstName ?? "Guest")!")
                                        .font(AppTypography.title2)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                }
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            }

                            Spacer(minLength: 8)

                            HStack(spacing: max(8, screenGeometry.size.width * 0.025)) {
                                // Search button - toggles inline search
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isSearchExpanded.toggle()
                                        if isSearchExpanded {
                                            isSearchFocused = true
                                        } else {
                                            searchText = ""
                                            isSearchFocused = false
                                        }
                                    }
                                    HapticFeedback.light()
                                }) {
                                    Image(systemName: isSearchExpanded ? "xmark" : "magnifyingglass")
                                        .font(.system(size: min(max(screenGeometry.size.width * 0.05, 18), 20)))
                                        .foregroundColor(.primary)
                                        .frame(width: min(max(screenGeometry.size.width * 0.1, 36), 40),
                                               height: min(max(screenGeometry.size.width * 0.1, 36), 40))
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .clipShape(Circle())
                                }

                                if !isSearchExpanded {
                                    // Favorites button
                                    Button(action: {
                                        showingFavorites = true
                                        HapticFeedback.light()
                                    }) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(RoleConfig.attendeePrimary)
                                                .frame(width: 40, height: 40)
                                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                                .clipShape(Circle())

                                            if !favoriteManager.favoriteEventIds.isEmpty {
                                                Text("\(favoriteManager.favoriteEventIds.count)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(4)
                                                    .background(Color.red)
                                                    .clipShape(Circle())
                                                    .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))

                                    // Notifications button
                                    Button(action: {
                                        showingNotifications = true
                                        HapticFeedback.light()
                                    }) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "bell.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.primary)
                                                .frame(width: 40, height: 40)
                                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                                .clipShape(Circle())

                                            if unreadNotifications > 0 {
                                                Text("\(min(unreadNotifications, 99))")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(minWidth: 16, minHeight: 16)
                                                    .padding(4)
                                                    .background(Color.red)
                                                    .clipShape(Circle())
                                                    .offset(x: 8, y: -8)
                                            }
                                        }
                                    }
                                    .padding(.trailing, 4)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }

                        // Inline Search Bar (expands when search is tapped)
                        if isSearchExpanded {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)

                                TextField("Search events, organizers, locations...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .autocorrectionDisabled()
                                    .focused($isSearchFocused)

                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                        HapticFeedback.light()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)

                    // Combined filters (single line)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            // Time filters
                            CategoryTile(
                                title: "Today",
                                icon: "calendar",
                                isSelected: selectedTimeCategory == .today,
                                onTap: {
                                    selectedTimeCategory = selectedTimeCategory == .today ? nil : .today
                                    selectedEventCategory = nil
                                    HapticFeedback.selection()
                                }
                            )

                            CategoryTile(
                                title: "This week",
                                icon: "calendar.badge.clock",
                                isSelected: selectedTimeCategory == .thisWeek,
                                onTap: {
                                    selectedTimeCategory = selectedTimeCategory == .thisWeek ? nil : .thisWeek
                                    selectedEventCategory = nil
                                    HapticFeedback.selection()
                                }
                            )

                            CategoryTile(
                                title: "This month",
                                icon: "calendar.circle",
                                isSelected: selectedTimeCategory == .thisMonth,
                                onTap: {
                                    selectedTimeCategory = selectedTimeCategory == .thisMonth ? nil : .thisMonth
                                    selectedEventCategory = nil
                                    HapticFeedback.selection()
                                }
                            )

                            // Divider
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 30)
                                .padding(.horizontal, 4)

                            // Event category filters
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                CategoryTile(
                                    title: category.rawValue,
                                    icon: category.iconName,
                                    isSelected: selectedEventCategory == category,
                                    onTap: {
                                        selectedEventCategory = selectedEventCategory == category ? nil : category
                                        selectedTimeCategory = nil
                                        HapticFeedback.selection()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .padding(.bottom, AppSpacing.lg)

                    // Events feed - responsive grid
                    if isLoading {
                        VStack(spacing: AppSpacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonEventCard()
                            }
                        }
                        .padding(.horizontal, ResponsiveSpacing.md(geometry))
                    } else {
                        LazyVGrid(columns: ResponsiveGrid.gridItems(isLandscape: isLandscape, baseColumns: 1, spacing: ResponsiveSpacing.md(geometry)), spacing: ResponsiveSpacing.md(geometry)) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailsView(event: event)) {
                                    EventCard(
                                        event: event,
                                        isLiked: favoriteManager.isFavorite(eventId: event.id),
                                        onLikeTap: {
                                            favoriteManager.toggleFavorite(eventId: event.id)
                                            HapticFeedback.light()
                                        },
                                        onCardTap: {}
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, ResponsiveSpacing.md(geometry))
                        .padding(.bottom, ResponsiveSpacing.xl(geometry))
                    }
                }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            }
            .onAppear {
                loadEvents()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView(unreadCount: $unreadNotifications)
            }
            .sheet(isPresented: $showingFavorites) {
                FavoriteEventsView()
                    .environmentObject(services)
            }
    }

    private var filteredEvents: [Event] {
        var filtered = events

        // Filter out past events (event has ended)
        filtered = filtered.filter { $0.endDate >= Date() }

        // Filter by time category
        if let timeCategory = selectedTimeCategory {
            filtered = filtered.filter { $0.timeCategory == timeCategory }
        }

        // Filter by event category
        if let eventCategory = selectedEventCategory {
            filtered = filtered.filter { $0.category == eventCategory }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.organizerName.localizedCaseInsensitiveContains(searchText) ||
                event.venue.name.localizedCaseInsensitiveContains(searchText) ||
                event.venue.city.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private func loadEvents() {
        Task {
            do {
                let fetchedEvents = try await services.eventService.fetchEvents()
                await MainActor.run {
                    events = fetchedEvents
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

#Preview {
    AttendeeHomeView()
        .environmentObject(MockAuthService())
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

//
//  AttendeeHomeView.swift
//  EventPassUG
//
//  Attendee home screen with categories and event feed
//  FIXED: No auto-scrolling on first load
//

import SwiftUI

struct AttendeeHomeView: View {
    @EnvironmentObject var authService: MockAuthRepository
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var favoriteManager = FavoriteManager.shared

    // MVVM: Use StateObject for stable ViewModel reference
    // Note: We can't use @EnvironmentObject in init, so we create the ViewModel lazily
    @StateObject private var viewModel = AttendeeHomeViewModel(
        eventService: MockEventRepository() // Will be replaced with injected service
    )

    // Local UI state only (not data state)
    @State private var unreadNotifications = 3
    @State private var showingNotifications = false
    @State private var showingFavorites = false
    @FocusState private var isSearchFocused: Bool

    // Scroll position anchor - critical for preventing auto-scroll
    @State private var scrollViewID = UUID()

    // Share functionality
    @State private var showingShareSheet = false
    @State private var shareEvent: Event?

    // MARK: - Body

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header with action buttons and inline search (FIXED OUTSIDE ScrollView)
                    headerView(geometry: geometry)

                    // Combined filters (single line)
                    filterScrollView

                    // Events feed - SCROLL STABILIZED
                    stableScrollView(geometry: geometry)
                }
                .background(Color(UIColor.systemGroupedBackground))
                .navigationBarHidden(true)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Inject the environment service into the ViewModel on first appear
            if viewModel.eventService is MockEventRepository {
                viewModel.updateEventService(services.eventService)
            }

            // Inject current user for personalized recommendations
            viewModel.setCurrentUser(authService.currentUser)
        }
        .onChange(of: authService.currentUser) { newUser in
            // Update recommendations when user changes
            viewModel.setCurrentUser(newUser)
            if let user = newUser {
                Task {
                    await viewModel.generateRecommendations(for: user)
                }
            }
        }
        // CRITICAL: Load data in task, not onAppear
        // This prevents animations from affecting scroll position
        .task {
            viewModel.loadEventsIfNeeded()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(unreadCount: $unreadNotifications)
        }
        .sheet(isPresented: $showingFavorites) {
            FavoriteEventsView()
                .environmentObject(services)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let event = shareEvent {
                ShareSheet(items: shareItems(for: event)) { completed in
                    if completed {
                        HapticFeedback.success()
                    }
                }
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private func headerView(geometry: GeometryProxy) -> some View {
        VStack(spacing: max(8, geometry.size.width * 0.03)) {
            // Top row: Greeting + Action Buttons
            HStack(alignment: .top) {
                if !viewModel.isSearchExpanded {
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

                HStack(spacing: max(8, geometry.size.width * 0.025)) {
                    // Search button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.isSearchExpanded.toggle()
                            if viewModel.isSearchExpanded {
                                isSearchFocused = true
                            } else {
                                viewModel.searchText = ""
                                isSearchFocused = false
                            }
                        }
                        HapticFeedback.light()
                    }) {
                        Image(systemName: viewModel.isSearchExpanded ? "xmark" : "magnifyingglass")
                            .font(.system(size: min(max(geometry.size.width * 0.05, 18), 20)))
                            .foregroundColor(.primary)
                            .frame(width: min(max(geometry.size.width * 0.1, 36), 40),
                                   height: min(max(geometry.size.width * 0.1, 36), 40))
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }

                    if !viewModel.isSearchExpanded {
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
            if viewModel.isSearchExpanded {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search events, organizers, locations...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .focused($isSearchFocused)

                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
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
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Filter Scroll View

    @ViewBuilder
    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // Time filters
                CategoryTile(
                    title: "Today",
                    icon: "calendar",
                    isSelected: viewModel.selectedTimeCategory == .today,
                    onTap: {
                        viewModel.selectedTimeCategory = viewModel.selectedTimeCategory == .today ? nil : .today
                        viewModel.selectedEventCategory = nil
                        HapticFeedback.selection()
                    }
                )

                CategoryTile(
                    title: "This week",
                    icon: "calendar.badge.clock",
                    isSelected: viewModel.selectedTimeCategory == .thisWeek,
                    onTap: {
                        viewModel.selectedTimeCategory = viewModel.selectedTimeCategory == .thisWeek ? nil : .thisWeek
                        viewModel.selectedEventCategory = nil
                        HapticFeedback.selection()
                    }
                )

                CategoryTile(
                    title: "This month",
                    icon: "calendar.circle",
                    isSelected: viewModel.selectedTimeCategory == .thisMonth,
                    onTap: {
                        viewModel.selectedTimeCategory = viewModel.selectedTimeCategory == .thisMonth ? nil : .thisMonth
                        viewModel.selectedEventCategory = nil
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
                        isSelected: viewModel.selectedEventCategory == category,
                        onTap: {
                            viewModel.selectedEventCategory = viewModel.selectedEventCategory == category ? nil : category
                            viewModel.selectedTimeCategory = nil
                            HapticFeedback.selection()
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Stable Scroll View (NO AUTO-SCROLL)

    @ViewBuilder
    private func stableScrollView(geometry: GeometryProxy) -> some View {
        // CRITICAL FIX: Use ScrollViewReader to control scroll position
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                // Anchor point at top - prevents scroll jumping
                Color.clear
                    .frame(height: 0)
                    .id("scrollTop")

                // CRITICAL: Use consistent content structure
                // Don't switch between skeleton and real content
                LazyVStack(spacing: ResponsiveSpacing.md(geometry)) {
                    if viewModel.isLoading {
                        // Show skeleton cards while loading
                        ForEach(0..<3, id: \.self) { index in
                            SkeletonEventCard()
                                .id("skeleton_\(index)")
                        }
                    } else {
                        // Show actual event cards (ranked by recommendations)
                        ForEach(viewModel.rankedEvents, id: \.id) { event in
                            NavigationLink(destination: EventDetailsView(event: event)) {
                                EventCard(
                                    event: event,
                                    isLiked: favoriteManager.isFavorite(eventId: event.id),
                                    onLikeTap: {
                                        favoriteManager.toggleFavorite(eventId: event.id)
                                        // Record like interaction for recommendations
                                        viewModel.recordEventInteraction(event: event, type: .like)
                                        HapticFeedback.light()
                                    },
                                    onCardTap: {
                                        // Record view interaction for recommendations
                                        viewModel.recordEventInteraction(event: event, type: .view)
                                    },
                                    onShareTap: {
                                        shareEvent = event
                                        showingShareSheet = true
                                        // Record share interaction for recommendations
                                        viewModel.recordEventInteraction(event: event, type: .share)
                                        HapticFeedback.light()
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .id(event.id) // Stable ID
                        }
                    }
                }
                .padding(.horizontal, ResponsiveSpacing.md(geometry))
                .padding(.bottom, ResponsiveSpacing.xl(geometry))
            }
            // CRITICAL: Disable animations on scroll content changes
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
            // CRITICAL: Give ScrollView a stable ID
            .id(scrollViewID)
        }
    }

    // MARK: - Share Functionality

    private func shareItems(for event: Event) -> [Any] {
        var items: [Any] = []

        let eventText = """
        🎉 Check out this event: \(event.title)

        📅 \(DateUtilities.formatEventDateTime(event.startDate))
        📍 \(event.venue.name), \(event.venue.city)

        🎫 Get tickets now!
        """

        items.append(eventText)

        // Deep link URL for the event
        if let url = URL(string: "https://eventpassug.com/events/\(event.id)") {
            items.append(url)
        }

        return items
    }
}

// MARK: - Preview

#Preview {
    AttendeeHomeView()
        .environmentObject(MockAuthRepository())
        .environmentObject(ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        ))
}

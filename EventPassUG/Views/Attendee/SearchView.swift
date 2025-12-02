//
//  SearchView.swift
//  EventPassUG
//
//  Search events by title, category, organizer, and location
//  ✨ Fully responsive with adaptive grid layout
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var favoriteManager = FavoriteManager.shared

    @State private var searchText = ""
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var selectedCategory: EventCategory?

    // Share functionality
    @State private var showingShareSheet = false
    @State private var shareEvent: Event?

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search events, organizers, locations...", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(AppCornerRadius.medium)
                    .padding(AppSpacing.md)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            CategoryFilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                onTap: { selectedCategory = nil }
                            )

                            ForEach(EventCategory.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    onTap: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .padding(.bottom, AppSpacing.md)

                    Divider()

                    // Results
                    if isLoading {
                        ScrollView {
                            VStack(spacing: AppSpacing.md) {
                                ForEach(0..<3, id: \.self) { _ in
                                    SkeletonEventCard()
                                }
                            }
                            .padding(AppSpacing.md)
                        }
                    } else if filteredEvents.isEmpty {
                        VStack(spacing: AppSpacing.lg) {
                            Spacer()

                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text(searchText.isEmpty ? "Start searching" : "No results found")
                                .font(AppTypography.title3)
                                .fontWeight(.semibold)

                            if !searchText.isEmpty {
                                Text("Try adjusting your search or filters")
                                    .font(AppTypography.body)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            ResponsiveEventGrid(
                                events: filteredEvents,
                                geometry: geometry,
                                isLoading: false,
                                onEventTap: { _ in },
                                onLikeTap: { eventId in
                                    favoriteManager.toggleFavorite(eventId: eventId)
                                    HapticFeedback.light()
                                },
                                onShareTap: { event in
                                    shareEvent = event
                                    showingShareSheet = true
                                    HapticFeedback.light()
                                }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Search Events")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            loadEvents()
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

    private var filteredEvents: [Event] {
        var filtered = events

        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
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

// MARK: - Responsive Event Grid

struct ResponsiveEventGrid: View {
    let events: [Event]
    let geometry: GeometryProxy
    let isLoading: Bool
    let onEventTap: (Event) -> Void
    let onLikeTap: (UUID) -> Void
    let onShareTap: ((Event) -> Void)?

    @StateObject private var favoriteManager = FavoriteManager.shared

    // Calculate adaptive columns based on screen width
    private var columns: [GridItem] {
        let width = geometry.size.width
        let minCardWidth: CGFloat = 320 // Minimum card width
        let spacing: CGFloat = AppSpacing.md
        let padding: CGFloat = AppSpacing.md * 2

        // Calculate how many columns can fit
        let availableWidth = width - padding
        let columnCount = max(1, Int(availableWidth / (minCardWidth + spacing)))

        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(events) { event in
                NavigationLink(destination: EventDetailsView(event: event)) {
                    EventCard(
                        event: event,
                        isLiked: favoriteManager.isFavorite(eventId: event.id),
                        onLikeTap: {
                            onLikeTap(event.id)
                        },
                        onCardTap: {},
                        onShareTap: onShareTap != nil ? {
                            onShareTap?(event)
                        } : nil
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity) // Fill entire width
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            HapticFeedback.selection()
        }) {
            Text(title)
                .font(AppTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? RoleConfig.attendeePrimary : Color(UIColor.secondarySystemGroupedBackground))
                )
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

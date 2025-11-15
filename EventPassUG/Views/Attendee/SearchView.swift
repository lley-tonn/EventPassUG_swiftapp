//
//  SearchView.swift
//  EventPassUG
//
//  Search events by title, category, organizer, and location
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

    var body: some View {
        NavigationView {
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
                    VStack(spacing: AppSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonEventCard()
                        }
                    }
                    .padding(AppSpacing.md)
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
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
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
                        .padding(AppSpacing.md)
                    }
                }
            }
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
        .onAppear {
            loadEvents()
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
}

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

#Preview {
    SearchView()
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

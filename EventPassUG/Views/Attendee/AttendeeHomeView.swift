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

    @State private var events: [Event] = []
    @State private var selectedTimeCategory: TimeCategory? = nil
    @State private var selectedEventCategory: EventCategory? = nil
    @State private var isLoading = true
    @State private var likedEventIds: Set<UUID> = []
    @State private var unreadNotifications = 3
    @State private var showingNotifications = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HeaderBar(
                        firstName: authService.currentUser?.firstName ?? "Guest",
                        notificationCount: unreadNotifications,
                        onNotificationTap: {
                            showingNotifications = true
                        }
                    )
                    .padding(.bottom, AppSpacing.md)

                    // Time categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.md) {
                            CategoryTile(
                                title: "Today",
                                icon: "calendar",
                                isSelected: selectedTimeCategory == .today,
                                onTap: {
                                    selectedTimeCategory = selectedTimeCategory == .today ? nil : .today
                                    selectedEventCategory = nil
                                }
                            )

                            CategoryTile(
                                title: "This week",
                                icon: "calendar.badge.clock",
                                isSelected: selectedTimeCategory == .thisWeek,
                                onTap: {
                                    selectedTimeCategory = selectedTimeCategory == .thisWeek ? nil : .thisWeek
                                    selectedEventCategory = nil
                                }
                            )

                            CategoryTile(
                                title: "This month",
                                icon: "calendar.circle",
                                isSelected: selectedTimeCategory == .thisMonth,
                                onTap: {
                                    selectedTimeCategory = selectedTimeCategory == .thisMonth ? nil : .thisMonth
                                    selectedEventCategory = nil
                                }
                            )
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .padding(.bottom, AppSpacing.md)

                    // Event categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.md) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                CategoryTile(
                                    title: category.rawValue,
                                    icon: category.iconName,
                                    isSelected: selectedEventCategory == category,
                                    onTap: {
                                        selectedEventCategory = selectedEventCategory == category ? nil : category
                                        selectedTimeCategory = nil
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .padding(.bottom, AppSpacing.lg)

                    // Events feed
                    if isLoading {
                        VStack(spacing: AppSpacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonEventCard()
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    } else {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailsView(event: event)) {
                                    EventCard(
                                        event: event,
                                        isLiked: likedEventIds.contains(event.id),
                                        onLikeTap: {
                                            toggleLike(for: event.id)
                                        },
                                        onCardTap: {}
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)
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
    }

    private var filteredEvents: [Event] {
        var filtered = events

        // Filter by time category
        if let timeCategory = selectedTimeCategory {
            filtered = filtered.filter { $0.timeCategory == timeCategory }
        }

        // Filter by event category
        if let eventCategory = selectedEventCategory {
            filtered = filtered.filter { $0.category == eventCategory }
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

    private func toggleLike(for eventId: UUID) {
        if likedEventIds.contains(eventId) {
            likedEventIds.remove(eventId)
            Task {
                try? await services.eventService.unlikeEvent(id: eventId)
            }
        } else {
            likedEventIds.insert(eventId)
            Task {
                try? await services.eventService.likeEvent(id: eventId)
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

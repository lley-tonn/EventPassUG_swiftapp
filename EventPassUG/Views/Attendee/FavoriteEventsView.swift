//
//  FavoriteEventsView.swift
//  EventPassUG
//
//  Displays user's favorited/saved events
//

import SwiftUI

struct FavoriteEventsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var favoriteManager = FavoriteManager.shared

    @State private var allEvents: [Event] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: AppSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonEventCard()
                        }
                    }
                    .padding(AppSpacing.md)
                } else if favoriteEvents.isEmpty {
                    // Empty state
                    VStack(spacing: AppSpacing.lg) {
                        Spacer()

                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Favorites Yet")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)

                        Text("Events you like will appear here")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                    .padding(AppSpacing.xl)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(favoriteEvents) { event in
                                NavigationLink(destination: EventDetailsView(event: event)) {
                                    EventCard(
                                        event: event,
                                        isLiked: true,
                                        onLikeTap: {
                                            favoriteManager.removeFavorite(eventId: event.id)
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
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }

                if !favoriteEvents.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                favoriteManager.clearAll()
                                HapticFeedback.success()
                            }) {
                                Label("Clear All Favorites", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadEvents()
        }
    }

    private var favoriteEvents: [Event] {
        allEvents.filter { favoriteManager.isFavorite(eventId: $0.id) }
    }

    private func loadEvents() {
        Task {
            do {
                let fetchedEvents = try await services.eventService.fetchEvents()
                await MainActor.run {
                    allEvents = fetchedEvents
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
    FavoriteEventsView()
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

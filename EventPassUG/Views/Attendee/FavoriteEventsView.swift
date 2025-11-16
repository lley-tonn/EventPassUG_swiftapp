//
//  FavoriteEventsView.swift
//  EventPassUG
//
//  Displays user's favorited/saved events with modern UI
//

import SwiftUI

struct FavoriteEventsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var favoriteManager = FavoriteManager.shared

    @State private var allEvents: [Event] = []
    @State private var isLoading = true
    @State private var sortOption: SortOption = .dateAdded
    @State private var showingSortMenu = false

    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case eventDate = "Event Date"
        case alphabetical = "A-Z"

        var icon: String {
            switch self {
            case .dateAdded: return "clock"
            case .eventDate: return "calendar"
            case .alphabetical: return "textformat.abc"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Modern header with gradient accent
            VStack(spacing: 0) {
                // Top bar with close and actions
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(UIColor.tertiarySystemFill))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Sort button
                    if !favoriteEvents.isEmpty {
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    sortOption = option
                                    HapticFeedback.selection()
                                }) {
                                    Label(option.rawValue, systemImage: option.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(Color(UIColor.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                    }

                    if !favoriteEvents.isEmpty {
                        Menu {
                            Button(role: .destructive, action: {
                                withAnimation {
                                    favoriteManager.clearAll()
                                }
                                HapticFeedback.success()
                            }) {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(Color(UIColor.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)

                // Title section with heart icon
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.pink)

                    Text("My Favorites")
                        .font(.system(size: 28, weight: .bold))

                    Spacer()

                    if !favoriteEvents.isEmpty {
                        Text("\(favoriteEvents.count)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 28)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.pink)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.sm)

                // Sort indicator
                if !favoriteEvents.isEmpty {
                    HStack {
                        Image(systemName: sortOption.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text("Sorted by \(sortOption.rawValue)")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                }
            }
            .background(Color(UIColor.systemBackground))

            // Content
            if isLoading {
                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonEventCard()
                        }
                    }
                    .padding(AppSpacing.md)
                }
            } else if favoriteEvents.isEmpty {
                // Modern empty state
                VStack(spacing: AppSpacing.lg) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.1))
                            .frame(width: 120, height: 120)

                        Image(systemName: "heart.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.pink.opacity(0.6))
                    }

                    VStack(spacing: AppSpacing.sm) {
                        Text("No Favorites Yet")
                            .font(.system(size: 24, weight: .bold))

                        Text("Tap the heart icon on events\nyou'd like to save for later")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: { dismiss() }) {
                        Text("Browse Events")
                            .font(AppTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.xl)
                            .padding(.vertical, AppSpacing.sm)
                            .background(Color.pink)
                            .cornerRadius(AppCornerRadius.medium)
                    }
                    .padding(.top, AppSpacing.md)

                    Spacer()
                }
                .padding(AppSpacing.xl)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(sortedFavoriteEvents) { event in
                            FavoriteEventCard(
                                event: event,
                                onRemove: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        favoriteManager.removeFavorite(eventId: event.id)
                                    }
                                    HapticFeedback.light()
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            loadEvents()
        }
    }

    private var favoriteEvents: [Event] {
        allEvents.filter { favoriteManager.isFavorite(eventId: $0.id) }
    }

    private var sortedFavoriteEvents: [Event] {
        switch sortOption {
        case .dateAdded:
            return favoriteEvents // Already in order of addition
        case .eventDate:
            return favoriteEvents.sorted(by: { $0.startDate < $1.startDate })
        case .alphabetical:
            return favoriteEvents.sorted(by: { $0.title < $1.title })
        }
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

// MARK: - Favorite Event Card (Compact Design)

struct FavoriteEventCard: View {
    let event: Event
    let onRemove: () -> Void

    private var isFreeEvent: Bool {
        event.ticketTypes.allSatisfy { $0.price == 0 }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Event image thumbnail
            ZStack {
                if let posterURL = event.posterURL, !posterURL.isEmpty {
                    AsyncImage(url: URL(string: posterURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [event.category.color, event.category.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: event.category.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(AppCornerRadius.medium)
            .clipped()

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppTypography.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(event.venue.name)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Price tag
                HStack {
                    if isFreeEvent {
                        Text("FREE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    } else {
                        Text("From UGX \(Int(event.ticketTypes.first?.price ?? 0).formatted())")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.pink)
                    }
                }
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.pink)
                    .frame(width: 44, height: 44)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(AppSpacing.sm)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
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

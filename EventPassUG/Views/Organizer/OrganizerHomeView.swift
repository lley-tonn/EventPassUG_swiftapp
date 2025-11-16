//
//  OrganizerHomeView.swift
//  EventPassUG
//
//  Organizer home screen with event list and create button
//

import SwiftUI

struct OrganizerHomeView: View {
    @EnvironmentObject var authService: MockAuthService
    @EnvironmentObject var services: ServiceContainer

    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var showingCreateEvent = false
    @State private var selectedFilter: EventStatus = .published
    @State private var unreadNotifications = 2
    @State private var showingVerificationSheet = false

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
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventWizard()
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
                // Header
                HeaderBar(
                    firstName: authService.currentUser?.firstName ?? "Organizer",
                    notificationCount: unreadNotifications,
                    onNotificationTap: {}
                )
                .padding(.bottom, AppSpacing.md)

                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach([EventStatus.published, .draft, .ongoing], id: \.self) { status in
                            FilterChip(
                                title: status.rawValue.capitalized,
                                count: events.filter { $0.status == status }.count,
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
                                NavigationLink(destination: OrganizerEventDetailView(event: event)) {
                                    OrganizerEventCard(event: event)
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateEvent = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }
                }
            }
    }

    private var filteredEvents: [Event] {
        events.filter { $0.status == selectedFilter }
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

    var body: some View {
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

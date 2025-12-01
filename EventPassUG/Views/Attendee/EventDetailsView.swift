//
//  EventDetailsView.swift
//  EventPassUG
//
//  Event details screen with map, tickets, and rating
//

import SwiftUI
import MapKit

struct EventDetailsView: View {
    let event: Event

    @EnvironmentObject var services: ServiceContainer
    @EnvironmentObject var authService: MockAuthService
    @Environment(\.dismiss) var dismiss
    @StateObject private var followManager = FollowManager.shared

    @State private var isLiked = false
    @State private var selectedTicketType: TicketType?
    @State private var showingTicketPurchase = false
    @State private var showingShareSheet = false
    @State private var userRating: Double = 0
    @State private var region: MKCoordinateRegion

    init(event: Event) {
        self.event = event
        _region = State(initialValue: MKCoordinateRegion(
            center: event.venue.coordinate.clLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster image - FIXED: Using GeometryReader for responsive sizing
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        // Poster - maintains aspect ratio based on screen width
                        EventPosterImage(posterURL: event.posterURL, height: geometry.size.width * 0.67) // FIXED: Responsive height (3:2 ratio)

                        // Happening now banner
                        if event.isHappeningNow {
                            HStack(spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                                PulsingDot(size: 11) // FIXED: Increased from 10 for better visibility
                                Text("HAPPENING NOW")
                                    .font(AppTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, AppSpacing.md) // FIXED: Using design system constant
                            .padding(.vertical, AppSpacing.compactSpacing) // FIXED: Using design system constant
                            .background(
                                RoleConfig.happeningNow
                            )
                            .cornerRadius(AppCornerRadius.small)
                            .padding(AppSpacing.md)
                        }
                    }
                }
                .aspectRatio(1.5, contentMode: .fit) // FIXED: Aspect ratio constraint (3:2 = 1.5)

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Title and actions
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(event.title)
                            .font(AppTypography.largeTitle) // FIXED: Using design system typography instead of fixed size
                            .minimumScaleFactor(0.7)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: AppSpacing.sm) {
                            Text("by \(event.organizerName)")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)

                            Button(action: {
                                followManager.toggleFollow(
                                    organizerId: event.organizerId,
                                    organizerName: event.organizerName,
                                    followerId: authService.currentUser?.id,
                                    followerName: authService.currentUser?.fullName
                                )
                                HapticFeedback.light()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: followManager.isFollowing(organizerId: event.organizerId) ? "checkmark" : "plus")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(followManager.isFollowing(organizerId: event.organizerId) ? "Following" : "Follow")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(followManager.isFollowing(organizerId: event.organizerId) ? .white : RoleConfig.attendeePrimary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 6)
                                .background(
                                    followManager.isFollowing(organizerId: event.organizerId)
                                        ? RoleConfig.attendeePrimary
                                        : RoleConfig.attendeePrimary.opacity(0.1)
                                )
                                .cornerRadius(AppCornerRadius.small)
                            }

                            Spacer()
                        }

                        // Actions
                        HStack(spacing: AppSpacing.sm) { // FIXED: Using design system constant
                            AnimatedLikeButton(isLiked: $isLiked) {
                                isLiked.toggle()
                            }
                            .frame(minWidth: AppButtonDimensions.minimumTouchTarget, minHeight: AppButtonDimensions.minimumTouchTarget) // FIXED: Ensure touch target

                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 24)) // FIXED: Increased from 22 for better visibility
                                    .foregroundColor(.primary)
                                    .frame(minWidth: AppButtonDimensions.minimumTouchTarget, minHeight: AppButtonDimensions.minimumTouchTarget) // FIXED: Ensure touch target
                            }

                            Button(action: {}) {
                                Image(systemName: "exclamationmark.bubble")
                                    .font(.system(size: 24)) // FIXED: Increased from 22 for better visibility
                                    .foregroundColor(.primary)
                                    .frame(minWidth: AppButtonDimensions.minimumTouchTarget, minHeight: AppButtonDimensions.minimumTouchTarget) // FIXED: Ensure touch target
                            }

                            Spacer(minLength: AppSpacing.compactSpacing) // FIXED: Using design system constant

                            // Rating
                            if event.totalRatings > 0 {
                                HStack(spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 18)) // FIXED: Increased from 16 for better visibility
                                    Text(String(format: "%.1f", event.rating))
                                        .font(AppTypography.headline)
                                        .lineLimit(1)
                                    Text("(\(event.totalRatings))")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Divider()

                    // Date and time
                    InfoRow(
                        icon: "calendar",
                        title: "Date & Time",
                        value: DateUtilities.formatEventFullDateTime(event.startDate, endDate: event.endDate)
                    )

                    Divider()

                    // Venue with map
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        InfoRow(
                            icon: "location.fill",
                            title: "Venue",
                            value: "\(event.venue.name)\n\(event.venue.address), \(event.venue.city)"
                        )

                        // Map - FIXED: Responsive height using GeometryReader
                        GeometryReader { geometry in
                            Map(coordinateRegion: .constant(region), annotationItems: [event]) { event in
                                MapMarker(
                                    coordinate: event.venue.coordinate.clLocation,
                                    tint: RoleConfig.attendeePrimary
                                )
                            }
                            .frame(width: geometry.size.width)
                            .cornerRadius(AppCornerRadius.medium)
                            .allowsHitTesting(false)
                        }
                        .aspectRatio(2.0, contentMode: .fit) // FIXED: Aspect ratio instead of fixed height
                        .frame(maxWidth: .infinity)

                        Button(action: openInMaps) {
                            Label("Open in Maps", systemImage: "map.fill")
                                .font(AppTypography.callout)
                                .foregroundColor(RoleConfig.attendeePrimary)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("About")
                            .font(AppTypography.title3)
                            .fontWeight(.semibold)

                        Text(event.description)
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()

                    // Tickets
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Tickets")
                            .font(AppTypography.title3)
                            .fontWeight(.semibold)

                        // Filter and sort tickets: Active first, then Upcoming, hide Expired
                        let sortedTickets = event.ticketTypes
                            .filter { $0.availabilityStatus != .expired } // Hide expired tickets
                            .sorted { ticket1, ticket2 in
                                // Sort by status: Active > Upcoming > SoldOut
                                let statusOrder: [TicketAvailabilityStatus: Int] = [
                                    .active: 0,
                                    .upcoming: 1,
                                    .soldOut: 2,
                                    .expired: 3
                                ]
                                return (statusOrder[ticket1.availabilityStatus] ?? 3) < (statusOrder[ticket2.availabilityStatus] ?? 3)
                            }

                        if sortedTickets.isEmpty {
                            Text("No tickets currently available")
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, AppSpacing.lg)
                        } else {
                            ForEach(sortedTickets) { ticketType in
                                TicketTypeCard(
                                    ticketType: ticketType,
                                    isSelected: selectedTicketType?.id == ticketType.id,
                                    onTap: {
                                        if ticketType.isPurchasable {
                                            HapticFeedback.selection()
                                            selectedTicketType = ticketType
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Rating section (if event ended and user attended)
                    if event.endDate < Date() {
                        Divider()

                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Rate this event")
                                .font(AppTypography.title3)
                                .fontWeight(.semibold)

                            HStack(spacing: AppSpacing.sm) { // FIXED: Using design system constant
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        userRating = Double(star)
                                        HapticFeedback.light()
                                    }) {
                                        Image(systemName: star <= Int(userRating) ? "star.fill" : "star")
                                            .font(.system(size: 34)) // FIXED: Increased from 30 for better visibility
                                            .foregroundColor(.yellow)
                                            .frame(minWidth: AppButtonDimensions.minimumTouchTarget, minHeight: AppButtonDimensions.minimumTouchTarget) // FIXED: Ensure touch target
                                    }
                                }
                            }

                            if userRating > 0 {
                                Button(action: submitRating) {
                                    Text("Submit Rating")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(RoleConfig.attendeePrimary)
                                        .cornerRadius(AppCornerRadius.medium)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !event.ticketTypes.isEmpty && event.startDate > Date() {
                let hasActivePurchasableTickets = event.ticketTypes.contains { $0.isPurchasable }

                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: AppSpacing.sm) { // FIXED: Using design system constant
                        VStack(alignment: .leading, spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                            if let ticketType = selectedTicketType {
                                Text(ticketType.formattedPrice)
                                    .font(AppTypography.title3)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                HStack(spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                                    Text(ticketType.name)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)

                                    if ticketType.isPurchasable {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12)) // FIXED: Increased from 10 for better visibility
                                            .foregroundColor(.green)
                                    }
                                }
                            } else if hasActivePurchasableTickets {
                                Text(event.priceRange)
                                    .font(AppTypography.title3)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Text("Select a ticket type")
                                    .font(AppTypography.caption)
                                    .minimumScaleFactor(0.85)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text("No tickets on sale")
                                    .font(AppTypography.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Text("Check back later")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer(minLength: AppSpacing.compactSpacing) // FIXED: Using design system constant

                        Button(action: {
                            // Double-check that ticket is still purchasable before opening purchase sheet
                            if let ticket = selectedTicketType, ticket.isPurchasable {
                                showingTicketPurchase = true
                            }
                        }) {
                            Text(event.isHappeningNow ? "Join Now" : "Buy Ticket")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.horizontal, AppSpacing.lg) // FIXED: Using design system constant
                                .padding(.vertical, AppSpacing.md)
                                .frame(minHeight: AppButtonDimensions.minimumTouchTarget) // FIXED: Ensure touch target
                                .background(RoleConfig.attendeePrimary)
                                .cornerRadius(AppCornerRadius.medium)
                        }
                        .disabled(selectedTicketType == nil || !(selectedTicketType?.isPurchasable ?? false))
                        .opacity((selectedTicketType != nil && selectedTicketType?.isPurchasable == true) ? 1.0 : 0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
        .sheet(isPresented: $showingTicketPurchase) {
            if let ticketType = selectedTicketType {
                TicketPurchaseView(event: event, ticketType: ticketType)
            }
        }
    }

    private func openInMaps() {
        let coordinate = event.venue.coordinate.clLocation
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = event.venue.name
        mapItem.openInMaps(launchOptions: nil)
    }

    private func submitRating() {
        Task {
            try? await services.eventService.rateEvent(id: event.id, rating: userRating, review: nil)
            HapticFeedback.success()
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22)) // FIXED: Increased from 20 for better visibility
                .foregroundColor(RoleConfig.attendeePrimary)
                .frame(minWidth: 32) // FIXED: Changed from fixed width to minWidth

            VStack(alignment: .leading, spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(AppTypography.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TicketTypeCard: View {
    let ticketType: TicketType
    let isSelected: Bool
    let onTap: () -> Void

    private var isDisabled: Bool {
        !ticketType.isPurchasable
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top, spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                    VStack(alignment: .leading, spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                        HStack(spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                            Text(ticketType.name)
                                .font(AppTypography.headline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)

                            // Status badge
                            HStack(spacing: 3) { // Keep small for compact badge
                                Image(systemName: ticketType.availabilityStatus.iconName)
                                    .font(.system(size: 11)) // FIXED: Increased from 10 for better visibility
                                Text(ticketType.availabilityStatus.rawValue)
                                    .font(.system(size: 11, weight: .semibold)) // FIXED: Increased from 10 for better readability
                            }
                            .foregroundColor(ticketType.availabilityStatus.color)
                            .padding(.horizontal, AppSpacing.compactSpacing) // FIXED: Using design system constant
                            .padding(.vertical, 3) // Keep small for compact badge
                            .background(ticketType.availabilityStatus.color.opacity(0.15))
                            .cornerRadius(AppCornerRadius.small) // FIXED: Using design system constant
                        }

                        if let description = ticketType.description {
                            Text(description)
                                .font(AppTypography.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                        }

                        // Quantity remaining
                        if ticketType.isUnlimitedQuantity {
                            Text("Unlimited tickets available")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(ticketType.remaining) of \(ticketType.quantity) remaining")
                                .font(AppTypography.caption)
                                .foregroundColor(ticketType.isSoldOut ? .red : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                        Text(ticketType.formattedPrice)
                            .font(AppTypography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(isDisabled ? .gray : RoleConfig.attendeePrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if isSelected && !isDisabled {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22)) // FIXED: Added explicit size for better visibility
                                .foregroundColor(RoleConfig.attendeePrimary)
                        }
                    }
                    .frame(minWidth: 70) // FIXED: Slightly increased from 60 for better layout
                }
                .frame(maxWidth: .infinity)

                // Availability info
                if ticketType.availabilityStatus == .upcoming {
                    HStack(spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12)) // FIXED: Increased from 11 for better visibility
                        Text(ticketType.availabilityText)
                            .font(.system(size: 12, weight: .medium)) // FIXED: Increased from 11 for better readability
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, AppSpacing.compactSpacing) // FIXED: Using design system constant
                    .padding(.vertical, AppSpacing.compactSpacing) // FIXED: Using design system constant
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small) // FIXED: Using design system constant
                } else if ticketType.availabilityStatus == .active {
                    HStack(spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                        Image(systemName: "timer")
                            .font(.system(size: 12)) // FIXED: Increased from 11 for better visibility
                        Text(ticketType.availabilityText)
                            .font(.system(size: 12)) // FIXED: Increased from 11 for better readability
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(
                        isSelected && !isDisabled ? RoleConfig.attendeePrimary : Color.gray.opacity(0.3),
                        lineWidth: isSelected && !isDisabled ? 2 : 1
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isDisabled ? Color(UIColor.systemGray6) : Color.clear)
            )
            .opacity(isDisabled ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    NavigationView {
        EventDetailsView(event: Event.samples[0])
            .environmentObject(ServiceContainer(
                authService: MockAuthService(),
                eventService: MockEventService(),
                ticketService: MockTicketService(),
                paymentService: MockPaymentService()
            ))
    }
}

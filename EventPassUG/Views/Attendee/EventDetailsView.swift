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
    @Environment(\.dismiss) var dismiss

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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Poster image
                ZStack(alignment: .topLeading) {
                    if let posterURL = event.posterURL {
                        Image(posterURL)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 280)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            )
                    }

                    // Happening now banner
                    if event.isHappeningNow {
                        HStack(spacing: 8) {
                            PulsingDot(size: 10)
                            Text("HAPPENING NOW")
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoleConfig.happeningNow
                        )
                        .cornerRadius(AppCornerRadius.small)
                        .padding(AppSpacing.md)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Title and actions
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(event.title)
                            .font(AppTypography.largeTitle)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("by \(event.organizerName)")
                            .font(AppTypography.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        // Actions
                        HStack(spacing: AppSpacing.lg) {
                            AnimatedLikeButton(isLiked: $isLiked) {
                                isLiked.toggle()
                            }

                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                    .foregroundColor(.primary)
                            }

                            Button(action: {}) {
                                Image(systemName: "exclamationmark.bubble")
                                    .font(.system(size: 22))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            // Rating
                            if event.totalRatings > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", event.rating))
                                        .font(AppTypography.headline)
                                    Text("(\(event.totalRatings))")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
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

                        // Map
                        Map(coordinateRegion: .constant(region), annotationItems: [event]) { event in
                            MapMarker(
                                coordinate: event.venue.coordinate.clLocation,
                                tint: RoleConfig.attendeePrimary
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .cornerRadius(AppCornerRadius.medium)
                        .allowsHitTesting(false)

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

                        ForEach(event.ticketTypes) { ticketType in
                            TicketTypeCard(
                                ticketType: ticketType,
                                isSelected: selectedTicketType?.id == ticketType.id,
                                onTap: {
                                    HapticFeedback.selection()
                                    selectedTicketType = ticketType
                                }
                            )
                        }
                    }

                    // Rating section (if event ended and user attended)
                    if event.endDate < Date() {
                        Divider()

                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Rate this event")
                                .font(AppTypography.title3)
                                .fontWeight(.semibold)

                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(userRating) ? "star.fill" : "star")
                                        .font(.system(size: 30))
                                        .foregroundColor(.yellow)
                                        .onTapGesture {
                                            userRating = Double(star)
                                            HapticFeedback.light()
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
                .padding(AppSpacing.md)
            }
        }
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
                VStack(spacing: 0) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedTicketType?.formattedPrice ?? event.priceRange)
                                .font(AppTypography.title3)
                                .fontWeight(.bold)
                                .lineLimit(1)

                            if let ticketType = selectedTicketType {
                                Text(ticketType.name)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 8)

                        Button(action: {
                            showingTicketPurchase = true
                        }) {
                            Text(event.isHappeningNow ? "Join Now" : "Buy Ticket")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, AppSpacing.xl)
                                .padding(.vertical, AppSpacing.md)
                                .background(RoleConfig.attendeePrimary)
                                .cornerRadius(AppCornerRadius.medium)
                        }
                        .disabled(selectedTicketType == nil)
                        .opacity(selectedTicketType == nil ? 0.5 : 1.0)
                    }
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
                .font(.system(size: 20))
                .foregroundColor(RoleConfig.attendeePrimary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(AppTypography.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TicketTypeCard: View {
    let ticketType: TicketType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticketType.name)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let description = ticketType.description {
                        Text(description)
                            .font(AppTypography.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Text("\(ticketType.remaining) of \(ticketType.quantity) remaining")
                        .font(AppTypography.caption)
                        .foregroundColor(ticketType.isSoldOut ? .red : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(ticketType.formattedPrice)
                        .font(AppTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(RoleConfig.attendeePrimary)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(RoleConfig.attendeePrimary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(
                        isSelected ? RoleConfig.attendeePrimary : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .opacity(ticketType.isSoldOut ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(ticketType.isSoldOut)
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

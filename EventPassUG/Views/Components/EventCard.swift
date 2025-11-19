//
//  EventCard.swift
//  EventPassUG
//
//  Event card component with poster, details, and happening now indicator
//

import SwiftUI

struct EventCard: View {
    let event: Event
    let isLiked: Bool
    let onLikeTap: () -> Void
    let onCardTap: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let cardHeight = geometry.size.width * 0.55

            VStack(alignment: .leading, spacing: 0) {
                // Poster image
                ZStack(alignment: .topLeading) {
                    // Poster
                    if let posterURL = event.posterURL {
                        Image(posterURL)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: geometry.size.width, height: cardHeight)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: geometry.size.width, height: cardHeight)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: min(geometry.size.width * 0.12, 40)))
                                    .foregroundColor(.gray)
                            )
                    }

                    // Happening now indicator
                    if event.isHappeningNow {
                        HStack(spacing: 6) {
                            PulsingDot(size: 8)
                            Text("Happening now")
                                .font(.system(size: max(10, geometry.size.width * 0.03)))
                                .fontWeight(.semibold)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(.horizontal, max(8, geometry.size.width * 0.03))
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .padding(AppSpacing.sm)
                    }
                }

                // Event details
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    // Title and like button
                    HStack(alignment: .top, spacing: 8) {
                        Text(event.title)
                            .font(AppTypography.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        AnimatedLikeButton(isLiked: .constant(isLiked)) {
                            onLikeTap()
                        }
                        .frame(width: 30, height: 30)
                    }

                    // Date and time
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(DateUtilities.formatEventDateTime(event.startDate))
                            .font(AppTypography.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(.secondary)

                    // Venue
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(event.venue.name)
                            .font(AppTypography.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(.secondary)

                    // Price and rating
                    HStack(spacing: 8) {
                        Text(event.priceRange)
                            .font(AppTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(RoleConfig.attendeePrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Spacer(minLength: 4)

                        if event.totalRatings > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", event.rating))
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.secondary)
                                Text("(\(event.totalRatings))")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        }
                    }
                }
                .padding(.horizontal, max(12, geometry.size.width * 0.04))
                .padding(.vertical, AppSpacing.sm)
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(AppCornerRadius.medium)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(event.title), \(DateUtilities.formatEventDateTime(event.startDate)), \(event.venue.name)")
            .accessibilityHint("Double tap to view event details")
            .frame(height: cardHeight + 140) // Dynamic card height + content
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.md) {
            ForEach(Event.samples.prefix(2)) { event in
                EventCard(
                    event: event,
                    isLiked: false,
                    onLikeTap: {},
                    onCardTap: {}
                )
            }
        }
        .padding()
    }
}

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
        VStack(alignment: .leading, spacing: 0) {
            // Poster image - FIXED: Using aspect ratio instead of fixed height
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Poster - maintains 4:5 aspect ratio
                    EventPosterImage(posterURL: event.posterURL, height: geometry.size.width * 1.25)

                    // Happening now indicator
                    if event.isHappeningNow {
                        HStack(spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                            PulsingDot(size: 10) // FIXED: Increased from 8 for better visibility
                            Text("Happening now")
                                .font(.system(size: 13)) // FIXED: Increased from 12 for better readability
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, AppSpacing.sm) // FIXED: Using design system constant
                        .padding(.vertical, AppSpacing.compactSpacing) // FIXED: Using design system constant
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .padding(AppSpacing.sm)
                    }
                }
            }
            .aspectRatio(0.65, contentMode: .fit) // Reduced poster size for compact display

            // Event details
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Title and like button
                HStack(alignment: .top, spacing: AppSpacing.compactSpacing) { // FIXED: Using design system constant
                    Text(event.title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    AnimatedLikeButton(isLiked: .constant(isLiked)) {
                        onLikeTap()
                    }
                    .frame(width: AppButtonDimensions.minimumTouchTarget, height: AppButtonDimensions.minimumTouchTarget) // FIXED: Minimum 44pt touch target
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
            .padding(.horizontal, AppSpacing.sm) // FIXED: Using design system constant
            .padding(.vertical, AppSpacing.sm)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.1), radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y) // FIXED: Using design system shadow values
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), \(DateUtilities.formatEventDateTime(event.startDate)), \(event.venue.name)")
        .accessibilityHint("Double tap to view event details")
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

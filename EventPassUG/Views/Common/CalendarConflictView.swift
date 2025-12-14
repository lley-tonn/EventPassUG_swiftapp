//
//  CalendarConflictView.swift
//  EventPassUG
//
//  View to display calendar conflicts when purchasing tickets or creating events
//  Warns users about conflicting events and allows them to proceed or cancel
//

import SwiftUI
import EventKit

struct CalendarConflictView: View {
    let conflicts: [CalendarConflict]
    let event: Event
    let onProceed: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Warning header
                warningHeader

                // Conflicts list
                ScrollView {
                    VStack(spacing: AppDesign.Spacing.md) {
                        ForEach(conflicts) { conflict in
                            ConflictCard(conflict: conflict)
                        }
                    }
                    .padding(AppDesign.Spacing.edge)
                }

                // Actions
                actionButtons
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Schedule Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                        onCancel()
                    }
                }
            }
        }
    }

    // MARK: - Components

    private var warningHeader: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Calendar Conflict Detected")
                .font(AppTypography.title2)
                .fontWeight(.bold)

            Text("You have \(conflicts.count) \(conflicts.count == 1 ? "event" : "events") that \(conflicts.count == 1 ? "conflicts" : "conflict") with this event")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Event info
            VStack(spacing: AppDesign.Spacing.xs) {
                Text(event.title)
                    .font(AppTypography.headline)
                    .fontWeight(.semibold)

                HStack(spacing: AppDesign.Spacing.xs) {
                    Image(systemName: "calendar")
                    Text(formatDateRange(start: event.startDate, end: event.endDate))
                }
                .font(AppTypography.subheadline)
                .foregroundColor(.secondary)

                HStack(spacing: AppDesign.Spacing.xs) {
                    Image(systemName: "location.fill")
                    Text(event.venue.name)
                }
                .font(AppTypography.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(AppDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.medium)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .padding(AppDesign.Spacing.edge)
        .background(Color(UIColor.systemBackground))
    }

    private var actionButtons: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            // Proceed button
            Button(action: {
                dismiss()
                onProceed()
            }) {
                Text("Proceed Anyway")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppDesign.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppDesign.CornerRadius.medium)
                            .fill(Color.orange)
                    )
            }

            // Cancel button
            Button(action: {
                dismiss()
                onCancel()
            }) {
                Text("Cancel")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
            }

            // Info text
            Text("You can still purchase tickets, but be aware of the conflict")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppDesign.Spacing.edge)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Helper Methods

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDate(start, inSameDayAs: end) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let dateStr = formatter.string(from: start)

            formatter.dateStyle = .none
            let endTimeStr = formatter.string(from: end)

            return "\(dateStr) - \(endTimeStr)"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)
            return "\(startStr) - \(endStr)"
        }
    }
}

// MARK: - Conflict Card

struct ConflictCard: View {
    let conflict: CalendarConflict

    var body: some View {
        HStack(alignment: .top, spacing: AppDesign.Spacing.md) {
            Image(systemName: conflictIcon)
                .font(.title2)
                .foregroundColor(conflictColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
                Text(conflict.event.title ?? "Untitled Event")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)

                Text(conflict.displayDescription)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)

                if let startDate = conflict.event.startDate,
                   let endDate = conflict.event.endDate {
                    HStack(spacing: AppDesign.Spacing.xs) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(formatTime(start: startDate, end: endDate))
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(.secondary)
                }

                if let location = conflict.event.location {
                    HStack(spacing: AppDesign.Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(location)
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(.secondary)
                }

                // Conflict type badge
                HStack(spacing: AppDesign.Spacing.xs) {
                    Image(systemName: conflictTypeIcon)
                        .font(.caption2)
                    Text(conflictTypeText)
                        .font(AppTypography.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppDesign.Spacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(conflictColor)
                )
            }

            Spacer()
        }
        .padding(AppDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.medium)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private var conflictIcon: String {
        switch conflict.conflictType {
        case .exact:
            return "exclamationmark.circle.fill"
        case .partial:
            return "exclamationmark.triangle.fill"
        case .adjacent:
            return "info.circle.fill"
        }
    }

    private var conflictColor: Color {
        switch conflict.conflictType {
        case .exact:
            return .red
        case .partial:
            return .orange
        case .adjacent:
            return .blue
        }
    }

    private var conflictTypeIcon: String {
        switch conflict.conflictType {
        case .exact:
            return "equal.circle.fill"
        case .partial:
            return "arrow.left.and.right.circle.fill"
        case .adjacent:
            return "arrow.right.circle.fill"
        }
    }

    private var conflictTypeText: String {
        switch conflict.conflictType {
        case .exact:
            return "Same Time"
        case .partial:
            return "Overlapping"
        case .adjacent:
            return "Back-to-back"
        }
    }

    private func formatTime(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let startTime = formatter.string(from: start)
        let endTime = formatter.string(from: end)

        return "\(startTime) - \(endTime)"
    }
}

// MARK: - Preview

#Preview {
    let mockEvent = Event(
        title: "Summer Music Festival",
        description: "Amazing concert",
        organizerId: UUID(),
        organizerName: "EventMasters",
        category: .music,
        startDate: Date().addingTimeInterval(7200),
        endDate: Date().addingTimeInterval(10800),
        venue: Venue(
            name: "Kampala Serena Hotel",
            address: "Kintu Road",
            city: "Kampala",
            coordinate: Venue.Coordinate(latitude: 0.3136, longitude: 32.5811)
        )
    )

    let mockEKEvent = EKEvent(eventStore: EKEventStore())
    mockEKEvent.title = "Team Meeting"
    mockEKEvent.startDate = Date().addingTimeInterval(7200)
    mockEKEvent.endDate = Date().addingTimeInterval(9000)
    mockEKEvent.location = "Office"

    let mockConflict = CalendarConflict(event: mockEKEvent, conflictType: .partial)

    return CalendarConflictView(
        conflicts: [mockConflict],
        event: mockEvent,
        onProceed: { print("Proceed") },
        onCancel: { print("Cancel") }
    )
}

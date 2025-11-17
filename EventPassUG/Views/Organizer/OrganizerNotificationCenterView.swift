//
//  OrganizerNotificationCenterView.swift
//  EventPassUG
//
//  Notification center for organizers showing ticket sales, event updates, etc.
//

import SwiftUI

struct OrganizerNotificationCenterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @EnvironmentObject var services: ServiceContainer

    @State private var notifications: [OrganizerNotification] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
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

                    Text("Notifications")
                        .font(AppTypography.headline)

                    Spacer()

                    Button(action: markAllAsRead) {
                        Text("Mark all read")
                            .font(AppTypography.caption)
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)

                Divider()

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if notifications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notifications) { notification in
                                OrganizerNotificationRow(notification: notification)
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadNotifications()
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Notifications")
                .font(AppTypography.title3)
                .fontWeight(.semibold)

            Text("You'll see ticket sales, event updates, and important alerts here")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }

    private func loadNotifications() {
        // Load organizer-specific notifications
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                // Mock organizer notifications
                notifications = [
                    OrganizerNotification(
                        id: UUID(),
                        type: .ticketSale,
                        title: "New Ticket Sale",
                        message: "Someone purchased 2 VIP tickets for your event 'Tech Innovators Summit'",
                        timestamp: Date().addingTimeInterval(-3600),
                        isRead: false,
                        eventId: UUID()
                    ),
                    OrganizerNotification(
                        id: UUID(),
                        type: .eventMilestone,
                        title: "Event Milestone",
                        message: "Your event 'Summer Music Festival' reached 100 ticket sales!",
                        timestamp: Date().addingTimeInterval(-7200),
                        isRead: false,
                        eventId: UUID()
                    ),
                    OrganizerNotification(
                        id: UUID(),
                        type: .eventReminder,
                        title: "Event Starting Soon",
                        message: "Your event 'Charity Run' starts in 24 hours",
                        timestamp: Date().addingTimeInterval(-86400),
                        isRead: true,
                        eventId: UUID()
                    )
                ]
                isLoading = false
            }
        }
    }

    private func markAllAsRead() {
        withAnimation {
            notifications = notifications.map { notification in
                var updated = notification
                updated.isRead = true
                return updated
            }
        }
        HapticFeedback.success()
    }
}

// MARK: - Organizer Notification Model

struct OrganizerNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let eventId: UUID?

    enum NotificationType {
        case ticketSale
        case eventMilestone
        case eventReminder
        case payoutReady
        case eventUpdate

        var iconName: String {
            switch self {
            case .ticketSale: return "ticket.fill"
            case .eventMilestone: return "star.fill"
            case .eventReminder: return "bell.fill"
            case .payoutReady: return "banknote.fill"
            case .eventUpdate: return "info.circle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .ticketSale: return .green
            case .eventMilestone: return .yellow
            case .eventReminder: return .orange
            case .payoutReady: return .blue
            case .eventUpdate: return .purple
            }
        }
    }
}

// MARK: - Notification Row

struct OrganizerNotificationRow: View {
    let notification: OrganizerNotification

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.type.iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: notification.type.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(notification.type.iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(AppTypography.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)

                    Spacer()

                    if !notification.isRead {
                        Circle()
                            .fill(RoleConfig.organizerPrimary)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.message)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(notification.timestamp.formatted(.relative(presentation: .named)))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(notification.isRead ? Color.clear : RoleConfig.organizerPrimary.opacity(0.05))
    }
}

#Preview {
    OrganizerNotificationCenterView()
        .environmentObject(MockAuthService())
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

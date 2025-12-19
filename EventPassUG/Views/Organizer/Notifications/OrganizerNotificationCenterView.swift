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
    @StateObject private var notificationManager = InAppNotificationManager.shared

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
                } else if notificationManager.notifications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notificationManager.notifications) { notification in
                                OrganizerNotificationRowView(notification: notification)
                                    .onTapGesture {
                                        notificationManager.markAsRead(notificationId: notification.id)
                                    }
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
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func markAllAsRead() {
        notificationManager.markAllAsRead()
        HapticFeedback.success()
    }
}

// MARK: - Organizer Notification Row

struct OrganizerNotificationRowView: View {
    let notification: NotificationModel

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

// MARK: - NotificationType Extension

extension NotificationType {
    var iconName: String {
        switch self {
        case .ticketPurchased: return "ticket.fill"
        case .ticketScanned: return "checkmark.circle.fill"
        case .eventReminder: return "bell.fill"
        case .paymentReceived: return "banknote.fill"
        case .eventUpdate: return "info.circle.fill"
        case .newEvent: return "star.fill"
        case .newFollower: return "person.badge.plus.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .ticketPurchased: return .green
        case .ticketScanned: return .blue
        case .eventReminder: return .orange
        case .paymentReceived: return .purple
        case .eventUpdate: return .indigo
        case .newEvent: return .yellow
        case .newFollower: return .pink
        }
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

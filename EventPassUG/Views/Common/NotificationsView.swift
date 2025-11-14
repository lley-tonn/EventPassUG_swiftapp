//
//  NotificationsView.swift
//  EventPassUG
//
//  Notifications list screen
//

import SwiftUI

struct NotificationsView: View {
    @Binding var unreadCount: Int
    @Environment(\.dismiss) var dismiss
    @State private var notifications = NotificationModel.samples

    var body: some View {
        NavigationView {
            List {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        markAllAsRead()
                        dismiss()
                    }
                }

                if notifications.contains(where: { !$0.isRead }) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mark all read") {
                            markAllAsRead()
                        }
                    }
                }
            }
        }
    }

    private func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        unreadCount = 0
    }
}

struct NotificationRow: View {
    let notification: NotificationModel

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(AppCornerRadius.small)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)

                Text(notification.message)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(DateUtilities.formatRelativeDate(notification.timestamp))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(RoleConfig.attendeePrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }

    private var iconName: String {
        switch notification.type {
        case .eventReminder: return "bell.fill"
        case .ticketPurchased: return "ticket.fill"
        case .eventUpdate: return "info.circle.fill"
        case .newEvent: return "star.fill"
        case .ticketScanned: return "qrcode"
        case .paymentReceived: return "dollarsign.circle.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case .eventReminder: return .blue
        case .ticketPurchased: return .green
        case .eventUpdate: return .orange
        case .newEvent: return .purple
        case .ticketScanned: return .indigo
        case .paymentReceived: return .green
        }
    }
}

#Preview {
    NotificationsView(unreadCount: .constant(2))
}

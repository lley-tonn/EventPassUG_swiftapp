//
//  HeaderBar.swift
//  EventPassUG
//
//  Reusable header bar with date, greeting, and notification badge
//

import SwiftUI

struct HeaderBar: View {
    let firstName: String
    let notificationCount: Int
    let onNotificationTap: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Left side: Date and greeting
            VStack(alignment: .leading, spacing: 4) {
                Text(DateUtilities.formatHeaderDate())
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)

                Text("\(DateUtilities.getGreeting()), \(firstName)")
                    .font(AppTypography.title3)
                    .foregroundColor(.primary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            // Right side: Notification bell
            Button(action: {
                HapticFeedback.light()
                onNotificationTap()
            }) {
                NotificationBadge(count: notificationCount)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

#Preview {
    VStack {
        HeaderBar(
            firstName: "John",
            notificationCount: 3,
            onNotificationTap: {}
        )
        .background(Color(UIColor.systemBackground))

        Spacer()
    }
}

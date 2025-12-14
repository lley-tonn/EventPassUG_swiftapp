//
//  CategoryTile.swift
//  EventPassUG
//
//  Category filter chip with icon and label
//

import SwiftUI

struct CategoryTile: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onTap()
        }) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 50, height: 50)
                    .background(
                        isSelected
                            ? RoleConfig.attendeePrimary
                            : Color(UIColor.secondarySystemBackground)
                    )
                    .clipShape(Circle())

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) category")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: AppSpacing.md) {
            CategoryTile(title: "Today", icon: "calendar", isSelected: true, onTap: {})
            CategoryTile(title: "This week", icon: "calendar.badge.clock", isSelected: false, onTap: {})
            CategoryTile(title: "Music", icon: "music.note", isSelected: false, onTap: {})
            CategoryTile(title: "Sports", icon: "figure.run", isSelected: false, onTap: {})
        }
        .padding()
    }
}

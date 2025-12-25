//
//  ProfileHeaderView.swift
//  EventPassUG
//
//  Compact, visually balanced profile header
//  Optimized for information density and clarity
//

import SwiftUI

// MARK: - Compact Profile Header

/// Compact profile header with avatar, name, followers, and role
/// Designed for maximum clarity with minimal vertical space
struct CompactProfileHeader: View {
    let user: User?
    let followerCount: Int
    let onAvatarTap: (() -> Void)?

    init(
        user: User?,
        followerCount: Int = 0,
        onAvatarTap: (() -> Void)? = nil
    ) {
        self.user = user
        self.followerCount = followerCount
        self.onAvatarTap = onAvatarTap
    }

    private var displayRole: UserRole {
        user?.role ?? .attendee
    }

    private var isOrganizer: Bool {
        user?.isOrganizer == true
    }

    private var isVerified: Bool {
        user?.isVerified == true
    }

    var body: some View {
        HStack(spacing: AppDesign.Spacing.md) {
            // Avatar
            avatarView

            // Name and metadata
            VStack(alignment: .leading, spacing: 4) {
                // Name with verification badge
                nameRow

                // Follower count + Role on same line
                metadataRow
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Avatar

    private var avatarView: some View {
        Group {
            if let onTap = onAvatarTap {
                Button(action: onTap) {
                    avatarImage
                }
                .buttonStyle(.plain)
            } else {
                avatarImage
            }
        }
    }

    private var avatarImage: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 56))
            .foregroundColor(RoleConfig.getPrimaryColor(for: displayRole))
            .frame(width: 56, height: 56)
    }

    // MARK: - Name Row

    private var nameRow: some View {
        HStack(spacing: 6) {
            Text(user?.fullName ?? "Guest")
                .font(AppDesign.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - Metadata Row (Followers + Role)

    private var metadataRow: some View {
        HStack(spacing: 6) {
            // Follower count (only for organizers)
            if isOrganizer {
                followerText

                // Bullet separator
                Text("•")
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)
            }

            // Role badge
            roleText
        }
    }

    private var followerText: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 10, weight: .medium))

            Text(formattedFollowerCount)
                .font(AppDesign.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.secondary)
    }

    private var roleText: some View {
        HStack(spacing: 4) {
            Image(systemName: displayRole == .organizer ? "briefcase.fill" : "person.fill")
                .font(.system(size: 10, weight: .medium))

            Text(displayRole.displayName)
                .font(AppDesign.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(RoleConfig.getPrimaryColor(for: displayRole))
    }

    // MARK: - Formatting

    private var formattedFollowerCount: String {
        if followerCount >= 1_000_000 {
            return String(format: "%.1fM followers", Double(followerCount) / 1_000_000)
        } else if followerCount >= 1_000 {
            return String(format: "%.1fK followers", Double(followerCount) / 1_000)
        } else if followerCount == 1 {
            return "1 follower"
        } else {
            return "\(followerCount) followers"
        }
    }
}

// MARK: - Alternative: Centered Profile Header

/// Centered profile header for profile/settings screens
/// Avatar above name, metadata below
struct CenteredProfileHeader: View {
    let user: User?
    let followerCount: Int
    let onAvatarTap: (() -> Void)?

    init(
        user: User?,
        followerCount: Int = 0,
        onAvatarTap: (() -> Void)? = nil
    ) {
        self.user = user
        self.followerCount = followerCount
        self.onAvatarTap = onAvatarTap
    }

    private var displayRole: UserRole {
        user?.role ?? .attendee
    }

    private var isOrganizer: Bool {
        user?.isOrganizer == true
    }

    private var isVerified: Bool {
        user?.isVerified == true
    }

    var body: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            // Avatar
            avatarView

            // Name with verification badge
            nameRow

            // Follower count + Role on same line
            metadataRow
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Avatar

    private var avatarView: some View {
        Group {
            if let onTap = onAvatarTap {
                Button(action: onTap) {
                    avatarImage
                }
                .buttonStyle(.plain)
            } else {
                avatarImage
            }
        }
    }

    private var avatarImage: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 72))
            .foregroundColor(RoleConfig.getPrimaryColor(for: displayRole))
            .frame(width: 72, height: 72)
    }

    // MARK: - Name Row

    private var nameRow: some View {
        HStack(spacing: 6) {
            Text(user?.fullName ?? "Guest")
                .font(AppDesign.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - Metadata Row (Followers + Role)

    private var metadataRow: some View {
        HStack(spacing: 6) {
            // Follower count (only for organizers)
            if isOrganizer {
                followerText

                // Bullet separator
                Text("•")
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)
            }

            // Role badge
            roleText
        }
    }

    private var followerText: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 10, weight: .medium))

            Text(formattedFollowerCount)
                .font(AppDesign.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.secondary)
    }

    private var roleText: some View {
        HStack(spacing: 4) {
            Image(systemName: displayRole == .organizer ? "briefcase.fill" : "person.fill")
                .font(.system(size: 10, weight: .medium))

            Text(displayRole.displayName)
                .font(AppDesign.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(RoleConfig.getPrimaryColor(for: displayRole))
    }

    // MARK: - Formatting

    private var formattedFollowerCount: String {
        if followerCount >= 1_000_000 {
            return String(format: "%.1fM followers", Double(followerCount) / 1_000_000)
        } else if followerCount >= 1_000 {
            return String(format: "%.1fK followers", Double(followerCount) / 1_000)
        } else if followerCount == 1 {
            return "1 follower"
        } else {
            return "\(followerCount) followers"
        }
    }
}


// MARK: - Previews

// Preview code temporarily disabled during architecture migration

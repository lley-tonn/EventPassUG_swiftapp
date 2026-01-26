//
//  FollowManager.swift
//  EventPassUG
//
//  Manages followed organizers using AppStorage
//

import Foundation
import SwiftUI

@MainActor
class FollowManager: ObservableObject {
    @AppStorage("followedOrganizerIds") private var followedIdsData: Data = Data()
    @AppStorage("organizerFollowerCounts") private var followerCountsData: Data = Data()

    @Published var followedOrganizerIds: Set<UUID> = []
    @Published var organizerFollowerCounts: [UUID: Int] = [:] // organizerId -> follower count

    static let shared = FollowManager()
    private let notificationManager = InAppNotificationManager.shared

    init() {
        loadFollowedOrganizers()
        loadFollowerCounts()
    }

    func loadFollowedOrganizers() {
        if let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: followedIdsData) {
            followedOrganizerIds = decoded
        }
    }

    func loadFollowerCounts() {
        if let decoded = try? JSONDecoder().decode([UUID: Int].self, from: followerCountsData) {
            organizerFollowerCounts = decoded
        }
    }

    func saveFollowedOrganizers() {
        if let encoded = try? JSONEncoder().encode(followedOrganizerIds) {
            followedIdsData = encoded
        }
    }

    func saveFollowerCounts() {
        if let encoded = try? JSONEncoder().encode(organizerFollowerCounts) {
            followerCountsData = encoded
        }
    }

    func toggleFollow(organizerId: UUID, organizerName: String, followerId: UUID? = nil, followerName: String? = nil) {
        if followedOrganizerIds.contains(organizerId) {
            // Unfollow
            followedOrganizerIds.remove(organizerId)
            decrementFollowerCount(for: organizerId)
        } else {
            // Follow
            followedOrganizerIds.insert(organizerId)
            incrementFollowerCount(for: organizerId)

            // Send notification to organizer
            sendFollowNotification(
                to: organizerId,
                organizerName: organizerName,
                followerId: followerId,
                followerName: followerName
            )
        }
        saveFollowedOrganizers()
    }

    private func incrementFollowerCount(for organizerId: UUID) {
        let currentCount = organizerFollowerCounts[organizerId] ?? 0
        organizerFollowerCounts[organizerId] = currentCount + 1
        saveFollowerCounts()
    }

    private func decrementFollowerCount(for organizerId: UUID) {
        let currentCount = organizerFollowerCounts[organizerId] ?? 0
        organizerFollowerCounts[organizerId] = max(0, currentCount - 1)
        saveFollowerCounts()
    }

    private func sendFollowNotification(to organizerId: UUID, organizerName: String, followerId: UUID?, followerName: String?) {
        // Guest user - skip notification
        guard let followerId = followerId else {
            print("Guest user follow - notification skipped")
            return
        }

        let notification = NotificationModel(
            type: .newFollower,
            title: "New Follower!",
            message: "\(followerName ?? "Someone") started following you",
            relatedUserId: followerId
        )
        notificationManager.addNotification(notification)
    }

    func getFollowerCount(for organizerId: UUID) -> Int {
        organizerFollowerCounts[organizerId] ?? 0
    }

    func isFollowing(organizerId: UUID) -> Bool {
        followedOrganizerIds.contains(organizerId)
    }

    func followOrganizer(organizerId: UUID, organizerName: String = "", followerId: UUID? = nil, followerName: String? = nil) {
        if !followedOrganizerIds.contains(organizerId) {
            followedOrganizerIds.insert(organizerId)
            incrementFollowerCount(for: organizerId)
            sendFollowNotification(to: organizerId, organizerName: organizerName, followerId: followerId, followerName: followerName)
            saveFollowedOrganizers()
        }
    }

    func unfollowOrganizer(organizerId: UUID) {
        if followedOrganizerIds.contains(organizerId) {
            followedOrganizerIds.remove(organizerId)
            decrementFollowerCount(for: organizerId)
            saveFollowedOrganizers()
        }
    }

    func clearAll() {
        followedOrganizerIds.removeAll()
        saveFollowedOrganizers()
    }
}

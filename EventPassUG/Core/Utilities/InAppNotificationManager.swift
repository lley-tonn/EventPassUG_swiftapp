//
//  InAppNotificationManager.swift
//  EventPassUG
//
//  Manages in-app notifications using AppStorage
//

import Foundation
import SwiftUI

@MainActor
class InAppNotificationManager: ObservableObject {
    @AppStorage("inAppNotifications") private var notificationsData: Data = Data()

    @Published var notifications: [NotificationModel] = []

    static let shared = InAppNotificationManager()

    init() {
        loadNotifications()
    }

    func loadNotifications() {
        if let decoded = try? JSONDecoder().decode([NotificationModel].self, from: notificationsData) {
            notifications = decoded.sorted { $0.timestamp > $1.timestamp }
        }
    }

    func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            notificationsData = encoded
        }
    }

    func addNotification(_ notification: NotificationModel) {
        notifications.insert(notification, at: 0)
        saveNotifications()
    }

    func markAsRead(notificationId: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }

    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        saveNotifications()
    }

    func deleteNotification(notificationId: UUID) {
        notifications.removeAll { $0.id == notificationId }
        saveNotifications()
    }

    func clearAll() {
        notifications.removeAll()
        saveNotifications()
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    // Get notifications for a specific user (organizer)
    func getNotificationsForOrganizer(organizerId: UUID) -> [NotificationModel] {
        // In a real app, this would filter by recipient
        // For now, returning all notifications
        return notifications
    }
}

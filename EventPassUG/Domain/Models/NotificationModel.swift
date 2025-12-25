//
//  NotificationModel.swift
//  EventPassUG
//
//  In-app notification model
//

import Foundation

enum NotificationType: String, Codable {
    case eventReminder
    case ticketPurchased
    case eventUpdate
    case newEvent
    case ticketScanned
    case paymentReceived
    case newFollower
}

struct NotificationModel: Identifiable, Codable, Equatable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let relatedEventId: UUID?
    let relatedTicketId: UUID?
    let relatedUserId: UUID? // For follow notifications

    init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        relatedEventId: UUID? = nil,
        relatedTicketId: UUID? = nil,
        relatedUserId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.relatedEventId = relatedEventId
        self.relatedTicketId = relatedTicketId
        self.relatedUserId = relatedUserId
    }
}

// Sample notifications
extension NotificationModel {
    static let samples: [NotificationModel] = [
        NotificationModel(
            type: .eventReminder,
            title: "Event Tomorrow!",
            message: "Summer Music Festival starts tomorrow at 6:00 PM",
            timestamp: Date().addingTimeInterval(-3600),
            isRead: false
        ),
        NotificationModel(
            type: .ticketPurchased,
            title: "Ticket Purchased",
            message: "Your ticket for Tech Summit has been confirmed",
            timestamp: Date().addingTimeInterval(-7200),
            isRead: false
        ),
        NotificationModel(
            type: .eventUpdate,
            title: "Event Update",
            message: "Venue changed for Charity Run - Check details",
            timestamp: Date().addingTimeInterval(-86400),
            isRead: true
        )
    ]
}

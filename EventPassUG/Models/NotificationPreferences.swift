//
//  NotificationPreferences.swift
//  EventPassUG
//
//  User notification preferences model
//

import Foundation

struct NotificationPreferences: Codable, Equatable {
    // Event Notifications
    var upcomingEventReminders: ChannelPreferences
    var eventUpdates: ChannelPreferences
    var ticketsExpiringSoon: ChannelPreferences

    // Purchase Notifications
    var ticketPurchaseConfirmations: ChannelPreferences
    var paymentStatusUpdates: ChannelPreferences

    // Organizer Notifications
    var newTicketSales: ChannelPreferences
    var lowTicketAlerts: ChannelPreferences
    var eventApprovalStatus: ChannelPreferences

    // App Updates & Promotions
    var newFeatures: ChannelPreferences
    var promotionalEvents: ChannelPreferences
    var discounts: ChannelPreferences

    static var defaultPreferences: NotificationPreferences {
        NotificationPreferences(
            // Event Notifications - enabled by default
            upcomingEventReminders: ChannelPreferences(push: true, email: true, sms: false),
            eventUpdates: ChannelPreferences(push: true, email: true, sms: true),
            ticketsExpiringSoon: ChannelPreferences(push: true, email: true, sms: false),
            // Purchase Notifications - enabled by default
            ticketPurchaseConfirmations: ChannelPreferences(push: true, email: true, sms: true),
            paymentStatusUpdates: ChannelPreferences(push: true, email: true, sms: true),
            // Organizer Notifications - enabled by default
            newTicketSales: ChannelPreferences(push: true, email: true, sms: false),
            lowTicketAlerts: ChannelPreferences(push: true, email: true, sms: true),
            eventApprovalStatus: ChannelPreferences(push: true, email: true, sms: false),
            // App Updates - disabled by default
            newFeatures: ChannelPreferences(push: true, email: false, sms: false),
            promotionalEvents: ChannelPreferences(push: false, email: false, sms: false),
            discounts: ChannelPreferences(push: true, email: false, sms: false)
        )
    }
}

struct ChannelPreferences: Codable, Equatable {
    var push: Bool
    var email: Bool
    var sms: Bool

    init(push: Bool = false, email: Bool = false, sms: Bool = false) {
        self.push = push
        self.email = email
        self.sms = sms
    }
}

// Saved Payment Method
struct SavedPaymentMethod: Codable, Identifiable, Equatable {
    let id: UUID
    var type: PaymentMethodType
    var isDefault: Bool
    var displayName: String

    // For Mobile Money
    var mobileMoneyNumber: String?

    // For Card
    var lastFourDigits: String?
    var cardBrand: String?
    var expiryMonth: Int?
    var expiryYear: Int?
    var cardholderName: String?

    var formattedDisplay: String {
        switch type {
        case .mtnMomo:
            return "MTN MoMo (\(mobileMoneyNumber ?? ""))"
        case .airtelMoney:
            return "Airtel Money (\(mobileMoneyNumber ?? ""))"
        case .card:
            return "\(cardBrand ?? "Card") •••• \(lastFourDigits ?? "")"
        case .cash:
            return "Cash"
        }
    }
}

enum PaymentMethodType: String, Codable, CaseIterable {
    case mtnMomo = "MTN MoMo"
    case airtelMoney = "Airtel Money"
    case card = "Card"
    case cash = "Cash"

    var iconName: String {
        switch self {
        case .mtnMomo: return "phone.fill"
        case .airtelMoney: return "phone.fill"
        case .card: return "creditcard.fill"
        case .cash: return "banknote.fill"
        }
    }
}

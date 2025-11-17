//
//  TicketType.swift
//  EventPassUG
//
//  Ticket type model for event pricing tiers
//

import Foundation

// MARK: - Ticket Availability Status

enum TicketAvailabilityStatus: String, Codable {
    case upcoming = "Upcoming"
    case active = "Active"
    case expired = "Expired"
    case soldOut = "Sold Out"

    var color: Color {
        switch self {
        case .upcoming: return .orange
        case .active: return .green
        case .expired: return .gray
        case .soldOut: return .red
        }
    }

    var iconName: String {
        switch self {
        case .upcoming: return "clock.fill"
        case .active: return "checkmark.circle.fill"
        case .expired: return "xmark.circle.fill"
        case .soldOut: return "exclamationmark.circle.fill"
        }
    }
}

import SwiftUI

struct TicketType: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var price: Double // in UGX
    var quantity: Int
    var sold: Int
    var description: String?
    var perks: [String]

    // Availability window
    var saleStartDate: Date
    var saleEndDate: Date
    var isUnlimitedQuantity: Bool

    var remaining: Int {
        isUnlimitedQuantity ? Int.max : (quantity - sold)
    }

    var isSoldOut: Bool {
        !isUnlimitedQuantity && remaining <= 0
    }

    var formattedPrice: String {
        if price == 0 {
            return "Free"
        }
        return "UGX \(Int(price).formatted())"
    }

    // MARK: - Availability Status

    var availabilityStatus: TicketAvailabilityStatus {
        let now = Date()

        if isSoldOut {
            return .soldOut
        } else if now < saleStartDate {
            return .upcoming
        } else if now > saleEndDate {
            return .expired
        } else {
            return .active
        }
    }

    var isAvailableForPurchase: Bool {
        let now = Date()
        return now >= saleStartDate && now <= saleEndDate && !isSoldOut
    }

    var isPurchasable: Bool {
        isAvailableForPurchase
    }

    // Formatted availability text
    var availabilityText: String {
        let now = Date()

        switch availabilityStatus {
        case .upcoming:
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "On sale \(formatter.localizedString(for: saleStartDate, relativeTo: now))"
        case .active:
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Sale ends \(formatter.localizedString(for: saleEndDate, relativeTo: now))"
        case .expired:
            return "Sale ended"
        case .soldOut:
            return "Sold out"
        }
    }

    var formattedSaleWindow: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return "\(dateFormatter.string(from: saleStartDate)) - \(dateFormatter.string(from: saleEndDate))"
    }

    init(
        id: UUID = UUID(),
        name: String,
        price: Double,
        quantity: Int,
        sold: Int = 0,
        description: String? = nil,
        perks: [String] = [],
        saleStartDate: Date? = nil,
        saleEndDate: Date? = nil,
        isUnlimitedQuantity: Bool = false
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.sold = sold
        self.description = description
        self.perks = perks
        // Default: sales start immediately and end far in the future
        self.saleStartDate = saleStartDate ?? Date()
        self.saleEndDate = saleEndDate ?? Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year default
        self.isUnlimitedQuantity = isUnlimitedQuantity
    }
}

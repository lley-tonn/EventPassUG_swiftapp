//
//  TicketType.swift
//  EventPassUG
//
//  Ticket type model for event pricing tiers
//

import Foundation

struct TicketType: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var price: Double // in UGX
    var quantity: Int
    var sold: Int
    var description: String?
    var perks: [String]

    var remaining: Int {
        quantity - sold
    }

    var isSoldOut: Bool {
        remaining <= 0
    }

    var formattedPrice: String {
        if price == 0 {
            return "Free"
        }
        return "UGX \(Int(price).formatted())"
    }

    init(
        id: UUID = UUID(),
        name: String,
        price: Double,
        quantity: Int,
        sold: Int = 0,
        description: String? = nil,
        perks: [String] = []
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.sold = sold
        self.description = description
        self.perks = perks
    }
}

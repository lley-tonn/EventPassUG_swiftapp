//
//  Event.swift
//  EventPassUG
//
//  Event model representing an event in the system
//

import Foundation
import CoreLocation
import SwiftUI

enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case music = "Music"
    case artsCulture = "Arts & Culture"
    case concerts = "Concerts"
    case sportsWellness = "Sports & Wellness"
    case technology = "Technology"
    case fundraising = "Fundraising"
    case comedy = "Comedy"
    case poetry = "Poetry"
    case drama = "Drama"
    case exhibitions = "Exhibitions"
    case networking = "Networking"
    case education = "Education"
    case food = "Food & Drinks"
    case nightlife = "Nightlife"
    case festivals = "Festivals"
    case other = "Other"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .music: return "music.note"
        case .artsCulture: return "paintpalette"
        case .concerts: return "mic"
        case .sportsWellness: return "figure.run"
        case .technology: return "laptopcomputer"
        case .fundraising: return "heart.circle"
        case .comedy: return "theatermasks.fill"
        case .poetry: return "text.book.closed.fill"
        case .drama: return "film.fill"
        case .exhibitions: return "building.columns.fill"
        case .networking: return "person.3.fill"
        case .education: return "graduationcap.fill"
        case .food: return "fork.knife"
        case .nightlife: return "moon.stars.fill"
        case .festivals: return "party.popper.fill"
        case .other: return "star"
        }
    }

    var color: Color {
        switch self {
        case .music: return .purple
        case .artsCulture: return .cyan
        case .concerts: return .pink
        case .sportsWellness: return .green
        case .technology: return .blue
        case .fundraising: return .pink
        case .comedy: return .orange
        case .poetry: return .brown
        case .drama: return .red
        case .exhibitions: return .indigo
        case .networking: return .teal
        case .education: return .yellow
        case .food: return Color(red: 0.8, green: 0.4, blue: 0.2)
        case .nightlife: return .purple
        case .festivals: return .orange
        case .other: return .gray
        }
    }
}

enum TimeCategory: String, Codable {
    case today = "Today"
    case thisWeek = "This week"
    case thisMonth = "This month"
}

enum EventStatus: String, Codable {
    case draft
    case published
    case ongoing
    case completed
    case cancelled
}

enum AgeRestriction: Int, Codable {
    case none = 0
    case thirteen = 13
    case sixteen = 16
    case eighteen = 18
    case twentyOne = 21

    var displayName: String {
        switch self {
        case .none: return "All Ages"
        case .thirteen: return "13+"
        case .sixteen: return "16+"
        case .eighteen: return "18+"
        case .twentyOne: return "21+"
        }
    }

    var icon: String {
        switch self {
        case .none: return "person.3.fill"
        case .thirteen, .sixteen, .eighteen, .twentyOne: return "exclamationmark.triangle.fill"
        }
    }
}

struct Venue: Codable, Equatable {
    let name: String
    let address: String
    let city: String
    let coordinate: Coordinate

    struct Coordinate: Codable, Equatable {
        let latitude: Double
        let longitude: Double

        var clLocation: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

struct Event: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var organizerId: UUID
    var organizerName: String
    var posterURL: String?
    var category: EventCategory
    var startDate: Date
    var endDate: Date
    var venue: Venue
    var ticketTypes: [TicketType]
    var status: EventStatus
    var rating: Double
    var totalRatings: Int
    var likeCount: Int
    var createdAt: Date
    var updatedAt: Date
    var ageRestriction: AgeRestriction // Age restriction for the event

    // Computed properties
    var isHappeningNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && status == .published
    }

    var priceRange: String {
        let prices = ticketTypes.map { $0.price }
        guard let min = prices.min(), let max = prices.max() else {
            return "Free"
        }
        if min == 0 && max == 0 {
            return "Free"
        } else if min == max {
            return "UGX \(Int(min).formatted())"
        } else {
            return "UGX \(Int(min).formatted()) - \(Int(max).formatted())"
        }
    }

    var timeCategory: TimeCategory? {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(startDate) {
            return .today
        } else if calendar.isDate(startDate, equalTo: now, toGranularity: .weekOfYear) {
            return .thisWeek
        } else if calendar.isDate(startDate, equalTo: now, toGranularity: .month) {
            return .thisMonth
        }
        return nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        organizerId: UUID,
        organizerName: String,
        posterURL: String? = nil,
        category: EventCategory,
        startDate: Date,
        endDate: Date,
        venue: Venue,
        ticketTypes: [TicketType] = [],
        status: EventStatus = .draft,
        rating: Double = 0.0,
        totalRatings: Int = 0,
        likeCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        ageRestriction: AgeRestriction = .none
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.organizerId = organizerId
        self.organizerName = organizerName
        self.posterURL = posterURL
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.venue = venue
        self.ticketTypes = ticketTypes
        self.status = status
        self.rating = rating
        self.totalRatings = totalRatings
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ageRestriction = ageRestriction
    }
}

// Sample events for development
extension Event {
    static let samples: [Event] = [
        Event(
            title: "Summer Music Festival",
            description: "Join us for an unforgettable night of music featuring top artists from across East Africa.",
            organizerId: UUID(),
            organizerName: "EventMasters UG",
            posterURL: "sample_poster_1",
            category: .music,
            startDate: Date().addingTimeInterval(-3600), // Started 1 hour ago
            endDate: Date().addingTimeInterval(7200), // Ends in 2 hours
            venue: Venue(
                name: "Kampala Serena Hotel",
                address: "Kintu Road",
                city: "Kampala",
                coordinate: Venue.Coordinate(latitude: 0.3136, longitude: 32.5811)
            ),
            ticketTypes: [
                TicketType(
                    name: "General Admission",
                    price: 50000,
                    quantity: 500,
                    sold: 320,
                    saleStartDate: Date().addingTimeInterval(-86400 * 30), // Started 30 days ago
                    saleEndDate: Date().addingTimeInterval(3600) // Ends in 1 hour
                ),
                TicketType(
                    name: "VIP",
                    price: 150000,
                    quantity: 100,
                    sold: 75,
                    saleStartDate: Date().addingTimeInterval(-86400 * 30),
                    saleEndDate: Date().addingTimeInterval(3600)
                )
            ],
            status: .published,
            rating: 4.5,
            totalRatings: 120,
            likeCount: 450
        ),
        Event(
            title: "Tech Innovators Summit 2024",
            description: "Connect with industry leaders and explore the latest in technology and innovation.",
            organizerId: UUID(),
            organizerName: "TechHub Kampala",
            posterURL: "sample_poster_2",
            category: .technology,
            startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!.addingTimeInterval(28800),
            venue: Venue(
                name: "Uganda Museum",
                address: "Kira Road",
                city: "Kampala",
                coordinate: Venue.Coordinate(latitude: 0.3301, longitude: 32.5729)
            ),
            ticketTypes: [
                // Early Bird - ends soon
                TicketType(
                    name: "Early Bird",
                    price: 75000,
                    quantity: 200,
                    sold: 150,
                    saleStartDate: Date().addingTimeInterval(-86400 * 14), // Started 2 weeks ago
                    saleEndDate: Date().addingTimeInterval(86400 * 2) // Ends in 2 days
                ),
                // Regular - starts after Early Bird ends
                TicketType(
                    name: "Regular",
                    price: 100000,
                    quantity: 300,
                    sold: 50,
                    saleStartDate: Date().addingTimeInterval(86400 * 2), // Starts in 2 days (Upcoming)
                    saleEndDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                ),
                // Last Minute - future sale
                TicketType(
                    name: "Last Minute",
                    price: 125000,
                    quantity: 50,
                    sold: 0,
                    saleStartDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!, // Upcoming
                    saleEndDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                )
            ],
            status: .published,
            rating: 4.8,
            totalRatings: 95,
            likeCount: 320
        ),
        Event(
            title: "Charity Run for Education",
            description: "Run for a cause! Support education initiatives across Uganda.",
            organizerId: UUID(),
            organizerName: "Hope Foundation",
            posterURL: "sample_poster_3",
            category: .fundraising,
            startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!.addingTimeInterval(14400),
            venue: Venue(
                name: "Kololo Independence Grounds",
                address: "Kololo",
                city: "Kampala",
                coordinate: Venue.Coordinate(latitude: 0.3270, longitude: 32.5970)
            ),
            ticketTypes: [
                TicketType(
                    name: "5K Run",
                    price: 20000,
                    quantity: 1000,
                    sold: 650,
                    saleStartDate: Date().addingTimeInterval(-86400 * 7),
                    saleEndDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!
                ),
                TicketType(
                    name: "10K Run",
                    price: 35000,
                    quantity: 500,
                    sold: 280,
                    saleStartDate: Date().addingTimeInterval(-86400 * 7),
                    saleEndDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!
                ),
                // Student discount - limited time
                TicketType(
                    name: "Student Discount",
                    price: 10000,
                    quantity: 100,
                    sold: 100, // Sold out!
                    saleStartDate: Date().addingTimeInterval(-86400 * 7),
                    saleEndDate: Date().addingTimeInterval(-86400) // Expired yesterday
                )
            ],
            status: .published,
            rating: 4.7,
            totalRatings: 210,
            likeCount: 580
        ),
        Event(
            title: "Contemporary Art Exhibition",
            description: "Explore the works of emerging Ugandan artists in this month-long exhibition.",
            organizerId: UUID(),
            organizerName: "Kampala Art Gallery",
            posterURL: "sample_poster_4",
            category: .artsCulture,
            startDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date())!,
            venue: Venue(
                name: "Nommo Gallery",
                address: "Naguru",
                city: "Kampala",
                coordinate: Venue.Coordinate(latitude: 0.3324, longitude: 32.6003)
            ),
            ticketTypes: [
                TicketType(
                    name: "Single Entry",
                    price: 15000,
                    quantity: 2000,
                    sold: 450,
                    saleStartDate: Date(), // Active now
                    saleEndDate: Calendar.current.date(byAdding: .day, value: 45, to: Date())!,
                    isUnlimitedQuantity: false
                ),
                // Unlimited season pass
                TicketType(
                    name: "Season Pass",
                    price: 50000,
                    quantity: 0, // Ignored when unlimited
                    sold: 0,
                    saleStartDate: Date(),
                    saleEndDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
                    isUnlimitedQuantity: true
                )
            ],
            status: .published,
            rating: 4.3,
            totalRatings: 67,
            likeCount: 190
        )
    ]
}

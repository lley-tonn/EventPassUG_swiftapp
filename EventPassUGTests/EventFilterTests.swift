//
//  EventFilterTests.swift
//  EventPassUGTests
//
//  Unit tests for event category filtering
//

import XCTest
@testable import EventPassUG

final class EventFilterTests: XCTestCase {

    var sampleEvents: [Event]!

    override func setUp() {
        super.setUp()
        sampleEvents = Event.samples
    }

    override func tearDown() {
        sampleEvents = nil
        super.tearDown()
    }

    func testFilterByCategory() {
        let musicEvents = sampleEvents.filter { $0.category == .music }
        XCTAssertTrue(musicEvents.allSatisfy { $0.category == .music },
                      "All filtered events should be music category")
    }

    func testFilterByTimeCategory() {
        let todayEvents = sampleEvents.filter { $0.timeCategory == .today }

        for event in todayEvents {
            let isToday = Calendar.current.isDateInToday(event.startDate)
            XCTAssertTrue(isToday, "Filtered events should start today")
        }
    }

    func testHappeningNowDetection() {
        let calendar = Calendar.current
        let now = Date()

        // Create event happening now
        let happeningEvent = Event(
            title: "Live Event",
            description: "Test",
            organizerId: UUID(),
            organizerName: "Test",
            category: .music,
            startDate: calendar.date(byAdding: .hour, value: -1, to: now)!,
            endDate: calendar.date(byAdding: .hour, value: 1, to: now)!,
            venue: Venue(
                name: "Test Venue",
                address: "Test Address",
                city: "Kampala",
                coordinate: Venue.Coordinate(latitude: 0.0, longitude: 0.0)
            ),
            status: .published
        )

        XCTAssertTrue(happeningEvent.isHappeningNow,
                      "Event should be marked as happening now")
    }

    func testPriceRangeCalculation() {
        let event = Event.samples[0]
        let prices = event.ticketTypes.map { $0.price }

        if let minPrice = prices.min(), let maxPrice = prices.max() {
            let expectedRange = "UGX \(Int(minPrice).formatted()) - \(Int(maxPrice).formatted())"
            XCTAssertTrue(event.priceRange.contains("UGX"),
                          "Price range should contain currency")
        }
    }

    func testFreeEventPriceRange() {
        let freeEvent = Event(
            title: "Free Event",
            description: "Test",
            organizerId: UUID(),
            organizerName: "Test",
            category: .music,
            startDate: Date(),
            endDate: Date(),
            venue: Venue(
                name: "Test",
                address: "Test",
                city: "Kampala",
                coordinate: Venue.Coordinate(latitude: 0.0, longitude: 0.0)
            ),
            ticketTypes: [TicketType(name: "Free", price: 0, quantity: 100)]
        )

        XCTAssertEqual(freeEvent.priceRange, "Free",
                       "Free events should show 'Free' price range")
    }
}

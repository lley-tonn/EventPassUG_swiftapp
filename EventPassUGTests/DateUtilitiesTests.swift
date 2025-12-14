//
//  DateUtilitiesTests.swift
//  EventPassUGTests
//
//  Unit tests for date formatting and greeting logic
//

import XCTest
@testable import EventPassUG

final class DateUtilitiesTests: XCTestCase {

    // MARK: - Greeting Tests

    func testMorningGreeting() {
        // Test morning hours (5:00 - 11:59)
        let calendar = Calendar.current
        let morningDate = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!

        let greeting = DateUtilities.getGreeting(for: morningDate)
        XCTAssertEqual(greeting, "Good morning", "Expected 'Good morning' for 8:30 AM")
    }

    func testAfternoonGreeting() {
        // Test afternoon hours (12:00 - 16:59)
        let calendar = Calendar.current
        let afternoonDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!

        let greeting = DateUtilities.getGreeting(for: afternoonDate)
        XCTAssertEqual(greeting, "Good afternoon", "Expected 'Good afternoon' for 2:00 PM")
    }

    func testEveningGreeting() {
        // Test evening hours (17:00 - 20:59)
        let calendar = Calendar.current
        let eveningDate = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: Date())!

        let greeting = DateUtilities.getGreeting(for: eveningDate)
        XCTAssertEqual(greeting, "Good evening", "Expected 'Good evening' for 6:30 PM")
    }

    func testNightGreeting() {
        // Test night hours (21:00 - 04:59)
        let calendar = Calendar.current
        let nightDate = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!

        let greeting = DateUtilities.getGreeting(for: nightDate)
        XCTAssertEqual(greeting, "Good night", "Expected 'Good night' for 10:00 PM")
    }

    func testEdgeCaseMidnight() {
        let calendar = Calendar.current
        let midnightDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!

        let greeting = DateUtilities.getGreeting(for: midnightDate)
        XCTAssertEqual(greeting, "Good night", "Expected 'Good night' for midnight")
    }

    func testEdgeCaseNoon() {
        let calendar = Calendar.current
        let noonDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!

        let greeting = DateUtilities.getGreeting(for: noonDate)
        XCTAssertEqual(greeting, "Good afternoon", "Expected 'Good afternoon' for noon")
    }

    // MARK: - Date Formatting Tests

    func testHeaderDateFormat() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let testDate = dateFormatter.date(from: "2024-11-13 15:30:00")!

        let formatted = DateUtilities.formatHeaderDate(testDate)
        XCTAssertTrue(formatted.contains("Nov"), "Formatted date should contain month abbreviation")
        XCTAssertTrue(formatted.contains("13"), "Formatted date should contain day")
    }

    func testRelativeDateToday() {
        let today = Date()
        let relative = DateUtilities.formatRelativeDate(today)
        XCTAssertEqual(relative, "Today", "Expected 'Today' for current date")
    }

    func testRelativeDateTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let relative = DateUtilities.formatRelativeDate(tomorrow)
        XCTAssertEqual(relative, "Tomorrow", "Expected 'Tomorrow' for next day")
    }

    func testDurationCalculation() {
        let calendar = Calendar.current
        let start = Date()
        let end = calendar.date(byAdding: .hour, value: 2, to: start)!

        let duration = DateUtilities.formatDuration(from: start, to: end)
        XCTAssertEqual(duration, "2h", "Expected '2h' for 2-hour duration")
    }

    func testDurationWithMinutes() {
        let calendar = Calendar.current
        let start = Date()
        let end = calendar.date(byAdding: .minute, value: 90, to: start)!

        let duration = DateUtilities.formatDuration(from: start, to: end)
        XCTAssertTrue(duration.contains("1h") && duration.contains("30m"),
                      "Expected '1h 30m' for 90-minute duration")
    }
}

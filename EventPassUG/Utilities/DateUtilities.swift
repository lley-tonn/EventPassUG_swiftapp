//
//  DateUtilities.swift
//  EventPassUG
//
//  Date formatting and greeting utilities
//

import Foundation

struct DateUtilities {
    // MARK: - Greeting Logic

    /// Returns a time-based greeting
    /// - 05:00–11:59 → "Good morning"
    /// - 12:00–16:59 → "Good afternoon"
    /// - 17:00–20:59 → "Good evening"
    /// - 21:00–04:59 → "Good night"
    static func getGreeting(for date: Date = Date()) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    // MARK: - Date Formatters

    /// Returns date formatted as "Thu, Nov 13"
    static func formatHeaderDate(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    /// Returns date and time formatted as "Nov 13, 2024 • 6:00 PM"
    static func formatEventDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    /// Returns time formatted as "6:00 PM"
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    /// Returns relative date string (e.g., "Tomorrow", "In 2 days", "Today")
    static func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            formatter.locale = Locale.current
            return formatter.localizedString(for: date, relativeTo: now)
        }
    }

    /// Returns full date and time formatted for event details
    static func formatEventFullDateTime(_ startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        let sameDay = calendar.isDate(startDate, inSameDayAs: endDate)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        if sameDay {
            return """
            \(dateFormatter.string(from: startDate))
            \(timeFormatter.string(from: startDate)) - \(timeFormatter.string(from: endDate))
            """
        } else {
            return """
            \(dateFormatter.string(from: startDate)) at \(timeFormatter.string(from: startDate))
            to
            \(dateFormatter.string(from: endDate)) at \(timeFormatter.string(from: endDate))
            """
        }
    }

    /// Returns duration in hours and minutes
    static func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

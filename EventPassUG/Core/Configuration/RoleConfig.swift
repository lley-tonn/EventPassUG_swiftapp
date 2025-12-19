//
//  RoleConfig.swift
//  EventPassUG
//
//  Role-based configuration and theming
//

import SwiftUI

struct RoleConfig {
    // MARK: - Color Tokens (Exact as specified)

    // Attendee primary color
    static let attendeePrimary = Color(hex: "FF7A00")

    // Organizer primary color
    static let organizerPrimary = Color(hex: "FFA500")

    // Background colors
    static let lightBackground = Color(hex: "FBFBF7")
    static let darkBackground = Color(hex: "000000")

    // Special colors
    static let happeningNow = Color(hex: "7CFC66")

    // MARK: - Role-based Colors

    static func getPrimaryColor(for role: UserRole) -> Color {
        switch role {
        case .attendee:
            return attendeePrimary
        case .organizer:
            return organizerPrimary
        }
    }

    static func getAccentColor(for role: UserRole) -> Color {
        getPrimaryColor(for: role)
    }

    // MARK: - Semantic Colors

    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
}

// Design system tokens (typography, spacing, etc.) are defined in AppDesignSystem.swift
// This file only contains role-specific configuration

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

// Color extension is defined in AppDesignSystem.swift to avoid duplication

// MARK: - Typography

struct AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    // Button-specific typography
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let buttonMedium = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let buttonSmall = Font.system(size: 13, weight: .semibold, design: .rounded)
}

// MARK: - Spacing

struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // Section spacing
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    static let compactSpacing: CGFloat = 6
}

// MARK: - Corner Radius

struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let pill: CGFloat = 100 // For pill-shaped buttons/badges
}

// MARK: - Shadows

struct AppShadow {
    static let card = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let elevated = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    static let subtle = Shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    static let button = Shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Border

struct AppBorder {
    static let width: CGFloat = 1
    static let thickWidth: CGFloat = 1.5
    static let selectedWidth: CGFloat = 2
    static let color = Color(UIColor.separator)
    static let lightColor = Color.gray.opacity(0.3)
}

// MARK: - Button Dimensions

struct AppButtonDimensions {
    static let largeHeight: CGFloat = 56
    static let mediumHeight: CGFloat = 48
    static let smallHeight: CGFloat = 36
    static let iconButtonSize: CGFloat = 44
    static let compactIconSize: CGFloat = 32
    static let minimumTouchTarget: CGFloat = 44 // Apple's accessibility minimum
}

// MARK: - Animation

struct AppAnimation {
    static let standard = Animation.easeInOut(duration: 0.2)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let quick = Animation.easeInOut(duration: 0.15)
    static let slow = Animation.easeInOut(duration: 0.4)
}

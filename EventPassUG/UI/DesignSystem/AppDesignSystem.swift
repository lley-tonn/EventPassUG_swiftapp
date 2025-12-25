//
//  AppDesignSystem.swift
//  EventPassUG
//
//  Production-grade design system for EventPass
//  Centralized tokens for colors, typography, spacing, and styling
//

import SwiftUI

// MARK: - Design System

/// Central design system for EventPass
/// All UI components should reference these tokens for consistency
struct AppDesign {

    // MARK: - Colors

    struct Colors {
        // Brand Colors
        static let primary = Color(hex: "FF7A00") // Orange
        static let primaryDark = Color(hex: "E66D00")
        static let primaryLight = Color(hex: "FFA040")

        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // Backgrounds
        static let backgroundPrimary = Color(UIColor.systemBackground)
        static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
        static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
        static let backgroundGrouped = Color(UIColor.systemGroupedBackground)

        // Text
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(UIColor.tertiaryLabel)
        static let textInverse = Color.white

        // Interactive
        static let interactive = primary
        static let interactiveHover = primaryDark
        static let interactiveDisabled = Color.gray.opacity(0.3)

        // Borders
        static let border = Color(UIColor.separator)
        static let borderLight = Color.gray.opacity(0.2)
        static let borderDark = Color.gray.opacity(0.4)

        // Special
        static let happeningNow = Color(hex: "7CFC66")
        static let premium = Color(hex: "FFD700")
    }

    // MARK: - Typography

    struct Typography {
        // MARK: - Semantic Text Styles

        /// Hero/Screen titles - Main screen headings
        static let hero = Font.largeTitle.weight(.bold)

        /// Large titles - Onboarding, empty states
        static let largeTitle = Font.largeTitle.weight(.bold)

        /// Title - Dialog headers, important sections
        static let title = Font.title.weight(.semibold)

        /// Title 2 - Subsections
        static let title2 = Font.title2.weight(.semibold)

        /// Section - Major content sections
        static let section = Font.title3.weight(.semibold)

        /// Card title - Event names, card headings
        static let cardTitle = Font.headline.weight(.semibold)

        /// Body - Primary content, descriptions
        static let body = Font.body

        /// Body emphasized - Important body text
        static let bodyEmphasized = Font.body.weight(.semibold)

        /// Secondary - Supporting information
        static let secondary = Font.subheadline

        /// Callout - Emphasized content
        static let callout = Font.callout

        /// Callout emphasized - Important callouts
        static let calloutEmphasized = Font.callout.weight(.semibold)

        /// Caption - Metadata, timestamps, hints
        static let caption = Font.caption

        /// Caption emphasized - Important small text
        static let captionEmphasized = Font.caption.weight(.medium)

        /// Footnote - Fine print
        static let footnote = Font.footnote

        // MARK: - Button Typography

        /// Primary button text
        static let buttonPrimary = Font.headline.weight(.semibold)

        /// Secondary button text
        static let buttonSecondary = Font.subheadline.weight(.semibold)

        /// Small button text
        static let buttonSmall = Font.caption.weight(.semibold)

        // MARK: - Compatibility Aliases

        /// Standard system font names for compatibility
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let buttonMedium = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let buttonSmallLegacy = Font.system(size: 13, weight: .semibold, design: .rounded)
    }

    // MARK: - Spacing

    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64

        // Semantic spacing
        static let compact: CGFloat = 6
        static let section: CGFloat = 24
        static let item: CGFloat = 12
        static let edge: CGFloat = 16 // Screen edge padding

        // Aliases for compatibility
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let compactSpacing: CGFloat = 6
    }

    // MARK: - Border

    struct Border {
        static let width: CGFloat = 1
        static let selectedWidth: CGFloat = 2
        static let thickWidth: CGFloat = 3

        static let color = Colors.border
        static let lightColor = Colors.borderLight
        static let darkColor = Colors.borderDark
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 100

        // Semantic radius
        static let card: CGFloat = 12
        static let button: CGFloat = 12
        static let input: CGFloat = 10
        static let badge: CGFloat = 6

        // Aliases for compatibility
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Shadows

    struct Shadow {
        static let card = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )

        static let elevated = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 8
        )

        static let subtle = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )

        static let button = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 6,
            x: 0,
            y: 3
        )

        static let floating = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 20,
            x: 0,
            y: 10
        )
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Button Dimensions

    struct Button {
        static let heightLarge: CGFloat = 56
        static let heightMedium: CGFloat = 48
        static let heightSmall: CGFloat = 36
        static let heightCompact: CGFloat = 32

        static let iconSize: CGFloat = 44 // Accessibility minimum
        static let iconSizeCompact: CGFloat = 32

        static let paddingHorizontal: CGFloat = 24
        static let paddingVertical: CGFloat = 12

        // Aliases for compatibility
        static let largeHeight: CGFloat = 56
        static let mediumHeight: CGFloat = 48
        static let smallHeight: CGFloat = 36
        static let iconButtonSize: CGFloat = 44
        static let compactIconSize: CGFloat = 32
        static let minimumTouchTarget: CGFloat = 44
    }

    // MARK: - Input Field Dimensions

    struct Input {
        static let height: CGFloat = 52
        static let heightCompact: CGFloat = 44
        static let paddingHorizontal: CGFloat = 16
        static let iconSize: CGFloat = 20
    }

    // MARK: - Animation

    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply card shadow
    func cardShadow() -> some View {
        let shadow = AppDesign.Shadow.card
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply elevated shadow
    func elevatedShadow() -> some View {
        let shadow = AppDesign.Shadow.elevated
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply subtle shadow
    func subtleShadow() -> some View {
        let shadow = AppDesign.Shadow.subtle
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply button shadow
    func buttonShadow() -> some View {
        let shadow = AppDesign.Shadow.button
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Type Aliases for Convenience

typealias AppColors = AppDesign.Colors
typealias AppTypography = AppDesign.Typography
typealias AppSpacing = AppDesign.Spacing
typealias AppBorder = AppDesign.Border
typealias AppCornerRadius = AppDesign.CornerRadius
typealias AppShadow = AppDesign.Shadow
typealias AppButtonDimensions = AppDesign.Button
typealias AppInputDimensions = AppDesign.Input
typealias AppAnimation = AppDesign.Animation

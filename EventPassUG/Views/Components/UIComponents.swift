//
//  UIComponents.swift
//  EventPassUG
//
//  Reusable UI components for consistent design system
//

import SwiftUI

// MARK: - App Button

enum AppButtonStyle {
    case primary
    case secondary
    case destructive
    case outline
    case ghost
}

enum AppButtonSize {
    case large
    case medium
    case small

    // FIXED: Responsive button heights with minimum touch targets
    var height: CGFloat {
        switch self {
        case .large: return max(56, AppButtonDimensions.minimumTouchTarget)
        case .medium: return max(48, AppButtonDimensions.minimumTouchTarget)
        case .small: return max(44, AppButtonDimensions.minimumTouchTarget) // Increased from 36 to meet accessibility
        }
    }

    var font: Font {
        switch self {
        case .large: return AppTypography.buttonLarge
        case .medium: return AppTypography.buttonMedium
        case .small: return AppTypography.buttonSmall
        }
    }

    // FIXED: Responsive icon sizes
    var iconSize: CGFloat {
        switch self {
        case .large: return 20
        case .medium: return 18
        case .small: return 16 // Increased from 14 for better visibility
        }
    }
}

struct AppButton: View {
    let title: String
    let style: AppButtonStyle
    var size: AppButtonSize = .large
    var icon: String? = nil
    var iconPosition: IconPosition = .leading
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    var role: UserRole = .attendee
    let action: () -> Void

    enum IconPosition {
        case leading
        case trailing
    }

    private var backgroundColor: Color {
        if isDisabled { return Color.gray.opacity(0.3) }
        switch style {
        case .primary:
            return RoleConfig.getPrimaryColor(for: role)
        case .secondary:
            return Color(UIColor.secondarySystemBackground)
        case .destructive:
            return RoleConfig.error
        case .outline, .ghost:
            return .clear
        }
    }

    private var foregroundColor: Color {
        if isDisabled { return .gray }
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        case .outline:
            return RoleConfig.getPrimaryColor(for: role)
        case .ghost:
            return RoleConfig.getPrimaryColor(for: role)
        }
    }

    private var borderColor: Color {
        switch style {
        case .outline:
            return isDisabled ? .gray : RoleConfig.getPrimaryColor(for: role)
        default:
            return .clear
        }
    }

    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                HapticFeedback.light()
                action()
            }
        }) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon, iconPosition == .leading {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }

                    Text(title)
                        .font(size.font)

                    if let icon = icon, iconPosition == .trailing {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(backgroundColor)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(borderColor, lineWidth: AppBorder.selectedWidth)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Social Auth Button

struct SocialAuthButton: View {
    enum Provider {
        case google
        case apple
        case phone

        var iconName: String {
            switch self {
            case .google: return "g.circle.fill"
            case .apple: return "apple.logo"
            case .phone: return "phone.fill"
            }
        }

        var title: String {
            switch self {
            case .google: return "Continue with Google"
            case .apple: return "Continue with Apple"
            case .phone: return "Continue with Phone"
            }
        }
    }

    let provider: Provider
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            if !isLoading {
                HapticFeedback.light()
                action()
            }
        }) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.9)
                } else {
                    if provider == .google {
                        // Custom Google logo - FIXED: Using design system values
                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22) // Slightly larger for better visibility
                            .overlay(
                                Text("G")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                    } else {
                        Image(systemName: provider.iconName)
                            .font(.system(size: 20, weight: .medium)) // Increased from 18 for consistency
                    }

                    Text(provider.title)
                        .font(AppTypography.buttonMedium)
                }
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: AppButtonDimensions.mediumHeight)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppBorder.lightColor, lineWidth: AppBorder.width)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - App Card

struct AppCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.md
    var cornerRadius: CGFloat = AppCornerRadius.medium
    var hasShadow: Bool = true
    var hasBorder: Bool = false
    let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(cornerRadius)
            .if(hasShadow) { view in
                view.shadow(
                    color: AppShadow.card.color,
                    radius: AppShadow.card.radius,
                    x: AppShadow.card.x,
                    y: AppShadow.card.y
                )
            }
            .if(hasBorder) { view in
                view.overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(AppBorder.lightColor, lineWidth: AppBorder.width)
                )
            }
    }
}

// MARK: - App Section Header

struct AppSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"
    var icon: String? = nil
    var iconColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                HStack(spacing: AppSpacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold)) // FIXED: Increased from 18 for better visibility
                            .foregroundColor(iconColor ?? .primary)
                    }

                    Text(title)
                        .font(AppTypography.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                if let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(AppTypography.subheadline)
                            .foregroundColor(RoleConfig.attendeePrimary)
                    }
                }
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - App Input Field

struct AppInputField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var errorMessage: String? = nil
    var helperText: String? = nil

    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack(spacing: AppSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18)) // FIXED: Increased from 16 for better visibility
                        .foregroundColor(.secondary)
                        .frame(minWidth: 22) // FIXED: Changed from fixed width to minWidth
                }

                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                        .font(AppTypography.body)
                } else {
                    TextField(placeholder, text: $text)
                        .font(AppTypography.body)
                        .keyboardType(keyboardType)
                        .autocapitalization(autocapitalization)
                }

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 18)) // FIXED: Increased from 16 for better visibility
                            .foregroundColor(.secondary)
                            .frame(minWidth: AppButtonDimensions.minimumTouchTarget, minHeight: AppButtonDimensions.minimumTouchTarget) // FIXED: Ensure touch target
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(
                        errorMessage != nil ? RoleConfig.error : AppBorder.lightColor,
                        lineWidth: AppBorder.width
                    )
            )

            if let error = errorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(RoleConfig.error)
            } else if let helper = helperText {
                Text(helper)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - App Icon Button

struct AppIconButton: View {
    let icon: String
    var size: CGFloat = AppButtonDimensions.iconButtonSize
    var iconSize: CGFloat = 20 // FIXED: Increased from 18 for better visibility
    var backgroundColor: Color = Color(UIColor.tertiarySystemFill)
    var foregroundColor: Color = .primary
    var badge: Int? = nil
    let action: () -> Void

    // FIXED: Responsive badge sizing
    private var badgeSize: CGFloat {
        max(18, size * 0.4) // Badge scales with button size, minimum 18pt
    }

    private var badgeFontSize: CGFloat {
        max(11, badgeSize * 0.6) // Font scales with badge, minimum 11pt
    }

    private var badgeOffset: CGFloat {
        size * 0.1 // Offset is 10% of button size
    }

    var body: some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(foregroundColor)
                    .frame(width: max(size, AppButtonDimensions.minimumTouchTarget), height: max(size, AppButtonDimensions.minimumTouchTarget)) // FIXED: Ensure minimum touch target
                    .background(backgroundColor)
                    .clipShape(Circle())

                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: badgeFontSize, weight: .bold)) // FIXED: Responsive font size
                        .foregroundColor(.white)
                        .frame(minWidth: badgeSize, minHeight: badgeSize) // FIXED: Responsive badge size
                        .background(RoleConfig.error)
                        .clipShape(Circle())
                        .offset(x: badgeOffset, y: -badgeOffset) // FIXED: Responsive offset
                }
            }
        }
    }
}

// MARK: - App Chip

struct AppChip: View {
    let title: String
    var icon: String? = nil
    var isSelected: Bool = false
    var color: Color = RoleConfig.attendeePrimary
    var onTap: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onTap?()
        }) {
            HStack(spacing: AppSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13)) // FIXED: Increased from 12 for better visibility
                }

                Text(title)
                    .font(AppTypography.caption)
                    .fontWeight(.medium)

                if let onRemove = onRemove {
                    Button(action: {
                        HapticFeedback.light()
                        onRemove()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15)) // FIXED: Increased from 14 for better visibility
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                }
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.compactSpacing)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(AppCornerRadius.pill)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil && onRemove == nil)
    }
}

// MARK: - App Divider

struct AppDivider: View {
    var color: Color = AppBorder.color
    var height: CGFloat = 1
    var padding: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .padding(.horizontal, padding)
    }
}

// MARK: - App Empty State

struct AppEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var iconColor: Color = .secondary
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    var role: UserRole = .attendee

    // FIXED: Responsive sizing for empty state
    private let circleSize: CGFloat = 130 // Increased from 120 for better visibility
    private let iconSize: CGFloat = 55 // Increased from 50 for better visibility

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: circleSize, height: circleSize) // FIXED: Using constant

                Image(systemName: icon)
                    .font(.system(size: iconSize)) // FIXED: Using constant
                    .foregroundColor(iconColor.opacity(0.6))
            }

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.title3)
                    .fontWeight(.bold)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle = buttonTitle, let action = buttonAction {
                AppButton(
                    title: buttonTitle,
                    style: .primary,
                    size: .medium,
                    fullWidth: false,
                    role: role,
                    action: action
                )
                .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - App Loading Overlay

struct AppLoadingOverlay: View {
    var message: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                if let message = message {
                    Text(message)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(AppSpacing.lg)
            .background(Color(UIColor.systemGray).opacity(0.9))
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

// MARK: - App Status Badge

struct AppStatusBadge: View {
    let status: String
    var color: Color = .green
    var icon: String? = nil

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11)) // FIXED: Increased from 10 for better visibility
            }

            Text(status)
                .font(.system(size: 12, weight: .semibold)) // FIXED: Increased from 11 for better readability
        }
        .foregroundColor(color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(color.opacity(0.15))
        .cornerRadius(AppCornerRadius.small)
    }
}

// MARK: - View Extension for Conditional Modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Previews

#Preview("Buttons") {
    ScrollView {
        VStack(spacing: AppSpacing.md) {
            AppButton(title: "Primary Button", style: .primary) {}
            AppButton(title: "Secondary Button", style: .secondary) {}
            AppButton(title: "Destructive", style: .destructive) {}
            AppButton(title: "Outline", style: .outline) {}
            AppButton(title: "With Icon", style: .primary, icon: "arrow.right", iconPosition: .trailing) {}
            AppButton(title: "Loading", style: .primary, isLoading: true) {}
            AppButton(title: "Disabled", style: .primary, isDisabled: true) {}

            SocialAuthButton(provider: .google) {}
            SocialAuthButton(provider: .apple) {}
            SocialAuthButton(provider: .phone) {}
        }
        .padding()
    }
}

#Preview("Components") {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            AppSectionHeader(
                title: "Section Title",
                subtitle: "Optional subtitle text",
                action: {},
                icon: "star.fill",
                iconColor: .yellow
            )

            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Card Title")
                        .font(AppTypography.headline)
                    Text("This is a reusable card component")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                }
            }

            AppInputField(
                title: "Email",
                text: .constant(""),
                placeholder: "Enter your email",
                icon: "envelope",
                keyboardType: .emailAddress
            )

            AppInputField(
                title: "Password",
                text: .constant(""),
                placeholder: "Enter password",
                icon: "lock",
                isSecure: true
            )

            HStack {
                AppChip(title: "Music", icon: "music.note", isSelected: true)
                AppChip(title: "Sports", icon: "figure.run", isSelected: false)
                AppChip(title: "Tech", icon: "laptopcomputer", isSelected: false)
            }

            AppStatusBadge(status: "Active", color: .green, icon: "checkmark.circle.fill")

            AppEmptyState(
                icon: "heart.slash",
                title: "No Favorites",
                message: "Start saving events you like",
                iconColor: .pink,
                buttonTitle: "Browse Events",
                buttonAction: {}
            )
        }
        .padding()
    }
}

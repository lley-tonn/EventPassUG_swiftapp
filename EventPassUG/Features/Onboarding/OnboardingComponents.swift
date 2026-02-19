//
//  OnboardingComponents.swift
//  EventPassUG
//
//  Reusable UI components for the onboarding flow
//

import SwiftUI

// MARK: - Onboarding Slide Container

struct OnboardingSlideContainer<Content: View>: View {
    let step: OnboardingStep
    let direction: SlideDirection
    @ViewBuilder let content: () -> Content

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : direction.offset * 50)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Progress Indicator

struct OnboardingProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? accentColor : inactiveColor)
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
    }

    private var accentColor: Color {
        AppColors.primary
    }

    private var inactiveColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : AppColors.borderLight
    }
}

// MARK: - Primary Button

struct OnboardingPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingTheme.buttonCornerRadius)
                        .fill(isEnabled ? buttonGradient : disabledGradient)
                )
                .shadow(color: isEnabled ? shadowColor : .clear, radius: 12, x: 0, y: 6)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    private var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.interactiveDisabled, AppColors.interactiveDisabled.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shadowColor: Color {
        AppColors.primary.opacity(0.4)
    }
}

// MARK: - Back Button

struct OnboardingBackButton: View {
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(textColor)
        }
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : AppColors.primary
    }
}

// MARK: - Skip Button

struct OnboardingSkipButton: View {
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            Text("Skip")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
        }
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.gray
    }
}

// MARK: - Section Header

struct OnboardingSectionHeader: View {
    let title: String
    let subtitle: String?

    @Environment(\.colorScheme) var colorScheme

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(primaryTextColor)
                .multilineTextAlignment(.center)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(UIColor.label)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(UIColor.secondaryLabel)
    }
}

// MARK: - Role Card

struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 72, height: 72)

                    Image(systemName: role.icon)
                        .font(.system(size: 28))
                        .foregroundColor(iconColor)
                }

                // Text
                VStack(spacing: 6) {
                    Text(role.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(primaryTextColor)

                    Text(role.description)
                        .font(.system(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : borderColor, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: shadowColor, radius: isSelected ? 16 : 8, x: 0, y: isSelected ? 8 : 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white
    }

    private var iconBackground: Color {
        isSelected
            ? AppColors.primary.opacity(0.15)
            : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
    }

    private var iconColor: Color {
        isSelected
            ? AppColors.primary
            : (colorScheme == .dark ? .white : Color(UIColor.label))
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(UIColor.label)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(UIColor.secondaryLabel)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08)
    }
}

// MARK: - Interest Chip

struct InterestChip: View {
    let interest: InterestCategory
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: interest.icon)
                    .font(.system(size: 14))

                Text(interest.displayName)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var foregroundColor: Color {
        isSelected ? .white : (colorScheme == .dark ? .white : Color(UIColor.label))
    }

    private var backgroundColor: Color {
        isSelected ? interest.color : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }
}

// MARK: - Event Type Chip

struct EventTypeChip: View {
    let eventType: OrganizerEventType
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: eventType.icon)
                    .font(.system(size: 14))

                Text(eventType.displayName)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var foregroundColor: Color {
        isSelected ? .white : (colorScheme == .dark ? .white : Color(UIColor.label))
    }

    private var backgroundColor: Color {
        isSelected ? eventType.color : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }
}

// MARK: - Text Field Style

struct OnboardingTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 17))
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.smallCornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingTheme.smallCornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(UIColor.tertiarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.gray.opacity(0.2)
    }
}

// MARK: - Info Row

struct OnboardingInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme

    init(icon: String, title: String, value: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.action = action
    }

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(secondaryTextColor)

                Text(value)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(primaryTextColor)
            }

            Spacer()

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tertiaryTextColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: OnboardingTheme.smallCornerRadius)
                .fill(cardBackground)
        )
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(UIColor.tertiarySystemBackground)
    }

    private var iconBackground: Color {
        AppColors.primary.opacity(colorScheme == .dark ? 0.2 : 0.1)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(UIColor.label)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.secondaryLabel)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.4) : Color(UIColor.tertiaryLabel)
    }
}

// MARK: - Permission Card

struct OnboardingPermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)
            }

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(primaryTextColor)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            // Action button
            Button(action: action) {
                Text(isEnabled ? "Enabled" : "Enable Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? .green : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: OnboardingTheme.smallCornerRadius)
                            .fill(buttonBackground)
                    )
            }
            .disabled(isEnabled)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                .fill(cardBackground)
        )
        .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white
    }

    private var iconBackground: Color {
        AppColors.primary.opacity(colorScheme == .dark ? 0.2 : 0.1)
    }

    private var iconColor: Color {
        AppColors.primary
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(UIColor.label)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(UIColor.secondaryLabel)
    }

    private var buttonBackground: Color {
        isEnabled
            ? (colorScheme == .dark ? Color.green.opacity(0.2) : Color.green.opacity(0.1))
            : AppColors.primary
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08)
    }
}

// MARK: - Animated Illustration

struct OnboardingIllustration: View {
    let systemName: String
    let size: CGFloat

    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background circles
            ForEach(0..<3) { index in
                Circle()
                    .fill(circleColor(for: index))
                    .frame(width: size - CGFloat(index * 30), height: size - CGFloat(index * 30))
                    .scaleEffect(isAnimating ? 1.1 : 1)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }

            // Icon
            Image(systemName: systemName)
                .font(.system(size: size * 0.35))
                .foregroundColor(.white)
        }
        .onAppear {
            isAnimating = true
        }
    }

    private func circleColor(for index: Int) -> Color {
        let opacity = 0.3 - Double(index) * 0.08
        return AppColors.primary.opacity(opacity)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Previews

#Preview("Progress Indicator") {
    VStack(spacing: 40) {
        OnboardingProgressIndicator(currentStep: 0, totalSteps: 6)
        OnboardingProgressIndicator(currentStep: 2, totalSteps: 6)
        OnboardingProgressIndicator(currentStep: 5, totalSteps: 6)
    }
    .padding()
}

#Preview("Primary Button") {
    VStack(spacing: 20) {
        OnboardingPrimaryButton(title: "Continue", isEnabled: true) {}
        OnboardingPrimaryButton(title: "Continue", isEnabled: false) {}
    }
    .padding()
}

#Preview("Role Card") {
    VStack(spacing: 16) {
        RoleCard(role: .attendee, isSelected: true) {}
        RoleCard(role: .organizer, isSelected: false) {}
    }
    .padding()
}

#Preview("Interest Chips") {
    FlowLayout(spacing: 10) {
        ForEach(InterestCategory.allCases) { interest in
            InterestChip(interest: interest, isSelected: interest == .music) {}
        }
    }
    .padding()
}

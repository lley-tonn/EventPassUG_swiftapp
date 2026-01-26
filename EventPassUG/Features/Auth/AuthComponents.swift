//
//  AuthComponents.swift
//  EventPassUG
//
//  Reusable authentication UI components
//  Modern, accessible, production-ready
//

import SwiftUI

// MARK: - Auth Text Field

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var errorMessage: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            HStack(spacing: AppDesign.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppDesign.Typography.body)
                        .foregroundColor(isFocused ? AppDesign.Colors.primary : AppDesign.Colors.textSecondary)
                        .frame(width: AppDesign.Input.iconSize)
                }

                TextField(placeholder, text: $text)
                    .font(AppDesign.Typography.body)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
            .padding(.horizontal, AppDesign.Input.paddingHorizontal)
            .frame(height: AppDesign.Input.height)
            .background(AppDesign.Colors.backgroundSecondary)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(borderColor, lineWidth: 1.5)
            )

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(AppDesign.Typography.caption)
                    Text(error)
                        .font(AppDesign.Typography.caption)
                }
                .foregroundColor(AppDesign.Colors.error)
            }
        }
        .animation(AppDesign.Animation.quick, value: isFocused)
        .animation(AppDesign.Animation.quick, value: errorMessage)
    }

    private var borderColor: Color {
        if let _ = errorMessage {
            return AppDesign.Colors.error
        }
        return isFocused ? AppDesign.Colors.primary : Color.clear
    }
}

// MARK: - Auth Secure Field

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    var errorMessage: String?

    @State private var isSecure: Bool = true
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            HStack(spacing: AppDesign.Spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(AppDesign.Typography.body)
                    .foregroundColor(isFocused ? AppDesign.Colors.primary : AppDesign.Colors.textSecondary)
                    .frame(width: AppDesign.Input.iconSize)

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AppDesign.Typography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)

                Button(action: {
                    isSecure.toggle()
                    HapticFeedback.light()
                }) {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .font(AppDesign.Typography.body)
                        .foregroundColor(AppDesign.Colors.textSecondary)
                }
            }
            .padding(.horizontal, AppDesign.Input.paddingHorizontal)
            .frame(height: AppDesign.Input.height)
            .background(AppDesign.Colors.backgroundSecondary)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(borderColor, lineWidth: 1.5)
            )

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(AppDesign.Typography.caption)
                    Text(error)
                        .font(AppDesign.Typography.caption)
                }
                .foregroundColor(AppDesign.Colors.error)
            }
        }
        .animation(AppDesign.Animation.quick, value: isFocused)
        .animation(AppDesign.Animation.quick, value: errorMessage)
    }

    private var borderColor: Color {
        if let _ = errorMessage {
            return AppDesign.Colors.error
        }
        return isFocused ? AppDesign.Colors.primary : Color.clear
    }
}

// MARK: - Auth Button

struct AuthButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            HStack(spacing: AppDesign.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }

                Text(title)
                    .font(AppDesign.Typography.buttonPrimary)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppDesign.Button.heightLarge)
            .background(buttonBackground)
            .cornerRadius(AppDesign.CornerRadius.button)
        }
        .disabled(isDisabled || isLoading)
        .buttonShadow()
        .opacity(isDisabled ? 0.5 : 1.0)
        .animation(AppDesign.Animation.quick, value: isLoading)
        .animation(AppDesign.Animation.quick, value: isDisabled)
    }

    private var buttonBackground: Color {
        if isDisabled {
            return AppDesign.Colors.interactiveDisabled
        }
        return AppDesign.Colors.primary
    }
}

// MARK: - Auth Secondary Button

struct AuthSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Text(title)
                .font(AppDesign.Typography.buttonSecondary)
                .foregroundColor(AppDesign.Colors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: AppDesign.Button.heightMedium)
                .background(AppDesign.Colors.backgroundSecondary)
                .cornerRadius(AppDesign.CornerRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.CornerRadius.button)
                        .stroke(AppDesign.Colors.primary, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - OTP Input View

struct OTPInputView: View {
    @Binding var otpCode: String
    let digitCount: Int = 6

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field for keyboard input
            TextField("", text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 1, height: 1)

            // Visual digit boxes
            HStack(spacing: AppDesign.Spacing.sm) {
                ForEach(0..<digitCount, id: \.self) { index in
                    OTPDigitBox(
                        digit: getDigit(at: index),
                        isFilled: index < otpCode.count,
                        isActive: index == otpCode.count
                    )
                }
            }
        }
        .onTapGesture {
            isFocused = true
        }
        .onChange(of: otpCode) { newValue in
            // Limit to digit count
            if newValue.count > digitCount {
                otpCode = String(newValue.prefix(digitCount))
            }
            // Only allow numbers
            otpCode = otpCode.filter { $0.isNumber }
        }
        .onAppear {
            isFocused = true
        }
    }

    private func getDigit(at index: Int) -> String {
        guard index < otpCode.count else { return "" }
        return String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)])
    }
}

struct OTPDigitBox: View {
    let digit: String
    let isFilled: Bool
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.md)
                .fill(AppDesign.Colors.backgroundSecondary)
                .frame(width: 48, height: 56)

            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.md)
                .stroke(borderColor, lineWidth: 2)
                .frame(width: 48, height: 56)

            Text(digit)
                .font(AppDesign.Typography.title)
                .foregroundColor(AppDesign.Colors.textPrimary)
        }
        .animation(AppDesign.Animation.quick, value: isFilled)
        .animation(AppDesign.Animation.quick, value: isActive)
    }

    private var borderColor: Color {
        if isActive {
            return AppDesign.Colors.primary
        }
        if isFilled {
            return AppDesign.Colors.primary.opacity(0.5)
        }
        return AppDesign.Colors.border
    }
}

// MARK: - Social Login Button

enum SocialLoginProvider {
    case apple
    case google
    case facebook

    var iconName: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .facebook: return "f.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .apple: return "Continue with Apple"
        case .google: return "Continue with Google"
        case .facebook: return "Continue with Facebook"
        }
    }

    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .apple:
            // Light mode: black, Dark mode: white
            return colorScheme == .dark ? .white : .black
        case .google:
            // Light mode: white, Dark mode: subtle gray
            return colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : .white
        case .facebook:
            // Facebook blue - slightly lighter in dark mode for visibility
            return colorScheme == .dark ? Color(hex: "2D88FF") : Color(hex: "1877F2")
        }
    }

    func foregroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .apple:
            // Inverse of background
            return colorScheme == .dark ? .black : .white
        case .google:
            // Dark text in light mode, light text in dark mode
            return colorScheme == .dark ? .white : .black
        case .facebook:
            // Always white for contrast
            return .white
        }
    }

    func borderColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .apple:
            // Border in dark mode for visibility
            return colorScheme == .dark ? Color.white.opacity(0.2) : Color.clear
        case .google:
            // Always has border for definition
            return colorScheme == .dark ? Color.white.opacity(0.15) : AppDesign.Colors.border
        case .facebook:
            // No border needed with colored background
            return Color.clear
        }
    }
}

struct SocialLoginButton: View {
    let provider: SocialLoginProvider
    let isLoading: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: AppDesign.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: provider.foregroundColor(for: colorScheme)))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: provider.iconName)
                        .font(AppDesign.Typography.title2)
                }

                Text(provider.title)
                    .font(AppDesign.Typography.buttonSecondary)
            }
            .foregroundColor(provider.foregroundColor(for: colorScheme))
            .frame(maxWidth: .infinity)
            .frame(height: AppDesign.Button.heightLarge)
            .background(provider.backgroundColor(for: colorScheme))
            .cornerRadius(AppDesign.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.button)
                    .stroke(provider.borderColor(for: colorScheme), lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .subtleShadow()
    }
}

// MARK: - Auth Mode Toggle

struct AuthModeToggle: View {
    @Binding var mode: AuthMode

    var body: some View {
        HStack(spacing: 0) {
            ModeButton(title: "Login", isSelected: mode == .login) {
                withAnimation(AppDesign.Animation.spring) {
                    mode = .login
                }
                HapticFeedback.selection()
            }

            ModeButton(title: "Register", isSelected: mode == .register) {
                withAnimation(AppDesign.Animation.spring) {
                    mode = .register
                }
                HapticFeedback.selection()
            }
        }
        .frame(height: 44)
        .background(AppDesign.Colors.backgroundSecondary)
        .cornerRadius(AppDesign.CornerRadius.pill)
    }

    struct ModeButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(AppDesign.Typography.buttonSecondary)
                    .foregroundColor(isSelected ? .white : AppDesign.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: AppDesign.CornerRadius.pill)
                            .fill(isSelected ? AppDesign.Colors.primary : Color.clear)
                    )
                    .padding(2)
            }
        }
    }
}

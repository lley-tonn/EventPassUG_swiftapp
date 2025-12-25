//
//  ModernAuthView.swift
//  EventPassUG
//
//  Modern authentication screen with pill toggle, OTP, and social login
//  Production-ready, accessible, beautiful UI
//

import SwiftUI

struct ModernAuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    init(authService: any AuthRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, AppDesign.Spacing.xxl)
                        .padding(.bottom, AppDesign.Spacing.xl)

                    // Mode toggle
                    AuthModeToggle(mode: $viewModel.mode)
                        .padding(.horizontal, AppDesign.Spacing.edge)
                        .padding(.bottom, AppDesign.Spacing.xl)

                    // Content based on mode
                    Group {
                        switch viewModel.mode {
                        case .login:
                            loginContent
                        case .register:
                            registerContent
                        case .otp:
                            // OTP mode disabled - fallback to login
                            loginContent
                        }
                    }
                    .padding(.horizontal, AppDesign.Spacing.edge)

                    // Error message
                    if case .error(let message) = viewModel.state {
                        errorBanner(message: message)
                            .padding(.horizontal, AppDesign.Spacing.edge)
                            .padding(.top, AppDesign.Spacing.md)
                    }
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(AppDesign.Colors.backgroundGrouped.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            // App icon or logo
            Image(systemName: "ticket.fill")
                .font(.system(size: 60))
                .foregroundColor(AppDesign.Colors.primary)

            Text("EventPass")
                .font(AppDesign.Typography.hero)
                .foregroundColor(AppDesign.Colors.textPrimary)

            Text(headerSubtitle)
                .font(AppDesign.Typography.secondary)
                .foregroundColor(AppDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var headerSubtitle: String {
        switch viewModel.mode {
        case .login:
            return "Welcome back! Sign in to continue"
        case .register:
            return "Create your account to get started"
        case .otp:
            return "Welcome back! Sign in to continue"
        }
    }

    // MARK: - Login Content

    private var loginContent: some View {
        VStack(spacing: AppDesign.Spacing.lg) {
            AuthTextField(
                placeholder: "Email",
                text: $viewModel.email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                errorMessage: viewModel.emailError
            )

            AuthSecureField(
                placeholder: "Password",
                text: $viewModel.password,
                errorMessage: viewModel.passwordError
            )

            // Forgot password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    HapticFeedback.light()
                    // Handle forgot password
                }
                .font(AppDesign.Typography.callout)
                .foregroundColor(AppDesign.Colors.primary)
            }

            AuthButton(
                title: "Sign In",
                isLoading: viewModel.state.isLoading,
                isDisabled: !viewModel.isLoginValid
            ) {
                Task {
                    await viewModel.signIn()
                }
            }
            .padding(.top, AppDesign.Spacing.sm)

            // Divider
            dividerWithText("OR")
                .padding(.vertical, AppDesign.Spacing.md)

            // Social login
            socialLoginSection
        }
    }

    // MARK: - Register Content

    private var registerContent: some View {
        VStack(spacing: AppDesign.Spacing.lg) {
            AuthTextField(
                placeholder: "Full Name",
                text: $viewModel.fullName,
                icon: "person.fill",
                autocapitalization: .words,
                errorMessage: viewModel.fullNameError
            )

            AuthTextField(
                placeholder: "Email",
                text: $viewModel.email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                errorMessage: viewModel.emailError
            )

            AuthSecureField(
                placeholder: "Password",
                text: $viewModel.password,
                errorMessage: viewModel.passwordError
            )

            AuthSecureField(
                placeholder: "Confirm Password",
                text: $viewModel.confirmPassword,
                errorMessage: viewModel.confirmPasswordError
            )

            AuthButton(
                title: "Create Account",
                isLoading: viewModel.state.isLoading,
                isDisabled: !viewModel.isRegisterValid
            ) {
                Task {
                    await viewModel.signUp()
                }
            }
            .padding(.top, AppDesign.Spacing.sm)

            // Divider
            dividerWithText("OR")
                .padding(.vertical, AppDesign.Spacing.md)

            // Social login
            socialLoginSection

            // Terms
            termsText
                .padding(.top, AppDesign.Spacing.sm)
        }
    }


    // MARK: - Social Login Section

    private var socialLoginSection: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            SocialLoginButton(
                provider: .apple,
                isLoading: false
            ) {
                Task {
                    await viewModel.signInWithApple()
                }
            }

            SocialLoginButton(
                provider: .google,
                isLoading: false
            ) {
                Task {
                    await viewModel.signInWithGoogle()
                }
            }
        }
    }

    // MARK: - Helper Views

    private func dividerWithText(_ text: String) -> some View {
        HStack(spacing: AppDesign.Spacing.md) {
            Rectangle()
                .fill(AppDesign.Colors.border)
                .frame(height: 1)

            Text(text)
                .font(AppDesign.Typography.caption)
                .foregroundColor(AppDesign.Colors.textSecondary)

            Rectangle()
                .fill(AppDesign.Colors.border)
                .frame(height: 1)
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppDesign.Typography.callout)
            Text(message)
                .font(AppDesign.Typography.callout)
        }
        .foregroundColor(.white)
        .padding(AppDesign.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppDesign.Colors.error)
        .cornerRadius(AppDesign.CornerRadius.md)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var termsText: some View {
        Text("By creating an account, you agree to our ")
            .font(AppDesign.Typography.caption)
            .foregroundColor(AppDesign.Colors.textSecondary)
        + Text("Terms of Service")
            .font(AppDesign.Typography.caption)
            .foregroundColor(AppDesign.Colors.primary)
        + Text(" and ")
            .font(AppDesign.Typography.caption)
            .foregroundColor(AppDesign.Colors.textSecondary)
        + Text("Privacy Policy")
            .font(AppDesign.Typography.caption)
            .foregroundColor(AppDesign.Colors.primary)
    }
}

// MARK: - Preview

#Preview {
    ModernAuthView(authService: MockAuthRepository())
}

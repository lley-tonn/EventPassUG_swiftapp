//
//  AuthChoiceView.swift
//  EventPassUG
//
//  Authentication choice screen shown after onboarding
//  Allows users to: Login, Become an Organizer, or Continue as Guest
//

import SwiftUI

struct AuthChoiceView: View {
    @Binding var showingAuth: Bool
    @Binding var showingOrganizerSignup: Bool
    @Binding var continueAsGuest: Bool

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.1)

                    // Header
                    headerSection
                        .padding(.bottom, AppDesign.Spacing.xxl)

                    // Options
                    VStack(spacing: AppDesign.Spacing.lg) {
                        // Option 1: Login
                        loginOption

                        // Option 2: Become an Organizer (Most prominent)
                        organizerOption

                        // Option 3: Continue as Guest (Secondary)
                        guestOption
                    }
                    .padding(.horizontal, AppDesign.Spacing.edge)

                    Spacer()
                        .frame(height: geometry.size.height * 0.1)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(AppDesign.Colors.backgroundGrouped.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            // App icon
            Image(systemName: "ticket.fill")
                .font(.system(size: 70))
                .foregroundColor(AppDesign.Colors.primary)

            Text("Welcome to EventPass")
                .font(AppDesign.Typography.hero)
                .foregroundColor(AppDesign.Colors.textPrimary)

            Text("Choose how you'd like to continue")
                .font(AppDesign.Typography.secondary)
                .foregroundColor(AppDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppDesign.Spacing.lg)
        }
    }

    // MARK: - Option 1: Login

    private var loginOption: some View {
        Button(action: {
            HapticFeedback.light()
            showingAuth = true
        }) {
            HStack(spacing: AppDesign.Spacing.md) {
                // Icon
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppDesign.Colors.primary)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign In")
                        .font(AppDesign.Typography.cardTitle)
                        .foregroundColor(AppDesign.Colors.textPrimary)

                    Text("Already have an account?")
                        .font(AppDesign.Typography.caption)
                        .foregroundColor(AppDesign.Colors.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesign.Colors.textTertiary)
            }
            .padding(AppDesign.Spacing.lg)
            .background(AppDesign.Colors.backgroundSecondary)
            .cornerRadius(AppDesign.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.card)
                    .stroke(AppDesign.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Option 2: Become an Organizer (Prominent)

    private var organizerOption: some View {
        Button(action: {
            HapticFeedback.medium()
            showingOrganizerSignup = true
        }) {
            VStack(spacing: AppDesign.Spacing.md) {
                // Icon
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .padding(AppDesign.Spacing.md)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [RoleConfig.organizerPrimary, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                // Text
                VStack(spacing: 6) {
                    Text("Host Your Own Events")
                        .font(AppDesign.Typography.section)
                        .foregroundColor(.white)

                    Text("Create and manage events, sell tickets, and grow your audience")
                        .font(AppDesign.Typography.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppDesign.Spacing.md)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppDesign.Spacing.xl)
            .padding(.horizontal, AppDesign.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [RoleConfig.organizerPrimary, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppDesign.CornerRadius.card)
            .shadow(color: RoleConfig.organizerPrimary.opacity(0.3), radius: 20, y: 10)
        }
    }

    // MARK: - Option 3: Continue as Guest

    private var guestOption: some View {
        Button(action: {
            HapticFeedback.light()
            continueAsGuest = true
        }) {
            HStack(spacing: AppDesign.Spacing.md) {
                // Icon
                Image(systemName: "eye.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesign.Colors.textSecondary)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Browse Events")
                        .font(AppDesign.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppDesign.Colors.textPrimary)

                    Text("Explore without signing in")
                        .font(AppDesign.Typography.caption)
                        .foregroundColor(AppDesign.Colors.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesign.Colors.textTertiary)
            }
            .padding(AppDesign.Spacing.md)
            .background(AppDesign.Colors.backgroundSecondary.opacity(0.5))
            .cornerRadius(AppDesign.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.button)
                    .stroke(AppDesign.Colors.border.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AuthChoiceView(
        showingAuth: .constant(false),
        showingOrganizerSignup: .constant(false),
        continueAsGuest: .constant(false)
    )
}

//
//  GuestPlaceholders.swift
//  EventPassUG
//
//  Placeholder views shown to guest users for restricted tabs
//  - GuestTicketsPlaceholder: Shows in Tickets tab
//  - GuestProfilePlaceholder: Shows in Profile tab with organizer teaser
//

import SwiftUI

// MARK: - Guest Tickets Placeholder

struct GuestTicketsPlaceholder: View {
    @State private var showingAuth = false
    @EnvironmentObject var authService: MockAuthRepository

    var body: some View {
        ScrollView {
            VStack(spacing: AppDesign.Spacing.xl) {
                Spacer()
                    .frame(height: 60)

                // Icon
                Image(systemName: "ticket.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppDesign.Colors.primary.opacity(0.3))

                // Title
                Text("Sign in to view your tickets")
                    .font(AppDesign.Typography.section)
                    .foregroundColor(AppDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                // Benefits
                VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                    benefitRow(
                        icon: "qrcode",
                        title: "Access QR Codes",
                        description: "Quick entry at events"
                    )

                    benefitRow(
                        icon: "wallet.pass.fill",
                        title: "Add to Wallet",
                        description: "Store tickets in Apple Wallet"
                    )

                    benefitRow(
                        icon: "clock.fill",
                        title: "Purchase History",
                        description: "Track all your tickets"
                    )
                }
                .padding(.horizontal, AppDesign.Spacing.xl)

                // Sign In Button
                Button(action: {
                    HapticFeedback.medium()
                    showingAuth = true
                }) {
                    Text("Sign In")
                        .font(AppDesign.Typography.buttonPrimary)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppDesign.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [AppDesign.Colors.primary, AppDesign.Colors.primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppDesign.CornerRadius.button)
                        .shadow(color: AppDesign.Colors.primary.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, AppDesign.Spacing.edge)
                .padding(.top, AppDesign.Spacing.lg)

                Spacer()
            }
            .padding(.vertical, AppDesign.Spacing.xl)
        }
        .background(AppDesign.Colors.backgroundGrouped.ignoresSafeArea())
        .navigationTitle("Tickets")
        .sheet(isPresented: $showingAuth) {
            ModernAuthView(authService: authService)
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppDesign.Colors.primary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppDesign.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppDesign.Colors.textPrimary)

                Text(description)
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(AppDesign.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Guest Profile Placeholder

struct GuestProfilePlaceholder: View {
    @State private var showingAuth = false
    @Binding var showingOrganizerSignup: Bool
    @EnvironmentObject var authService: MockAuthRepository

    var body: some View {
        ScrollView {
            VStack(spacing: AppDesign.Spacing.xxl) {
                // Section 1: Sign In CTA
                signInSection

                // Section 2: Become an Organizer Teaser
                organizerSection
            }
            .padding(.vertical, AppDesign.Spacing.xxl)
            .padding(.horizontal, AppDesign.Spacing.edge)
        }
        .background(AppDesign.Colors.backgroundGrouped.ignoresSafeArea())
        .navigationTitle("Profile")
        .sheet(isPresented: $showingAuth) {
            ModernAuthView(authService: authService)
        }
        // Note: fullScreenCover for organizer signup is handled by MainTabView
    }

    // MARK: - Sign In Section

    private var signInSection: some View {
        VStack(spacing: AppDesign.Spacing.lg) {
            // Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(AppDesign.Colors.primary.opacity(0.3))

            // Title
            Text("Create your account")
                .font(AppDesign.Typography.section)
                .foregroundColor(AppDesign.Colors.textPrimary)

            // Benefits
            VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                benefitItem(icon: "heart.fill", text: "Save your favorite events")
                benefitItem(icon: "person.2.fill", text: "Follow your favorite organizers")
                benefitItem(icon: "bell.fill", text: "Get personalized notifications")
                benefitItem(icon: "gearshape.fill", text: "Manage your preferences")
            }

            // Create Account Button
            Button(action: {
                HapticFeedback.medium()
                showingAuth = true
            }) {
                Text("Create Account")
                    .font(AppDesign.Typography.buttonPrimary)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppDesign.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [AppDesign.Colors.primary, AppDesign.Colors.primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppDesign.CornerRadius.button)
                    .shadow(color: AppDesign.Colors.primary.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.top, AppDesign.Spacing.sm)
        }
        .padding(AppDesign.Spacing.xl)
        .background(AppDesign.Colors.backgroundSecondary)
        .cornerRadius(AppDesign.CornerRadius.large)
    }

    // MARK: - Organizer Section

    private var organizerSection: some View {
        Button(action: {
            HapticFeedback.medium()
            showingOrganizerSignup = true
        }) {
            VStack(spacing: AppDesign.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [RoleConfig.organizerPrimary, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Host Events & Sell Tickets")
                        .font(AppDesign.Typography.section)
                        .foregroundColor(AppDesign.Colors.textPrimary)

                    Text("Reach thousands of attendees, track sales in real-time, and grow your events with our powerful tools")
                        .font(AppDesign.Typography.body)
                        .foregroundColor(AppDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                // Features
                HStack(spacing: AppDesign.Spacing.lg) {
                    organizerFeature(icon: "chart.line.uptrend.xyaxis", text: "Analytics")
                    organizerFeature(icon: "ticket.fill", text: "Ticket Sales")
                    organizerFeature(icon: "person.3.fill", text: "Audience")
                }

                // Button
                HStack {
                    Text("Become an Organizer")
                        .font(AppDesign.Typography.buttonPrimary)
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppDesign.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [RoleConfig.organizerPrimary, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppDesign.CornerRadius.button)
            }
            .padding(AppDesign.Spacing.xl)
            .background(AppDesign.Colors.backgroundSecondary)
            .cornerRadius(AppDesign.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.large)
                    .stroke(
                        LinearGradient(
                            colors: [RoleConfig.organizerPrimary.opacity(0.3), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
    }

    private func benefitItem(icon: String, text: String) -> some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppDesign.Colors.primary)
                .frame(width: 24)

            Text(text)
                .font(AppDesign.Typography.body)
                .foregroundColor(AppDesign.Colors.textSecondary)
        }
    }

    private func organizerFeature(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(RoleConfig.organizerPrimary)

            Text(text)
                .font(AppDesign.Typography.caption)
                .foregroundColor(AppDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Guest Tickets") {
    NavigationStack {
        GuestTicketsPlaceholder()
            .environmentObject(MockAuthRepository())
    }
}

#Preview("Guest Profile") {
    NavigationStack {
        GuestProfilePlaceholder(showingOrganizerSignup: .constant(false))
            .environmentObject(MockAuthRepository())
    }
}

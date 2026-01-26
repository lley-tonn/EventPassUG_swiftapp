//
//  AuthPromptSheet.swift
//  EventPassUG
//
//  Reusable authentication prompt modal shown when guests
//  attempt restricted actions (like, favorite, purchase, etc.)
//

import SwiftUI

struct AuthPromptSheet: View {
    let reason: String
    let icon: String
    let onAuthSuccess: (() -> Void)?

    @Binding var isPresented: Bool
    @EnvironmentObject var authService: MockAuthRepository

    @State private var showingAuthFlow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppDesign.Spacing.xl) {
                    Spacer()
                        .frame(height: 20)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppDesign.Colors.primary.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: icon)
                            .font(.system(size: 48))
                            .foregroundColor(AppDesign.Colors.primary)
                    }

                    // Title
                    VStack(spacing: 8) {
                        Text("Sign in \(reason)")
                            .font(AppDesign.Typography.section)
                            .foregroundColor(AppDesign.Colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Create an account or sign in to unlock this feature")
                            .font(AppDesign.Typography.body)
                            .foregroundColor(AppDesign.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, AppDesign.Spacing.lg)

                    // Benefits
                    VStack(spacing: AppDesign.Spacing.md) {
                        benefitRow(
                            icon: "checkmark.circle.fill",
                            text: getBenefit1()
                        )

                        benefitRow(
                            icon: "checkmark.circle.fill",
                            text: getBenefit2()
                        )

                        benefitRow(
                            icon: "checkmark.circle.fill",
                            text: getBenefit3()
                        )
                    }
                    .padding(.horizontal, AppDesign.Spacing.xl)

                    // Buttons
                    VStack(spacing: AppDesign.Spacing.md) {
                        // Sign In Button (Primary)
                        Button(action: {
                            HapticFeedback.medium()
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingAuthFlow = true
                            }
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

                        // Create Account Button (Secondary)
                        Button(action: {
                            HapticFeedback.medium()
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingAuthFlow = true
                            }
                        }) {
                            Text("Create Account")
                                .font(AppDesign.Typography.buttonPrimary)
                                .fontWeight(.semibold)
                                .foregroundColor(AppDesign.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppDesign.Spacing.md)
                                .background(AppDesign.Colors.backgroundSecondary)
                                .cornerRadius(AppDesign.CornerRadius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.CornerRadius.button)
                                        .stroke(AppDesign.Colors.primary, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal, AppDesign.Spacing.edge)
                    .padding(.top, AppDesign.Spacing.sm)

                    Spacer()
                }
                .padding(.vertical, AppDesign.Spacing.xl)
            }
            .background(AppDesign.Colors.backgroundGrouped.ignoresSafeArea())
            .navigationTitle("Authentication Required")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        isPresented = false
                    }) {
                        Text("Not Now")
                            .font(AppDesign.Typography.body)
                            .foregroundColor(AppDesign.Colors.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAuthFlow) {
            ModernAuthView(authService: authService)
        }
        .onChange(of: authService.isAuthenticated) { isAuth in
            if isAuth {
                // User authenticated successfully
                isPresented = false
                // Execute the pending action after a brief delay
                if let callback = onAuthSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        callback()
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppDesign.Colors.success)
                .frame(width: 28)

            Text(text)
                .font(AppDesign.Typography.body)
                .foregroundColor(AppDesign.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Benefit Text Generators

    private func getBenefit1() -> String {
        switch reason {
        case let str where str.contains("like") || str.contains("favorite"):
            return "Save and sync your favorites across devices"
        case let str where str.contains("follow"):
            return "Get notified about new events from organizers"
        case let str where str.contains("purchase") || str.contains("buy"):
            return "Secure checkout with multiple payment options"
        case let str where str.contains("rate"):
            return "Share your experience with other attendees"
        default:
            return "Access exclusive features and benefits"
        }
    }

    private func getBenefit2() -> String {
        switch reason {
        case let str where str.contains("like") || str.contains("favorite"):
            return "Get personalized event recommendations"
        case let str where str.contains("follow"):
            return "Discover similar organizers you might like"
        case let str where str.contains("purchase") || str.contains("buy"):
            return "QR codes and Apple Wallet integration"
        case let str where str.contains("rate"):
            return "Help others discover great events"
        default:
            return "Personalized experience tailored to you"
        }
    }

    private func getBenefit3() -> String {
        switch reason {
        case let str where str.contains("like") || str.contains("favorite"):
            return "Never miss events you're interested in"
        case let str where str.contains("follow"):
            return "Build your personalized event feed"
        case let str where str.contains("purchase") || str.contains("buy"):
            return "Track all your tickets in one place"
        case let str where str.contains("rate"):
            return "Build your event history and preferences"
        default:
            return "Join thousands of event enthusiasts"
        }
    }
}

// MARK: - Preview

#Preview {
    AuthPromptSheet(
        reason: "to save favorites",
        icon: "heart.fill",
        onAuthSuccess: {
            print("Auth successful")
        },
        isPresented: .constant(true)
    )
    .environmentObject(MockAuthRepository())
}

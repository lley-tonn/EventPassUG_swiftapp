//
//  ProfileView+ContactVerification.swift
//  EventPassUG
//
//  Contact verification and linking section for ProfileView
//  ADD THIS TO THE EXISTING PROFILE VIEW
//

import SwiftUI

/*
 * INSTRUCTIONS FOR INTEGRATION:
 *
 * 1. Add these state variables to ProfileView:
 *    @State private var showingEmailVerification = false
 *    @State private var showingPhoneVerification = false
 *    @State private var showingAddEmail = false
 *    @State private var showingAddPhone = false
 *    @State private var showingAccountLinking = false
 *    @State private var isVerifyingEmail = false
 *
 * 2. Add this section BEFORE the "Settings" section (around line 152):
 */

struct ContactVerificationSection: View {
    @EnvironmentObject var authService: MockAuthRepository
    @Binding var showingEmailVerification: Bool
    @Binding var showingPhoneVerification: Bool
    @Binding var showingAddEmail: Bool
    @Binding var showingAddPhone: Bool
    @Binding var showingAccountLinking: Bool
    @Binding var isVerifyingEmail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Contact Information")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 1) {
                // Email Status/Actions
                if let email = authService.currentUser?.email {
                    // Email exists
                    if authService.currentUser?.isEmailVerified == true {
                        // Verified email
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Email Verified")
                                    .foregroundColor(.primary)
                                Text(email)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                    } else {
                        // Unverified email
                        Button(action: {
                            showingEmailVerification = true
                        }) {
                            HStack {
                                Image(systemName: "envelope.badge")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Verify Email")
                                        .foregroundColor(.primary)
                                    Text(email)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }

                    Divider()
                } else {
                    // No email - show add button
                    Button(action: {
                        showingAddEmail = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)

                            Text("Add Email Address")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)
                        }
                        .padding()
                    }

                    Divider()
                }

                // Phone Status/Actions
                if let phone = authService.currentUser?.phoneNumber {
                    // Phone exists
                    if authService.currentUser?.isPhoneVerified == true {
                        // Verified phone
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phone Verified")
                                    .foregroundColor(.primary)
                                Text(phone)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                    } else {
                        // Unverified phone
                        Button(action: {
                            showingPhoneVerification = true
                        }) {
                            HStack {
                                Image(systemName: "phone.badge")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Verify Phone Number")
                                        .foregroundColor(.primary)
                                    Text(phone)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }

                    Divider()
                } else {
                    // No phone - show add button
                    Button(action: {
                        showingAddPhone = true
                    }) {
                        HStack {
                            Image(systemName: "phone.badge.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)

                            Text("Add Phone Number")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)
                        }
                        .padding()
                    }

                    Divider()
                }

                // Account Linking (if user has less than 3 providers)
                if (authService.currentUser?.authProviders.count ?? 0) < 3 {
                    Button(action: {
                        showingAccountLinking = true
                    }) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Link Accounts")
                                    .foregroundColor(.primary)
                                Text("Add more sign-in options")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

// SNIPPET: Add these sheets to ProfileView
/*
 * Add these modifiers to the main VStack in ProfileView:
 *
 * .sheet(isPresented: $showingEmailVerification) {
 *     EmailVerificationSheet(
 *         isVerifying: $isVerifyingEmail
 *     )
 *     .environmentObject(authService)
 * }
 * .sheet(isPresented: $showingPhoneVerification) {
 *     if let phone = authService.currentUser?.phoneNumber {
 *         PhoneVerificationView(phoneNumber: phone) {
 *             // On verified
 *         }
 *         .environmentObject(authService)
 *     }
 * }
 * .sheet(isPresented: $showingAddEmail) {
 *     AddContactMethodView(method: .email)
 *         .environmentObject(authService)
 * }
 * .sheet(isPresented: $showingAddPhone) {
 *     AddContactMethodView(method: .phone)
 *         .environmentObject(authService)
 * }
 * .sheet(isPresented: $showingAccountLinking) {
 *     AccountLinkingView()
 *         .environmentObject(authService)
 * }
 */

// Email Verification Sheet
struct EmailVerificationSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthRepository
    @Binding var isVerifying: Bool

    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(RoleConfig.attendeePrimary)

                    Text("Verify Your Email")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    if let email = authService.currentUser?.email {
                        Text("We'll send a verification link to:")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)

                        Text(email)
                            .font(AppTypography.headline)
                            .foregroundColor(RoleConfig.attendeePrimary)
                    }

                    Text("Click the link in the email to verify your address")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if isVerifying {
                    ProgressView()
                        .padding()
                } else {
                    Button(action: sendVerificationEmail) {
                        Text("Send Verification Email")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoleConfig.attendeePrimary)
                            .cornerRadius(AppCornerRadius.medium)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Email Sent!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Check your inbox and click the verification link.")
        }
    }

    private func sendVerificationEmail() {
        isVerifying = true

        Task {
            do {
                try await authService.sendEmailVerification()

                await MainActor.run {
                    isVerifying = false
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    HapticFeedback.error()
                }
            }
        }
    }
}

// Account Linking View
struct AccountLinkingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthRepository

    @State private var isLinking = false
    @State private var showSuccess = false
    @State private var successMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Link Accounts")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)

                        Text("Add more ways to sign in to your account")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)

                    // Current Providers
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Connected")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, AppSpacing.md)

                        VStack(spacing: 1) {
                            ForEach(authService.currentUser?.authProviders ?? [], id: \.self) { provider in
                                HStack {
                                    Image(systemName: iconForProvider(provider))
                                        .foregroundColor(.green)

                                    Text(displayNameForProvider(provider))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding()
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    // Available to Link
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Available to Link")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, AppSpacing.md)

                        VStack(spacing: AppSpacing.md) {
                            if !(authService.currentUser?.authProviders.contains("google.com") ?? false) {
                                linkButton(
                                    icon: "g.circle.fill",
                                    title: "Link Google Account",
                                    action: linkGoogle
                                )
                            }

                            if !(authService.currentUser?.authProviders.contains("apple.com") ?? false) {
                                linkButton(
                                    icon: "applelogo",
                                    title: "Link Apple Account",
                                    action: linkApple
                                )
                            }

                            if !(authService.currentUser?.authProviders.contains("email") ?? false) {
                                linkButton(
                                    icon: "envelope.fill",
                                    title: "Link Email & Password",
                                    action: {} // Shows add email sheet
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Account Linked!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text(successMessage)
        }
    }

    private func linkButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(RoleConfig.attendeePrimary)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if isLinking {
                    ProgressView()
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundColor(RoleConfig.attendeePrimary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
        }
        .disabled(isLinking)
    }

    private func linkGoogle() {
        isLinking = true

        Task {
            do {
                try await authService.linkGoogleAccount()

                await MainActor.run {
                    isLinking = false
                    successMessage = "Google account linked successfully!"
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isLinking = false
                    HapticFeedback.error()
                }
            }
        }
    }

    private func linkApple() {
        isLinking = true

        Task {
            do {
                try await authService.linkAppleAccount()

                await MainActor.run {
                    isLinking = false
                    successMessage = "Apple account linked successfully!"
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isLinking = false
                    HapticFeedback.error()
                }
            }
        }
    }

    private func iconForProvider(_ provider: String) -> String {
        switch provider {
        case "google.com": return "g.circle.fill"
        case "apple.com": return "applelogo"
        case "phone": return "phone.fill"
        case "email": return "envelope.fill"
        default: return "questionmark.circle"
        }
    }

    private func displayNameForProvider(_ provider: String) -> String {
        switch provider {
        case "google.com": return "Google"
        case "apple.com": return "Apple"
        case "phone": return "Phone Number"
        case "email": return "Email & Password"
        default: return provider
        }
    }
}

#Preview {
    ContactVerificationSection(
        showingEmailVerification: .constant(false),
        showingPhoneVerification: .constant(false),
        showingAddEmail: .constant(false),
        showingAddPhone: .constant(false),
        showingAccountLinking: .constant(false),
        isVerifyingEmail: .constant(false)
    )
    .environmentObject(MockAuthRepository())
}

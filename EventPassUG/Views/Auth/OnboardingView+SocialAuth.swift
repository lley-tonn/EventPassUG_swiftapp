//
//  OnboardingView+SocialAuth.swift
//  EventPassUG
//
//  Extension to add social auth methods to onboarding
//  ADD THIS TO THE EXISTING ONBOARDING VIEW
//

import SwiftUI

/*
 * INSTRUCTIONS FOR INTEGRATION:
 *
 * 1. Add these state variables to OnboardingView:
 *    @State private var showingSocialRoleSelection = false
 *    @State private var selectedAuthMethod: String = "" // "google", "apple", "phone"
 *    @State private var showingPhoneAuth = false
 *    @State private var tempPhoneNumber = ""
 *    @State private var phoneVerificationId: String?
 *
 * 2. Replace the original sign-up form section with this:
 */

// SNIPPET TO ADD AFTER THE SIGN UP FORM (around line 86):

struct OnboardingSocialAuthSection: View {
    @EnvironmentObject var authService: MockAuthService
    @Binding var selectedRole: UserRole
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @Binding var showingRoleSelection: Bool
    @Binding var showingSocialRoleSelection: Bool
    @Binding var selectedAuthMethod: String
    @Binding var showingPhoneAuth: Bool

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Original Email/Password Form (keep existing)
            TextField("First Name", text: $firstName)
                .textFieldStyle(.roundedBorder)
                .textContentType(.givenName)
                .autocapitalization(.words)

            TextField("Last Name", text: $lastName)
                .textFieldStyle(.roundedBorder)
                .textContentType(.familyName)
                .autocapitalization(.words)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)

            if let error = errorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Button(action: {
                showingRoleSelection = true
            }) {
                Text("Continue")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoleConfig.getPrimaryColor(for: selectedRole))
                    .cornerRadius(AppCornerRadius.medium)
            }
            .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty)
            .opacity((firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) ? 0.5 : 1.0)

            // NEW: Social Auth Buttons
            SocialAuthButtons(
                onGoogleTap: {
                    selectedAuthMethod = "google"
                    showingSocialRoleSelection = true
                },
                onAppleTap: {
                    selectedAuthMethod = "apple"
                    showingSocialRoleSelection = true
                },
                isLoading: isLoading
            )

            // NEW: Phone Auth Button
            PhoneAuthButton(
                onPhoneTap: {
                    selectedAuthMethod = "phone"
                    showingPhoneAuth = true
                },
                isLoading: isLoading
            )
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

// SNIPPET: Add these helper functions to OnboardingView:

extension OnboardingView {
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await authService.signInWithGoogle(
                    firstName: "Google", // In real implementation, get from Google
                    lastName: "User",
                    role: selectedRole
                )
                HapticFeedback.success()
            } catch {
                errorMessage = error.localizedDescription
                HapticFeedback.error()
                isLoading = false
                showingSocialRoleSelection = false
            }
        }
    }

    func signInWithApple() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await authService.signInWithApple(
                    firstName: "Apple", // In real implementation, get from Apple
                    lastName: "User",
                    role: selectedRole
                )
                HapticFeedback.success()
            } catch {
                errorMessage = error.localizedDescription
                HapticFeedback.error()
                isLoading = false
                showingSocialRoleSelection = false
            }
        }
    }
}

// SNIPPET: Social auth role selection sheet
// Add this as a .sheet modifier to the main VStack in OnboardingView:

struct SocialAuthRoleSheet: View {
    @EnvironmentObject var authService: MockAuthService
    @Binding var showingSocialRoleSelection: Bool
    @Binding var selectedRole: UserRole
    @Binding var selectedAuthMethod: String
    @Binding var isLoading: Bool

    let onContinue: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                Text("Choose your role")
                    .font(AppTypography.title2)
                    .fontWeight(.bold)
                    .padding(.top, AppSpacing.xl)

                Text("You can switch roles later in settings")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: AppSpacing.md) {
                    RoleSelectionCard(
                        role: .attendee,
                        isSelected: selectedRole == .attendee,
                        onTap: {
                            HapticFeedback.selection()
                            selectedRole = .attendee
                        }
                    )

                    RoleSelectionCard(
                        role: .organizer,
                        isSelected: selectedRole == .organizer,
                        onTap: {
                            HapticFeedback.selection()
                            selectedRole = .organizer
                        }
                    )
                }

                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Button(action: onContinue) {
                        HStack {
                            Image(systemName: selectedAuthMethod == "google" ? "g.circle.fill" : "applelogo")
                            Text("Continue with \(selectedAuthMethod.capitalized)")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoleConfig.getPrimaryColor(for: selectedRole))
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingSocialRoleSelection = false
                    }
                }
            }
        }
    }
}

/*
 * INTEGRATION STEPS:
 *
 * 1. Add the state variables listed at the top
 * 2. Add this modifier to the main VStack:
 *    .sheet(isPresented: $showingSocialRoleSelection) {
 *        SocialAuthRoleSheet(
 *            showingSocialRoleSelection: $showingSocialRoleSelection,
 *            selectedRole: $selectedRole,
 *            selectedAuthMethod: $selectedAuthMethod,
 *            isLoading: $isLoading,
 *            onContinue: {
 *                if selectedAuthMethod == "google" {
 *                    signInWithGoogle()
 *                } else if selectedAuthMethod == "apple" {
 *                    signInWithApple()
 *                }
 *            }
 *        )
 *        .environmentObject(authService)
 *    }
 *
 * 3. Add phone auth sheet:
 *    .sheet(isPresented: $showingPhoneAuth) {
 *        PhoneAuthFlowView(
 *            onComplete: { phoneUser in
 *                // Phone auth completed
 *            }
 *        )
 *        .environmentObject(authService)
 *    }
 */

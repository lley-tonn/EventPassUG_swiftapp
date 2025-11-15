//
//  OnboardingView.swift
//  EventPassUG
//
//  Onboarding and role selection screen
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: MockAuthService
    @State private var selectedRole: UserRole = .attendee
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingRoleSelection = false

    // Social Auth
    @State private var showingSocialRoleSelection = false
    @State private var selectedAuthMethod: String = "" // "google", "apple", "phone"
    @State private var showingPhoneAuth = false
    @State private var tempPhoneNumber = ""
    @State private var phoneVerificationId: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Logo and title
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 80))
                            .foregroundColor(RoleConfig.getPrimaryColor(for: selectedRole))

                        Text("EventPass UG")
                            .font(AppTypography.largeTitle)
                            .fontWeight(.bold)

                        Text("Discover and manage events across Uganda")
                            .font(AppTypography.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, AppSpacing.xxl)

                    if !showingRoleSelection {
                        // Sign up form
                        VStack(spacing: AppSpacing.md) {
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

                            // Social Auth Buttons
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

                            // Phone Auth Button
                            PhoneAuthButton(
                                onPhoneTap: {
                                    selectedAuthMethod = "phone"
                                    showingPhoneAuth = true
                                },
                                isLoading: isLoading
                            )
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    } else {
                        // Role selection
                        VStack(spacing: AppSpacing.md) {
                            Text("Choose your role")
                                .font(AppTypography.title2)
                                .fontWeight(.bold)

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
                                Button(action: signUp) {
                                    Text("Get Started")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(RoleConfig.getPrimaryColor(for: selectedRole))
                                        .cornerRadius(AppCornerRadius.medium)
                                }

                                Button(action: {
                                    showingRoleSelection = false
                                }) {
                                    Text("Back")
                                        .font(AppTypography.callout)
                                        .foregroundColor(RoleConfig.getPrimaryColor(for: selectedRole))
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSocialRoleSelection) {
            SocialAuthRoleSheet(
                showingSocialRoleSelection: $showingSocialRoleSelection,
                selectedRole: $selectedRole,
                selectedAuthMethod: $selectedAuthMethod,
                isLoading: $isLoading,
                onContinue: {
                    if selectedAuthMethod == "google" {
                        signInWithGoogle()
                    } else if selectedAuthMethod == "apple" {
                        signInWithApple()
                    }
                }
            )
            .environmentObject(authService)
        }
        .sheet(isPresented: $showingPhoneAuth) {
            PhoneAuthFlowView(
                onComplete: { phoneUser in
                    // Phone auth completed
                    showingPhoneAuth = false
                }
            )
            .environmentObject(authService)
        }
    }

    private func signUp() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await authService.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    role: selectedRole
                )
                HapticFeedback.success()
            } catch {
                errorMessage = error.localizedDescription
                HapticFeedback.error()
                isLoading = false
            }
        }
    }

    private func signInWithGoogle() {
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

    private func signInWithApple() {
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

struct RoleSelectionCard: View {
    let role: UserRole
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: role == .attendee ? "person.fill" : "briefcase.fill")
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : RoleConfig.getPrimaryColor(for: role))
                    .frame(width: 60, height: 60)
                    .background(
                        isSelected
                            ? RoleConfig.getPrimaryColor(for: role)
                            : RoleConfig.getPrimaryColor(for: role).opacity(0.1)
                    )
                    .cornerRadius(AppCornerRadius.medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)

                    Text(role == .attendee
                         ? "Discover and attend events"
                         : "Create and manage events"
                    )
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(RoleConfig.getPrimaryColor(for: role))
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(
                        isSelected ? RoleConfig.getPrimaryColor(for: role) : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// Social Auth Role Selection Sheet
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

// Phone Auth Flow View
struct PhoneAuthFlowView: View {
    @EnvironmentObject var authService: MockAuthService
    @Environment(\.dismiss) var dismiss
    @State private var phoneNumber = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedRole: UserRole = .attendee
    @State private var verificationId: String?
    @State private var showingVerification = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingRoleSelection = false

    let onComplete: (User) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    if !showingRoleSelection {
                        // Phone number entry
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "phone.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(RoleConfig.attendeePrimary)

                            Text("Sign in with Phone")
                                .font(AppTypography.title2)
                                .fontWeight(.bold)

                            Text("We'll send you a verification code")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            TextField("First Name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.givenName)
                                .autocapitalization(.words)

                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.familyName)
                                .autocapitalization(.words)

                            TextField("Phone Number", text: $phoneNumber)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)

                            if let error = errorMessage {
                                Text(error)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.red)
                            }

                            if isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                Button(action: {
                                    showingRoleSelection = true
                                }) {
                                    Text("Continue")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(RoleConfig.attendeePrimary)
                                        .cornerRadius(AppCornerRadius.medium)
                                }
                                .disabled(firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty)
                                .opacity((firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty) ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    } else {
                        // Role selection
                        VStack(spacing: AppSpacing.md) {
                            Text("Choose your role")
                                .font(AppTypography.title2)
                                .fontWeight(.bold)

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
                                Button(action: sendCode) {
                                    Text("Send Code")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(RoleConfig.getPrimaryColor(for: selectedRole))
                                        .cornerRadius(AppCornerRadius.medium)
                                }

                                Button(action: {
                                    showingRoleSelection = false
                                }) {
                                    Text("Back")
                                        .font(AppTypography.callout)
                                        .foregroundColor(RoleConfig.getPrimaryColor(for: selectedRole))
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }
                }
                .padding(.top, AppSpacing.xl)
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
        .sheet(isPresented: $showingVerification) {
            if let verificationId = verificationId {
                PhoneVerificationView(phoneNumber: phoneNumber) {
                    // Verification completed
                    showingVerification = false
                    dismiss()
                }
                .environmentObject(authService)
            }
        }
    }

    private func sendCode() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let verId = try await authService.signInWithPhone(
                    phoneNumber: phoneNumber,
                    firstName: firstName,
                    lastName: lastName,
                    role: selectedRole
                )

                await MainActor.run {
                    verificationId = verId
                    showingVerification = true
                    isLoading = false
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    HapticFeedback.error()
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(MockAuthService())
}

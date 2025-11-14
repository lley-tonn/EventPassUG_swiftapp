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

#Preview {
    OnboardingView()
        .environmentObject(MockAuthService())
}

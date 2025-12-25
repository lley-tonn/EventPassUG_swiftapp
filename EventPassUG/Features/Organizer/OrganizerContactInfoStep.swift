//
//  OrganizerContactInfoStep.swift
//  EventPassUG
//
//  Step 3: Public contact information for organizer onboarding
//

import SwiftUI

struct OrganizerContactInfoStep: View {
    @EnvironmentObject var authService: MockAuthRepository
    @Binding var profile: OrganizerProfile
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var useAccountEmail = true
    @State private var useAccountPhone = true

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(RoleConfig.organizerPrimary)

                    Text("Contact Information")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text("This information will be visible to attendees on your event pages.")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xl)

                // Required Contact Info
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Required Information")
                        .font(AppTypography.headline)

                    // Public Email
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Public Email")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        if let accountEmail = authService.currentUser?.email {
                            Toggle("Use my account email", isOn: $useAccountEmail)
                                .tint(RoleConfig.organizerPrimary)
                                .onChange(of: useAccountEmail) { newValue in
                                    if newValue {
                                        profile.publicEmail = accountEmail
                                    }
                                }
                        }

                        if !useAccountEmail || authService.currentUser?.email == nil {
                            TextField("contact@yourorganization.com", text: $profile.publicEmail)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        } else {
                            Text(profile.publicEmail)
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)
                                .padding(.vertical, AppSpacing.xs)
                        }
                    }

                    // Public Phone
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Public Phone Number")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        if let accountPhone = authService.currentUser?.phoneNumber {
                            Toggle("Use my account phone", isOn: $useAccountPhone)
                                .tint(RoleConfig.organizerPrimary)
                                .onChange(of: useAccountPhone) { newValue in
                                    if newValue {
                                        profile.publicPhone = accountPhone
                                    }
                                }
                        }

                        if !useAccountPhone || authService.currentUser?.phoneNumber == nil {
                            TextField("+256 700 000 000", text: $profile.publicPhone)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                        } else {
                            Text(profile.publicPhone)
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)
                                .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
                .padding(.horizontal, AppSpacing.md)

                // Optional Brand Info
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Brand Information (Optional)")
                        .font(AppTypography.headline)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Brand/Organization Name")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        TextField("Your Brand Name", text: Binding(
                            get: { profile.brandName ?? "" },
                            set: { profile.brandName = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Website")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        TextField("https://yourwebsite.com", text: Binding(
                            get: { profile.website ?? "" },
                            set: { profile.website = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Instagram Handle")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        TextField("@yourhandle", text: Binding(
                            get: { profile.instagramHandle ?? "" },
                            set: { profile.instagramHandle = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Twitter/X Handle")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        TextField("@yourhandle", text: Binding(
                            get: { profile.twitterHandle ?? "" },
                            set: { profile.twitterHandle = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Facebook Page")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        TextField("facebook.com/yourpage", text: Binding(
                            get: { profile.facebookPage ?? "" },
                            set: { profile.facebookPage = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: AppSpacing.xl)

                // Navigation buttons
                VStack(spacing: AppSpacing.sm) {
                    Button(action: onNext) {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? RoleConfig.organizerPrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .disabled(!isFormValid)

                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                if !isFormValid {
                    Text("Please provide public email and phone number")
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .onAppear {
            // Pre-fill with account info if available
            if let email = authService.currentUser?.email, profile.publicEmail.isEmpty {
                profile.publicEmail = email
            }
            if let phone = authService.currentUser?.phoneNumber, profile.publicPhone.isEmpty {
                profile.publicPhone = phone
            }
        }
    }

    private var isFormValid: Bool {
        !profile.publicEmail.isEmpty &&
        !profile.publicPhone.isEmpty &&
        profile.publicEmail.contains("@") &&
        profile.publicPhone.count >= 10
    }
}

#Preview {
    OrganizerContactInfoStep(
        profile: .constant(OrganizerProfile()),
        onNext: {},
        onBack: {}
    )
    .environmentObject(MockAuthRepository())
}

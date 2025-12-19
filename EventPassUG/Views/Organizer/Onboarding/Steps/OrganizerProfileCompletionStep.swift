//
//  OrganizerProfileCompletionStep.swift
//  EventPassUG
//
//  Step 1: Profile completion check for organizer onboarding
//

import SwiftUI

struct OrganizerProfileCompletionStep: View {
    @EnvironmentObject var authService: MockAuthService
    let onNext: () -> Void

    @State private var showEditProfile = false
    @State private var showEmailVerification = false
    @State private var showPhoneVerification = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 60))
                        .foregroundColor(RoleConfig.organizerPrimary)

                    Text("Complete Your Profile")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text("Before becoming an organizer, we need to verify your profile information.")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xl)

                // Requirements checklist
                VStack(spacing: AppSpacing.md) {
                    RequirementRow(
                        title: "Full Legal Name",
                        subtitle: currentUserFullName,
                        isComplete: hasFullName,
                        action: { showEditProfile = true }
                    )

                    RequirementRow(
                        title: "Verified Email Address",
                        subtitle: currentUserEmail,
                        isComplete: hasVerifiedEmail,
                        action: {
                            if authService.currentUser?.email == nil {
                                showEditProfile = true
                            } else {
                                showEmailVerification = true
                            }
                        }
                    )

                    RequirementRow(
                        title: "Verified Phone Number",
                        subtitle: currentUserPhone,
                        isComplete: hasVerifiedPhone,
                        action: {
                            if authService.currentUser?.phoneNumber == nil {
                                showEditProfile = true
                            } else {
                                showPhoneVerification = true
                            }
                        }
                    )

                    RequirementRow(
                        title: "Profile Photo",
                        subtitle: hasProfilePhoto ? "Added" : "Optional",
                        isComplete: hasProfilePhoto,
                        isOptional: true,
                        action: { showEditProfile = true }
                    )
                }
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: AppSpacing.xl)

                // Continue button
                Button(action: onNext) {
                    HStack {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? RoleConfig.organizerPrimary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .disabled(!canContinue)
                .padding(.horizontal, AppSpacing.md)

                if !canContinue {
                    Text("Please complete all required fields to continue")
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationView {
                EditProfileView()
                    .environmentObject(authService)
            }
        }
        .sheet(isPresented: $showEmailVerification) {
            NavigationView {
                EmailVerificationView()
                    .environmentObject(authService)
            }
        }
        .sheet(isPresented: $showPhoneVerification) {
            NavigationView {
                OrganizerPhoneVerificationView()
                    .environmentObject(authService)
            }
        }
    }

    private var canContinue: Bool {
        hasFullName && hasVerifiedEmail && hasVerifiedPhone
    }

    private var hasFullName: Bool {
        guard let user = authService.currentUser else { return false }
        return !user.firstName.isEmpty && !user.lastName.isEmpty && user.firstName.count >= 2 && user.lastName.count >= 2
    }

    private var hasVerifiedEmail: Bool {
        guard let user = authService.currentUser else { return false }
        return user.email != nil && user.isEmailVerified
    }

    private var hasVerifiedPhone: Bool {
        guard let user = authService.currentUser else { return false }
        return user.phoneNumber != nil && user.isPhoneVerified
    }

    private var hasProfilePhoto: Bool {
        authService.currentUser?.profileImageURL != nil
    }

    private var currentUserFullName: String {
        guard let user = authService.currentUser else { return "Not set" }
        if user.firstName.isEmpty && user.lastName.isEmpty {
            return "Not set"
        }
        return user.fullName
    }

    private var currentUserEmail: String {
        guard let user = authService.currentUser else { return "Not set" }
        if let email = user.email {
            return user.isEmailVerified ? "\(email) (Verified)" : "\(email) (Unverified)"
        }
        return "Not set"
    }

    private var currentUserPhone: String {
        guard let user = authService.currentUser else { return "Not set" }
        if let phone = user.phoneNumber {
            return user.isPhoneVerified ? "\(phone) (Verified)" : "\(phone) (Unverified)"
        }
        return "Not set"
    }
}

struct RequirementRow: View {
    let title: String
    let subtitle: String
    let isComplete: Bool
    var isOptional: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : (isOptional ? "circle.dashed" : "circle"))
                    .font(.system(size: 24))
                    .foregroundColor(isComplete ? .green : (isOptional ? .orange : .gray))

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        if isOptional {
                            Text("(Optional)")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !isComplete {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// Simple email verification view
struct EmailVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @State private var isVerifying = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Verify Your Email")
                .font(AppTypography.title2)
                .fontWeight(.bold)

            if let email = authService.currentUser?.email {
                Text("We'll send a verification link to:\n\(email)")
                    .font(AppTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Button(action: verifyEmail) {
                HStack {
                    if isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Verification Email")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoleConfig.organizerPrimary)
                .foregroundColor(.white)
                .cornerRadius(AppCornerRadius.medium)
            }
            .disabled(isVerifying)

            Spacer()
        }
        .padding()
        .navigationTitle("Email Verification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func verifyEmail() {
        isVerifying = true
        Task {
            try? await authService.sendEmailVerification()
            await MainActor.run {
                isVerifying = false
                HapticFeedback.success()
                dismiss()
            }
        }
    }
}

// Simple phone verification view for organizer onboarding
struct OrganizerPhoneVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @State private var verificationCode = ""
    @State private var verificationId = ""
    @State private var codeSent = false
    @State private var isVerifying = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "phone.badge.checkmark.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Verify Your Phone")
                .font(AppTypography.title2)
                .fontWeight(.bold)

            if let phone = authService.currentUser?.phoneNumber {
                Text("We'll send a verification code to:\n\(phone)")
                    .font(AppTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            if codeSent {
                TextField("Enter 6-digit code", text: $verificationCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)

                Button(action: verifyCode) {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Verify Code")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(verificationCode.count == 6 ? RoleConfig.organizerPrimary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .disabled(verificationCode.count != 6 || isVerifying)
            } else {
                Button(action: sendCode) {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Verification Code")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoleConfig.organizerPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .disabled(isVerifying)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Phone Verification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func sendCode() {
        guard let phone = authService.currentUser?.phoneNumber else { return }
        isVerifying = true

        Task {
            let id = try? await authService.sendPhoneVerification(phoneNumber: phone)
            await MainActor.run {
                verificationId = id ?? ""
                codeSent = true
                isVerifying = false
            }
        }
    }

    private func verifyCode() {
        isVerifying = true
        Task {
            try? await authService.verifyPhone(verificationId: verificationId, code: verificationCode)
            await MainActor.run {
                isVerifying = false
                HapticFeedback.success()
                dismiss()
            }
        }
    }
}

#Preview {
    OrganizerProfileCompletionStep(onNext: {})
        .environmentObject(MockAuthService())
}

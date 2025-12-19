//
//  PhoneVerificationView.swift
//  EventPassUG
//
//  Phone number verification with SMS OTP
//

import SwiftUI

struct PhoneVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService

    let phoneNumber: String
    let onVerified: (() -> Void)?

    @State private var verificationId: String = ""
    @State private var otpCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var codeSent = false

    init(phoneNumber: String, onVerified: (() -> Void)? = nil) {
        self.phoneNumber = phoneNumber
        self.onVerified = onVerified
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 60))
                            .foregroundColor(RoleConfig.attendeePrimary)
                            .padding(.bottom, AppSpacing.sm)

                        Text("Verify Phone Number")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)

                        Text("We'll send a verification code to")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)

                        Text(phoneNumber)
                            .font(AppTypography.headline)
                            .foregroundColor(RoleConfig.attendeePrimary)
                    }
                    .padding(.top, AppSpacing.xl)

                    if !codeSent {
                        // Send Code Button
                        VStack(spacing: AppSpacing.md) {
                            Text("You'll receive a 6-digit code via SMS")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button(action: sendCode) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Send Verification Code")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoleConfig.attendeePrimary)
                                .foregroundColor(.white)
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    } else {
                        // OTP Input
                        VStack(spacing: AppSpacing.md) {
                            Text("Enter the 6-digit code")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)

                            // OTP Field
                            TextField("000000", text: $otpCode)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                                .onChange(of: otpCode) { newValue in
                                    // Limit to 6 digits
                                    if newValue.count > 6 {
                                        otpCode = String(newValue.prefix(6))
                                    }
                                }

                            if let error = errorMessage {
                                Text(error)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.red)
                            }

                            // Verify Button
                            Button(action: verifyCode) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Verify Code")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(otpCode.count == 6 ? RoleConfig.attendeePrimary : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .disabled(otpCode.count != 6 || isLoading)

                            // Resend Code
                            Button(action: sendCode) {
                                Text("Resend Code")
                                    .font(AppTypography.callout)
                                    .foregroundColor(RoleConfig.attendeePrimary)
                            }
                            .disabled(isLoading)
                            .padding(.top, AppSpacing.sm)
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }

                    Spacer()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Phone Verified", isPresented: $showSuccess) {
            Button("Done") {
                onVerified?()
                dismiss()
            }
        } message: {
            Text("Your phone number has been verified successfully!")
        }
    }

    private func sendCode() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let verId = try await authService.sendPhoneVerification(phoneNumber: phoneNumber)

                await MainActor.run {
                    verificationId = verId
                    codeSent = true
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

    private func verifyCode() {
        guard otpCode.count == 6 else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.verifyPhone(verificationId: verificationId, code: otpCode)

                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Invalid code. Please try again."
                    otpCode = ""
                    isLoading = false
                    HapticFeedback.error()
                }
            }
        }
    }
}

#Preview {
    PhoneVerificationView(phoneNumber: "+256700123456")
        .environmentObject(MockAuthService())
}

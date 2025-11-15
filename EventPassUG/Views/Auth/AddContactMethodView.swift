//
//  AddContactMethodView.swift
//  EventPassUG
//
//  Add email or phone number to existing account
//

import SwiftUI

enum ContactMethod {
    case email
    case phone
}

struct AddContactMethodView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService

    let method: ContactMethod

    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPhoneVerification = false
    @State private var verificationId: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: method == .email ? "envelope.fill" : "phone.fill")
                            .font(.system(size: 60))
                            .foregroundColor(RoleConfig.attendeePrimary)
                            .padding(.bottom, AppSpacing.sm)

                        Text("Add \(method == .email ? "Email" : "Phone Number")")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)

                        Text(method == .email
                             ? "Add an email address to your account for additional login options"
                             : "Add a phone number to your account for SMS verification and login"
                        )
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }
                    .padding(.top, AppSpacing.xl)

                    // Form
                    VStack(spacing: AppSpacing.md) {
                        if method == .email {
                            TextField("Email Address", text: $email)
                                .textFieldStyle(.plain)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)

                            SecureField("Create Password", text: $password)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)

                            Text("You'll be able to sign in with this email and password")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        } else {
                            TextField("+256 700 123 456", text: $phoneNumber)
                                .textFieldStyle(.plain)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)

                            Text("A verification code will be sent to this number")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(.red)
                        }

                        Button(action: addContactMethod) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Add \(method == .email ? "Email" : "Phone Number")")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? RoleConfig.attendeePrimary : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(AppCornerRadius.medium)
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal, AppSpacing.xl)

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
        .sheet(isPresented: $showPhoneVerification) {
            if let verId = verificationId {
                PhoneVerificationView(phoneNumber: phoneNumber) {
                    // On verified
                    Task {
                        guard var user = authService.currentUser else { return }
                        user.phoneNumber = phoneNumber
                        user.isPhoneVerified = true
                        if !user.authProviders.contains("phone") {
                            user.authProviders.append("phone")
                        }
                        try? await authService.updateProfile(user)
                        dismiss()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        if method == .email {
            return !email.isEmpty && !password.isEmpty && password.count >= 6
        } else {
            return !phoneNumber.isEmpty && phoneNumber.count >= 10
        }
    }

    private func addContactMethod() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                if method == .email {
                    try await authService.addEmail(email: email, password: password)

                    await MainActor.run {
                        isLoading = false
                        HapticFeedback.success()
                        dismiss()
                    }
                } else {
                    let verId = try await authService.addPhoneNumber(phoneNumber: phoneNumber)

                    await MainActor.run {
                        verificationId = verId
                        isLoading = false
                        showPhoneVerification = true
                        HapticFeedback.success()
                    }
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
    AddContactMethodView(method: .email)
        .environmentObject(MockAuthService())
}

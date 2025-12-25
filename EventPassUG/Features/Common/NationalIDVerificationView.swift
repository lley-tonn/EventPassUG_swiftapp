//
//  NationalIDVerificationView.swift
//  EventPassUG
//
//  National ID verification screen for organizers
//

import SwiftUI
import PhotosUI

struct NationalIDVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthRepository

    @State private var documentType: VerificationDocumentType = .nationalID
    @State private var fullName: String = ""
    @State private var nationalIDNumber: String = ""
    @State private var frontImageItem: PhotosPickerItem?
    @State private var backImageItem: PhotosPickerItem?
    @State private var frontImageData: Data?
    @State private var backImageData: Data?
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(RoleConfig.organizerPrimary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, AppSpacing.sm)

                        Text("Verify Your Identity")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("To access organizer features, we need to verify your identity. This helps ensure the safety and security of our event community.")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, AppSpacing.md)

                    Divider()
                        .padding(.vertical, AppSpacing.sm)

                    // Form
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Document Type Selection
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Document Type")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Picker("Document Type", selection: $documentType) {
                                Text("National ID").tag(VerificationDocumentType.nationalID)
                                Text("Passport").tag(VerificationDocumentType.passport)
                            }
                            .pickerStyle(.segmented)
                        }

                        // Full Name
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Full Name")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            TextField("As shown on your \(documentType.displayName)", text: $fullName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                                .autocapitalization(.words)
                        }

                        // Document Number
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(documentType == .nationalID ? "National ID Number" : "Passport Number")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            TextField(documentType == .nationalID ? "e.g., CM12345678901234" : "e.g., A12345678", text: $nationalIDNumber)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                                .keyboardType(.asciiCapable)
                                .autocapitalization(.allCharacters)
                        }

                        // Front Image Upload
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(documentType == .nationalID ? "National ID (Front)" : "Passport Photo Page")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            PhotosPicker(selection: $frontImageItem, matching: .images) {
                                HStack {
                                    Image(systemName: frontImageData != nil ? "checkmark.circle.fill" : "camera.fill")
                                        .foregroundColor(frontImageData != nil ? .green : RoleConfig.organizerPrimary)
                                    Text(frontImageData != nil ? "Image Selected" : documentType == .nationalID ? "Upload Front of ID" : "Upload Photo Page")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .onChange(of: frontImageItem) { newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                        frontImageData = data
                                    }
                                }
                            }

                            if let frontImageData = frontImageData,
                               let uiImage = UIImage(data: frontImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(AppCornerRadius.medium)
                                    .padding(.top, AppSpacing.xs)
                            }
                        }

                        // Back Image Upload (only for National ID)
                        if documentType == .nationalID {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("National ID (Back)")
                                    .font(AppTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                PhotosPicker(selection: $backImageItem, matching: .images) {
                                    HStack {
                                        Image(systemName: backImageData != nil ? "checkmark.circle.fill" : "camera.fill")
                                            .foregroundColor(backImageData != nil ? .green : RoleConfig.organizerPrimary)
                                        Text(backImageData != nil ? "Back Image Selected" : "Upload Back of ID")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(AppCornerRadius.medium)
                                }
                                .onChange(of: backImageItem) { newValue in
                                    Task {
                                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                            backImageData = data
                                        }
                                    }
                                }

                                if let backImageData = backImageData,
                                   let uiImage = UIImage(data: backImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(AppCornerRadius.medium)
                                        .padding(.top, AppSpacing.xs)
                                }
                            }
                        }

                        // Privacy Notice
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(RoleConfig.organizerPrimary)
                                .font(.caption)
                            Text("Your information is encrypted and securely stored. We only use it to verify your identity for organizer activities.")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
                        .cornerRadius(AppCornerRadius.medium)
                    }

                    // Submit Button
                    Button(action: submitVerification) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Submit for Verification")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? RoleConfig.organizerPrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.top, AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
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
        .alert("Verification Submitted", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your \(documentType.displayName) has been submitted for verification. You'll be notified once approved.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Pre-fill with user's name
            if let user = authService.currentUser {
                fullName = user.fullName
            }
        }
    }

    private var isFormValid: Bool {
        let baseValidation = !fullName.isEmpty &&
            !nationalIDNumber.isEmpty &&
            nationalIDNumber.count >= 6 &&
            frontImageData != nil

        if documentType == .nationalID {
            return baseValidation && backImageData != nil
        } else {
            // Passport only requires front (photo page)
            return baseValidation
        }
    }

    private func submitVerification() {
        guard isFormValid else { return }

        isSubmitting = true

        Task {
            do {
                try await authService.submitVerification(
                    documentType: documentType,
                    documentNumber: nationalIDNumber,
                    frontImageData: frontImageData,
                    backImageData: documentType == .nationalID ? backImageData : nil
                )

                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

#Preview {
    NationalIDVerificationView()
        .environmentObject(MockAuthRepository())
}

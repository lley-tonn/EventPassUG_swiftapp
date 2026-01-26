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

    // New states for capture method selection
    @State private var showingFrontCaptureOptions = false
    @State private var showingBackCaptureOptions = false
    @State private var showingFrontCamera = false
    @State private var showingBackCamera = false
    @State private var showingFrontPhotoPicker = false
    @State private var showingBackPhotoPicker = false

    // MARK: - View Components

    private var headerSection: some View {
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
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            documentTypeSection
            fullNameSection
            documentNumberSection
            frontImageSection
            if documentType == .nationalID {
                backImageSection
            }
            privacyNoticeSection
        }
    }

    private var documentTypeSection: some View {
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
    }

    private var fullNameSection: some View {
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
    }

    private var documentNumberSection: some View {
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
    }

    private var frontImageSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(documentType == .nationalID ? "National ID (Front)" : "Passport Photo Page")
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Button(action: {
                showingFrontCaptureOptions = true
            }) {
                HStack {
                    Image(systemName: frontImageData != nil ? "checkmark.circle.fill" : "camera.fill")
                        .foregroundColor(frontImageData != nil ? .green : RoleConfig.organizerPrimary)
                    Text(frontImageData != nil ? "Image Selected" : documentType == .nationalID ? "Capture Front of ID" : "Capture Photo Page")
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

            if let frontImageData = frontImageData,
               let uiImage = UIImage(data: frontImageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.top, AppSpacing.xs)

                    Button(action: {
                        self.frontImageData = nil
                        HapticFeedback.light()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                    }
                    .padding([.top, .trailing], AppSpacing.sm)
                }
            }
        }
    }

    private var backImageSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("National ID (Back)")
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Button(action: {
                showingBackCaptureOptions = true
            }) {
                HStack {
                    Image(systemName: backImageData != nil ? "checkmark.circle.fill" : "camera.fill")
                        .foregroundColor(backImageData != nil ? .green : RoleConfig.organizerPrimary)
                    Text(backImageData != nil ? "Back Image Selected" : "Capture Back of ID")
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

            if let backImageData = backImageData,
               let uiImage = UIImage(data: backImageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.top, AppSpacing.xs)

                    Button(action: {
                        self.backImageData = nil
                        HapticFeedback.light()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                    }
                    .padding([.top, .trailing], AppSpacing.sm)
                }
            }
        }
    }

    private var privacyNoticeSection: some View {
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

    private var submitButton: some View {
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerSection

                    Divider()
                        .padding(.vertical, AppSpacing.sm)

                    formSection

                    submitButton
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
        .confirmationDialog("Capture Front Image", isPresented: $showingFrontCaptureOptions) {
            Button("Take Photo") {
                showingFrontCamera = true
            }
            Button("Choose from Library") {
                showingFrontPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Capture Back Image", isPresented: $showingBackCaptureOptions) {
            Button("Take Photo") {
                showingBackCamera = true
            }
            Button("Choose from Library") {
                showingBackPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showingFrontCamera) {
            IDCameraView(
                documentName: documentType == .nationalID ? "National ID (Front)" : "Passport Photo Page",
                onCapture: { image in
                    frontImageData = image.jpegData(compressionQuality: 0.8)
                    showingFrontCamera = false
                },
                onCancel: {
                    showingFrontCamera = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingBackCamera) {
            IDCameraView(
                documentName: "National ID (Back)",
                onCapture: { image in
                    backImageData = image.jpegData(compressionQuality: 0.8)
                    showingBackCamera = false
                },
                onCancel: {
                    showingBackCamera = false
                }
            )
        }
        .photosPicker(isPresented: $showingFrontPhotoPicker, selection: $frontImageItem, matching: .images)
        .photosPicker(isPresented: $showingBackPhotoPicker, selection: $backImageItem, matching: .images)
        .onChange(of: frontImageItem) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    frontImageData = data
                }
            }
        }
        .onChange(of: backImageItem) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    backImageData = data
                }
            }
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

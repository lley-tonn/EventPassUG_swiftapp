//
//  SubmitTicketView.swift
//  EventPassUG
//
//  Submit support ticket form
//

import SwiftUI
import PhotosUI
import UIKit

struct SubmitTicketView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService

    @State private var name: String = ""
    @State private var contactInfo: String = ""
    @State private var selectedCategory: SupportCategory = .other
    @State private var issueDescription: String = ""
    @State private var attachmentItem: PhotosPickerItem?
    @State private var attachmentData: Data?
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var ticketNumber: String = ""

    var body: some View {
        Form {
            // Contact Info (Prefilled)
            Section {
                TextField("Full Name", text: $name)
                    .textContentType(.name)

                TextField("Email or Phone", text: $contactInfo)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
            } header: {
                Text("Contact Information")
            }

            // Issue Category
            Section {
                Picker("Issue Category", selection: $selectedCategory) {
                    ForEach(SupportCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.iconName)
                            Text(category.rawValue)
                        }
                        .tag(category)
                    }
                }
            } header: {
                Text("What's the issue?")
            }

            // Description
            Section {
                TextEditor(text: $issueDescription)
                    .frame(minHeight: 150)
            } header: {
                Text("Describe Your Issue")
            } footer: {
                Text("Please provide as much detail as possible to help us resolve your issue quickly.")
            }

            // Screenshot Attachment
            Section {
                PhotosPicker(selection: $attachmentItem, matching: .images) {
                    HStack {
                        Image(systemName: attachmentData != nil ? "checkmark.circle.fill" : "camera.fill")
                            .foregroundColor(attachmentData != nil ? .green : RoleConfig.attendeePrimary)

                        Text(attachmentData != nil ? "Screenshot Attached" : "Attach Screenshot")
                            .foregroundColor(.primary)

                        Spacer()

                        if attachmentData != nil {
                            Button("Remove") {
                                attachmentData = nil
                                attachmentItem = nil
                            }
                            .font(AppTypography.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
                .onChange(of: attachmentItem) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            attachmentData = data
                        }
                    }
                }

                if let data = attachmentData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(AppCornerRadius.small)
                }
            } header: {
                Text("Attachment (Optional)")
            }

            // App Diagnostics (Auto-included)
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("The following will be included:")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    DiagnosticInfoRow(label: "App Version", value: getAppVersion())
                    DiagnosticInfoRow(label: "Device", value: getDeviceModel())
                    DiagnosticInfoRow(label: "iOS", value: getiOSVersion())
                    DiagnosticInfoRow(label: "User ID", value: getUserID())
                }
            } header: {
                Label("App Diagnostics", systemImage: "info.circle")
            }

            // Submit Button
            Section {
                Button(action: submitTicket) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit Ticket")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!isFormValid || isSubmitting)
                .listRowBackground(
                    (isFormValid && !isSubmitting) ? RoleConfig.attendeePrimary : Color.gray
                )
                .foregroundColor(.white)
            }
        }
        .navigationTitle("Submit Ticket")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            prefillUserInfo()
        }
        .alert("Ticket Submitted", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your support ticket #\(ticketNumber) has been created. We'll respond within 24-48 hours.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !contactInfo.isEmpty && !issueDescription.isEmpty && issueDescription.count >= 20
    }

    private func prefillUserInfo() {
        if let user = authService.currentUser {
            name = user.fullName
            contactInfo = user.email ?? user.phoneNumber ?? ""
        }
    }

    private func submitTicket() {
        isSubmitting = true

        let _ = SupportTicket(
            name: name,
            contactInfo: contactInfo,
            category: selectedCategory,
            description: issueDescription,
            attachmentURL: attachmentData != nil ? "mock://attachment-\(UUID().uuidString)" : nil,
            appVersion: getAppVersion(),
            deviceModel: getDeviceModel(),
            iosVersion: getiOSVersion(),
            userId: authService.currentUser?.id.uuidString ?? "unknown"
        )

        // Mock submission
        Task {
            try await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                isSubmitting = false
                ticketNumber = String(format: "TKT-%06d", Int.random(in: 100000...999999))
                showSuccess = true
                HapticFeedback.success()
            }
        }
    }

    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func getDeviceModel() -> String {
        UIDevice.current.model
    }

    private func getiOSVersion() -> String {
        UIDevice.current.systemVersion
    }

    private func getUserID() -> String {
        authService.currentUser?.id.uuidString ?? "Unknown"
    }
}

struct DiagnosticInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.caption)
            Spacer()
            Text(value)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        SubmitTicketView()
            .environmentObject(MockAuthService())
    }
}

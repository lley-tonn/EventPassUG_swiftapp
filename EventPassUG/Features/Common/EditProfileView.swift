//
//  EditProfileView.swift
//  EventPassUG
//
//  Edit profile with email/phone update and verification flows
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthRepository

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var profileImageItem: PhotosPickerItem?
    @State private var profileImageData: Data?

    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // Email update flow
    @State private var showingEmailUpdate = false
    @State private var showingPhoneUpdate = false
    @State private var showingAddEmail = false
    @State private var showingAddPhone = false

    var body: some View {
        let currentRole = authService.currentUser?.role ?? .attendee

        return Form {
            // Profile Photo Section
            Section {
                VStack(spacing: AppSpacing.md) {
                    // Current profile photo or placeholder
                    if let imageData = profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(RoleConfig.getPrimaryColor(for: currentRole), lineWidth: 3)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(RoleConfig.getPrimaryColor(for: currentRole))
                    }

                    PhotosPicker(selection: $profileImageItem, matching: .images) {
                        Text("Change Photo")
                            .font(AppTypography.subheadline)
                            .foregroundColor(RoleConfig.getPrimaryColor(for: currentRole))
                    }
                    .onChange(of: profileImageItem) { newValue in
                        Task { @MainActor in
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                profileImageData = data
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
            } header: {
                Text("Profile Photo")
            }

            // Personal Info Section
            Section {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)

                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)
            } header: {
                Text("Personal Information")
            }

            // Email Section
            Section {
                if let email = authService.currentUser?.email {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(email)
                                .font(AppTypography.body)

                            if authService.currentUser?.isEmailVerified == true {
                                Label("Verified", systemImage: "checkmark.circle.fill")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("Not Verified", systemImage: "exclamationmark.circle.fill")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.orange)
                            }

                            // Show pending email if exists
                            if let pending = authService.currentUser?.pendingEmail {
                                Text("Pending: \(pending)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button("Change") {
                            showingEmailUpdate = true
                        }
                        .font(AppTypography.subheadline)
                        .foregroundColor(RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee))
                    }
                } else {
                    Button(action: {
                        showingAddEmail = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee))
                            Text("Add Email Address")
                                .foregroundColor(.primary)
                        }
                    }
                }
            } header: {
                Text("Email Address")
            } footer: {
                if authService.currentUser?.email != nil {
                    Text("Changing your email requires verification. Your current email remains active until the new one is verified.")
                }
            }

            // Phone Section
            Section {
                if let phone = authService.currentUser?.phoneNumber {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phone)
                                .font(AppTypography.body)

                            if authService.currentUser?.isPhoneVerified == true {
                                Label("Verified", systemImage: "checkmark.circle.fill")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("Not Verified", systemImage: "exclamationmark.circle.fill")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.orange)
                            }

                            // Show pending phone if exists
                            if let pending = authService.currentUser?.pendingPhoneNumber {
                                Text("Pending: \(pending)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button("Change") {
                            showingPhoneUpdate = true
                        }
                        .font(AppTypography.subheadline)
                        .foregroundColor(RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee))
                    }
                } else {
                    Button(action: {
                        showingAddPhone = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee))
                            Text("Add Phone Number")
                                .foregroundColor(.primary)
                        }
                    }
                }
            } header: {
                Text("Phone Number")
            } footer: {
                if authService.currentUser?.phoneNumber != nil {
                    Text("Changing your phone number requires SMS verification.")
                }
            }

            // Primary Contact Method
            if authService.currentUser?.email != nil && authService.currentUser?.phoneNumber != nil {
                Section {
                    Picker("Primary Contact", selection: Binding(
                        get: { authService.currentUser?.primaryContactMethod ?? .email },
                        set: { newValue in
                            Task {
                                await updatePrimaryContactMethod(newValue)
                            }
                        }
                    )) {
                        Text("Email").tag(ContactMethod.email)
                        Text("Phone").tag(ContactMethod.phone)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Primary Contact Method")
                } footer: {
                    Text("This determines how you receive ticket confirmations and important updates.")
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving || !hasChanges)
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
        .alert("Profile Updated", isPresented: $showingSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been updated successfully.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingEmailUpdate) {
            UpdateEmailView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingPhoneUpdate) {
            UpdatePhoneView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingAddEmail) {
            AddContactMethodView(method: .email)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingAddPhone) {
            AddContactMethodView(method: .phone)
                .environmentObject(authService)
        }
    }

    private var hasChanges: Bool {
        guard let user = authService.currentUser else { return false }
        return firstName != user.firstName ||
               lastName != user.lastName ||
               profileImageData != nil
    }

    private func loadCurrentProfile() {
        guard let user = authService.currentUser else { return }
        firstName = user.firstName
        lastName = user.lastName
    }

    private func saveProfile() {
        guard var user = authService.currentUser else { return }

        isSaving = true

        user.firstName = firstName
        user.lastName = lastName

        // Handle profile image
        if profileImageData != nil {
            // In production, upload to storage and get URL
            // For now, we'll store a mock URL
            user.profileImageURL = "mock://profile-image-\(user.id.uuidString)"
            // TODO: Store actual image data in local storage or upload to server
        }

        Task {
            do {
                try await authService.updateProfile(user)

                await MainActor.run {
                    isSaving = false
                    showingSaveSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingError = true
                    HapticFeedback.error()
                }
            }
        }
    }

    private func updatePrimaryContactMethod(_ method: ContactMethod) async {
        guard var user = authService.currentUser else { return }
        user.primaryContactMethod = method

        do {
            try await authService.updateProfile(user)
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            HapticFeedback.error()
        }
    }
}

// MARK: - Update Email View

struct UpdateEmailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthRepository

    @State private var newEmail: String = ""
    @State private var password: String = ""
    @State private var isUpdating = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let currentEmail = authService.currentUser?.email {
                        HStack {
                            Text("Current Email")
                            Spacer()
                            Text(currentEmail)
                                .foregroundColor(.secondary)
                        }
                    }

                    TextField("New Email Address", text: $newEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Confirm Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Update Email")
                } footer: {
                    Text("A verification link will be sent to your new email. Your current email remains active until verification is complete.")
                }
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        updateEmail()
                    }
                    .disabled(newEmail.isEmpty || password.isEmpty || isUpdating)
                }
            }
        }
        .alert("Verification Sent", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("A verification link has been sent to \(newEmail). Please check your inbox.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func updateEmail() {
        isUpdating = true

        Task {
            do {
                try await authService.updateEmail(newEmail: newEmail, password: password)

                await MainActor.run {
                    isUpdating = false
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Update Phone View

struct UpdatePhoneView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthRepository

    @State private var newPhoneNumber: String = ""
    @State private var verificationId: String = ""
    @State private var verificationCode: String = ""
    @State private var codeSent = false
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let currentPhone = authService.currentUser?.phoneNumber {
                        HStack {
                            Text("Current Phone")
                            Spacer()
                            Text(currentPhone)
                                .foregroundColor(.secondary)
                        }
                    }

                    TextField("New Phone Number", text: $newPhoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)

                    if codeSent {
                        TextField("Verification Code", text: $verificationCode)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("Update Phone Number")
                } footer: {
                    if !codeSent {
                        Text("Enter your new phone number. We'll send a verification code via SMS.")
                    } else {
                        Text("Enter the 6-digit code sent to your new phone number.")
                    }
                }
            }
            .navigationTitle("Change Phone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !codeSent {
                        Button("Send Code") {
                            sendVerificationCode()
                        }
                        .disabled(newPhoneNumber.isEmpty || isProcessing)
                    } else {
                        Button("Verify") {
                            verifyCode()
                        }
                        .disabled(verificationCode.count < 6 || isProcessing)
                    }
                }
            }
        }
        .alert("Phone Updated", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your phone number has been updated successfully.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func sendVerificationCode() {
        isProcessing = true

        Task {
            do {
                let id = try await authService.updatePhoneNumber(newPhoneNumber: newPhoneNumber)

                await MainActor.run {
                    verificationId = id
                    codeSent = true
                    isProcessing = false
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }

    private func verifyCode() {
        isProcessing = true

        Task {
            do {
                try await authService.verifyPhoneUpdate(verificationId: verificationId, code: verificationCode)

                await MainActor.run {
                    isProcessing = false
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(MockAuthRepository())
}

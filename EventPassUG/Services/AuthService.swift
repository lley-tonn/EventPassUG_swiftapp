//
//  AuthService.swift
//  EventPassUG
//
//  Authentication service protocol and mock implementation
//

import Foundation
import Combine

// MARK: - Protocol

protocol AuthServiceProtocol: AnyObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var currentUserPublisher: AnyPublisher<User?, Never> { get }

    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole) async throws -> User
    func signOut() throws
    func updateProfile(_ user: User) async throws
    func switchRole(to role: UserRole) async throws
    func submitVerification(documentType: VerificationDocumentType, documentNumber: String, frontImageData: Data?, backImageData: Data?) async throws

    // Social Auth
    func signInWithGoogle(firstName: String, lastName: String, role: UserRole) async throws -> User
    func signInWithApple(firstName: String, lastName: String, role: UserRole) async throws -> User

    // Phone Auth
    func signInWithPhone(phoneNumber: String, firstName: String, lastName: String, role: UserRole) async throws -> String // Returns verification ID
    func verifyPhoneCode(verificationId: String, code: String) async throws -> User

    // Email/Phone Verification
    func sendEmailVerification() async throws
    func sendPhoneVerification(phoneNumber: String) async throws -> String // Returns verification ID
    func verifyPhone(verificationId: String, code: String) async throws

    // Add Contact Methods
    func addEmail(email: String, password: String) async throws
    func addPhoneNumber(phoneNumber: String) async throws -> String // Returns verification ID

    // Account Linking
    func linkGoogleAccount() async throws
    func linkAppleAccount() async throws
    func linkEmailPassword(email: String, password: String) async throws

    // Update Contact Info (with verification)
    func updateEmail(newEmail: String, password: String) async throws
    func updatePhoneNumber(newPhoneNumber: String) async throws -> String // Returns verification ID
    func verifyPhoneUpdate(verificationId: String, code: String) async throws
}

// MARK: - Mock Implementation

class MockAuthService: AuthServiceProtocol, ObservableObject {
    @Published private(set) var currentUser: User?

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var currentUserPublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    private let userDefaultsKey = "com.eventpassug.currentUser"

    init() {
        // Load persisted user from UserDefaults
        loadPersistedUser()
    }

    func signIn(email: String, password: String) async throws -> User {
        // TODO: Replace with real API call
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Mock authentication - accept any credentials
        let user = User(
            firstName: "John",
            lastName: "Doe",
            email: email,
            role: .attendee
        )

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
        return user
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole) async throws -> User {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let user = User(
            firstName: firstName,
            lastName: lastName,
            email: email,
            role: role
        )

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
        return user
    }

    func signOut() throws {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    func updateProfile(_ user: User) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    func switchRole(to role: UserRole) async throws {
        guard var user = currentUser else { return }
        user.role = role

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    func submitVerification(documentType: VerificationDocumentType, documentNumber: String, frontImageData: Data?, backImageData: Data?) async throws {
        guard var user = currentUser else { return }

        // TODO: Replace with real API call to upload images and verify
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Mock success - update user verification status
        user.isVerified = true
        user.nationalIDNumber = documentNumber
        user.verificationDate = Date()
        user.verificationDocumentType = documentType

        // In real implementation, upload images to server and store URLs
        // For now, we'll just mark as verified
        if frontImageData != nil {
            user.nationalIDFrontImageURL = "mock://front-image-url"
        }
        if backImageData != nil {
            user.nationalIDBackImageURL = "mock://back-image-url"
        }

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    // MARK: - Social Auth

    func signInWithGoogle(firstName: String, lastName: String, role: UserRole) async throws -> User {
        // TODO: Implement Google Sign In with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let user = User(
            firstName: firstName,
            lastName: lastName,
            email: "\(firstName.lowercased()).\(lastName.lowercased())@gmail.com", // Mock email from Google
            role: role,
            isEmailVerified: true, // Google emails are pre-verified
            authProviders: ["google.com"]
        )

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
        return user
    }

    func signInWithApple(firstName: String, lastName: String, role: UserRole) async throws -> User {
        // TODO: Implement Apple Sign In with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let user = User(
            firstName: firstName,
            lastName: lastName,
            email: nil, // Apple can hide email
            role: role,
            authProviders: ["apple.com"]
        )

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
        return user
    }

    // MARK: - Phone Auth

    func signInWithPhone(phoneNumber: String, firstName: String, lastName: String, role: UserRole) async throws -> String {
        // TODO: Implement Firebase Phone Auth
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Mock verification ID
        return "mock-verification-id-\(UUID().uuidString)"
    }

    func verifyPhoneCode(verificationId: String, code: String) async throws -> User {
        // TODO: Verify phone code with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Extract phone from verification ID (in real implementation, Firebase handles this)
        let user = User(
            firstName: "Phone",
            lastName: "User",
            role: .attendee,
            phoneNumber: "+256700000000", // Mock phone number
            isPhoneVerified: true,
            authProviders: ["phone"]
        )

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
        return user
    }

    // MARK: - Email/Phone Verification

    func sendEmailVerification() async throws {
        guard var user = currentUser, user.email != nil else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No email address found"])
        }

        // TODO: Send email verification with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Mock: Automatically verify for now
        user.isEmailVerified = true

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    func sendPhoneVerification(phoneNumber: String) async throws -> String {
        guard currentUser != nil else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // TODO: Send SMS with Firebase Phone Auth
        try await Task.sleep(nanoseconds: 1_000_000_000)

        return "mock-verification-id-\(UUID().uuidString)"
    }

    func verifyPhone(verificationId: String, code: String) async throws {
        guard var user = currentUser else { return }

        // TODO: Verify code with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        user.isPhoneVerified = true

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    // MARK: - Add Contact Methods

    func addEmail(email: String, password: String) async throws {
        guard var user = currentUser else { return }

        // TODO: Add email/password to Firebase account
        try await Task.sleep(nanoseconds: 1_000_000_000)

        user.email = email
        if !user.authProviders.contains("email") {
            user.authProviders.append("email")
        }

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    func addPhoneNumber(phoneNumber: String) async throws -> String {
        guard currentUser != nil else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // TODO: Send SMS verification
        try await Task.sleep(nanoseconds: 1_000_000_000)

        return "mock-verification-id-\(UUID().uuidString)"
    }

    // MARK: - Account Linking

    func linkGoogleAccount() async throws {
        guard var user = currentUser else { return }

        // TODO: Link Google account with Firebase auth().link(with:)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        if !user.authProviders.contains("google.com") {
            user.authProviders.append("google.com")
        }
        if user.email == nil {
            user.email = "linked@gmail.com" // Mock
            user.isEmailVerified = true
        }

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    func linkAppleAccount() async throws {
        guard var user = currentUser else { return }

        // TODO: Link Apple account with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        if !user.authProviders.contains("apple.com") {
            user.authProviders.append("apple.com")
        }

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    func linkEmailPassword(email: String, password: String) async throws {
        guard var user = currentUser else { return }

        // TODO: Link email/password with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        user.email = email
        if !user.authProviders.contains("email") {
            user.authProviders.append("email")
        }

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    // MARK: - Update Contact Info

    func updateEmail(newEmail: String, password: String) async throws {
        guard var user = currentUser else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // TODO: Verify password first with Firebase
        // TODO: Send verification email to new address with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Store pending email (in production, this would wait for verification)
        user.pendingEmail = newEmail

        // In mock implementation, we'll auto-verify after a delay
        // In production, user would need to click verification link
        user.email = newEmail
        user.isEmailVerified = false // Needs verification
        user.pendingEmail = nil

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    func updatePhoneNumber(newPhoneNumber: String) async throws -> String {
        guard var user = currentUser else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // TODO: Send SMS verification to new number with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Store pending phone number
        user.pendingPhoneNumber = newPhoneNumber

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)

        // Return mock verification ID
        return "mock-phone-update-\(UUID().uuidString)"
    }

    func verifyPhoneUpdate(verificationId: String, code: String) async throws {
        guard var user = currentUser else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // TODO: Verify code with Firebase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Update phone number from pending
        if let pendingPhone = user.pendingPhoneNumber {
            user.phoneNumber = pendingPhone
            user.isPhoneVerified = true
            user.pendingPhoneNumber = nil

            if !user.authProviders.contains("phone") {
                user.authProviders.append("phone")
            }
        }

        await MainActor.run {
            self.currentUser = user
        }
        persistUser(user)
    }

    // MARK: - Persistence

    private func persistUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadPersistedUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
        }
    }
}

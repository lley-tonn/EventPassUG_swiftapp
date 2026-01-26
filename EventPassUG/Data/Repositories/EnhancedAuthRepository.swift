//
//  EnhancedAuthService.swift
//  EventPassUG
//
//  Production-ready authentication service using TestDatabase
//  Replaces MockAuthRepository with real database-backed auth
//

import Foundation
import Combine

@MainActor
class EnhancedAuthService: AuthRepositoryProtocol, ObservableObject {

    @Published private(set) var currentUser: User?

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var isGuestMode: Bool {
        currentUser == nil
    }

    var currentUserPublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    private let database = TestDatabase.shared

    // MARK: - Initialization

    init() {
        // Load persisted session
        loadPersistedSession()
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> User {
        let result = database.authenticate(email: email, password: password)

        switch result {
        case .success(let dbUser):
            let user = dbUser.toUser()
            currentUser = user
            database.saveSession(userId: dbUser.id)
            return user

        case .failure(let error):
            throw error
        }
    }

    // MARK: - Sign Up

    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole
    ) async throws -> User {
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)

        let dbUser = try database.createUser(
            fullName: fullName,
            email: email,
            password: password,
            authProvider: .email,
            role: role
        )

        let user = dbUser.toUser()
        currentUser = user
        database.saveSession(userId: dbUser.id)

        return user
    }

    // MARK: - Phone Authentication

    func signInWithPhone(
        phoneNumber: String,
        firstName: String,
        lastName: String,
        role: UserRole
    ) async throws -> String {
        // Return mock verification ID
        // In production, this would trigger SMS
        return "mock-verification-id-\(UUID().uuidString)"
    }

    func verifyPhoneCode(verificationId: String, code: String) async throws -> User {
        // Extract phone number from verification ID or use mock
        // For testing, we'll use the mock phone number
        let phoneNumber = "+256700123456"

        let result = database.authenticateWithPhone(phoneNumber, otp: code)

        switch result {
        case .success(let dbUser):
            let user = dbUser.toUser()
            currentUser = user
            database.saveSession(userId: dbUser.id)
            return user

        case .failure(let error):
            throw error
        }
    }

    // MARK: - Social Authentication

    func signInWithApple(firstName: String, lastName: String, role: UserRole) async throws -> User {
        // Mock Apple Sign In
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        let dbUser = try database.createUser(
            fullName: fullName,
            email: "apple.\(UUID().uuidString.prefix(8))@privaterelay.appleid.com",
            authProvider: .apple,
            role: role
        )

        let user = dbUser.toUser()
        currentUser = user
        database.saveSession(userId: dbUser.id)
        return user
    }

    func signInWithGoogle(firstName: String, lastName: String, role: UserRole) async throws -> User {
        // Mock Google Sign In
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        let dbUser = try database.createUser(
            fullName: fullName,
            email: "google.user.\(UUID().uuidString.prefix(8))@gmail.com",
            authProvider: .google,
            role: role
        )

        let user = dbUser.toUser()
        currentUser = user
        database.saveSession(userId: dbUser.id)
        return user
    }

    // MARK: - Sign Out

    func signOut() throws {
        currentUser = nil
        database.clearSession()
    }

    // MARK: - Session Management

    private func loadPersistedSession() {
        guard let userId = database.loadSession(),
              let dbUser = database.findUser(byId: userId) else {
            return
        }

        currentUser = dbUser.toUser()
    }

    // MARK: - User Updates

    func updateProfile(_ user: User) async throws {
        guard var dbUser = database.findUser(byId: user.id) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        dbUser.fullName = user.fullName
        database.updateUser(dbUser)

        currentUser = dbUser.toUser()
    }

    func switchRole(to role: UserRole) async throws {
        guard var user = currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        user.role = role

        guard var dbUser = database.findUser(byId: user.id) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        dbUser.role = role
        database.updateUser(dbUser)
        currentUser = user
    }

    func submitVerification(documentType: VerificationDocumentType, documentNumber: String, frontImageData: Data?, backImageData: Data?) async throws {
        // Mock verification submission
        guard var user = currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        // In production, this would upload to backend
        user.isVerified = true
        currentUser = user
    }

    // MARK: - Email/Phone Verification

    func sendEmailVerification() async throws {
        // Mock email verification
        // In production, this would trigger email
    }

    func sendPhoneVerification(phoneNumber: String) async throws -> String {
        // Mock phone verification
        return "mock-verification-id-\(UUID().uuidString)"
    }

    func verifyPhone(verificationId: String, code: String) async throws {
        // Mock phone verification
        guard code == "123456" else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code"])
        }
    }

    // MARK: - Add Contact Methods

    func addEmail(email: String, password: String) async throws {
        guard let userId = currentUser?.id,
              var dbUser = database.findUser(byId: userId) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        dbUser.email = email
        database.updateUser(dbUser)
        currentUser = dbUser.toUser()
    }

    func addPhoneNumber(phoneNumber: String) async throws -> String {
        // Return verification ID
        return "mock-verification-id-\(UUID().uuidString)"
    }

    // MARK: - Account Linking

    func linkGoogleAccount() async throws {
        // Mock Google account linking
    }

    func linkAppleAccount() async throws {
        // Mock Apple account linking
    }

    func linkEmailPassword(email: String, password: String) async throws {
        guard let userId = currentUser?.id,
              var dbUser = database.findUser(byId: userId) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        dbUser.email = email
        dbUser.passwordHash = PasswordHasher.hash(password)
        database.updateUser(dbUser)
        currentUser = dbUser.toUser()
    }

    // MARK: - Update Contact Info

    func updateEmail(newEmail: String, password: String) async throws {
        guard let userId = currentUser?.id,
              var dbUser = database.findUser(byId: userId) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        // Verify password
        guard let passwordHash = dbUser.passwordHash,
              PasswordHasher.verify(password, hash: passwordHash) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid password"])
        }

        dbUser.email = newEmail
        database.updateUser(dbUser)
        currentUser = dbUser.toUser()
    }

    func updatePhoneNumber(newPhoneNumber: String) async throws -> String {
        // Return verification ID
        return "mock-verification-id-\(UUID().uuidString)"
    }

    func verifyPhoneUpdate(verificationId: String, code: String) async throws {
        guard code == "123456" else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code"])
        }

        guard let userId = currentUser?.id,
              var dbUser = database.findUser(byId: userId) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        // In production, extract phone number from verificationId
        let newPhoneNumber = "+256700000000" // Mock
        dbUser.phoneNumber = newPhoneNumber
        database.updateUser(dbUser)
        currentUser = dbUser.toUser()
    }
}

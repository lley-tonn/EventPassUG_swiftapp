//
//  TestDatabase.swift
//  EventPassUG
//
//  Production-grade test database for multi-user authentication
//  Supports registration, login, and session persistence
//

import Foundation
import CryptoKit

// MARK: - Database User Model

struct DatabaseUser: Codable, Identifiable {
    let id: UUID
    var fullName: String
    var email: String?
    var phoneNumber: String?
    var passwordHash: String?
    var authProvider: AuthProvider
    var role: UserRole
    var createdAt: Date
    var lastLoginAt: Date?
    var isEmailVerified: Bool
    var isPhoneVerified: Bool
    var profileImageURL: String?

    enum AuthProvider: String, Codable {
        case email
        case phone
        case apple
        case google
        case facebook
    }

    /// Convert to app User model
    func toUser() -> User {
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.first ?? fullName
        let lastName = nameParts.dropFirst().joined(separator: " ")

        return User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            role: role,
            profileImageURL: profileImageURL,
            phoneNumber: phoneNumber,
            dateJoined: createdAt,
            isEmailVerified: isEmailVerified,
            isPhoneVerified: isPhoneVerified,
            authProviders: [authProvider.rawValue],
            isVerified: isEmailVerified || isPhoneVerified
        )
    }
}

// MARK: - Password Hasher

struct PasswordHasher {
    /// Hash a password with salt
    static func hash(_ password: String) -> String {
        let salt = generateSalt()
        let saltedPassword = salt + password
        let hash = SHA256.hash(data: Data(saltedPassword.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return "\(salt)$\(hashString)"
    }

    /// Verify a password against a hash
    static func verify(_ password: String, hash: String) -> Bool {
        let components = hash.components(separatedBy: "$")
        guard components.count == 2 else { return false }

        let salt = components[0]
        let storedHash = components[1]

        let saltedPassword = salt + password
        let computedHash = SHA256.hash(data: Data(saltedPassword.utf8))
        let computedHashString = computedHash.compactMap { String(format: "%02x", $0) }.joined()

        return computedHashString == storedHash
    }

    private static func generateSalt() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<16).map{ _ in letters.randomElement()! })
    }
}

// MARK: - Test Database

@MainActor
class TestDatabase: ObservableObject {
    static let shared = TestDatabase()

    @Published private(set) var users: [DatabaseUser] = []

    private let userDefaultsKey = "com.eventpass.testDatabase.users"
    private let sessionKey = "com.eventpass.currentSession"

    // MARK: - Initialization

    private init() {
        loadUsers()
        if users.isEmpty {
            seedTestData()
        }
    }

    // MARK: - User Management

    /// Create a new user
    func createUser(
        fullName: String,
        email: String? = nil,
        phoneNumber: String? = nil,
        password: String? = nil,
        authProvider: DatabaseUser.AuthProvider,
        role: UserRole
    ) throws -> DatabaseUser {
        // Check for duplicate email
        if let email = email, users.contains(where: { $0.email?.lowercased() == email.lowercased() }) {
            throw DatabaseError.duplicateEmail
        }

        // Check for duplicate phone
        if let phone = phoneNumber, users.contains(where: { $0.phoneNumber == phone }) {
            throw DatabaseError.duplicatePhone
        }

        let user = DatabaseUser(
            id: UUID(),
            fullName: fullName,
            email: email,
            phoneNumber: phoneNumber,
            passwordHash: password.map { PasswordHasher.hash($0) },
            authProvider: authProvider,
            role: role,
            createdAt: Date(),
            lastLoginAt: nil,
            isEmailVerified: authProvider != .email, // Auto-verify non-email
            isPhoneVerified: authProvider == .phone,
            profileImageURL: nil
        )

        users.append(user)
        saveUsers()

        print("✅ Created user: \(fullName) (\(email ?? phoneNumber ?? "N/A"))")
        return user
    }

    /// Find user by email
    func findUser(byEmail email: String) -> DatabaseUser? {
        users.first { $0.email?.lowercased() == email.lowercased() }
    }

    /// Find user by phone
    func findUser(byPhone phoneNumber: String) -> DatabaseUser? {
        users.first { $0.phoneNumber == phoneNumber }
    }

    /// Find user by ID
    func findUser(byId id: UUID) -> DatabaseUser? {
        users.first { $0.id == id }
    }

    /// Update user
    func updateUser(_ user: DatabaseUser) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveUsers()
        }
    }

    /// Update last login
    func updateLastLogin(userId: UUID) {
        if let index = users.firstIndex(where: { $0.id == userId }) {
            users[index].lastLoginAt = Date()
            saveUsers()
        }
    }

    // MARK: - Authentication

    /// Authenticate with email and password
    func authenticate(email: String, password: String) -> Result<DatabaseUser, DatabaseError> {
        guard let user = findUser(byEmail: email) else {
            return .failure(.userNotFound)
        }

        guard let passwordHash = user.passwordHash else {
            return .failure(.invalidCredentials)
        }

        guard PasswordHasher.verify(password, hash: passwordHash) else {
            return .failure(.invalidCredentials)
        }

        updateLastLogin(userId: user.id)
        return .success(user)
    }

    /// Authenticate with phone (mock OTP)
    func authenticateWithPhone(_ phoneNumber: String, otp: String) -> Result<DatabaseUser, DatabaseError> {
        // Mock OTP verification (always accept "123456")
        guard otp == "123456" else {
            return .failure(.invalidOTP)
        }

        if let user = findUser(byPhone: phoneNumber) {
            updateLastLogin(userId: user.id)
            return .success(user)
        }

        // Auto-create user for phone auth
        do {
            let user = try createUser(
                fullName: "User \(phoneNumber.suffix(4))",
                phoneNumber: phoneNumber,
                authProvider: .phone,
                role: .attendee
            )
            return .success(user)
        } catch {
            return .failure(.creationFailed)
        }
    }

    // MARK: - Session Management

    func saveSession(userId: UUID) {
        UserDefaults.standard.set(userId.uuidString, forKey: sessionKey)
    }

    func loadSession() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: sessionKey) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    // MARK: - Persistence

    private func saveUsers() {
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadUsers() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([DatabaseUser].self, from: data) else {
            return
        }
        users = decoded
    }

    // MARK: - Test Data

    func seedTestData() {
        print("🌱 Seeding test data...")

        let testUsers: [(String, String, String, UserRole)] = [
            ("John Doe", "john@example.com", "password123", .attendee),
            ("Jane Smith", "jane@example.com", "password123", .attendee),
            ("Bob Organizer", "bob@events.com", "organizer123", .organizer),
            ("Alice Johnson", "alice@example.com", "password123", .attendee),
            ("Sarah Events", "sarah@events.com", "organizer123", .organizer)
        ]

        for (name, email, password, role) in testUsers {
            do {
                _ = try createUser(
                    fullName: name,
                    email: email,
                    password: password,
                    authProvider: .email,
                    role: role
                )
            } catch {
                print("⚠️  Skipped duplicate: \(email)")
            }
        }

        // Add phone-only user
        do {
            _ = try createUser(
                fullName: "Phone User",
                phoneNumber: "+256700123456",
                authProvider: .phone,
                role: .attendee
            )
        } catch {
            print("⚠️  Skipped duplicate phone user")
        }

        print("✅ Seeded \(users.count) test users")
    }

    func resetDatabase() {
        users = []
        saveUsers()
        clearSession()
        print("🗑️  Database reset")
    }

    // MARK: - Statistics

    func getStatistics() -> DatabaseStatistics {
        DatabaseStatistics(
            totalUsers: users.count,
            attendees: users.filter { $0.role == .attendee }.count,
            organizers: users.filter { $0.role == .organizer }.count,
            emailUsers: users.filter { $0.authProvider == .email }.count,
            phoneUsers: users.filter { $0.authProvider == .phone }.count,
            socialUsers: users.filter { [.apple, .google, .facebook].contains($0.authProvider) }.count
        )
    }
}

// MARK: - Database Statistics

struct DatabaseStatistics {
    let totalUsers: Int
    let attendees: Int
    let organizers: Int
    let emailUsers: Int
    let phoneUsers: Int
    let socialUsers: Int
}

// MARK: - Database Errors

enum DatabaseError: LocalizedError {
    case duplicateEmail
    case duplicatePhone
    case userNotFound
    case invalidCredentials
    case invalidOTP
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .duplicateEmail:
            return "An account with this email already exists"
        case .duplicatePhone:
            return "An account with this phone number already exists"
        case .userNotFound:
            return "No account found with this email"
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidOTP:
            return "Invalid verification code"
        case .creationFailed:
            return "Failed to create account"
        }
    }
}

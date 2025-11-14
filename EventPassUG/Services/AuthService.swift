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

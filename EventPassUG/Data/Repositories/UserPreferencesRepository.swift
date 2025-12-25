//
//  UserPreferencesService.swift
//  EventPassUG
//
//  Service for managing user preferences (notifications, payments, event types)
//

import Foundation
import Combine

protocol UserPreferencesRepositoryProtocol {
    var notificationPreferences: NotificationPreferences { get }
    var savedPaymentMethods: [SavedPaymentMethod] { get }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws
    func resetNotificationPreferences() async throws
    func savePaymentMethod(_ method: SavedPaymentMethod) async throws
    func removePaymentMethod(_ methodId: UUID) async throws
    func setDefaultPaymentMethod(_ methodId: UUID) async throws
    func fetchPreferences() async throws
}

class MockUserPreferencesRepository: UserPreferencesRepositoryProtocol, ObservableObject {
    @Published private(set) var notificationPreferences: NotificationPreferences = .defaultPreferences
    @Published private(set) var savedPaymentMethods: [SavedPaymentMethod] = []

    private let notificationPrefsKey = "com.eventpassug.notificationPreferences"
    private let paymentMethodsKey = "com.eventpassug.savedPaymentMethods"

    init() {
        loadPersistedPreferences()
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            self.notificationPreferences = preferences
        }
        persistNotificationPreferences(preferences)
    }

    func resetNotificationPreferences() async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        let defaults = NotificationPreferences.defaultPreferences
        await MainActor.run {
            self.notificationPreferences = defaults
        }
        persistNotificationPreferences(defaults)
    }

    func savePaymentMethod(_ method: SavedPaymentMethod) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        let updatedMethods = await MainActor.run { () -> [SavedPaymentMethod] in
            var methods = savedPaymentMethods

            // If this is set as default, unset others
            if method.isDefault {
                methods = methods.map { existingMethod in
                    var updated = existingMethod
                    updated.isDefault = false
                    return updated
                }
            }

            // Add or update the method
            if let index = methods.firstIndex(where: { $0.id == method.id }) {
                methods[index] = method
            } else {
                methods.append(method)
            }

            self.savedPaymentMethods = methods
            return methods
        }
        persistPaymentMethods(updatedMethods)
    }

    func removePaymentMethod(_ methodId: UUID) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        let updatedMethods = await MainActor.run { () -> [SavedPaymentMethod] in
            var methods = savedPaymentMethods.filter { $0.id != methodId }

            // If removed method was default, set first remaining as default
            if !methods.isEmpty && !methods.contains(where: { $0.isDefault }) {
                methods[0].isDefault = true
            }

            self.savedPaymentMethods = methods
            return methods
        }
        persistPaymentMethods(updatedMethods)
    }

    func setDefaultPaymentMethod(_ methodId: UUID) async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)

        let updatedMethods = await MainActor.run { () -> [SavedPaymentMethod] in
            let methods = savedPaymentMethods.map { method in
                var updated = method
                updated.isDefault = (method.id == methodId)
                return updated
            }
            self.savedPaymentMethods = methods
            return methods
        }
        persistPaymentMethods(updatedMethods)
    }

    func fetchPreferences() async throws {
        // TODO: Replace with real API call
        try await Task.sleep(nanoseconds: 500_000_000)
        loadPersistedPreferences()
    }

    // MARK: - Persistence

    private func persistNotificationPreferences(_ preferences: NotificationPreferences) {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: notificationPrefsKey)
        }
    }

    private func persistPaymentMethods(_ methods: [SavedPaymentMethod]) {
        if let encoded = try? JSONEncoder().encode(methods) {
            UserDefaults.standard.set(encoded, forKey: paymentMethodsKey)
        }
    }

    private func loadPersistedPreferences() {
        // Load notification preferences
        if let data = UserDefaults.standard.data(forKey: notificationPrefsKey),
           let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.notificationPreferences = prefs
        }

        // Load payment methods
        if let data = UserDefaults.standard.data(forKey: paymentMethodsKey),
           let methods = try? JSONDecoder().decode([SavedPaymentMethod].self, from: data) {
            self.savedPaymentMethods = methods
        }
    }
}

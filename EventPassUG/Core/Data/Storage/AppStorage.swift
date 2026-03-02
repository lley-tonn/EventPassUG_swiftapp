//
//  AppStorage.swift
//  EventPassUG
//
//  App-wide storage utilities using UserDefaults
//

import Foundation

class AppStorageManager {
    static let shared = AppStorageManager()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Onboarding

    /// Use the same key as AppStorageKeys.hasSeenOnboarding for consistency
    var hasCompletedOnboarding: Bool {
        get {
            defaults.bool(forKey: AppStorageKeys.hasSeenOnboarding)
        }
        set {
            defaults.set(newValue, forKey: AppStorageKeys.hasSeenOnboarding)
        }
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

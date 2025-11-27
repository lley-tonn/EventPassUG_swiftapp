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

    private let onboardingCompletedKey = "hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool {
        get {
            defaults.bool(forKey: onboardingCompletedKey)
        }
        set {
            defaults.set(newValue, forKey: onboardingCompletedKey)
        }
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

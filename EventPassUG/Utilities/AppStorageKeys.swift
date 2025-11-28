//
//  AppStorageKeys.swift
//  EventPassUG
//
//  Centralized AppStorage keys for consistency
//

import Foundation

struct AppStorageKeys {
    /// Key for tracking whether user has seen the onboarding slides
    static let hasSeenOnboarding = "hasSeenOnboarding"

    /// Key for tracking app first launch
    static let isFirstLaunch = "isFirstLaunch"

    // Add other storage keys here as needed
    // static let selectedTheme = "selectedTheme"
    // static let notificationsEnabled = "notificationsEnabled"
}

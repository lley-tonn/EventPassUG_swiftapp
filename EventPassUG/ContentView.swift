//
//  ContentView.swift
//  EventPassUG
//
//  Root view that handles onboarding and authentication flow
//  FIXED: Onboarding shows only once on first launch
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: MockAuthService

    // CRITICAL FIX: Use @AppStorage directly for persistence
    // This ensures the flag persists across app launches
    @AppStorage(AppStorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false

    // Track onboarding completion in current session
    @State private var isOnboardingComplete = false
    @State private var showPreferencesOnboarding = false

    var body: some View {
        Group {
            // FLOW LOGIC (Priority Order):
            // 1. First time user (hasn't seen onboarding) → Show onboarding
            // 2. Logged in user → Show main app
            // 3. Returning user (not logged in) → Show login

            if !hasSeenOnboarding && !isOnboardingComplete {
                // FIRST TIME USER: Show onboarding slides
                AppIntroSlidesView(isComplete: $isOnboardingComplete)
                    .onChange(of: isOnboardingComplete) { completed in
                        if completed {
                            // CRITICAL: Save to persistent storage
                            // This ensures onboarding never shows again
                            hasSeenOnboarding = true

                            // Also update legacy storage for compatibility
                            AppStorageManager.shared.hasCompletedOnboarding = true
                        }
                    }
                    .transition(.opacity)

            } else if authService.isAuthenticated {
                // USER IS LOGGED IN: Show main app
                if let user = authService.currentUser {
                    // Use currentActiveRole for navigation (supports dual-role switching)
                    MainTabView(userRole: user.currentActiveRole)
                        .fullScreenCover(isPresented: $showPreferencesOnboarding) {
                            OnboardingFlowView(showOnboarding: $showPreferencesOnboarding)
                                .environmentObject(authService)
                        }
                        .onAppear {
                            // Check if user needs to complete post-login onboarding
                            if !user.hasCompletedOnboarding {
                                showPreferencesOnboarding = true
                            }
                        }
                        .onChange(of: authService.currentUser?.hasCompletedOnboarding) { completed in
                            if completed == true {
                                showPreferencesOnboarding = false
                            }
                        }
                } else {
                    // Edge case: authenticated but no user object
                    OnboardingView()
                }

            } else {
                // USER NOT LOGGED IN: Show login/signup
                // (Onboarding already seen, so skip it)
                OnboardingView()
            }
        }
        // Smooth transitions between states
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.3), value: isOnboardingComplete)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(MockAuthService())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

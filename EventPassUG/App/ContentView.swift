//
//  ContentView.swift
//  EventPassUG
//
//  Root view that handles onboarding and authentication flow
//  FIXED: Onboarding shows only once on first launch
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: MockAuthRepository

    // CRITICAL FIX: Use @AppStorage directly for persistence
    // This ensures the flag persists across app launches
    @AppStorage(AppStorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage("hasChosenAuthMethod") private var hasChosenAuthMethod = false

    // Track onboarding completion in current session
    @State private var isOnboardingComplete = false
    @State private var showPreferencesOnboarding = false

    // Guest mode support
    @State private var continueAsGuest = false
    @State private var showingAuth = false
    @State private var showingOrganizerSignup = false

    var body: some View {
        Group {
            // FLOW LOGIC (Priority Order):
            // 1. First time user (hasn't seen onboarding) → Show onboarding
            // 2. After onboarding → Show auth choice screen
            // 3. Logged in user → Show main app
            // 4. Guest user → Show main app (guest mode)
            // 5. Returning user (not logged in) → Show main app (guest mode)

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

            } else if hasSeenOnboarding && !hasChosenAuthMethod && !authService.isAuthenticated {
                // AFTER ONBOARDING: Show auth choice screen
                AuthChoiceView(
                    showingAuth: $showingAuth,
                    showingOrganizerSignup: $showingOrganizerSignup,
                    continueAsGuest: $continueAsGuest
                )
                .sheet(isPresented: $showingAuth) {
                    ModernAuthView(authService: authService)
                }
                .sheet(isPresented: $showingOrganizerSignup) {
                    ModernAuthView(authService: authService)
                        // Note: Would need AuthViewModel support to preset organizer role
                }
                .onChange(of: continueAsGuest) { isGuest in
                    if isGuest {
                        hasChosenAuthMethod = true
                    }
                }
                .onChange(of: authService.isAuthenticated) { isAuth in
                    if isAuth {
                        hasChosenAuthMethod = true
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
                    ModernAuthView(authService: authService)
                }

            } else {
                // GUEST MODE OR RETURNING USER: Show main app in guest mode
                // User can browse events without authentication
                MainTabView(userRole: nil)
            }
        }
        // Smooth transitions between states
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.3), value: isOnboardingComplete)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasChosenAuthMethod)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(MockAuthRepository())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

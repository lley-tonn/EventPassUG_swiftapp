//
//  ContentView.swift
//  EventPassUG
//
//  Root view that handles authentication and role-based navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: MockAuthService
    @State private var showOnboarding = false
    @State private var showPreferencesOnboarding = false

    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    // Use currentActiveRole for navigation (supports dual-role switching)
                    MainTabView(userRole: user.currentActiveRole)
                        .fullScreenCover(isPresented: $showPreferencesOnboarding) {
                            OnboardingFlowView(showOnboarding: $showPreferencesOnboarding)
                                .environmentObject(authService)
                        }
                        .onAppear {
                            // Check if user needs to complete onboarding
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
                    OnboardingView()
                }
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            // Auto-login for development (remove in production)
            if !authService.isAuthenticated {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MockAuthService())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

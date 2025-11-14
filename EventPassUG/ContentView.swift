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

    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    MainTabView(userRole: user.role)
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

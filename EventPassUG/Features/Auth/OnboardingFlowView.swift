//
//  OnboardingFlowView.swift
//  EventPassUG
//
//  First-time user onboarding flow (event preferences, etc.)
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var authService: MockAuthRepository
    @Binding var showOnboarding: Bool

    var body: some View {
        FavoriteEventCategoriesView(isOnboarding: true) {
            // On complete
            showOnboarding = false
        }
        .environmentObject(authService)
    }
}

// MARK: - Onboarding Coordinator

class OnboardingCoordinator: ObservableObject {
    @Published var showOnboarding = false

    func checkOnboardingStatus(for user: User?) {
        guard let user = user else {
            showOnboarding = false
            return
        }

        showOnboarding = !user.hasCompletedOnboarding
    }
}

#Preview {
    OnboardingFlowView(showOnboarding: .constant(true))
        .environmentObject(MockAuthRepository())
}

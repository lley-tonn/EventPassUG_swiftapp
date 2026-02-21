//
//  OrganizerSignupFlowView.swift
//  EventPassUG
//
//  Complete organizer signup flow: Auth → KYC verification
//  Ensures organizers complete identity verification before accessing organizer features
//

import SwiftUI

struct OrganizerSignupFlowView: View {
    let authService: any AuthRepositoryProtocol
    let onComplete: () -> Void

    @EnvironmentObject var mockAuthService: MockAuthRepository
    @State private var flowStep: OrganizerSignupStep = .auth
    @State private var hasCompletedAuth = false

    enum OrganizerSignupStep {
        case auth       // Step 1: Sign up or login
        case kyc        // Step 2: KYC verification (BecomeOrganizerFlow)
    }

    var body: some View {
        ZStack {
            switch flowStep {
            case .auth:
                // Step 1: Authentication
                NavigationStack {
                    ModernAuthView(authService: authService)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    onComplete()
                                }
                            }
                        }
                }
                .onChange(of: mockAuthService.isAuthenticated) { isAuth in
                    // When user authenticates, move to KYC step
                    if isAuth && !hasCompletedAuth {
                        hasCompletedAuth = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                flowStep = .kyc
                            }
                        }
                    }
                }

            case .kyc:
                // Step 2: KYC Verification (BecomeOrganizerFlow)
                BecomeOrganizerFlow()
                    .environmentObject(mockAuthService)
            }
        }
        .interactiveDismissDisabled(flowStep == .kyc) // Prevent accidental dismissal during KYC
        .onDisappear {
            // Only call onComplete when the entire view disappears
            // This happens when KYC is completed or cancelled
        }
    }
}

#Preview {
    OrganizerSignupFlowView(
        authService: MockAuthRepository(),
        onComplete: {}
    )
    .environmentObject(MockAuthRepository())
}

//
//  BecomeOrganizerFlow.swift
//  EventPassUG
//
//  Multi-step onboarding flow for becoming an organizer
//

import SwiftUI

struct BecomeOrganizerFlow: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService

    @State private var currentStep: OrganizerOnboardingStep = .profileCompletion
    @State private var organizerProfile = OrganizerProfile()
    @State private var showCompletionAlert = false
    @State private var showExitConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressHeaderView(currentStep: currentStep)

                // Step content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
            .navigationTitle("Become an Organizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showExitConfirmation = true
                    }
                }
            }
            .alert("Exit Setup?", isPresented: $showExitConfirmation) {
                Button("Continue Setup", role: .cancel) {}
                Button("Exit", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your progress will not be saved. You can restart the organizer setup anytime from your profile.")
            }
            .alert("Congratulations!", isPresented: $showCompletionAlert) {
                Button("Switch to Organizer Mode") {
                    switchToOrganizerMode()
                }
                Button("Stay in Attendee Mode", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("You're now an Organizer! Would you like to switch to Organizer Mode now?")
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .profileCompletion:
            OrganizerProfileCompletionStep(
                onNext: { moveToStep(.identityVerification) }
            )

        case .identityVerification:
            OrganizerIdentityVerificationStep(
                onNext: { moveToStep(.contactInformation) },
                onBack: { moveToStep(.profileCompletion) }
            )

        case .contactInformation:
            OrganizerContactInfoStep(
                profile: $organizerProfile,
                onNext: { moveToStep(.payoutSetup) },
                onBack: { moveToStep(.identityVerification) }
            )

        case .payoutSetup:
            OrganizerPayoutSetupStep(
                profile: $organizerProfile,
                onNext: { moveToStep(.termsAgreement) },
                onBack: { moveToStep(.contactInformation) }
            )

        case .termsAgreement:
            OrganizerTermsAgreementStep(
                profile: $organizerProfile,
                onComplete: { completeOnboarding() },
                onBack: { moveToStep(.payoutSetup) }
            )
        }
    }

    private func moveToStep(_ step: OrganizerOnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    private func completeOnboarding() {
        guard var user = authService.currentUser else { return }

        // Update user to be an organizer
        user.isOrganizerRole = true
        user.isVerifiedOrganizer = true
        user.organizerProfile = organizerProfile
        organizerProfile.completedOnboardingSteps = Set(OrganizerOnboardingStep.allCases)

        Task {
            try? await authService.updateProfile(user)

            await MainActor.run {
                HapticFeedback.success()
                showCompletionAlert = true
            }
        }
    }

    private func switchToOrganizerMode() {
        guard var user = authService.currentUser else {
            dismiss()
            return
        }

        user.currentActiveRole = .organizer

        Task {
            try? await authService.updateProfile(user)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct ProgressHeaderView: View {
    let currentStep: OrganizerOnboardingStep

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Step indicators
            HStack(spacing: AppSpacing.xs) {
                ForEach(OrganizerOnboardingStep.allCases, id: \.self) { step in
                    stepIndicator(for: step)
                }
            }
            .padding(.horizontal, AppSpacing.md)

            // Current step name
            Text("Step \(currentStep.stepNumber) of 5: \(currentStep.displayName)")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    @ViewBuilder
    private func stepIndicator(for step: OrganizerOnboardingStep) -> some View {
        let isCompleted = step.stepNumber < currentStep.stepNumber
        let isCurrent = step == currentStep

        Circle()
            .fill(isCompleted ? RoleConfig.organizerPrimary : (isCurrent ? RoleConfig.organizerPrimary.opacity(0.5) : Color.gray.opacity(0.3)))
            .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
            .overlay {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: currentStep)

        if step != OrganizerOnboardingStep.allCases.last {
            Rectangle()
                .fill(isCompleted ? RoleConfig.organizerPrimary : Color.gray.opacity(0.3))
                .frame(height: 2)
        }
    }
}

#Preview {
    BecomeOrganizerFlow()
        .environmentObject(MockAuthService())
}

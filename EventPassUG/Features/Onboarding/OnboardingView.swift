//
//  OnboardingView.swift
//  EventPassUG
//
//  Main container view for the onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme

    init(isComplete: Binding<Bool>) {
        self._isComplete = isComplete
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressIndicator(
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: OnboardingStep.allCases.count
                )
                .padding(.horizontal, OnboardingTheme.horizontalPadding)
                .padding(.top, 16)

                // Content area with slide transition
                GeometryReader { geometry in
                    ZStack {
                        slideContent
                            .id(viewModel.currentStep)
                            .transition(slideTransition)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, OnboardingTheme.horizontalPadding)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(nil) // Respect system setting
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark
                    ? Color(red: 0.08, green: 0.08, blue: 0.12)
                    : Color(red: 0.96, green: 0.96, blue: 0.98),
                colorScheme == .dark
                    ? Color(red: 0.05, green: 0.05, blue: 0.08)
                    : Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Slide Content

    @ViewBuilder
    private var slideContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeSlide()
        case .roleSelection:
            RoleSelectionSlide(viewModel: viewModel)
        case .basicInfo:
            BasicInfoSlide(viewModel: viewModel)
        case .personalization:
            PersonalizationSlide(viewModel: viewModel)
        case .permissions:
            PermissionsSlide(viewModel: viewModel)
        case .completion:
            CompletionSlide(viewModel: viewModel)
        }
    }

    // MARK: - Transition

    private var slideTransition: AnyTransition {
        let insertion: AnyTransition
        let removal: AnyTransition

        if viewModel.slideDirection == .forward {
            insertion = .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
            removal = insertion
        } else {
            insertion = .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
            removal = insertion
        }

        return viewModel.slideDirection == .forward ? insertion : removal
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if viewModel.canGoBack {
                Button(action: viewModel.back) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: OnboardingTheme.buttonCornerRadius)
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.1)
                                  : Color.black.opacity(0.05))
                    )
                }
                .disabled(viewModel.isAnimating)
            }

            // Continue button
            OnboardingPrimaryButton(
                title: viewModel.continueButtonTitle,
                isEnabled: viewModel.canContinue,
                action: {
                    if viewModel.isLastStep {
                        viewModel.completeOnboarding()
                        isComplete = true
                    } else {
                        viewModel.next()
                    }
                }
            )
            .disabled(viewModel.isAnimating)
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    OnboardingView(isComplete: .constant(false))
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    OnboardingView(isComplete: .constant(false))
        .preferredColorScheme(.dark)
}

#Preview("Role Selection") {
    OnboardingPreviewWrapper(step: .roleSelection)
}

#Preview("Basic Info") {
    OnboardingPreviewWrapper(step: .basicInfo)
}

#Preview("Personalization - Attendee") {
    OnboardingPreviewWrapper(step: .personalization, role: .attendee)
}

#Preview("Personalization - Organizer") {
    OnboardingPreviewWrapper(step: .personalization, role: .organizer)
}

#Preview("Permissions") {
    OnboardingPreviewWrapper(step: .permissions)
}

#Preview("Completion") {
    OnboardingPreviewWrapper(step: .completion)
}

// MARK: - Preview Helper

private struct OnboardingPreviewWrapper: View {
    let step: OnboardingStep
    var role: UserRole? = nil

    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark
                        ? Color(red: 0.08, green: 0.08, blue: 0.12)
                        : Color(red: 0.96, green: 0.96, blue: 0.98),
                    colorScheme == .dark
                        ? Color(red: 0.05, green: 0.05, blue: 0.08)
                        : Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressIndicator(
                    currentStep: step.rawValue,
                    totalSteps: OnboardingStep.allCases.count
                )
                .padding(.horizontal, OnboardingTheme.horizontalPadding)
                .padding(.top, 16)

                slideContent

                Spacer()
            }
        }
        .onAppear {
            if let role = role {
                viewModel.selectRole(role)
            }
            viewModel.goToStep(step)
        }
    }

    @ViewBuilder
    private var slideContent: some View {
        switch step {
        case .welcome:
            WelcomeSlide()
        case .roleSelection:
            RoleSelectionSlide(viewModel: viewModel)
        case .basicInfo:
            BasicInfoSlide(viewModel: viewModel)
        case .personalization:
            PersonalizationSlide(viewModel: viewModel)
        case .permissions:
            PermissionsSlide(viewModel: viewModel)
        case .completion:
            CompletionSlide(viewModel: viewModel)
        }
    }
}

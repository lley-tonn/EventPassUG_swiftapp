//
//  OnboardingViewModel.swift
//  EventPassUG
//
//  State management for the onboarding flow
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentStep: OnboardingStep = .welcome
    @Published var profile: OnboardingProfile = OnboardingProfile()
    @Published var slideDirection: SlideDirection = .forward
    @Published var isAnimating: Bool = false
    @Published var showDatePicker: Bool = false
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Computed Properties

    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    var canContinue: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .roleSelection:
            return profile.role != nil
        case .basicInfo:
            return profile.isBasicInfoComplete
        case .personalization:
            return profile.isPersonalizationComplete
        case .permissions:
            return true
        case .completion:
            return true
        }
    }

    var canGoBack: Bool {
        currentStep.rawValue > 0
    }

    var isLastStep: Bool {
        currentStep == .completion
    }

    var continueButtonTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .completion:
            return "Start Exploring"
        default:
            return "Continue"
        }
    }

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        checkNotificationPermission()
    }

    // MARK: - Navigation

    func next() {
        guard canContinue, !isAnimating else { return }

        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex < allSteps.count - 1 else {
            completeOnboarding()
            return
        }

        slideDirection = .forward
        isAnimating = true

        withAnimation(OnboardingTheme.transitionAnimation) {
            currentStep = allSteps[currentIndex + 1]
        }

        // Reset animation flag after transition
        DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingTheme.transitionDuration) {
            self.isAnimating = false
        }

        HapticFeedback.selection()
    }

    func back() {
        guard canGoBack, !isAnimating else { return }

        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex > 0 else { return }

        slideDirection = .backward
        isAnimating = true

        withAnimation(OnboardingTheme.transitionAnimation) {
            currentStep = allSteps[currentIndex - 1]
        }

        // Reset animation flag after transition
        DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingTheme.transitionDuration) {
            self.isAnimating = false
        }

        HapticFeedback.selection()
    }

    func goToStep(_ step: OnboardingStep) {
        guard !isAnimating else { return }

        let direction: SlideDirection = step.rawValue > currentStep.rawValue ? .forward : .backward
        slideDirection = direction
        isAnimating = true

        withAnimation(OnboardingTheme.transitionAnimation) {
            currentStep = step
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingTheme.transitionDuration) {
            self.isAnimating = false
        }
    }

    // MARK: - Role Selection

    func selectRole(_ role: UserRole) {
        profile.role = role
        HapticFeedback.selection()
    }

    // MARK: - Basic Info

    func updateFullName(_ name: String) {
        profile.fullName = name
    }

    func updateDateOfBirth(_ date: Date) {
        profile.dateOfBirth = date
    }

    // MARK: - Interests (Attendee)

    func toggleInterest(_ interest: InterestCategory) {
        if profile.interests.contains(interest) {
            profile.interests.remove(interest)
        } else {
            profile.interests.insert(interest)
        }
        HapticFeedback.selection()
    }

    func isInterestSelected(_ interest: InterestCategory) -> Bool {
        profile.interests.contains(interest)
    }

    // MARK: - Event Types (Organizer)

    func toggleEventType(_ eventType: OrganizerEventType) {
        if profile.eventTypes.contains(eventType) {
            profile.eventTypes.remove(eventType)
        } else {
            profile.eventTypes.insert(eventType)
        }
        HapticFeedback.selection()
    }

    func isEventTypeSelected(_ eventType: OrganizerEventType) -> Bool {
        profile.eventTypes.contains(eventType)
    }

    // MARK: - Notifications

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
                self.profile.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.profile.notificationsEnabled = granted
                self.notificationPermissionStatus = granted ? .authorized : .denied
                if granted {
                    HapticFeedback.success()
                } else {
                    HapticFeedback.warning()
                }
            }
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Completion

    func completeOnboarding() {
        profile.completed = true
        saveProfile()
        HapticFeedback.success()
    }

    private func saveProfile() {
        // Save to UserDefaults or backend
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "onboarding_profile")
        }

        // Also save completion status
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
    }

    // MARK: - Load Saved Profile

    func loadSavedProfile() {
        if let data = UserDefaults.standard.data(forKey: "onboarding_profile"),
           let decoded = try? JSONDecoder().decode(OnboardingProfile.self, from: data) {
            profile = decoded
        }
    }

    // MARK: - Reset

    func reset() {
        profile = OnboardingProfile()
        currentStep = .welcome
        UserDefaults.standard.removeObject(forKey: "onboarding_profile")
        UserDefaults.standard.removeObject(forKey: "onboarding_completed")
    }

    // MARK: - Validation

    var nameValidationMessage: String? {
        let trimmed = profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil // Don't show error for empty field
        }
        if trimmed.count < 2 {
            return "Name must be at least 2 characters"
        }
        return nil
    }

    var ageValidationMessage: String? {
        guard let age = profile.age else { return nil }
        if age < 13 {
            return "You must be at least 13 years old"
        }
        return nil
    }

    var formattedAge: String {
        guard let age = profile.age else { return "-" }
        return "\(age) years old"
    }

    var formattedDateOfBirth: String {
        guard let dob = profile.dateOfBirth else { return "Select date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dob)
    }

    var maxDateOfBirth: Date {
        Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    }

    var minDateOfBirth: Date {
        Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date()
    }
}

// MARK: - Static Helpers

extension OnboardingViewModel {
    static var isOnboardingCompleted: Bool {
        UserDefaults.standard.bool(forKey: "onboarding_completed")
    }
}

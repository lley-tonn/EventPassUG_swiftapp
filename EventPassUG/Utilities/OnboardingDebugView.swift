//
//  OnboardingDebugView.swift
//  EventPassUG
//
//  Debug utility for testing onboarding flow
//  Add this to your settings or debug menu
//

import SwiftUI

struct OnboardingDebugView: View {
    @AppStorage(AppStorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @EnvironmentObject var authService: MockAuthService

    var body: some View {
        List {
            Section("Onboarding Status") {
                HStack {
                    Text("Has Seen Onboarding")
                    Spacer()
                    Text(hasSeenOnboarding ? "Yes" : "No")
                        .foregroundColor(hasSeenOnboarding ? .green : .red)
                }

                HStack {
                    Text("Is Authenticated")
                    Spacer()
                    Text(authService.isAuthenticated ? "Yes" : "No")
                        .foregroundColor(authService.isAuthenticated ? .green : .red)
                }

                HStack {
                    Text("Legacy Storage")
                    Spacer()
                    Text(AppStorageManager.shared.hasCompletedOnboarding ? "Yes" : "No")
                        .foregroundColor(.secondary)
                }
            }

            Section("Testing Actions") {
                Button("Reset Onboarding") {
                    // Reset @AppStorage flag
                    hasSeenOnboarding = false

                    // Reset legacy storage
                    AppStorageManager.shared.resetOnboarding()

                    // Provide feedback
                    HapticFeedback.success()
                }
                .foregroundColor(.red)

                Button("Logout") {
                    try? authService.signOut()
                    HapticFeedback.light()
                }
                .foregroundColor(.orange)

                Button("Clear All UserDefaults") {
                    UserDefaults.standard.dictionaryRepresentation().keys.forEach { key in
                        UserDefaults.standard.removeObject(forKey: key)
                    }
                    HapticFeedback.warning()
                }
                .foregroundColor(.red)
            }

            Section("Expected Flow") {
                VStack(alignment: .leading, spacing: 8) {
                    FlowStep(number: 1, title: "First Launch", description: "Show onboarding slides")
                    FlowStep(number: 2, title: "After Onboarding", description: "Show login screen")
                    FlowStep(number: 3, title: "After Login", description: "Show main app")
                    FlowStep(number: 4, title: "Next Launch", description: "Go directly to main app (skip onboarding)")
                    FlowStep(number: 5, title: "After Logout", description: "Show login (skip onboarding)")
                }
                .font(.caption)
            }

            Section("How to Test") {
                VStack(alignment: .leading, spacing: 12) {
                    TestInstruction(
                        title: "Test First Launch",
                        steps: [
                            "Tap 'Reset Onboarding'",
                            "Tap 'Logout'",
                            "Restart the app",
                            "You should see onboarding slides"
                        ]
                    )

                    Divider()

                    TestInstruction(
                        title: "Test Returning User",
                        steps: [
                            "Complete onboarding",
                            "Login to the app",
                            "Close and restart app",
                            "Should go directly to home (no onboarding)"
                        ]
                    )

                    Divider()

                    TestInstruction(
                        title: "Test Logged Out User",
                        steps: [
                            "Tap 'Logout'",
                            "Close and restart app",
                            "Should show login screen (no onboarding)"
                        ]
                    )
                }
                .font(.caption)
            }
        }
        .navigationTitle("Onboarding Debug")
    }
}

// MARK: - Supporting Views

struct FlowStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TestInstruction: View {
    let title: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .foregroundColor(.secondary)
                    Text(step)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        OnboardingDebugView()
            .environmentObject(MockAuthService())
    }
}

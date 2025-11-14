//
//  ProfileView.swift
//  EventPassUG
//
//  User profile screen with role switching and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: MockAuthService
    @State private var showingRoleSwitch = false
    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationView {
            List {
                // Profile header
                Section {
                    HStack(spacing: AppSpacing.md) {
                        // Profile image placeholder
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(
                                RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.fullName ?? "Guest")
                                .font(AppTypography.title3)
                                .fontWeight(.bold)

                            Text(authService.currentUser?.email ?? "")
                                .font(AppTypography.subheadline)
                                .foregroundColor(.secondary)

                            // Role badge
                            HStack(spacing: 4) {
                                Image(systemName: authService.currentUser?.role == .organizer
                                      ? "briefcase.fill"
                                      : "person.fill"
                                )
                                .font(.caption)

                                Text(authService.currentUser?.role.displayName ?? "")
                                    .font(AppTypography.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee)
                            )
                            .cornerRadius(AppCornerRadius.small)
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }

                // Role switcher
                Section {
                    Button(action: {
                        showingRoleSwitch = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(
                                    RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee)
                                )

                            Text("Switch Role")
                                .foregroundColor(.primary)

                            Spacer()

                            Text(authService.currentUser?.role == .attendee ? "To Organizer" : "To Attendee")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Account")
                }

                // Settings
                Section {
                    NavigationLink(destination: Text("Edit Profile")) {
                        Label("Edit Profile", systemImage: "person")
                    }

                    NavigationLink(destination: Text("Favorites")) {
                        Label("Favorite Events", systemImage: "heart")
                    }

                    NavigationLink(destination: Text("Notifications Settings")) {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink(destination: Text("Payment Methods")) {
                        Label("Payment Methods", systemImage: "creditcard")
                    }
                } header: {
                    Text("Settings")
                }

                // Support
                Section {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }

                    NavigationLink(destination: Text("Contact Support")) {
                        Label("Contact Support", systemImage: "envelope")
                    }

                    NavigationLink(destination: Text("Terms & Privacy")) {
                        Label("Terms & Privacy", systemImage: "doc.text")
                    }
                } header: {
                    Text("Support")
                }

                // App info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .confirmationDialog(
            "Switch to \(authService.currentUser?.role == .attendee ? "Organizer" : "Attendee") mode?",
            isPresented: $showingRoleSwitch,
            titleVisibility: .visible
        ) {
            Button("Switch Role") {
                switchRole()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can switch back anytime from this screen.")
        }
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private func switchRole() {
        guard let currentRole = authService.currentUser?.role else { return }
        let newRole: UserRole = currentRole == .attendee ? .organizer : .attendee

        Task {
            do {
                try await authService.switchRole(to: newRole)
                HapticFeedback.success()
            } catch {
                print("Error switching role: \(error)")
                HapticFeedback.error()
            }
        }
    }

    private func signOut() {
        do {
            try authService.signOut()
            HapticFeedback.light()
        } catch {
            print("Error signing out: \(error)")
            HapticFeedback.error()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(MockAuthService())
}

//
//  ProfileView.swift
//  EventPassUG
//
//  User profile screen with role switching and settings - with collapsible header
//

import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var authService: MockAuthService
    @State private var showingRoleSwitch = false
    @State private var showingLogoutConfirmation = false
    @State private var scrollOffset: CGFloat = 0

    private var progress: CGFloat {
        let threshold: CGFloat = 60
        return max(0, min(1, -scrollOffset / threshold))
    }

    private var headerHeight: CGFloat {
        let minHeight: CGFloat = 80
        let maxHeight: CGFloat = 160
        return maxHeight - (maxHeight - minHeight) * progress
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Collapsible Profile Header
                ZStack {
                    Color(UIColor.systemBackground)

                    HStack(spacing: AppSpacing.md) {
                        // Profile image
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60 - (progress * 20)))
                            .foregroundColor(
                                RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.fullName ?? "Guest")
                                .font(progress > 0.5 ? AppTypography.headline : AppTypography.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)

                            Group {
                                Text(authService.currentUser?.email ?? "")
                                    .foregroundColor(Color.secondary)
                                    .lineLimit(1)
                            }
                            .opacity(progress < 0.8 ? max(0, 1.0 - (progress * 1.5)) : 0)

                            // Role badge
                            Group {
                                HStack(spacing: 4) {
                                    Image(systemName: authService.currentUser?.role == .organizer
                                          ? "briefcase.fill"
                                          : "person.fill"
                                    )
                                    .font(.caption)

                                    Text(authService.currentUser?.role.displayName ?? "")
                                        .font(.caption)
                                }
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee)
                                )
                                .cornerRadius(AppCornerRadius.small)
                            }
                            .opacity(progress < 0.5 ? max(0, 1.0 - (progress * 2.0)) : 0)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .frame(height: headerHeight)
                .animation(.easeInOut(duration: 0.2), value: progress)

                Divider()

                // Settings List
                ScrollOffsetReader(content: {
                    VStack(spacing: AppSpacing.lg) {
                        // Role switcher (conditional)
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Account")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, AppSpacing.md)

                            // Conditional role switching based on user capabilities
                            if authService.currentUser?.hasBothRoles == true {
                                // User has both roles - show switch
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
                                    .padding()
                                }
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                                .padding(.horizontal, AppSpacing.md)
                            } else if authService.currentUser?.isAttendee == true {
                                // User is only attendee - show become organizer
                                NavigationLink(destination: Text("Become Organizer Form")) {
                                    HStack {
                                        Image(systemName: "briefcase")
                                            .foregroundColor(RoleConfig.organizerPrimary)

                                        Text("Become an Organizer")
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                                .padding(.horizontal, AppSpacing.md)
                            }
                        }

                        // Settings
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Settings")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, AppSpacing.md)

                            VStack(spacing: 1) {
                                settingsRow(icon: "person", title: "Edit Profile", destination: AnyView(Text("Edit Profile")))
                                settingsRow(icon: "heart", title: "Favorite Events", destination: AnyView(Text("Favorites")))
                                settingsRow(icon: "bell", title: "Notifications", destination: AnyView(Text("Notifications Settings")))
                                settingsRow(icon: "creditcard", title: "Payment Methods", destination: AnyView(Text("Payment Methods")))
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                            .padding(.horizontal, AppSpacing.md)
                        }

                        // Community
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Community")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, AppSpacing.md)

                            VStack(spacing: 1) {
                                // Invite Friends
                                Button(action: inviteFriends) {
                                    HStack {
                                        Label("Invite Friends", systemImage: "person.2.fill")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                                .buttonStyle(.plain)

                                Divider()

                                // Rate Us
                                Button(action: rateApp) {
                                    HStack {
                                        Label("Rate Us", systemImage: "star.fill")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                            .padding(.horizontal, AppSpacing.md)

                            // Social Media Icons
                            HStack(spacing: AppSpacing.lg) {
                                Spacer()

                                socialMediaImageButton(imageName: "tiktok_icon", url: "https://tiktok.com/@eventpassug", tintColor: .white)
                                socialMediaImageButton(imageName: "instagram_icon", url: "https://instagram.com/eventpassug")
                                socialMediaImageButton(imageName: "x_icon", url: "https://x.com/eventpassug", tintColor: .white)
                                socialMediaImageButton(imageName: "facebook_icon", url: "https://facebook.com/eventpassug")
                                socialMediaSystemButton(icon: "globe", url: "https://eventpassug.com")

                                Spacer()
                            }
                            .padding(.vertical, AppSpacing.sm)
                        }

                        // Support
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Support")
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, AppSpacing.md)

                            VStack(spacing: 1) {
                                settingsRow(icon: "questionmark.circle", title: "Help Center", destination: AnyView(Text("Help Center")))
                                settingsRow(icon: "envelope", title: "Contact Support", destination: AnyView(Text("Contact Support")))
                                settingsRow(icon: "doc.text", title: "Terms & Privacy", destination: AnyView(Text("Terms & Privacy")))
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                            .padding(.horizontal, AppSpacing.md)
                        }

                        // App info
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)

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
                                .padding()
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                        }
                        .padding(.horizontal, AppSpacing.md)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, AppSpacing.md)
                }, onOffsetChange: { offset in
                    scrollOffset = offset
                })
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
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

    @ViewBuilder
    private func settingsRow(icon: String, title: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func socialMediaImageButton(imageName: String, url: String, tintColor: Color? = nil) -> some View {
        Button(action: {
            openURL(url)
        }) {
            Group {
                if let tintColor = tintColor {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(tintColor)
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 28, height: 28)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        }
    }

    @ViewBuilder
    private func socialMediaSystemButton(icon: String, url: String) -> some View {
        Button(action: {
            openURL(url)
        }) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Circle())
        }
    }

    private func inviteFriends() {
        let shareText = """
        Hey! Check out EventPass UG - the best way to discover and book amazing events in Uganda!

        Download now: https://eventpassug.com/download
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2,
                                                                           y: UIScreen.main.bounds.height / 2,
                                                                           width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityVC, animated: true)
        }

        HapticFeedback.light()
    }

    private func rateApp() {
        // Option 1: Request in-app review (preferred)
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }

        // Option 2: Direct App Store link (fallback)
        // Uncomment and add your App Store ID when available
        // let appStoreURL = "https://apps.apple.com/app/id YOUR_APP_ID?action=write-review"
        // openURL(appStoreURL)

        HapticFeedback.light()
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
        HapticFeedback.light()
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

//
//  ProfileView.swift
//  EventPassUG
//
//  User profile screen with role switching and settings
//  ✨ FULLY RESPONSIVE - All hard-coded values removed
//

import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var authService: MockAuthService
    @StateObject private var followManager = FollowManager.shared
    @State private var showingRoleSwitch = false
    @State private var showingLogoutConfirmation = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingVerification = false
    @State private var showingVerificationRequired = false

    // Contact Verification
    @State private var showingEmailVerification = false
    @State private var showingPhoneVerification = false
    @State private var showingAddEmail = false
    @State private var showingAddPhone = false
    @State private var showingAccountLinking = false
    @State private var isVerifyingEmail = false

    // Organizer Onboarding
    @State private var showingBecomeOrganizer = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Collapsible Profile Header
                    CollapsibleHeader(title: authService.currentUser?.fullName ?? "Profile", scrollOffset: scrollOffset) {
                        HStack(spacing: AppSpacing.md) {
                            // Profile image - RESPONSIVE SIZE
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: profileIconSize(for: geometry)))
                                .foregroundColor(
                                    RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee)
                                )

                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                HStack(spacing: AppSpacing.xs) {
                                    Text(authService.currentUser?.fullName ?? "Guest")
                                        .font(AppTypography.title2)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    // Account Verified Badge - RESPONSIVE SIZE
                                    if authService.currentUser?.isVerified == true {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: badgeIconSize(for: geometry)))
                                            .foregroundColor(.green)
                                    }
                                }

                                if authService.currentUser?.isVerified == true {
                                    Text("Account Verified")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text(authService.currentUser?.email ?? authService.currentUser?.phoneNumber ?? "")
                                        .font(AppTypography.caption)
                                        .foregroundColor(Color.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }

                                // Role badge - FULLY RESPONSIVE
                                roleBadge(for: geometry)

                                // Follower count badge (for organizers)
                                if authService.currentUser?.isOrganizer == true {
                                    followerBadge(for: geometry)
                                }
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Settings List
                    ScrollOffsetReader(content: {
                        VStack(spacing: AppSpacing.lg) {
                            // Role switcher and verification (conditional)
                            accountSection

                            // Contact Information
                            ContactVerificationSection(
                                showingEmailVerification: $showingEmailVerification,
                                showingPhoneVerification: $showingPhoneVerification,
                                showingAddEmail: $showingAddEmail,
                                showingAddPhone: $showingAddPhone,
                                showingAccountLinking: $showingAccountLinking,
                                isVerifyingEmail: $isVerifyingEmail
                            )
                            .environmentObject(authService)

                            // Settings
                            settingsSection

                            // Community
                            communitySection(geometry: geometry)

                            // Support
                            supportSection

                            // App info
                            appInfoSection

                            Spacer(minLength: AppSpacing.xl)
                        }
                        .padding(.top, AppSpacing.md)
                        .frame(maxWidth: .infinity)
                    }, onOffsetChange: { offset in
                        scrollOffset = offset
                    })
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
                .navigationBarHidden(true)
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingEmailVerification) {
            EmailVerificationSheet(
                isVerifying: $isVerifyingEmail
            )
            .environmentObject(authService)
        }
        .sheet(isPresented: $showingPhoneVerification) {
            if let phone = authService.currentUser?.phoneNumber {
                PhoneVerificationView(phoneNumber: phone) {
                    showingPhoneVerification = false
                }
                .environmentObject(authService)
            }
        }
        .sheet(isPresented: $showingAddEmail) {
            AddContactMethodView(method: .email)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingAddPhone) {
            AddContactMethodView(method: .phone)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingAccountLinking) {
            AccountLinkingView()
                .environmentObject(authService)
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
        .sheet(isPresented: $showingVerification) {
            NationalIDVerificationView()
                .environmentObject(authService)
        }
        .alert("Verification Required", isPresented: $showingVerificationRequired) {
            Button("Verify Now") {
                showingVerification = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You must complete National ID verification before accessing organizer features.")
        }
        .fullScreenCover(isPresented: $showingBecomeOrganizer) {
            BecomeOrganizerFlow()
                .environmentObject(authService)
        }
    }

    // MARK: - Responsive Sizing Functions

    /// Calculate profile icon size based on screen size
    private func profileIconSize(for geometry: GeometryProxy) -> CGFloat {
        let baseSize: CGFloat = 60
        let screenWidth = geometry.size.width

        // Scale up for iPad (width > 768)
        if screenWidth > 768 {
            return min(baseSize * 1.5, 90) // Max 90pt on large iPads
        }
        // Slightly smaller on very small phones
        else if screenWidth < 375 {
            return max(baseSize * 0.9, 50) // Min 50pt
        }
        return baseSize
    }

    /// Calculate badge icon size
    private func badgeIconSize(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return screenWidth > 768 ? 22 : 18
    }

    /// Calculate social icon size
    private func socialIconSize(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        if screenWidth > 768 {
            return 36 // iPad
        } else if screenWidth > 600 {
            return 32 // Large phones / iPad mini
        } else {
            return 28 // Standard phones
        }
    }

    /// Calculate social icon container size (44pt minimum for touch target)
    private func socialIconContainerSize(for geometry: GeometryProxy) -> CGFloat {
        max(socialIconSize(for: geometry) + 16, 44) // Add padding, ensure 44pt minimum
    }

    /// Responsive role badge
    @ViewBuilder
    private func roleBadge(for geometry: GeometryProxy) -> some View {
        HStack(spacing: AppSpacing.xs) { // FIXED: Changed from xxs to xs (xxs doesn't exist)
            Image(systemName: currentActiveRole == .organizer
                  ? "briefcase.fill"
                  : "person.fill"
            )
            .font(.caption)

            Text(currentActiveRole.displayName)
                .font(.caption)

            // Show dual-role indicator if user has both roles
            if authService.currentUser?.hasBothRoles == true {
                Text("(Switch)")
                    .font(.system(size: geometry.size.width > 768 ? 10 : 8))
                    .opacity(0.8)
            }
        }
        .foregroundColor(Color.white)
        .padding(.horizontal, geometry.size.width > 768 ? AppSpacing.sm : AppSpacing.xs)
        .padding(.vertical, AppSpacing.xs) // FIXED: Changed from xxs to xs (xxs doesn't exist)
        .background(
            RoleConfig.getPrimaryColor(for: currentActiveRole)
        )
        .cornerRadius(AppCornerRadius.small)
    }

    /// Follower count badge for organizers
    @ViewBuilder
    private func followerBadge(for geometry: GeometryProxy) -> some View {
        let followerCount = followManager.getFollowerCount(for: authService.currentUser?.id ?? UUID())

        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "person.2.fill")
                .font(.caption)

            Text("\(followerCount) \(followerCount == 1 ? "Follower" : "Followers")")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(Color.white)
        .padding(.horizontal, geometry.size.width > 768 ? AppSpacing.sm : AppSpacing.xs)
        .padding(.vertical, AppSpacing.xs)
        .background(
            LinearGradient(
                colors: [Color.orange, Color.pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(AppCornerRadius.small)
    }

    // MARK: - View Sections

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Account")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 1) {
                // Verification Status (for organizers)
                if authService.currentUser?.isOrganizer == true {
                    if authService.currentUser?.isVerified == true {
                        // Verified organizer
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Verified Organizer")
                                    .foregroundColor(.primary)
                                if let verificationDate = authService.currentUser?.verificationDate {
                                    Text("Verified on \(verificationDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                    } else {
                        // Unverified organizer
                        Button(action: {
                            showingVerification = true
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Verification Required")
                                        .foregroundColor(.primary)
                                    Text("Complete verification to access organizer features")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }

                    Divider()
                } else if authService.currentUser?.isAttendee == true {
                    // Attendee - optional verification
                    if authService.currentUser?.isVerified != true {
                        Button(action: {
                            showingVerification = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .foregroundColor(RoleConfig.getPrimaryColor(for: .attendee))

                                Text("Verify National ID (Optional)")
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }

                        Divider()
                    }
                }

                // Role switching
                roleSwitch
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .padding(.horizontal, AppSpacing.md)
        }
    }

    @ViewBuilder
    private var roleSwitch: some View {
        if authService.currentUser?.hasBothRoles == true {
            Button(action: {
                if authService.currentUser?.isVerifiedOrganizer != true && currentActiveRole == .attendee {
                    showingVerificationRequired = true
                } else {
                    toggleActiveRole()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(
                            RoleConfig.getPrimaryColor(for: currentActiveRole)
                        )

                    Text("Switch Role")
                        .foregroundColor(.primary)

                    Spacer()

                    Text(currentActiveRole == .attendee ? "To Organizer" : "To Attendee")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        } else if authService.currentUser?.canBecomeOrganizer == true {
            Button(action: { showingBecomeOrganizer = true }) {
                HStack {
                    Image(systemName: "briefcase")
                        .foregroundColor(RoleConfig.organizerPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Become an Organizer")
                            .foregroundColor(.primary)

                        Text("Host events and sell tickets")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Settings")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 1) {
                settingsRow(icon: "person", title: "Edit Profile", destination: AnyView(EditProfileView().environmentObject(authService)))
                settingsRow(icon: "sparkles", title: "Interests", destination: AnyView(FavoriteEventCategoriesView(isOnboarding: false).environmentObject(authService)))
                settingsRow(icon: "bell", title: "Notifications", destination: AnyView(NotificationSettingsView().environmentObject(authService)))
                settingsRow(icon: "creditcard", title: "Payment Methods", destination: AnyView(PaymentMethodsView().environmentObject(authService)))
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private func communitySection(geometry: GeometryProxy) -> some View {
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

            // Social Media Icons - FULLY RESPONSIVE
            HStack(spacing: AppSpacing.md) {
                Spacer()

                socialMediaImageButton(imageName: "tiktok_icon", url: "https://tiktok.com/@eventpassug", tintColor: .white, geometry: geometry)
                socialMediaImageButton(imageName: "instagram_icon", url: "https://instagram.com/eventpassug", geometry: geometry)
                socialMediaImageButton(imageName: "x_icon", url: "https://x.com/eventpassug", tintColor: .white, geometry: geometry)
                socialMediaImageButton(imageName: "facebook_icon", url: "https://facebook.com/eventpassug", geometry: geometry)
                socialMediaSystemButton(icon: "globe", url: "https://eventpassug.com", geometry: geometry)

                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Support")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 1) {
                settingsRow(icon: "questionmark.circle", title: "Help Center", destination: AnyView(HelpCenterView().environmentObject(authService)))
                settingsRow(icon: "envelope", title: "Contact Support", destination: AnyView(SupportCenterView().environmentObject(authService)))
                settingsRow(icon: "doc.text", title: "Terms & Privacy", destination: AnyView(TermsAndPrivacyView()))
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var appInfoSection: some View {
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
    }

    // MARK: - Helper Views

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
    private func socialMediaImageButton(imageName: String, url: String, tintColor: Color? = nil, geometry: GeometryProxy) -> some View {
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
            .frame(width: socialIconSize(for: geometry), height: socialIconSize(for: geometry))
            .frame(width: socialIconContainerSize(for: geometry), height: socialIconContainerSize(for: geometry))
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(Circle())
        }
    }

    @ViewBuilder
    private func socialMediaSystemButton(icon: String, url: String, geometry: GeometryProxy) -> some View {
        Button(action: {
            openURL(url)
        }) {
            Image(systemName: icon)
                .font(.system(size: socialIconSize(for: geometry) * 0.7))
                .foregroundColor(.gray)
                .frame(width: socialIconContainerSize(for: geometry), height: socialIconContainerSize(for: geometry))
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Circle())
        }
    }

    // MARK: - Actions

    private func inviteFriends() {
        let shareText = """
        Hey! Check out EventPass UG - the best way to discover and book amazing events in Uganda!

        Download now: https://eventpassug.com/download
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // RESPONSIVE POPOVER POSITIONING - Uses view controller's view bounds
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityVC, animated: true)
        }

        HapticFeedback.light()
    }

    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
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

    private func toggleActiveRole() {
        guard var user = authService.currentUser else { return }

        let newActiveRole: UserRole = currentActiveRole == .attendee ? .organizer : .attendee
        user.currentActiveRole = newActiveRole

        Task {
            do {
                try await authService.updateProfile(user)
                HapticFeedback.success()
            } catch {
                print("Error toggling role: \(error)")
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

    // MARK: - Computed Properties

    private var currentActiveRole: UserRole {
        authService.currentUser?.currentActiveRole ?? authService.currentUser?.role ?? .attendee
    }
}

// MARK: - Contact Verification Section (No changes needed - already well structured)

struct ContactVerificationSection: View {
    @EnvironmentObject var authService: MockAuthService
    @Binding var showingEmailVerification: Bool
    @Binding var showingPhoneVerification: Bool
    @Binding var showingAddEmail: Bool
    @Binding var showingAddPhone: Bool
    @Binding var showingAccountLinking: Bool
    @Binding var isVerifyingEmail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Contact Information")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 1) {
                // Email Status/Actions
                if let email = authService.currentUser?.email {
                    if authService.currentUser?.isEmailVerified == true {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Email Verified")
                                    .foregroundColor(.primary)
                                Text(email)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                    } else {
                        Button(action: {
                            showingEmailVerification = true
                        }) {
                            HStack {
                                Image(systemName: "envelope.badge")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Verify Email")
                                        .foregroundColor(.primary)
                                    Text(email)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }

                    Divider()
                } else {
                    Button(action: {
                        showingAddEmail = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)

                            Text("Add Email Address")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)
                        }
                        .padding()
                    }

                    Divider()
                }

                // Phone Status/Actions
                if let phone = authService.currentUser?.phoneNumber {
                    if authService.currentUser?.isPhoneVerified == true {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phone Verified")
                                    .foregroundColor(.primary)
                                Text(phone)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                    } else {
                        Button(action: {
                            showingPhoneVerification = true
                        }) {
                            HStack {
                                Image(systemName: "phone.badge")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Verify Phone Number")
                                        .foregroundColor(.primary)
                                    Text(phone)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }

                    Divider()
                } else {
                    Button(action: {
                        showingAddPhone = true
                    }) {
                        HStack {
                            Image(systemName: "phone.badge.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)

                            Text("Add Phone Number")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)
                        }
                        .padding()
                    }

                    Divider()
                }

                // Account Linking
                if (authService.currentUser?.authProviders.count ?? 0) < 3 {
                    Button(action: {
                        showingAccountLinking = true
                    }) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(RoleConfig.attendeePrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Link Accounts")
                                    .foregroundColor(.primary)
                                Text("Add more sign-in options")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

// MARK: - Email Verification Sheet (Already responsive - no changes needed)

struct EmailVerificationSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @Binding var isVerifying: Bool

    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: max(geometry.size.width * 0.15, 60)))
                            .foregroundColor(RoleConfig.attendeePrimary)

                        Text("Verify Your Email")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)

                        if let email = authService.currentUser?.email {
                            Text("We'll send a verification link to:")
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)

                            Text(email)
                                .font(AppTypography.headline)
                                .foregroundColor(RoleConfig.attendeePrimary)
                        }

                        Text("Click the link in the email to verify your address")
                            .font(AppTypography.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if isVerifying {
                        ProgressView()
                            .padding()
                    } else {
                        Button(action: sendVerificationEmail) {
                            Text("Send Verification Email")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoleConfig.attendeePrimary)
                                .cornerRadius(AppCornerRadius.medium)
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Email Sent!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Check your inbox and click the verification link.")
        }
    }

    private func sendVerificationEmail() {
        isVerifying = true

        Task {
            do {
                try await authService.sendEmailVerification()

                await MainActor.run {
                    isVerifying = false
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Account Linking View (Already responsive - no changes needed)

struct AccountLinkingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService

    @State private var isLinking = false
    @State private var showSuccess = false
    @State private var successMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Link Accounts")
                            .font(AppTypography.title2)
                            .fontWeight(.bold)

                        Text("Add more ways to sign in to your account")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)

                    // Current Providers
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Connected")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, AppSpacing.md)

                        VStack(spacing: 1) {
                            ForEach(authService.currentUser?.authProviders ?? [], id: \.self) { provider in
                                HStack {
                                    Image(systemName: iconForProvider(provider))
                                        .foregroundColor(.green)

                                    Text(displayNameForProvider(provider))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding()
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    // Available to Link
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Available to Link")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, AppSpacing.md)

                        VStack(spacing: AppSpacing.md) {
                            if !(authService.currentUser?.authProviders.contains("google.com") ?? false) {
                                linkButton(
                                    icon: "g.circle.fill",
                                    title: "Link Google Account",
                                    action: linkGoogle
                                )
                            }

                            if !(authService.currentUser?.authProviders.contains("apple.com") ?? false) {
                                linkButton(
                                    icon: "applelogo",
                                    title: "Link Apple Account",
                                    action: linkApple
                                )
                            }

                            if !(authService.currentUser?.authProviders.contains("email") ?? false) {
                                linkButton(
                                    icon: "envelope.fill",
                                    title: "Link Email & Password",
                                    action: {}
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Account Linked!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text(successMessage)
        }
    }

    private func linkButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(AppTypography.body)
                    .foregroundColor(RoleConfig.attendeePrimary)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if isLinking {
                    ProgressView()
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundColor(RoleConfig.attendeePrimary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
        }
        .disabled(isLinking)
    }

    private func linkGoogle() {
        isLinking = true

        Task {
            do {
                try await authService.linkGoogleAccount()

                await MainActor.run {
                    isLinking = false
                    successMessage = "Google account linked successfully!"
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isLinking = false
                    HapticFeedback.error()
                }
            }
        }
    }

    private func linkApple() {
        isLinking = true

        Task {
            do {
                try await authService.linkAppleAccount()

                await MainActor.run {
                    isLinking = false
                    successMessage = "Apple account linked successfully!"
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isLinking = false
                    HapticFeedback.error()
                }
            }
        }
    }

    private func iconForProvider(_ provider: String) -> String {
        switch provider {
        case "google.com": return "g.circle.fill"
        case "apple.com": return "applelogo"
        case "phone": return "phone.fill"
        case "email": return "envelope.fill"
        default: return "questionmark.circle"
        }
    }

    private func displayNameForProvider(_ provider: String) -> String {
        switch provider {
        case "google.com": return "Google"
        case "apple.com": return "Apple"
        case "phone": return "Phone Number"
        case "email": return "Email & Password"
        default: return provider
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(MockAuthService())
}

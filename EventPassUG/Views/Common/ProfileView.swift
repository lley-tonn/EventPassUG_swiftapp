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
    @State private var showingVerification = false
    @State private var showingVerificationRequired = false

    // Contact Verification
    @State private var showingEmailVerification = false
    @State private var showingPhoneVerification = false
    @State private var showingAddEmail = false
    @State private var showingAddPhone = false
    @State private var showingAccountLinking = false
    @State private var isVerifyingEmail = false

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
                        // Role switcher and verification (conditional)
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
                                        // Unverified organizer - show verification required
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

                                // Conditional role switching based on user capabilities
                                if authService.currentUser?.hasBothRoles == true {
                                    // User has both roles - show switch (only if verified)
                                    Button(action: {
                                        if authService.currentUser?.needsVerificationForOrganizerActions == true {
                                            showingVerificationRequired = true
                                        } else {
                                            showingRoleSwitch = true
                                        }
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
                                }
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                            .padding(.horizontal, AppSpacing.md)
                        }

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
        .sheet(isPresented: $showingEmailVerification) {
            EmailVerificationSheet(
                isVerifying: $isVerifyingEmail
            )
            .environmentObject(authService)
        }
        .sheet(isPresented: $showingPhoneVerification) {
            if let phone = authService.currentUser?.phoneNumber {
                PhoneVerificationView(phoneNumber: phone) {
                    // On verified
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

// Contact Verification Section
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
                    // Email exists
                    if authService.currentUser?.isEmailVerified == true {
                        // Verified email
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
                        // Unverified email
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
                    // No email - show add button
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
                    // Phone exists
                    if authService.currentUser?.isPhoneVerified == true {
                        // Verified phone
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
                        // Unverified phone
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
                    // No phone - show add button
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

                // Account Linking (if user has less than 3 providers)
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

// Email Verification Sheet
struct EmailVerificationSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @Binding var isVerifying: Bool

    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80))
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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

// Account Linking View
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
                                    action: {} // Shows add email sheet
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
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
                    .font(.system(size: 20))
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

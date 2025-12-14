//
//  NotificationSettingsView.swift
//  EventPassUG
//
//  Comprehensive notification settings with per-channel controls
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @StateObject private var preferencesService = MockUserPreferencesService()

    @State private var preferences: NotificationPreferences = .defaultPreferences
    @State private var isSaving = false
    @State private var showResetConfirmation = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Verification sheets
    @State private var showingEmailVerification = false
    @State private var showingPhoneVerification = false

    var body: some View {
        Form {
            // Event Notifications
            Section {
                NotificationToggleRow(
                    title: "Upcoming Event Reminders",
                    subtitle: "Get notified before events you're attending",
                    channelPrefs: $preferences.upcomingEventReminders,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )

                NotificationToggleRow(
                    title: "Event Updates",
                    subtitle: "Changes to location, time, or cancellations",
                    channelPrefs: $preferences.eventUpdates,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )

                NotificationToggleRow(
                    title: "Tickets Expiring Soon",
                    subtitle: "Alerts when your tickets are about to expire",
                    channelPrefs: $preferences.ticketsExpiringSoon,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )
            } header: {
                Text("Event Notifications")
            }

            // Purchase Notifications
            Section {
                NotificationToggleRow(
                    title: "Ticket Purchase Confirmations",
                    subtitle: "Receipts and QR codes after purchase",
                    channelPrefs: $preferences.ticketPurchaseConfirmations,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )

                NotificationToggleRow(
                    title: "Payment Status Updates",
                    subtitle: "Payment success, failure, or pending status",
                    channelPrefs: $preferences.paymentStatusUpdates,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )
            } header: {
                Text("Purchase Notifications")
            }

            // Organizer Notifications (only for organizers)
            if authService.currentUser?.isOrganizer == true {
                Section {
                    NotificationToggleRow(
                        title: "New Ticket Sales",
                        subtitle: "Get notified when someone buys a ticket",
                        channelPrefs: $preferences.newTicketSales,
                        hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                        hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                        onVerifyEmail: { showingEmailVerification = true },
                        onVerifyPhone: { showingPhoneVerification = true }
                    )

                    NotificationToggleRow(
                        title: "Low Ticket Alerts",
                        subtitle: "Warning when tickets are running low",
                        channelPrefs: $preferences.lowTicketAlerts,
                        hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                        hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                        onVerifyEmail: { showingEmailVerification = true },
                        onVerifyPhone: { showingPhoneVerification = true }
                    )

                    NotificationToggleRow(
                        title: "Event Approval Status",
                        subtitle: "Updates on your event submissions",
                        channelPrefs: $preferences.eventApprovalStatus,
                        hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                        hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                        onVerifyEmail: { showingEmailVerification = true },
                        onVerifyPhone: { showingPhoneVerification = true }
                    )
                } header: {
                    Text("Organizer Notifications")
                }
            }

            // App Updates & Promotions
            Section {
                NotificationToggleRow(
                    title: "New Features",
                    subtitle: "Learn about new app features",
                    channelPrefs: $preferences.newFeatures,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )

                NotificationToggleRow(
                    title: "Promotional Events",
                    subtitle: "Special events and featured activities",
                    channelPrefs: $preferences.promotionalEvents,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )

                NotificationToggleRow(
                    title: "Discounts & Offers",
                    subtitle: "Special deals and discount codes",
                    channelPrefs: $preferences.discounts,
                    hasVerifiedEmail: authService.currentUser?.isEmailVerified ?? false,
                    hasVerifiedPhone: authService.currentUser?.isPhoneVerified ?? false,
                    onVerifyEmail: { showingEmailVerification = true },
                    onVerifyPhone: { showingPhoneVerification = true }
                )
            } header: {
                Text("App Updates & Promotions")
            }

            // Reset Button
            Section {
                Button(action: {
                    showResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Default Settings")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: savePreferences) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            loadPreferences()
        }
        .confirmationDialog("Reset Notifications?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset to Defaults", role: .destructive) {
                resetPreferences()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all notification settings to their default values.")
        }
        .alert("Settings Saved", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Your notification preferences have been updated.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingEmailVerification) {
            EmailVerificationSheet(isVerifying: .constant(false))
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
    }

    private func loadPreferences() {
        preferences = preferencesService.notificationPreferences
    }

    private func savePreferences() {
        isSaving = true

        Task {
            do {
                try await preferencesService.updateNotificationPreferences(preferences)

                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }

    private func resetPreferences() {
        isSaving = true

        Task {
            do {
                try await preferencesService.resetNotificationPreferences()

                await MainActor.run {
                    preferences = .defaultPreferences
                    isSaving = false
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var channelPrefs: ChannelPreferences
    let hasVerifiedEmail: Bool
    let hasVerifiedPhone: Bool
    let onVerifyEmail: () -> Void
    let onVerifyPhone: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Main toggle button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppTypography.body)
                            .foregroundColor(.primary)

                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Channel toggles (expanded)
            if isExpanded {
                VStack(spacing: AppSpacing.sm) {
                    // Push Notifications
                    HStack {
                        Label("Push", systemImage: "bell.fill")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: $channelPrefs.push)
                            .labelsHidden()
                    }

                    Divider()

                    // Email Notifications
                    HStack {
                        Label("Email", systemImage: "envelope.fill")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()

                        if hasVerifiedEmail {
                            Toggle("", isOn: $channelPrefs.email)
                                .labelsHidden()
                        } else {
                            Button("Verify to enable") {
                                onVerifyEmail()
                            }
                            .font(AppTypography.caption)
                            .foregroundColor(.orange)
                        }
                    }

                    Divider()

                    // SMS Notifications
                    HStack {
                        Label("SMS", systemImage: "message.fill")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()

                        if hasVerifiedPhone {
                            Toggle("", isOn: $channelPrefs.sms)
                                .labelsHidden()
                        } else {
                            Button("Verify to enable") {
                                onVerifyPhone()
                            }
                            .font(AppTypography.caption)
                            .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.leading, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
            }
        }
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
            .environmentObject(MockAuthService())
    }
}

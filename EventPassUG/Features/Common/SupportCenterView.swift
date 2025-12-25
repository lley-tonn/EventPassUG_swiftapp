//
//  SupportCenterView.swift
//  EventPassUG
//
//  Contact support with multiple options
//

import SwiftUI
import UIKit

struct SupportCenterView: View {
    @EnvironmentObject var authService: MockAuthRepository
    @Environment(\.openURL) var openURL

    var body: some View {
        List {
            // Quick Contact
            Section {
                // WhatsApp
                Button(action: openWhatsApp) {
                    ContactRow(
                        icon: "message.fill",
                        title: "Live Chat",
                        subtitle: "WhatsApp Business",
                        color: .green
                    )
                }

                // Email
                Button(action: openEmail) {
                    ContactRow(
                        icon: "envelope.fill",
                        title: "Email Support",
                        subtitle: "support@eventpassug.com",
                        color: .blue
                    )
                }

                // Phone
                Button(action: callSupport) {
                    ContactRow(
                        icon: "phone.fill",
                        title: "Call Support",
                        subtitle: "+256 700 123 456",
                        color: .orange
                    )
                }
            } header: {
                Text("Quick Contact")
            } footer: {
                Text("Available Mon-Fri, 8AM - 6PM EAT")
            }

            // Help Center Link
            Section {
                NavigationLink(destination: HelpCenterView().environmentObject(authService)) {
                    ContactRow(
                        icon: "questionmark.circle.fill",
                        title: "Help Center",
                        subtitle: "FAQs, guides, and troubleshooting",
                        color: RoleConfig.attendeePrimary
                    )
                }
            }

            // Submit Ticket
            Section {
                NavigationLink(destination: SubmitTicketView().environmentObject(authService)) {
                    ContactRow(
                        icon: "ticket.fill",
                        title: "Submit Support Ticket",
                        subtitle: "Get personalized help",
                        color: .purple
                    )
                }
            } header: {
                Text("Need More Help?")
            }

            // App Diagnostics
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label("App Diagnostics", systemImage: "info.circle.fill")
                        .font(AppTypography.headline)

                    DiagnosticRow(label: "App Version", value: getAppVersion())
                    DiagnosticRow(label: "Device", value: getDeviceModel())
                    DiagnosticRow(label: "iOS Version", value: getiOSVersion())
                    DiagnosticRow(label: "User ID", value: getUserID())
                }
            } footer: {
                Text("This information helps us resolve issues faster")
            }

            // Social Media
            Section {
                HStack(spacing: AppSpacing.lg) {
                    Spacer()
                    SocialButton(icon: "message.fill", label: "WhatsApp", action: openWhatsApp)
                    SocialButton(icon: "camera.fill", label: "Instagram", action: openInstagram)
                    SocialButton(icon: "xmark", label: "X", action: openTwitter)
                    SocialButton(icon: "f.square.fill", label: "Facebook", action: openFacebook)
                    Spacer()
                }
                .padding(.vertical, AppSpacing.sm)
            } header: {
                Text("Follow Us")
            }

            // Organizer-Only Support
            if authService.currentUser?.isOrganizer == true {
                Section {
                    Button(action: callOrganizerHotline) {
                        ContactRow(
                            icon: "phone.badge.checkmark.fill",
                            title: "Priority Hotline",
                            subtitle: "+256 700 999 999",
                            color: .red
                        )
                    }

                    Button(action: openOrganizerWhatsApp) {
                        ContactRow(
                            icon: "message.badge.fill",
                            title: "Organizer WhatsApp",
                            subtitle: "Direct line for organizers",
                            color: .green
                        )
                    }

                    Button(action: callEmergencySupport) {
                        ContactRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Event Day Emergency",
                            subtitle: "24/7 for critical issues",
                            color: .red
                        )
                    }
                } header: {
                    Label("Organizer Support", systemImage: "briefcase.fill")
                } footer: {
                    Text("Priority support for verified organizers")
                }
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func openWhatsApp() {
        if let url = URL(string: "https://wa.me/256700123456") {
            openURL(url)
        }
    }

    private func openEmail() {
        if let url = URL(string: "mailto:support@eventpassug.com") {
            openURL(url)
        }
    }

    private func callSupport() {
        if let url = URL(string: "tel://+256700123456") {
            openURL(url)
        }
    }

    private func openInstagram() {
        if let url = URL(string: "https://instagram.com/eventpassug") {
            openURL(url)
        }
    }

    private func openTwitter() {
        if let url = URL(string: "https://x.com/eventpassug") {
            openURL(url)
        }
    }

    private func openFacebook() {
        if let url = URL(string: "https://facebook.com/eventpassug") {
            openURL(url)
        }
    }

    private func callOrganizerHotline() {
        if let url = URL(string: "tel://+256700999999") {
            openURL(url)
        }
    }

    private func openOrganizerWhatsApp() {
        if let url = URL(string: "https://wa.me/256700888888") {
            openURL(url)
        }
    }

    private func callEmergencySupport() {
        if let url = URL(string: "tel://+256700111111") {
            openURL(url)
        }
    }

    // MARK: - Diagnostics

    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func getDeviceModel() -> String {
        UIDevice.current.model
    }

    private func getiOSVersion() -> String {
        UIDevice.current.systemVersion
    }

    private func getUserID() -> String {
        String(authService.currentUser?.id.uuidString.prefix(8) ?? "Unknown")
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DiagnosticRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(AppTypography.caption)
                .foregroundColor(.primary)
        }
    }
}

struct SocialButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(RoleConfig.attendeePrimary)
        }
    }
}

#Preview {
    NavigationView {
        SupportCenterView()
            .environmentObject(MockAuthRepository())
    }
}

//
//  OrganizerIdentityVerificationStep.swift
//  EventPassUG
//
//  Step 2: Identity verification for organizer onboarding
//

import SwiftUI

struct OrganizerIdentityVerificationStep: View {
    @EnvironmentObject var authService: MockAuthService
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var showVerificationView = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(RoleConfig.organizerPrimary)

                    Text("Verify Your Identity")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text("To protect our community, we require identity verification for all organizers.")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xl)

                // Verification status
                if isVerified {
                    verifiedStatusView
                } else {
                    unverifiedStatusView
                }

                // Why we verify
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Why do we verify?")
                        .font(AppTypography.headline)

                    VerificationReasonRow(icon: "shield.fill", text: "Protect attendees from fraud")
                    VerificationReasonRow(icon: "person.badge.shield.checkmark.fill", text: "Build trust in the community")
                    VerificationReasonRow(icon: "lock.shield.fill", text: "Secure payment processing")
                    VerificationReasonRow(icon: "checkmark.seal.fill", text: "Verified organizer badge")
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: AppSpacing.xl)

                // Navigation buttons
                VStack(spacing: AppSpacing.sm) {
                    Button(action: onNext) {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isVerified ? RoleConfig.organizerPrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .disabled(!isVerified)

                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                if !isVerified {
                    Text("Complete identity verification to continue")
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .sheet(isPresented: $showVerificationView) {
            NavigationView {
                NationalIDVerificationView()
                    .environmentObject(authService)
            }
        }
    }

    private var isVerified: Bool {
        authService.currentUser?.isVerified ?? false
    }

    @ViewBuilder
    private var verifiedStatusView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Identity Verified")
                .font(AppTypography.headline)
                .foregroundColor(.green)

            if let date = authService.currentUser?.verificationDate {
                Text("Verified on \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            if let docType = authService.currentUser?.verificationDocumentType {
                Text("Document: \(docType.displayName)")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(AppCornerRadius.medium)
        .padding(.horizontal, AppSpacing.md)
    }

    @ViewBuilder
    private var unverifiedStatusView: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Choose a verification document:")
                .font(AppTypography.headline)

            Button(action: { showVerificationView = true }) {
                HStack {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(RoleConfig.organizerPrimary)

                    VStack(alignment: .leading) {
                        Text("National ID or Passport")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text("Upload front and back images")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

struct VerificationReasonRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(RoleConfig.organizerPrimary)
                .frame(width: 24)

            Text(text)
                .font(AppTypography.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OrganizerIdentityVerificationStep(onNext: {}, onBack: {})
        .environmentObject(MockAuthService())
}

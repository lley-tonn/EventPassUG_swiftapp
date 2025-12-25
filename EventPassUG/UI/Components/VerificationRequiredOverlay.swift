//
//  VerificationRequiredOverlay.swift
//  EventPassUG
//
//  Overlay shown when organizer needs to complete verification
//

import SwiftUI

struct VerificationRequiredOverlay: View {
    @Binding var showingVerificationSheet: Bool

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Warning icon
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)

                VStack(spacing: AppSpacing.md) {
                    Text("Verification Required")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("To access organizer features and create events, you must first verify your identity using your National ID or Passport.")
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }

                VStack(spacing: AppSpacing.md) {
                    Text("Why verification?")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        verificationBenefit(icon: "shield.checkmark.fill", text: "Ensures community safety")
                        verificationBenefit(icon: "person.badge.shield.checkmark.fill", text: "Builds trust with attendees")
                        verificationBenefit(icon: "lock.shield.fill", text: "Protects against fraud")
                        verificationBenefit(icon: "checkmark.seal.fill", text: "Unlocks all organizer features")
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(AppCornerRadius.large)
                .padding(.horizontal, AppSpacing.lg)

                Spacer()

                // Verify Now Button
                Button(action: {
                    showingVerificationSheet = true
                    HapticFeedback.medium()
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Verify Now")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoleConfig.organizerPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(AppCornerRadius.medium)
                }
                .padding(.horizontal, AppSpacing.xl)

                Text("Verification typically takes less than 5 minutes")
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    @ViewBuilder
    private func verificationBenefit(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)

            Text(text)
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}

#Preview {
    VerificationRequiredOverlay(showingVerificationSheet: .constant(false))
}

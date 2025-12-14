//
//  SocialAuthButtons.swift
//  EventPassUG
//
//  Reusable social authentication buttons
//

import SwiftUI

struct SocialAuthButtons: View {
    let onGoogleTap: () -> Void
    let onAppleTap: () -> Void
    let isLoading: Bool

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Divider with "OR"
            HStack {
                VStack { Divider() }
                Text("OR")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                VStack { Divider() }
            }

            // Google Sign In
            Button(action: onGoogleTap) {
                HStack(spacing: AppSpacing.sm) {
                    GoogleLogoView()
                        .frame(width: 20, height: 20)

                    Text("Continue with Google")
                        .font(AppTypography.headline)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isLoading)

            // Apple Sign In
            Button(action: onAppleTap) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20))

                    Text("Continue with Apple")
                        .font(AppTypography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(AppCornerRadius.medium)
            }
            .disabled(isLoading)
        }
    }
}

struct PhoneAuthButton: View {
    let onPhoneTap: () -> Void
    let isLoading: Bool

    var body: some View {
        Button(action: onPhoneTap) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 20))

                Text("Continue with Phone")
                    .font(AppTypography.headline)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack {
        SocialAuthButtons(
            onGoogleTap: {},
            onAppleTap: {},
            isLoading: false
        )
        .padding()

        PhoneAuthButton(onPhoneTap: {}, isLoading: false)
            .padding()
    }
}

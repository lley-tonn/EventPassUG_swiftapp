//
//  TermsAndPrivacyView.swift
//  EventPassUG
//
//  Combined view for Terms and Privacy navigation
//

import SwiftUI

struct TermsAndPrivacyView: View {
    var body: some View {
        List {
            NavigationLink(destination: TermsOfUseView()) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24))
                        .foregroundColor(RoleConfig.attendeePrimary)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Terms of Use")
                            .font(AppTypography.body)
                            .foregroundColor(.primary)

                        Text("Rules and conditions for using the app")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            NavigationLink(destination: PrivacyPolicyView()) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy Policy")
                            .font(AppTypography.body)
                            .foregroundColor(.primary)

                        Text("How we collect, use, and protect your data")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Terms & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        TermsAndPrivacyView()
    }
}

//
//  SecurityInfoView.swift
//  EventPassUG
//
//  Security and verification information
//

import SwiftUI

struct SecurityInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Your Security Matters")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text("We take your privacy and security seriously")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, AppSpacing.md)

                // Why ID Verification
                SecuritySection(
                    icon: "person.badge.shield.checkmark.fill",
                    title: "Why ID Verification?",
                    content: [
                        "Ensures community safety by verifying organizer identities",
                        "Prevents fraudulent events and protects attendees",
                        "Builds trust within the EventPass UG community",
                        "Required for organizers, optional for attendees",
                        "Verified accounts receive a badge on their profile"
                    ]
                )

                // How to Upload Documents
                SecuritySection(
                    icon: "doc.badge.arrow.up.fill",
                    title: "How to Upload Documents",
                    content: [
                        "Go to Profile > Account > Verify Identity",
                        "Choose National ID or Passport",
                        "Take clear photos of front (and back for National ID)",
                        "Ensure all text is readable and well-lit",
                        "Submit for review (usually approved within 24 hours)"
                    ]
                )

                // Data Storage
                SecuritySection(
                    icon: "externaldrive.fill.badge.checkmark",
                    title: "How Your Data is Stored",
                    content: [
                        "All data is encrypted using AES-256 encryption",
                        "Stored on secure servers with limited access",
                        "ID documents are only used for verification purposes",
                        "We never share your personal data with third parties",
                        "Compliant with Uganda Data Protection regulations"
                    ]
                )

                // Data Retention
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label("Data Retention", systemImage: "clock.fill")
                        .font(AppTypography.headline)
                        .foregroundColor(.blue)

                    Text("Your verification documents are securely stored for the duration of your account. You can request deletion at any time by contacting support. Account data is retained for 3 years after closure for legal compliance.")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Security & Verification")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SecuritySection: View {
    let icon: String
    let title: String
    let content: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(title, systemImage: icon)
                .font(AppTypography.headline)
                .foregroundColor(RoleConfig.attendeePrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(content, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.top, 2)

                        Text(item)
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }
}

#Preview {
    NavigationView {
        SecurityInfoView()
    }
}

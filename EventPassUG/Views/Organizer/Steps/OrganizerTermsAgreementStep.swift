//
//  OrganizerTermsAgreementStep.swift
//  EventPassUG
//
//  Step 5: Terms agreement for organizer onboarding
//

import SwiftUI

struct OrganizerTermsAgreementStep: View {
    @Binding var profile: OrganizerProfile
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var agreedToTerms = false
    @State private var isSubmitting = false

    private let termsVersion = "1.0"

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(RoleConfig.organizerPrimary)

                    Text("Organizer Agreement")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text("Please review and agree to the organizer terms before completing your registration.")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xl)

                // Terms sections
                VStack(spacing: AppSpacing.md) {
                    TermsSectionView(
                        icon: "arrow.uturn.backward.circle.fill",
                        title: "Refund Policy",
                        content: """
                        • You must honor refund requests according to your stated event policy
                        • Cancelled events require full refunds within 7-14 days
                        • Postponed events: tickets remain valid for new date
                        • EventPass UG may deduct processing fees from refunds
                        • False refund claims may result in account suspension
                        """
                    )

                    TermsSectionView(
                        icon: "shield.fill",
                        title: "Fraud Prevention",
                        content: """
                        • All event information must be accurate and truthful
                        • Fake events or misleading listings are prohibited
                        • Identity verification documents must be authentic
                        • Suspicious activity will be investigated and reported
                        • Fraudulent organizers face permanent bans and legal action
                        """
                    )

                    TermsSectionView(
                        icon: "briefcase.fill",
                        title: "Organizer Responsibilities",
                        content: """
                        • Provide accurate event details and updates
                        • Maintain appropriate insurance and permits
                        • Ensure venue safety and compliance with local laws
                        • Communicate changes promptly to ticket holders
                        • Respond to attendee inquiries within 48 hours
                        • Deliver the event as advertised
                        """
                    )

                    TermsSectionView(
                        icon: "exclamationmark.triangle.fill",
                        title: "Liability Limitations",
                        content: """
                        • EventPass UG acts as an intermediary only
                        • You are solely responsible for event execution
                        • EventPass UG is not liable for event cancellations
                        • Attendee safety is your responsibility
                        • EventPass UG's maximum liability is limited to platform fees collected
                        • You indemnify EventPass UG against claims from your events
                        """
                    )

                    TermsSectionView(
                        icon: "dollarsign.circle.fill",
                        title: "Financial Terms",
                        content: """
                        • EventPass UG charges a service fee of 5% per ticket
                        • Payouts are processed 3-5 business days after event ends
                        • You are responsible for all applicable taxes
                        • Chargebacks may be deducted from future payouts
                        • Minimum payout threshold: UGX 10,000
                        """
                    )
                }
                .padding(.horizontal, AppSpacing.md)

                // Agreement checkbox
                VStack(spacing: AppSpacing.md) {
                    Button(action: { agreedToTerms.toggle() }) {
                        HStack(alignment: .top, spacing: AppSpacing.md) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .font(.system(size: 24))
                                .foregroundColor(agreedToTerms ? RoleConfig.organizerPrimary : .gray)

                            Text("I have read and agree to the Organizer Terms of Service, including all responsibilities, policies, and limitations outlined above.")
                                .font(AppTypography.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(agreedToTerms ? RoleConfig.organizerPrimary.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(agreedToTerms ? RoleConfig.organizerPrimary : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Version \(termsVersion) • Last updated: November 2024")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: AppSpacing.xl)

                // Navigation buttons
                VStack(spacing: AppSpacing.sm) {
                    Button(action: submitAgreement) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Complete Registration")
                                    .fontWeight(.semibold)
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(agreedToTerms && !isSubmitting ? RoleConfig.organizerPrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .disabled(!agreedToTerms || isSubmitting)

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
                    .disabled(isSubmitting)
                }
                .padding(.horizontal, AppSpacing.md)

                if !agreedToTerms {
                    Text("You must agree to the terms to continue")
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
    }

    private func submitAgreement() {
        isSubmitting = true
        profile.agreedToTermsDate = Date()
        profile.termsVersion = termsVersion

        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
            onComplete()
        }
    }
}

struct TermsSectionView: View {
    let icon: String
    let title: String
    let content: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(RoleConfig.organizerPrimary)
                        .frame(width: 30)

                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(content)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

            Divider()
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }
}

#Preview {
    OrganizerTermsAgreementStep(
        profile: .constant(OrganizerProfile()),
        onComplete: {},
        onBack: {}
    )
}

//
//  TermsOfUseView.swift
//  EventPassUG
//
//  Terms of use and conditions
//

import SwiftUI

struct TermsOfUseView: View {
    @State private var expandedSections: Set<String> = []

    let sections: [(String, String, String)] = [
        ("App Purpose & Eligibility", "doc.text.fill", """
EventPass UG is a mobile platform connecting event organizers with attendees in Uganda. By using this app, you confirm:
- You are at least 18 years old or have parental consent
- You have the legal capacity to enter into these terms
- You will provide accurate and truthful information
- You will not use the app for illegal purposes
"""),
        ("Account Rules", "person.circle.fill", """
When creating and maintaining your account:
- You are responsible for maintaining account security
- You must provide accurate personal information
- One account per person is permitted
- You must notify us of unauthorized access immediately
- Sharing account credentials is prohibited
- False identity information may result in account termination
"""),
        ("Ticket Purchase Rules", "ticket.fill", """
When purchasing tickets through EventPass UG:
- All sales are final unless otherwise stated by the organizer
- Tickets are non-transferable unless explicitly permitted
- You may not resell tickets for profit without authorization
- Digital tickets must be presented in their original form
- Screenshots or copies may be rejected at entry
- Prices include applicable fees displayed at checkout
"""),
        ("Refund & Cancellation", "arrow.uturn.backward.circle.fill", """
Refund policies are determined by event organizers:
- Check individual event policies before purchase
- Cancelled events: Full refunds processed within 7-14 days
- Postponed events: Tickets remain valid for new date
- Requests must be submitted through the app
- EventPass UG is not liable for organizer refund decisions
- Payment processing fees may be non-refundable
"""),
        ("Organizer Responsibilities", "briefcase.fill", """
Event organizers agree to:
- Provide accurate event information
- Honor ticket sales and fulfill event promises
- Communicate changes promptly to ticket holders
- Maintain appropriate insurance and permits
- Comply with local laws and regulations
- Handle refunds according to stated policies
- Complete ID verification before creating events
"""),
        ("Prohibited Activities", "xmark.octagon.fill", """
The following are strictly prohibited:
- Fraudulent ticket sales or purchases
- Creating fake events or misleading listings
- Harassment of other users or organizers
- Attempting to hack or exploit the platform
- Using bots for ticket purchases
- Sharing copyrighted content without permission
- Money laundering or illegal financial activities
"""),
        ("Intellectual Property", "c.circle.fill", """
All content within EventPass UG including:
- Logos, trademarks, and branding
- App design and user interface
- Software code and algorithms
- Marketing materials and documentation
belongs to EventPass UG or its licensors. Users may not copy, modify, or distribute any proprietary content without written permission.
"""),
        ("Liability Limitations", "exclamationmark.triangle.fill", """
EventPass UG:
- Acts as an intermediary between organizers and attendees
- Is not responsible for event quality or execution
- Does not guarantee event occurrence
- Is not liable for injuries or losses at events
- Maximum liability limited to ticket purchase price
- Not responsible for third-party payment processing issues
"""),
        ("Account Termination", "trash.fill", """
We reserve the right to terminate accounts:
- For violation of these terms
- For fraudulent or suspicious activity
- Upon user request
- For extended inactivity (3+ years)
Terminated users may lose access to purchased tickets. Legal obligations survive termination.
"""),
        ("Governing Law", "building.columns.fill", """
These terms are governed by the laws of Uganda:
- Disputes resolved in Ugandan courts
- Subject to Data Protection Act of Uganda
- Consumer protection laws apply
- Electronic transactions are legally binding
Last updated: November 2024
Contact: legal@eventpassug.com
""")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                Text("Please read these terms carefully before using EventPass UG.")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppSpacing.md)

                // Sections
                ForEach(sections, id: \.0) { title, icon, content in
                    ExpandableLegalSection(
                        title: title,
                        icon: icon,
                        content: content,
                        isExpanded: expandedSections.contains(title),
                        onToggle: {
                            if expandedSections.contains(title) {
                                expandedSections.remove(title)
                            } else {
                                expandedSections.insert(title)
                            }
                        }
                    )
                }

                // Footer
                Text("By using EventPass UG, you agree to these terms.")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.lg)
            }
            .padding(.vertical, AppSpacing.md)
        }
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExpandableLegalSection: View {
    let title: String
    let icon: String
    let content: String
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(RoleConfig.attendeePrimary)
                        .frame(width: 30)

                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(content)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
                    .padding(.leading, 30 + AppSpacing.md)
            }

            Divider()
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

#Preview {
    NavigationView {
        TermsOfUseView()
    }
}

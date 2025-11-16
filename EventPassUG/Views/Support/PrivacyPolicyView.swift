//
//  PrivacyPolicyView.swift
//  EventPassUG
//
//  Privacy policy and data handling information
//

import SwiftUI

struct PrivacyPolicyView: View {
    @State private var expandedSections: Set<String> = []

    let sections: [(String, String, String)] = [
        ("Data We Collect", "folder.fill", """
We collect the following information:
- **Account Data**: Name, email, phone number
- **Profile Information**: Profile photo (optional), role preferences
- **Verification Data**: National ID or Passport (for organizers)
- **Payment Info**: Last 4 digits of card, mobile money number (we don't store full card details)
- **Usage Data**: App interactions, feature usage
- **Device Info**: Model, OS version, app version
- **Location**: Only when you allow, for finding nearby events
- **Event Preferences**: Your favorite categories and interests
"""),
        ("How We Use Your Data", "gearshape.fill", """
Your data is used to:
- Process ticket purchases and payments
- Send ticket confirmations and event reminders
- Personalize event recommendations
- Verify organizer identities for community safety
- Improve app features and user experience
- Communicate important updates and changes
- Resolve support issues
- Comply with legal requirements
- Prevent fraud and abuse
"""),
        ("Data Sharing", "person.2.fill", """
We may share data with:
- **Payment Processors**: MTN MoMo, Airtel Money, card processors for payments
- **Event Organizers**: Your name and ticket info for entry validation
- **Service Providers**: Cloud hosting, analytics (anonymized)
- **Legal Authorities**: When required by law

We **NEVER**:
- Sell your personal data to third parties
- Share your ID documents with organizers
- Use your data for unauthorized purposes
"""),
        ("Data Storage & Security", "lock.fill", """
Your data protection:
- All data encrypted using AES-256 standard
- Secure servers with restricted access
- Regular security audits and updates
- Multi-factor authentication support
- Automatic session timeouts
- Secure HTTPS connections
- Compliance with industry standards
- Data centers located in secure facilities
"""),
        ("Your Rights", "hand.raised.fill", """
You have the right to:
- **Access**: Request a copy of your data
- **Correction**: Update inaccurate information
- **Deletion**: Request account and data removal
- **Portability**: Export your data
- **Withdraw Consent**: Opt out of marketing
- **Object**: Challenge data processing decisions
- **Restrict**: Limit how we use your data

To exercise these rights, contact privacy@eventpassug.com
"""),
        ("Cookies & Tracking", "chart.bar.fill", """
We use:
- **Essential Cookies**: Required for app functionality
- **Analytics**: Anonymous usage statistics
- **Preferences**: Remember your settings

You can:
- Disable analytics in app settings
- Manage preferences anytime
- Clear local data through device settings

We don't use third-party advertising trackers.
"""),
        ("Data Retention", "clock.fill", """
How long we keep your data:
- **Active Accounts**: Data retained while account is active
- **Tickets**: Kept for 60 days after event ends
- **Closed Accounts**: Core data retained 3 years for legal compliance
- **Verification Documents**: Stored securely while account is active
- **Payment Records**: 7 years for financial regulations
- **Support Tickets**: 2 years after resolution

You can request earlier deletion where legally permitted.
"""),
        ("Contact Information", "envelope.fill", """
For privacy-related inquiries:

**Privacy Officer**
Email: privacy@eventpassug.com

**General Support**
Email: support@eventpassug.com
Website: eventpassug.com/privacy

**Data Protection Authority**
National Information Technology Authority - Uganda (NITA-U)

Last updated: November 2024
Policy version: 1.0
""")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Your privacy is important to us. This policy explains how we collect, use, and protect your personal information.")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                }
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
                VStack(spacing: AppSpacing.sm) {
                    Text("By using EventPass UG, you consent to this privacy policy.")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    Link(destination: URL(string: "https://eventpassug.com/privacy")!) {
                        Text("View Full Policy Online")
                            .font(AppTypography.caption)
                            .foregroundColor(RoleConfig.attendeePrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, AppSpacing.lg)
            }
            .padding(.vertical, AppSpacing.md)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
}

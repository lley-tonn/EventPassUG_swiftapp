//
//  HelpCenterView.swift
//  EventPassUG
//
//  Main help center with categorized support content
//

import SwiftUI

struct HelpCenterView: View {
    @EnvironmentObject var authService: MockAuthRepository

    var body: some View {
        List {
            // FAQs Section
            Section {
                NavigationLink(destination: FAQSectionView()) {
                    HelpCenterRow(
                        icon: "questionmark.circle.fill",
                        title: "FAQs",
                        subtitle: "Common questions answered"
                    )
                }
            }

            // Troubleshooting Section
            Section {
                NavigationLink(destination: TroubleshootingView()) {
                    HelpCenterRow(
                        icon: "wrench.and.screwdriver.fill",
                        title: "Troubleshooting",
                        subtitle: "Fix common issues"
                    )
                }
            }

            // App Guides Section
            Section {
                NavigationLink(destination: AppGuidesView()) {
                    HelpCenterRow(
                        icon: "book.fill",
                        title: "App Guides",
                        subtitle: "Learn how to use features"
                    )
                }
            }

            // Security & Verification
            Section {
                NavigationLink(destination: SecurityInfoView()) {
                    HelpCenterRow(
                        icon: "lock.shield.fill",
                        title: "Security & Verification",
                        subtitle: "Data protection & ID verification"
                    )
                }
            }

            // Feature Explanations
            Section {
                NavigationLink(destination: FeatureExplanationsView()) {
                    HelpCenterRow(
                        icon: "star.fill",
                        title: "Feature Explanations",
                        subtitle: "Understand app capabilities"
                    )
                }
            }

            // Quick Links
            Section {
                NavigationLink(destination: SupportCenterView().environmentObject(authService)) {
                    HelpCenterRow(
                        icon: "headphones",
                        title: "Contact Support",
                        subtitle: "Get direct help"
                    )
                }
            } header: {
                Text("Need More Help?")
            }
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpCenterRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(RoleConfig.attendeePrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.headline)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        HelpCenterView()
            .environmentObject(MockAuthRepository())
    }
}

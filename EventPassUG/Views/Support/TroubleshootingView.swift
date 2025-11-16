//
//  TroubleshootingView.swift
//  EventPassUG
//
//  Step-by-step troubleshooting guides
//

import SwiftUI

struct TroubleshootingView: View {
    let guides = TroubleshootingGuide.samples

    var body: some View {
        List(guides) { guide in
            NavigationLink(destination: TroubleshootingDetailView(guide: guide)) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: guide.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(guide.title)
                            .font(AppTypography.body)
                            .fontWeight(.medium)

                        Text("\(guide.steps.count) steps")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Troubleshooting")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TroubleshootingDetailView: View {
    let guide: TroubleshootingGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                HStack {
                    Image(systemName: guide.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text(guide.title)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                }
                .padding(.bottom, AppSpacing.md)

                // Steps
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: AppSpacing.md) {
                            Text("\(index + 1)")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(RoleConfig.attendeePrimary))

                            Text(step)
                                .font(AppTypography.body)
                        }
                    }
                }

                // Additional Info
                if let info = guide.additionalInfo {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Additional Info", systemImage: "info.circle.fill")
                            .font(AppTypography.headline)
                            .foregroundColor(.blue)

                        Text(info)
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        TroubleshootingView()
    }
}

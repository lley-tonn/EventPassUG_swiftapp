//
//  AppGuidesView.swift
//  EventPassUG
//
//  Step-by-step app tutorials
//

import SwiftUI

struct AppGuidesView: View {
    let guides = AppGuide.samples

    var body: some View {
        List(guides) { guide in
            NavigationLink(destination: AppGuideDetailView(guide: guide)) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: guide.icon)
                        .font(.system(size: 28))
                        .foregroundColor(RoleConfig.attendeePrimary)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(guide.title)
                            .font(AppTypography.body)
                            .fontWeight(.medium)

                        Text(guide.description)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("App Guides")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppGuideDetailView: View {
    let guide: AppGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: guide.icon)
                        .font(.system(size: 60))
                        .foregroundColor(RoleConfig.attendeePrimary)

                    Text(guide.title)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(guide.description)
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, AppSpacing.md)

                // Steps
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(guide.steps) { step in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Text("Step \(step.stepNumber)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoleConfig.attendeePrimary)
                                    .cornerRadius(AppCornerRadius.small)

                                Text(step.title)
                                    .font(AppTypography.headline)
                            }

                            Text(step.description)
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)

                            if step.imageName != nil {
                                // Placeholder for GIF/Image
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 150)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.gray)
                                            Text("Tutorial Image")
                                                .font(AppTypography.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)
                    }
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
        AppGuidesView()
    }
}

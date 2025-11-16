//
//  FeatureExplanationsView.swift
//  EventPassUG
//
//  Explanations of app features
//

import SwiftUI

struct FeatureExplanationsView: View {
    let features = FeatureExplanation.samples

    var body: some View {
        List(features) { feature in
            NavigationLink(destination: FeatureDetailView(feature: feature)) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 28))
                        .foregroundColor(RoleConfig.attendeePrimary)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(AppTypography.body)
                            .fontWeight(.medium)

                        Text("\(feature.benefits.count) benefits")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Features")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureDetailView: View {
    let feature: FeatureExplanation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 60))
                        .foregroundColor(RoleConfig.attendeePrimary)

                    Text(feature.title)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text(feature.description)
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                // Benefits
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Benefits")
                        .font(AppTypography.headline)

                    ForEach(feature.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)

                            Text(benefit)
                                .font(AppTypography.body)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle(feature.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        FeatureExplanationsView()
    }
}

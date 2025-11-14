//
//  LoadingView.swift
//  EventPassUG
//
//  Loading indicator with skeleton screens
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Loading...")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

struct SkeletonEventCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster skeleton
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 180)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.4), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: isAnimating ? 400 : -400)
                )
                .clipped()

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)

                // Subtitle skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 16)
            }
            .padding(AppSpacing.md)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    VStack {
        LoadingView()
            .frame(height: 200)

        ScrollView {
            VStack(spacing: AppSpacing.md) {
                SkeletonEventCard()
                SkeletonEventCard()
            }
            .padding()
        }
    }
}

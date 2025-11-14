//
//  AnimatedLikeButton.swift
//  EventPassUG
//
//  Animated heart button with scale and color fill animation
//

import SwiftUI

struct AnimatedLikeButton: View {
    @Binding var isLiked: Bool
    let onTap: () -> Void

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()

            guard !reduceMotion else { return }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .foregroundColor(isLiked ? .red : .gray)
                .font(.system(size: 22))
                .scaleEffect(isAnimating ? 1.3 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLiked ? "Unlike" : "Like")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isLiked = false

        var body: some View {
            VStack(spacing: 30) {
                AnimatedLikeButton(isLiked: $isLiked) {
                    isLiked.toggle()
                }

                Text(isLiked ? "Liked ❤️" : "Not liked")
                    .font(.caption)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

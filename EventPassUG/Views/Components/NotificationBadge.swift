//
//  NotificationBadge.swift
//  EventPassUG
//
//  Animated notification badge with bounce effect
//

import SwiftUI

struct NotificationBadge: View {
    let count: Int
    @State private var isBouncing = false
    @State private var previousCount = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.system(size: 24))
                .foregroundColor(.primary)

            if count > 0 {
                Text("\(min(count, 99))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
                    .scaleEffect(isBouncing ? 1.2 : 1.0)
                    .accessibilityLabel("\(count) unread notifications")
            }
        }
        .onChange(of: count) { newValue in
            guard newValue > previousCount, !reduceMotion else {
                previousCount = newValue
                return
            }

            // Bounce animation when count increases
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isBouncing = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isBouncing = false
                }
            }

            previousCount = newValue
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var count = 0

        var body: some View {
            VStack(spacing: 30) {
                NotificationBadge(count: count)

                Button("Add Notification") {
                    count += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    count = 0
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

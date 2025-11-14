//
//  PulsingDot.swift
//  EventPassUG
//
//  Animated pulsing dot for "Happening now" indicator
//

import SwiftUI

struct PulsingDot: View {
    let color: Color
    let size: CGFloat

    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(color: Color = RoleConfig.happeningNow, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer pulsing halo
            if !reduceMotion {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * 2.5, height: size * 2.5)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
            }

            // Inner solid dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
        .accessibilityLabel("Live event indicator")
    }
}

#Preview {
    VStack(spacing: 20) {
        PulsingDot()
        PulsingDot(color: .red, size: 12)
        PulsingDot(color: .blue, size: 16)
    }
    .padding()
}

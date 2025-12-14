//
//  GoogleLogoView.swift
//  EventPassUG
//
//  Google "G" logo for authentication buttons
//

import SwiftUI

struct GoogleLogoView: View {
    var body: some View {
        // Multicolored Google "G" logo
        // Using official Google brand colors
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let lineWidth = size * 0.15

            ZStack {
                // Blue arc (top-right)
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(Color(red: 66/255, green: 133/255, blue: 244/255), lineWidth: lineWidth)
                    .rotationEffect(.degrees(-45))

                // Green arc (bottom-right)
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(Color(red: 52/255, green: 168/255, blue: 83/255), lineWidth: lineWidth)
                    .rotationEffect(.degrees(45))

                // Yellow arc (bottom-left)
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(Color(red: 251/255, green: 188/255, blue: 5/255), lineWidth: lineWidth)
                    .rotationEffect(.degrees(135))

                // Red arc (top-left)
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(Color(red: 234/255, green: 67/255, blue: 53/255), lineWidth: lineWidth)
                    .rotationEffect(.degrees(225))

                // Blue horizontal bar (the "crossbar" of the G)
                Rectangle()
                    .fill(Color(red: 66/255, green: 133/255, blue: 244/255))
                    .frame(width: size * 0.55, height: lineWidth)
                    .offset(x: size * 0.05)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// Alternative: Simple text-based Google "G" with colors
struct GoogleLogoTextView: View {
    var body: some View {
        Text("G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 66/255, green: 133/255, blue: 244/255),  // Blue
                        Color(red: 234/255, green: 67/255, blue: 53/255),   // Red
                        Color(red: 251/255, green: 188/255, blue: 5/255),   // Yellow
                        Color(red: 52/255, green: 168/255, blue: 83/255)    // Green
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        GoogleLogoView()
            .frame(width: 24, height: 24)

        GoogleLogoView()
            .frame(width: 40, height: 40)

        GoogleLogoView()
            .frame(width: 60, height: 60)

        GoogleLogoTextView()
            .frame(width: 40, height: 40)
    }
    .padding()
}

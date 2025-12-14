//
//  DeviceOrientation.swift
//  EventPassUG
//
//  Utilities for responsive design and orientation handling
//

import SwiftUI

enum DeviceType {
    case phone
    case pad
}

struct DeviceInfo {
    static var isLandscape: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return false
        }
        return window.bounds.width > window.bounds.height
    }

    static var deviceType: DeviceType {
        UIDevice.current.userInterfaceIdiom == .pad ? .pad : .phone
    }

    static var screenWidth: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIScreen.main.bounds.width
        }
        return window.bounds.width
    }

    static var screenHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIScreen.main.bounds.height
        }
        return window.bounds.height
    }
}

struct AdaptiveStack<Content: View>: View {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    @ViewBuilder let content: () -> Content

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape - use HStack
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content()
                }
            } else {
                // Portrait - use VStack
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content()
                }
            }
        }
    }
}

// View modifier for responsive padding
struct ResponsivePadding: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            content
                .padding(.horizontal, isLandscape ? AppSpacing.xl : AppSpacing.md)
        }
    }
}

extension View {
    func responsivePadding() -> some View {
        modifier(ResponsivePadding())
    }

    func adaptiveColumns(_ count: Int, spacing: CGFloat = AppSpacing.md) -> some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: isLandscape ? count * 2 : count)

            LazyVGrid(columns: columns, spacing: spacing) {
                self
            }
        }
    }
}

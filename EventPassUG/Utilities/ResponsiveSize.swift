//
//  ResponsiveSize.swift
//  EventPassUG
//
//  Utilities for device-aware responsive sizing
//

import SwiftUI

struct ScreenSize {
    static var width: CGFloat {
        UIScreen.main.bounds.width
    }

    static var height: CGFloat {
        UIScreen.main.bounds.height
    }

    // Device categories
    enum DeviceSize {
        case small      // iPhone SE, iPhone 12 mini (width <= 375)
        case regular    // iPhone 12, 13, 14, 15 (width <= 390)
        case large      // iPhone Plus, Pro Max (width <= 430)
        case iPad       // iPad (width > 430)

        static var current: DeviceSize {
            let width = UIScreen.main.bounds.width
            switch width {
            case ...375:
                return .small
            case 376...390:
                return .regular
            case 391...430:
                return .large
            default:
                return .iPad
            }
        }
    }

    // Check device type
    static var isSmallDevice: Bool {
        width <= 375
    }

    static var isRegularDevice: Bool {
        width > 375 && width <= 390
    }

    static var isLargeDevice: Bool {
        width > 390 && width <= 430
    }

    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

// Responsive spacing based on device size
struct ResponsiveSpacing {
    static func xs(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSpacing(base: 4, context: context)
    }

    static func sm(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSpacing(base: 8, context: context)
    }

    static func md(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSpacing(base: 16, context: context)
    }

    static func lg(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSpacing(base: 24, context: context)
    }

    static func xl(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSpacing(base: 32, context: context)
    }

    static func xxl(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSpacing(base: 48, context: context)
    }

    private static func adaptiveSpacing(base: CGFloat, context: GeometryProxy?) -> CGFloat {
        let _ = context?.size.width ?? ScreenSize.width

        switch ScreenSize.DeviceSize.current {
        case .small:
            return base * 0.85  // 15% smaller on small devices
        case .regular:
            return base
        case .large:
            return base * 1.1   // 10% larger on large devices
        case .iPad:
            return base * 1.3   // 30% larger on iPad
        }
    }
}

// Responsive font sizes
struct ResponsiveFontSize {
    static func largeTitle(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 34, context: context)
    }

    static func title1(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 28, context: context)
    }

    static func title2(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 22, context: context)
    }

    static func title3(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 20, context: context)
    }

    static func headline(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 17, context: context)
    }

    static func body(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 17, context: context)
    }

    static func callout(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 16, context: context)
    }

    static func subheadline(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 15, context: context)
    }

    static func footnote(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 13, context: context)
    }

    static func caption(_ context: GeometryProxy? = nil) -> CGFloat {
        adaptiveSize(base: 12, context: context)
    }

    private static func adaptiveSize(base: CGFloat, context: GeometryProxy?) -> CGFloat {
        let _ = context?.size.width ?? ScreenSize.width

        switch ScreenSize.DeviceSize.current {
        case .small:
            return max(base * 0.9, 12)  // 10% smaller, minimum 12pt
        case .regular:
            return base
        case .large:
            return base * 1.05  // 5% larger
        case .iPad:
            return base * 1.15  // 15% larger on iPad
        }
    }
}

// Responsive image/card heights
struct ResponsiveHeight {
    static func eventCard(_ context: GeometryProxy? = nil) -> CGFloat {
        let _ = context?.size.width ?? ScreenSize.width

        switch ScreenSize.DeviceSize.current {
        case .small:
            return 160
        case .regular:
            return 180
        case .large:
            return 200
        case .iPad:
            return 240
        }
    }

    static func posterImage(isLandscape: Bool = false, context: GeometryProxy? = nil) -> CGFloat {
        if isLandscape {
            switch ScreenSize.DeviceSize.current {
            case .small:
                return 150
            case .regular:
                return 180
            case .large, .iPad:
                return 200
            }
        } else {
            switch ScreenSize.DeviceSize.current {
            case .small:
                return 220
            case .regular:
                return 260
            case .large:
                return 280
            case .iPad:
                return 350
            }
        }
    }

    static func buttonHeight(_ context: GeometryProxy? = nil) -> CGFloat {
        switch ScreenSize.DeviceSize.current {
        case .small:
            return 44  // Minimum touch target
        case .regular:
            return 50
        case .large:
            return 54
        case .iPad:
            return 60
        }
    }
}

// Responsive grid columns
struct ResponsiveGrid {
    static func columns(isLandscape: Bool = false, baseColumns: Int = 1) -> Int {
        if ScreenSize.isPad {
            return isLandscape ? baseColumns * 3 : baseColumns * 2
        } else if isLandscape {
            return baseColumns * 2
        } else {
            return baseColumns
        }
    }

    static func gridItems(isLandscape: Bool = false, baseColumns: Int = 1, spacing: CGFloat = AppSpacing.md) -> [GridItem] {
        let cols = columns(isLandscape: isLandscape, baseColumns: baseColumns)
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: cols)
    }
}

// View extension for responsive sizing
extension View {
    func responsiveFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        GeometryReader { geometry in
            let scale: CGFloat = {
                switch ScreenSize.DeviceSize.current {
                case .small: return 0.9
                case .regular: return 1.0
                case .large: return 1.05
                case .iPad: return 1.2
                }
            }()

            self.frame(
                width: width.map { $0 * scale },
                height: height.map { $0 * scale }
            )
        }
    }

    func responsivePadding(_ edges: Edge.Set = .all, geometry: GeometryProxy? = nil) -> some View {
        self.padding(edges, ResponsiveSpacing.md(geometry))
    }

    func scaledToFit(minScale: CGFloat = 0.5, idealScale: CGFloat = 1.0) -> some View {
        self.minimumScaleFactor(minScale)
            .lineLimit(1)
    }
}

//
//  ScrollHelpers.swift
//  EventPassUG
//
//  Scroll offset tracking and collapsible header utilities
//

import SwiftUI

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Offset Reader

struct ScrollOffsetReader<Content: View>: View {
    let content: Content
    let onOffsetChange: (CGFloat) -> Void

    init(@ViewBuilder content: () -> Content, onOffsetChange: @escaping (CGFloat) -> Void) {
        self.content = content()
        self.onOffsetChange = onOffsetChange
    }

    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scrollView")).minY
                    )
            }
            .frame(height: 0)

            content
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            onOffsetChange(value)
        }
    }
}

// MARK: - Collapsible Header View

struct CollapsibleHeader<Content: View>: View {
    let title: String
    let scrollOffset: CGFloat
    let content: Content

    init(title: String, scrollOffset: CGFloat, @ViewBuilder content: () -> Content) {
        self.title = title
        self.scrollOffset = scrollOffset
        self.content = content()
    }

    private var progress: CGFloat {
        let threshold: CGFloat = 60
        let progress = max(0, min(1, -scrollOffset / threshold))
        return progress
    }

    var body: some View {
        GeometryReader { geometry in
            let minHeight: CGFloat = 44
            let maxHeight: CGFloat = min(max(geometry.size.width * 0.35, 120), 160)
            let currentHeight = maxHeight - (maxHeight - minHeight) * progress
            let titleOpacity = 1 - progress
            let navTitleOpacity = progress

            VStack(spacing: 0) {
                // Large title area (collapses)
                ZStack {
                    Color(UIColor.systemBackground)

                    VStack(spacing: max(8, geometry.size.width * 0.03)) {
                        Spacer()

                        // Custom content (shown when expanded)
                        content
                            .opacity(titleOpacity)
                            .scaleEffect(1 - (progress * 0.1))

                        Spacer()
                    }
                    .padding(.horizontal, max(12, geometry.size.width * 0.04))
                }
                .frame(height: currentHeight)

                Divider()
            }
            .overlay(
                // Navigation title (appears when collapsed)
                HStack {
                    Text(title)
                        .font(AppTypography.headline)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                        .opacity(navTitleOpacity)
                    Spacer()
                }
                .padding(.horizontal, max(12, geometry.size.width * 0.04))
                .frame(height: minHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
            )
        }
        .frame(height: min(max(UIScreen.main.bounds.width * 0.35, 120), 160))
    }
}

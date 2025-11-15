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

    private let minHeight: CGFloat = 44
    private let maxHeight: CGFloat = 140

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

    private var currentHeight: CGFloat {
        maxHeight - (maxHeight - minHeight) * progress
    }

    private var titleOpacity: CGFloat {
        1 - progress
    }

    private var navTitleOpacity: CGFloat {
        progress
    }

    var body: some View {
        VStack(spacing: 0) {
            // Large title area (collapses)
            ZStack {
                Color(UIColor.systemBackground)

                VStack(spacing: AppSpacing.md) {
                    Spacer()

                    // Custom content (shown when expanded)
                    content
                        .opacity(titleOpacity)
                        .scaleEffect(1 - (progress * 0.1))

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
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
                    .opacity(navTitleOpacity)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: minHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
        )
    }
}

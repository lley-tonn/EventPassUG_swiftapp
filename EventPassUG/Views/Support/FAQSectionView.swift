//
//  FAQSectionView.swift
//  EventPassUG
//
//  Expandable FAQ categories
//

import SwiftUI

struct FAQSectionView: View {
    @State private var expandedCategories: Set<UUID> = []
    @State private var expandedItems: Set<UUID> = []
    @State private var searchText = ""

    let categories = FAQCategory.samples

    var filteredCategories: [FAQCategory] {
        if searchText.isEmpty {
            return categories
        }
        return categories.compactMap { category in
            let filteredItems = category.items.filter {
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }
            if filteredItems.isEmpty { return nil }
            return FAQCategory(title: category.title, icon: category.icon, items: filteredItems)
        }
    }

    var body: some View {
        List {
            ForEach(filteredCategories) { category in
                Section {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCategories.contains(category.id) },
                            set: { if $0 { expandedCategories.insert(category.id) } else { expandedCategories.remove(category.id) } }
                        )
                    ) {
                        ForEach(category.items) { item in
                            FAQItemView(
                                item: item,
                                isExpanded: expandedItems.contains(item.id),
                                onToggle: {
                                    if expandedItems.contains(item.id) {
                                        expandedItems.remove(item.id)
                                    } else {
                                        expandedItems.insert(item.id)
                                    }
                                }
                            )
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(RoleConfig.attendeePrimary)
                            Text(category.title)
                                .font(AppTypography.headline)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search FAQs")
        .navigationTitle("FAQs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button(action: onToggle) {
                HStack {
                    Text(item.question)
                        .font(AppTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        FAQSectionView()
    }
}

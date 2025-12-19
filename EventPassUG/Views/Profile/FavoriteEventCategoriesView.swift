//
//  FavoriteEventCategoriesView.swift
//  EventPassUG
//
//  View for selecting favorite event categories (onboarding and settings)
//  Now renamed to "Interests" in Settings for better UX
//

import SwiftUI

struct FavoriteEventCategoriesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService

    @State private var selectedCategories: Set<String> = []
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var hasChanges = false

    let isOnboarding: Bool
    var onComplete: (() -> Void)?

    init(isOnboarding: Bool = false, onComplete: (() -> Void)? = nil) {
        self.isOnboarding = isOnboarding
        self.onComplete = onComplete
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var filteredCategories: [EventCategory] {
        if searchText.isEmpty {
            return EventCategory.allCases
        }
        return EventCategory.allCases.filter { category in
            category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header for Settings view
            if !isOnboarding {
                settingsHeader
            }

            // Main content
            if isOnboarding {
                onboardingContent
            } else {
                settingsContent
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(isOnboarding ? "" : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(!isOnboarding)
        .onAppear {
            loadCurrentPreferences()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .interactiveDismissDisabled(isOnboarding)
        .onChange(of: selectedCategories) { _ in
            hasChanges = true
        }
    }

    // MARK: - Settings Header

    private var settingsHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("Interests")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Button(action: savePreferences) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(hasChanges ? RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee) : .gray)
                    }
                }
                .disabled(!hasChanges || isSaving)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)

            Divider()
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search interests...", text: $searchText)
                        .font(AppTypography.body)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.small)
                .padding(.horizontal, AppSpacing.md)

                // Selection summary
                VStack(spacing: AppSpacing.xs) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)

                        Text("Your Interests")
                            .font(AppTypography.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("\(selectedCategories.count) selected")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.small)
                    }

                    Text("Select categories you're interested in to personalize your event recommendations")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, AppSpacing.md)

                // Selected interests pills (if any)
                if !selectedCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(Array(selectedCategories).sorted(), id: \.self) { categoryRaw in
                                if let category = EventCategory(rawValue: categoryRaw) {
                                    InterestPill(
                                        category: category,
                                        onRemove: {
                                            toggleCategory(categoryRaw)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                }

                // Categories grid
                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    ForEach(filteredCategories) { category in
                        InterestCategoryCard(
                            category: category,
                            isSelected: selectedCategories.contains(category.rawValue),
                            onTap: {
                                toggleCategory(category.rawValue)
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .animation(.easeInOut(duration: 0.2), value: selectedCategories)
            }
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Onboarding Content

    private var onboardingContent: some View {
        NavigationView {
            VStack(spacing: 0) {
                onboardingHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                            ForEach(EventCategory.allCases) { category in
                                CategoryCard(
                                    category: category,
                                    isSelected: selectedCategories.contains(category.rawValue),
                                    onTap: {
                                        toggleCategory(category.rawValue)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)

                        Text("\(selectedCategories.count) categories selected")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, AppSpacing.sm)
                    }
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, 100)
                }

                // Save Button for onboarding
                VStack {
                    Divider()

                    Button(action: savePreferences) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedCategories.isEmpty ? Color.gray : RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee))
                        .foregroundColor(.white)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .disabled(selectedCategories.isEmpty || isSaving)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                }
                .background(Color(UIColor.systemBackground))
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var onboardingHeader: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee))

            Text("What events interest you?")
                .font(AppTypography.title2)
                .fontWeight(.bold)

            Text("Choose your favorite event categories to get personalized recommendations.")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .padding(.top, AppSpacing.xl)
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Actions

    private func toggleCategory(_ category: String) {
        HapticFeedback.selection()

        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }
    }

    private func loadCurrentPreferences() {
        if let user = authService.currentUser {
            selectedCategories = Set(user.favoriteEventTypes)
        }
        // Reset hasChanges after loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            hasChanges = false
        }
    }

    private func savePreferences() {
        guard var user = authService.currentUser else { return }

        isSaving = true

        // Save to the same favoriteEventTypes field (single source of truth)
        user.favoriteEventTypes = Array(selectedCategories)
        if isOnboarding {
            user.hasCompletedOnboarding = true
        }

        Task {
            do {
                try await authService.updateProfile(user)

                await MainActor.run {
                    isSaving = false
                    hasChanges = false
                    HapticFeedback.success()

                    if isOnboarding {
                        onComplete?()
                    } else {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Interest Category Card (Compact for Settings)

struct InterestCategoryCard: View {
    let category: EventCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(width: 50, height: 50)

                    Image(systemName: category.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : category.color)
                }

                Text(category.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? category.color : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(category.color)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interest Pill (Selected Items)

struct InterestPill: View {
    let category: EventCategory
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.iconName)
                .font(.system(size: 12))

            Text(category.rawValue)
                .font(.system(size: 12, weight: .medium))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(category.color)
        .cornerRadius(20)
    }
}

// MARK: - Category Card (for Onboarding)

struct CategoryCard: View {
    let category: EventCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: category.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : category.color)

                Text(category.rawValue)
                    .font(AppTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isSelected ? category.color : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FavoriteEventCategoriesView(isOnboarding: false)
        .environmentObject(MockAuthService())
}

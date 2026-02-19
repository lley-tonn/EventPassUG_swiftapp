//
//  OnboardingSlides.swift
//  EventPassUG
//
//  Individual slide views for the onboarding flow
//

import SwiftUI

// MARK: - Welcome Slide

struct WelcomeSlide: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                // Background gradient circles
                ForEach(0..<3) { index in
                    Circle()
                        .fill(circleGradient(for: index))
                        .frame(width: 280 - CGFloat(index * 50), height: 280 - CGFloat(index * 50))
                }

                // Logo/Icon
                Image(systemName: "ticket.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 48)

            // Text content
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(secondaryTextColor)

                Text("EventPass")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Discover, book, and experience\nthe best events in Uganda")
                    .font(.system(size: 17))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, OnboardingTheme.horizontalPadding)
    }

    private func circleGradient(for index: Int) -> LinearGradient {
        let opacity = 0.4 - Double(index) * 0.1
        return LinearGradient(
            colors: [
                AppColors.primary.opacity(opacity),
                AppColors.primaryDark.opacity(opacity * 0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gradientColors: [Color] {
        [AppColors.primary, AppColors.primaryDark]
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(UIColor.secondaryLabel)
    }
}

// MARK: - Role Selection Slide

struct RoleSelectionSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingSectionHeader(
                title: "How will you use EventPass?",
                subtitle: "Choose your primary role"
            )
            .padding(.top, 20)
            .padding(.bottom, 40)

            // Role cards
            VStack(spacing: 16) {
                RoleCard(
                    role: .attendee,
                    isSelected: viewModel.profile.role == .attendee
                ) {
                    viewModel.selectRole(.attendee)
                }

                RoleCard(
                    role: .organizer,
                    isSelected: viewModel.profile.role == .organizer
                ) {
                    viewModel.selectRole(.organizer)
                }
            }

            Spacer()

            // Helper text
            Text("You can change this later in settings")
                .font(.system(size: 14))
                .foregroundColor(tertiaryTextColor)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, OnboardingTheme.horizontalPadding)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color(UIColor.tertiaryLabel)
    }
}

// MARK: - Basic Info Slide

struct BasicInfoSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingSectionHeader(
                title: "Tell us about yourself",
                subtitle: "We'll personalize your experience"
            )
            .padding(.top, 20)
            .padding(.bottom, 32)

            // Form
            VStack(spacing: 20) {
                // Full Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryTextColor)

                    TextField("Enter your full name", text: Binding(
                        get: { viewModel.profile.fullName },
                        set: { viewModel.updateFullName($0) }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .focused($isNameFocused)

                    if let error = viewModel.nameValidationMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                }

                // Date of Birth
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryTextColor)

                    OnboardingInfoRow(
                        icon: "calendar",
                        title: "Birthday",
                        value: viewModel.formattedDateOfBirth
                    ) {
                        isNameFocused = false
                        viewModel.showDatePicker = true
                    }
                }

                // Age (read-only)
                if viewModel.profile.dateOfBirth != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Age")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryTextColor)

                        OnboardingInfoRow(
                            icon: "person.fill",
                            title: "Age",
                            value: viewModel.formattedAge
                        )

                        if let error = viewModel.ageValidationMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, OnboardingTheme.horizontalPadding)
        .sheet(isPresented: $viewModel.showDatePicker) {
            DatePickerSheet(
                selectedDate: viewModel.profile.dateOfBirth ?? viewModel.maxDateOfBirth,
                minDate: viewModel.minDateOfBirth,
                maxDate: viewModel.maxDateOfBirth
            ) { date in
                viewModel.updateDateOfBirth(date)
                viewModel.showDatePicker = false
            }
            .presentationDetents([.height(400)])
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.secondaryLabel)
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @State var selectedDate: Date
    let minDate: Date
    let maxDate: Date
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Date of Birth",
                    selection: $selectedDate,
                    in: minDate...maxDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding()
            .navigationTitle("Date of Birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSelect(selectedDate)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Personalization Slide

struct PersonalizationSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingSectionHeader(
                title: headerTitle,
                subtitle: headerSubtitle
            )
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Selection count
            HStack {
                Text(selectionCountText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.primary)

                Spacer()
            }
            .padding(.bottom, 16)

            // Content
            ScrollView {
                if viewModel.profile.role == .attendee {
                    interestsGrid
                } else {
                    eventTypesGrid
                }
            }

            Spacer()
        }
        .padding(.horizontal, OnboardingTheme.horizontalPadding)
    }

    private var headerTitle: String {
        viewModel.profile.role == .attendee
            ? "What interests you?"
            : "What events will you organize?"
    }

    private var headerSubtitle: String {
        viewModel.profile.role == .attendee
            ? "Select your favorite event types"
            : "Choose the types of events you'll create"
    }

    private var selectionCountText: String {
        let count = viewModel.profile.role == .attendee
            ? viewModel.profile.interests.count
            : viewModel.profile.eventTypes.count
        return "\(count) selected"
    }

    private var interestsGrid: some View {
        FlowLayout(spacing: 10) {
            ForEach(InterestCategory.allCases) { interest in
                InterestChip(
                    interest: interest,
                    isSelected: viewModel.isInterestSelected(interest)
                ) {
                    viewModel.toggleInterest(interest)
                }
            }
        }
    }

    private var eventTypesGrid: some View {
        FlowLayout(spacing: 10) {
            ForEach(OrganizerEventType.allCases) { eventType in
                EventTypeChip(
                    eventType: eventType,
                    isSelected: viewModel.isEventTypeSelected(eventType)
                ) {
                    viewModel.toggleEventType(eventType)
                }
            }
        }
    }
}

// MARK: - Permissions Slide

struct PermissionsSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingSectionHeader(
                title: "Stay in the loop",
                subtitle: "Get notified about events you'll love"
            )
            .padding(.top, 20)
            .padding(.bottom, 40)

            // Permission card
            OnboardingPermissionCard(
                icon: "bell.badge.fill",
                title: "Notifications",
                description: "Receive updates about new events, ticket sales, and reminders for events you're attending",
                isEnabled: viewModel.profile.notificationsEnabled
            ) {
                if viewModel.notificationPermissionStatus == .notDetermined {
                    viewModel.requestNotificationPermission()
                } else if viewModel.notificationPermissionStatus == .denied {
                    viewModel.openSettings()
                }
            }

            if viewModel.notificationPermissionStatus == .denied {
                Text("Notifications are disabled. Tap to open Settings.")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .padding(.top, 16)
            }

            Spacer()

            // Skip text
            Text("You can always enable this later")
                .font(.system(size: 14))
                .foregroundColor(tertiaryTextColor)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, OnboardingTheme.horizontalPadding)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color(UIColor.tertiaryLabel)
    }
}

// MARK: - Completion Slide

struct CompletionSlide: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showConfetti = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Success animation
            ZStack {
                // Background circles
                ForEach(0..<3) { index in
                    Circle()
                        .fill(circleColor(for: index))
                        .frame(width: 200 - CGFloat(index * 40), height: 200 - CGFloat(index * 40))
                        .scaleEffect(showConfetti ? 1.1 : 1)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: showConfetti
                        )
                }

                // Checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(showConfetti ? 1 : 0.5)
                    .opacity(showConfetti ? 1 : 0)
            }
            .padding(.bottom, 48)

            // Text
            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(primaryTextColor)

                Text("Welcome, \(viewModel.profile.fullName.components(separatedBy: " ").first ?? "")!")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(secondaryTextColor)

                Text(completionMessage)
                    .font(.system(size: 17))
                    .foregroundColor(tertiaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 8)
            }

            Spacer()

            // Summary
            summaryCard
                .padding(.bottom, 24)

            Spacer()
        }
        .padding(.horizontal, OnboardingTheme.horizontalPadding)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showConfetti = true
            }
        }
    }

    private var completionMessage: String {
        if viewModel.profile.role == .attendee {
            return "Start exploring amazing events happening in Uganda"
        } else {
            return "Create your first event and start selling tickets"
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            OnboardingSummaryRow(
                icon: "person.fill",
                title: "Role",
                value: viewModel.profile.role?.displayName ?? "-"
            )

            Divider()
                .background(dividerColor)

            OnboardingSummaryRow(
                icon: viewModel.profile.role == .attendee ? "heart.fill" : "calendar.badge.plus",
                title: viewModel.profile.role == .attendee ? "Interests" : "Event Types",
                value: summaryValue
            )

            Divider()
                .background(dividerColor)

            OnboardingSummaryRow(
                icon: "bell.fill",
                title: "Notifications",
                value: viewModel.profile.notificationsEnabled ? "Enabled" : "Disabled"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                .fill(cardBackground)
        )
    }

    private var summaryValue: String {
        if viewModel.profile.role == .attendee {
            return "\(viewModel.profile.interests.count) selected"
        } else {
            return "\(viewModel.profile.eventTypes.count) selected"
        }
    }

    private func circleColor(for index: Int) -> Color {
        Color.green.opacity(0.2 - Double(index) * 0.05)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(UIColor.label)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.8) : Color(UIColor.secondaryLabel)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.tertiaryLabel)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(UIColor.secondarySystemBackground)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2)
    }
}

// MARK: - Summary Row

struct OnboardingSummaryRow: View {
    let icon: String
    let title: String
    let value: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(secondaryTextColor)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(primaryTextColor)
        }
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(UIColor.label)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.secondaryLabel)
    }
}

// MARK: - Previews

#Preview("Welcome") {
    WelcomeSlide()
}

#Preview("Role Selection") {
    RoleSelectionSlide(viewModel: OnboardingViewModel())
}

#Preview("Basic Info") {
    BasicInfoSlide(viewModel: OnboardingViewModel())
}

#Preview("Personalization") {
    let vm = OnboardingViewModel()
    vm.profile.role = .attendee
    return PersonalizationSlide(viewModel: vm)
}

#Preview("Permissions") {
    PermissionsSlide(viewModel: OnboardingViewModel())
}

#Preview("Completion") {
    let vm = OnboardingViewModel()
    vm.profile.fullName = "John Doe"
    vm.profile.role = .attendee
    return CompletionSlide(viewModel: vm)
}

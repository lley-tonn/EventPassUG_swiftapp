//
//  FormInputComponents.swift
//  EventPassUG
//
//  Styled form input components using the app design system
//  Provides consistent text fields, text editors, and form styling
//

import SwiftUI

// MARK: - Styled Text Field

/// A styled text field that follows the app design system
struct StyledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var icon: String? = nil

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Label
            Text(label)
                .font(AppTypography.headline)
                .foregroundColor(.primary)

            // Input field
            HStack(spacing: AppSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: AppDesign.Input.iconSize))
                        .foregroundColor(isFocused ? accentColor : .secondary)
                        .frame(width: AppDesign.Input.iconSize)
                }

                TextField(placeholder, text: $text)
                    .font(AppTypography.body)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .focused($isFocused)
            }
            .padding(.horizontal, AppDesign.Input.paddingHorizontal)
            .frame(height: AppDesign.Input.height)
            .background(backgroundColor)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
            )
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.secondarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

// MARK: - Styled Text Editor

/// A styled multi-line text editor that follows the app design system
struct StyledTextEditor: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Label
            Text(label)
                .font(AppTypography.headline)
                .foregroundColor(.primary)

            // Text editor with placeholder
            ZStack(alignment: .topLeading) {
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTypography.body)
                        .foregroundColor(Color(UIColor.placeholderText))
                        .padding(.horizontal, AppDesign.Input.paddingHorizontal)
                        .padding(.top, 14)
                }

                // Text editor
                TextEditor(text: $text)
                    .font(AppTypography.body)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, AppDesign.Input.paddingHorizontal - 4)
                    .padding(.vertical, 8)
            }
            .frame(minHeight: minHeight)
            .background(backgroundColor)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
            )
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.secondarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

// MARK: - Styled Number Field

/// A styled number input field
struct StyledNumberField: View {
    let label: String
    let placeholder: String
    @Binding var value: Int
    var prefix: String? = nil
    var suffix: String? = nil

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Label
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            // Input field
            HStack(spacing: AppSpacing.xs) {
                if let prefix = prefix {
                    Text(prefix)
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                }

                TextField(placeholder, value: $value, format: .number)
                    .font(AppTypography.body)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .multilineTextAlignment(prefix != nil ? .trailing : .leading)

                if let suffix = suffix {
                    Text(suffix)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, AppDesign.Input.paddingHorizontal)
            .frame(height: AppDesign.Input.heightCompact)
            .background(backgroundColor)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
            )
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.secondarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

// MARK: - Form Section

/// A styled form section container
struct FormSection<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if let title = title {
                Text(title)
                    .font(AppTypography.section)
                    .foregroundColor(.primary)
            }

            content
        }
    }
}

// MARK: - Inline Text Field (No Label)

/// A compact text field without label, for use in forms where label is external
struct InlineTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppTypography.body)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .focused($isFocused)
            .padding(.horizontal, AppDesign.Input.paddingHorizontal)
            .frame(height: AppDesign.Input.height)
            .background(backgroundColor)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
            )
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.secondarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

// MARK: - Ticket Form Fields

/// Styled ticket name input field
struct TicketNameField: View {
    @Binding var text: String

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "ticket")
                .font(.system(size: 16))
                .foregroundColor(isFocused ? accentColor : .secondary)

            TextField("Name (e.g., Early Bird, VIP, Regular)", text: $text)
                .font(AppTypography.body)
                .focused($isFocused)
        }
        .padding(.horizontal, AppDesign.Input.paddingHorizontal)
        .frame(height: AppDesign.Input.height)
        .background(backgroundColor)
        .cornerRadius(AppDesign.CornerRadius.input)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
        )
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.tertiarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

/// Styled price input field with UGX formatting
struct TicketPriceField: View {
    @Binding var value: Double

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("UGX")
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(accentColor)

            TextField("0", value: $value, format: .number)
                .font(AppTypography.body)
                .keyboardType(.numberPad)
                .focused($isFocused)
        }
        .padding(.horizontal, AppDesign.Input.paddingHorizontal)
        .frame(height: AppDesign.Input.heightCompact)
        .background(backgroundColor)
        .cornerRadius(AppDesign.CornerRadius.input)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
        )
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.tertiarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

/// Styled quantity input field
struct TicketQuantityField: View {
    @Binding var value: Int

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TextField("100", value: $value, format: .number)
            .font(AppTypography.body)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppDesign.Input.paddingHorizontal)
            .frame(height: AppDesign.Input.heightCompact)
            .background(backgroundColor)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
            )
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.tertiarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

// MARK: - Venue Search Field

/// Location result from venue search
typealias VenueLocationResult = (name: String, address: String, city: String, coordinate: (lat: Double, lon: Double))

/// A styled text field with autocomplete predictions for venue search
struct VenueSearchField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showingPredictions: Bool
    @ObservedObject var locationService: LocationService
    let onLocationSelected: (VenueLocationResult) -> Void

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Input field
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppDesign.Input.iconSize))
                    .foregroundColor(isFocused ? accentColor : .secondary)
                    .frame(width: AppDesign.Input.iconSize)

                TextField(placeholder, text: $text)
                    .font(AppTypography.body)
                    .focused($isFocused)
                    .onChange(of: text) { newValue in
                        locationService.searchLocations(query: newValue)
                        showingPredictions = !newValue.isEmpty
                    }

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        showingPredictions = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, AppDesign.Input.paddingHorizontal)
            .frame(height: AppDesign.Input.height)
            .background(backgroundColor)
            .cornerRadius(AppDesign.CornerRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.input)
                    .stroke(isFocused ? accentColor : borderColor, lineWidth: isFocused ? 2 : 1)
            )

            // Autocomplete predictions
            if showingPredictions && !locationService.predictions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(locationService.predictions.prefix(5)) { prediction in
                        Button(action: {
                            onLocationSelected(locationService.selectLocation(prediction))
                        }) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(prediction.title)
                                        .font(AppTypography.callout)
                                        .foregroundColor(.primary)
                                    Text(prediction.subtitle)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                        }

                        if prediction.id != locationService.predictions.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppDesign.CornerRadius.input)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                .padding(.top, AppSpacing.xs)
            }
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(UIColor.secondarySystemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color(UIColor.separator)
    }

    private var accentColor: Color {
        RoleConfig.organizerPrimary
    }
}

// MARK: - Previews

#Preview("Styled Text Field") {
    VStack(spacing: 20) {
        StyledTextField(
            label: "Event Title",
            placeholder: "Enter event title",
            text: .constant("")
        )

        StyledTextField(
            label: "Venue Name",
            placeholder: "Enter venue name",
            text: .constant("Kampala Serena Hotel"),
            icon: "mappin.circle"
        )
    }
    .padding()
}

#Preview("Styled Text Editor") {
    StyledTextEditor(
        label: "Description",
        placeholder: "Describe your event...",
        text: .constant("")
    )
    .padding()
}

#Preview("Form Section") {
    FormSection(title: "Event Details") {
        StyledTextField(
            label: "Event Title",
            placeholder: "Enter event title",
            text: .constant("")
        )

        StyledTextEditor(
            label: "Description",
            placeholder: "Describe your event...",
            text: .constant("")
        )
    }
    .padding()
}

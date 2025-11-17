//
//  CreateEventWizard.swift
//  EventPassUG
//
//  3-step event creation wizard with Core Data drafts
//

import SwiftUI
import PhotosUI

struct CreateEventWizard: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @EnvironmentObject var services: ServiceContainer

    @State private var currentStep = 1
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var showingVerification = false

    // Step 1: Event Details
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: EventCategory = .music
    @State private var startDate = Date().addingTimeInterval(86400)
    @State private var endDate = Date().addingTimeInterval(90000)
    @State private var venueName = ""
    @State private var venueAddress = ""
    @State private var venueCity = "Kampala"
    @State private var selectedPosterItem: PhotosPickerItem?
    @State private var posterImageName: String?

    // Step 2: Ticketing
    @State private var ticketTypes: [TicketType] = [
        TicketType(name: "General Admission", price: 0, quantity: 100)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 3)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .tint(RoleConfig.organizerPrimary)

                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { step in
                        VStack(spacing: 4) {
                            Text("Step \(step)")
                                .font(AppTypography.caption)
                                .foregroundColor(currentStep >= step ? RoleConfig.organizerPrimary : .secondary)

                            Text(stepTitle(for: step))
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, AppSpacing.sm)

                Divider()

                // Step content
                TabView(selection: $currentStep) {
                    Step1EventDetails(
                        title: $title,
                        description: $description,
                        selectedCategory: $selectedCategory,
                        startDate: $startDate,
                        endDate: $endDate,
                        venueName: $venueName,
                        venueAddress: $venueAddress,
                        venueCity: $venueCity,
                        selectedPosterItem: $selectedPosterItem,
                        posterImageName: $posterImageName
                    )
                    .tag(1)

                    Step2Ticketing(ticketTypes: $ticketTypes)
                        .tag(2)

                    Step3Review(
                        title: title,
                        description: description,
                        category: selectedCategory,
                        startDate: startDate,
                        endDate: endDate,
                        venueName: venueName,
                        venueAddress: venueAddress,
                        ticketTypes: ticketTypes,
                        posterImageName: posterImageName,
                        onEdit: { step in
                            currentStep = step
                        }
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                Divider()

                HStack(spacing: AppSpacing.md) {
                    if currentStep > 1 {
                        Button(action: {
                            currentStep -= 1
                            HapticFeedback.light()
                        }) {
                            Text("Back")
                                .font(AppTypography.headline)
                                .foregroundColor(RoleConfig.organizerPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .stroke(RoleConfig.organizerPrimary, lineWidth: 2)
                                )
                        }
                    }

                    Button(action: handleContinue) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(currentStep == 3 ? "Publish Event" : "Continue")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.medium)
                    .disabled(!canContinue || isLoading)
                    .opacity(canContinue && !isLoading ? 1.0 : 0.5)
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Draft") {
                        saveDraft()
                    }
                    .foregroundColor(RoleConfig.organizerPrimary)
                }
            }
        }
        .alert("Event Published!", isPresented: $showingSuccessAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your event has been published successfully!")
        }
        .sheet(isPresented: $showingVerification) {
            NationalIDVerificationView()
                .environmentObject(authService)
        }
        .onAppear {
            // Check verification on load
            if authService.currentUser?.needsVerificationForOrganizerActions == true {
                showingVerification = true
            }
        }
    }

    private var canContinue: Bool {
        switch currentStep {
        case 1:
            return !title.isEmpty && !description.isEmpty && !venueName.isEmpty && !venueAddress.isEmpty
        case 2:
            return !ticketTypes.isEmpty && ticketTypes.allSatisfy { $0.quantity > 0 }
        case 3:
            return true
        default:
            return false
        }
    }

    private func stepTitle(for step: Int) -> String {
        switch step {
        case 1: return "Details"
        case 2: return "Tickets"
        case 3: return "Review"
        default: return ""
        }
    }

    private func handleContinue() {
        if currentStep < 3 {
            currentStep += 1
            HapticFeedback.light()
        } else {
            publishEvent()
        }
    }

    private func saveDraft() {
        // TODO: Implement Core Data draft saving
        HapticFeedback.success()
        dismiss()
    }

    private func publishEvent() {
        isLoading = true

        Task {
            do {
                guard let organizerId = authService.currentUser?.id,
                      let organizerName = authService.currentUser?.fullName else {
                    return
                }

                let event = Event(
                    title: title,
                    description: description,
                    organizerId: organizerId,
                    organizerName: organizerName,
                    posterURL: posterImageName,
                    category: selectedCategory,
                    startDate: startDate,
                    endDate: endDate,
                    venue: Venue(
                        name: venueName,
                        address: venueAddress,
                        city: venueCity,
                        coordinate: Venue.Coordinate(latitude: 0.3163, longitude: 32.5822) // Default Kampala
                    ),
                    ticketTypes: ticketTypes,
                    status: .published
                )

                _ = try await services.eventService.createEvent(event)

                await MainActor.run {
                    HapticFeedback.success()
                    isLoading = false
                    showingSuccessAlert = true
                }
            } catch {
                print("Error publishing event: \(error)")
                await MainActor.run {
                    HapticFeedback.error()
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Step 1: Event Details

struct Step1EventDetails: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedCategory: EventCategory
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var venueName: String
    @Binding var venueAddress: String
    @Binding var venueCity: String
    @Binding var selectedPosterItem: PhotosPickerItem?
    @Binding var posterImageName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Poster picker
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Event Poster")
                        .font(AppTypography.headline)

                    PhotosPicker(selection: $selectedPosterItem, matching: .images) {
                        if let posterName = posterImageName {
                            Image(posterName)
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(height: 180)
                                .cornerRadius(AppCornerRadius.medium)
                        } else {
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(Color(UIColor.systemGray6))
                                .frame(height: 180)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                        Text("Tap to select poster")
                                            .font(AppTypography.caption)
                                    }
                                    .foregroundColor(.secondary)
                                )
                        }
                    }
                }

                // Title
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Event Title")
                        .font(AppTypography.headline)
                    TextField("Enter event title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                // Description
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Description")
                        .font(AppTypography.headline)
                    TextEditor(text: $description)
                        .frame(height: 120)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                }

                // Category
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Category")
                        .font(AppTypography.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                    HapticFeedback.selection()
                                }) {
                                    HStack {
                                        Image(systemName: category.iconName)
                                        Text(category.rawValue)
                                    }
                                    .font(AppTypography.callout)
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategory == category
                                            ? RoleConfig.organizerPrimary
                                            : Color(UIColor.secondarySystemBackground)
                                    )
                                    .cornerRadius(AppCornerRadius.small)
                                }
                            }
                        }
                    }
                }

                // Dates
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Start Date & Time")
                        .font(AppTypography.headline)
                    DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("End Date & Time")
                        .font(AppTypography.headline)
                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                // Venue
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Venue Name")
                        .font(AppTypography.headline)
                    TextField("Enter venue name", text: $venueName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Address")
                        .font(AppTypography.headline)
                    TextField("Enter address", text: $venueAddress)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("City")
                        .font(AppTypography.headline)
                    TextField("Enter city", text: $venueCity)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(AppSpacing.md)
        }
    }
}

// MARK: - Step 2: Ticketing

struct Step2Ticketing: View {
    @Binding var ticketTypes: [TicketType]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Add ticket types and pricing for your event")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)

                ForEach(ticketTypes.indices, id: \.self) { index in
                    TicketTypeEditor(ticketType: $ticketTypes[index], onDelete: {
                        ticketTypes.remove(at: index)
                        HapticFeedback.light()
                    })
                }

                Button(action: {
                    ticketTypes.append(TicketType(name: "New Ticket Type", price: 0, quantity: 100))
                    HapticFeedback.light()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Ticket Type")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(RoleConfig.organizerPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(RoleConfig.organizerPrimary, lineWidth: 2)
                    )
                }
            }
            .padding(AppSpacing.md)
        }
    }
}

struct TicketTypeEditor: View {
    @Binding var ticketType: TicketType
    let onDelete: () -> Void

    @State private var showAdvancedOptions = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: ticketType.availabilityStatus.iconName)
                        .foregroundColor(ticketType.availabilityStatus.color)
                        .font(.system(size: 14))

                    Text("Ticket Type")
                        .font(AppTypography.headline)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            TextField("Name (e.g., Early Bird, VIP, Regular)", text: $ticketType.name)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price (UGX)")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    TextField("0", value: $ticketType.price, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Quantity")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: $ticketType.isUnlimitedQuantity)
                            .labelsHidden()
                            .scaleEffect(0.8)
                        Text("Unlimited")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    if !ticketType.isUnlimitedQuantity {
                        TextField("100", value: $ticketType.quantity, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    } else {
                        Text("∞")
                            .font(AppTypography.title2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                }
            }

            // Availability Window Section
            DisclosureGroup(
                isExpanded: $showAdvancedOptions,
                content: {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        // Sale Start Date
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.green)
                                Text("Sale Starts")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                            DatePicker(
                                "",
                                selection: $ticketType.saleStartDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        // Sale End Date
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.orange)
                                Text("Sale Ends")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                            DatePicker(
                                "",
                                selection: $ticketType.saleEndDate,
                                in: ticketType.saleStartDate...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        // Status Preview
                        HStack {
                            Image(systemName: ticketType.availabilityStatus.iconName)
                                .foregroundColor(ticketType.availabilityStatus.color)
                            Text("Status: \(ticketType.availabilityStatus.rawValue)")
                                .font(AppTypography.caption)
                                .foregroundColor(ticketType.availabilityStatus.color)
                            Spacer()
                            Text(ticketType.availabilityText)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(AppSpacing.xs)
                        .background(ticketType.availabilityStatus.color.opacity(0.1))
                        .cornerRadius(AppCornerRadius.small)
                    }
                    .padding(.top, AppSpacing.sm)
                },
                label: {
                    HStack {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .foregroundColor(RoleConfig.organizerPrimary)
                        Text("Availability Window")
                            .font(AppTypography.subheadline)
                            .fontWeight(.medium)
                    }
                }
            )
            .tint(RoleConfig.organizerPrimary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(ticketType.availabilityStatus.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Step 3: Review

struct Step3Review: View {
    let title: String
    let description: String
    let category: EventCategory
    let startDate: Date
    let endDate: Date
    let venueName: String
    let venueAddress: String
    let ticketTypes: [TicketType]
    let posterImageName: String?
    let onEdit: (Int) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Review your event before publishing")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)

                // Event preview card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if let posterName = posterImageName {
                        Image(posterName)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(AppCornerRadius.medium)
                    }

                    Text(title)
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text(description)
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: category.iconName)
                        Text(category.rawValue)
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(RoleConfig.organizerPrimary)

                    Divider()

                    InfoRow(icon: "calendar", title: "Date", value: DateUtilities.formatEventFullDateTime(startDate, endDate: endDate))
                    InfoRow(icon: "location.fill", title: "Venue", value: "\(venueName)\n\(venueAddress)")

                    Button(action: { onEdit(1) }) {
                        Text("Edit Details")
                            .font(AppTypography.caption)
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }
                }
                .padding(AppSpacing.md)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)

                // Tickets
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("Tickets")
                            .font(AppTypography.headline)
                        Spacer()
                        Button(action: { onEdit(2) }) {
                            Text("Edit")
                                .font(AppTypography.caption)
                                .foregroundColor(RoleConfig.organizerPrimary)
                        }
                    }

                    ForEach(ticketTypes) { type in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(type.name)
                                            .font(AppTypography.callout)
                                            .fontWeight(.medium)

                                        // Status badge
                                        HStack(spacing: 2) {
                                            Image(systemName: type.availabilityStatus.iconName)
                                                .font(.system(size: 10))
                                            Text(type.availabilityStatus.rawValue)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .foregroundColor(type.availabilityStatus.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(type.availabilityStatus.color.opacity(0.15))
                                        .cornerRadius(4)
                                    }

                                    if type.isUnlimitedQuantity {
                                        Text("Unlimited quantity")
                                            .font(AppTypography.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("\(type.quantity) available")
                                            .font(AppTypography.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text(type.formattedPrice)
                                    .font(AppTypography.callout)
                                    .fontWeight(.semibold)
                            }

                            // Sale window info
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(type.formattedSaleWindow)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(AppSpacing.sm)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.small)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }
}

#Preview {
    CreateEventWizard()
        .environmentObject(MockAuthService())
        .environmentObject(ServiceContainer(
            authService: MockAuthService(),
            eventService: MockEventService(),
            ticketService: MockTicketService(),
            paymentService: MockPaymentService()
        ))
}

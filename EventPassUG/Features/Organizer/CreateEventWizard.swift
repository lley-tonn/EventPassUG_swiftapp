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
    @EnvironmentObject var authService: MockAuthRepository
    @EnvironmentObject var services: ServiceContainer

    var existingDraft: Event? = nil

    @State private var currentStep = 1
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var showingVerification = false
    @State private var draftId: UUID?

    // Step 1: Event Details
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: EventCategory = .music
    @State private var startDate = Date().addingTimeInterval(86400)
    @State private var endDate = Date().addingTimeInterval(90000)
    @State private var venueName = ""
    @State private var venueAddress = ""
    @State private var venueCity = "Kampala"
    @State private var venueLatitude: Double = 0.3163
    @State private var venueLongitude: Double = 32.5822
    @State private var selectedPosterItem: PhotosPickerItem?
    @State private var posterImageName: String?
    @State private var posterUIImage: UIImage?

    @StateObject private var locationService = LocationService()

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
                        posterImageName: $posterImageName,
                        posterUIImage: $posterUIImage,
                        venueLatitude: $venueLatitude,
                        venueLongitude: $venueLongitude,
                        locationService: locationService
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
                            Text(currentStep == 3 ? (isEditingExistingEvent ? "Save Changes" : "Publish Event") : "Continue")
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
            .navigationTitle(isEditingExistingEvent ? "Edit Event" : "Create Event")
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
        .alert(isEditingExistingEvent ? "Event Updated!" : "Event Published!", isPresented: $showingSuccessAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text(isEditingExistingEvent ? "Your event has been updated successfully!" : "Your event has been published successfully!")
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

            // Load draft if provided
            if let draft = existingDraft {
                loadDraft(draft)
            }
        }
    }

    private var isEditingExistingEvent: Bool {
        return existingDraft != nil && existingDraft?.status != .draft
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
        Task {
            do {
                guard let organizerId = authService.currentUser?.id,
                      let organizerName = authService.currentUser?.fullName else {
                    return
                }

                // Normalize ticket sale dates to event start date if not explicitly set
                let normalizedTickets = ticketTypes.map { ticket in
                    var normalized = ticket
                    // If saleEndDate is more than 60 days away, assume it's using default and set to event start
                    if normalized.saleEndDate.timeIntervalSinceNow > (60 * 24 * 60 * 60) {
                        normalized.saleEndDate = startDate
                    }
                    return normalized
                }

                let event = Event(
                    id: draftId ?? UUID(),
                    title: title.isEmpty ? "Untitled Event" : title,
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
                        coordinate: Venue.Coordinate(latitude: venueLatitude, longitude: venueLongitude)
                    ),
                    ticketTypes: normalizedTickets,
                    status: .draft
                )

                if draftId != nil {
                    _ = try await services.eventService.updateEvent(event)
                } else {
                    _ = try await services.eventService.createEvent(event)
                }

                await MainActor.run {
                    HapticFeedback.success()
                    dismiss()
                }
            } catch {
                print("Error saving draft: \(error)")
                await MainActor.run {
                    HapticFeedback.error()
                }
            }
        }
    }

    private func loadDraft(_ draft: Event) {
        draftId = draft.id
        title = draft.title
        description = draft.description
        selectedCategory = draft.category
        startDate = draft.startDate
        endDate = draft.endDate
        venueName = draft.venue.name
        venueAddress = draft.venue.address
        venueCity = draft.venue.city
        venueLatitude = draft.venue.coordinate.latitude
        venueLongitude = draft.venue.coordinate.longitude
        posterImageName = draft.posterURL
        ticketTypes = draft.ticketTypes

        // Determine which step to resume
        if !ticketTypes.isEmpty && ticketTypes.allSatisfy({ $0.quantity > 0 }) {
            currentStep = 3  // Review step
        } else if !title.isEmpty && !description.isEmpty {
            currentStep = 2  // Tickets step
        } else {
            currentStep = 1  // Details step
        }
    }

    private func publishEvent() {
        isLoading = true

        Task {
            do {
                guard let organizerId = authService.currentUser?.id,
                      let organizerName = authService.currentUser?.fullName else {
                    return
                }

                // Normalize ticket sale dates to event start date if not explicitly set
                let normalizedTickets = ticketTypes.map { ticket in
                    var normalized = ticket
                    // If saleEndDate is more than 60 days away, assume it's using default and set to event start
                    if normalized.saleEndDate.timeIntervalSinceNow > (60 * 24 * 60 * 60) {
                        normalized.saleEndDate = startDate
                    }
                    return normalized
                }

                if let existingEvent = existingDraft, existingEvent.status != .draft {
                    // Updating existing event
                    var updatedEvent = existingEvent
                    updatedEvent.title = title
                    updatedEvent.description = description
                    updatedEvent.category = selectedCategory
                    updatedEvent.startDate = startDate
                    updatedEvent.endDate = endDate
                    updatedEvent.venue = Venue(
                        name: venueName,
                        address: venueAddress,
                        city: venueCity,
                        coordinate: Venue.Coordinate(latitude: venueLatitude, longitude: venueLongitude)
                    )
                    updatedEvent.ticketTypes = normalizedTickets
                    updatedEvent.posterURL = posterImageName
                    updatedEvent.updatedAt = Date()

                    _ = try await services.eventService.updateEvent(updatedEvent)
                } else {
                    // Creating new event
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
                            coordinate: Venue.Coordinate(latitude: venueLatitude, longitude: venueLongitude)
                        ),
                        ticketTypes: normalizedTickets,
                        status: .published
                    )

                    _ = try await services.eventService.createEvent(event)
                }

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
    @Binding var posterUIImage: UIImage?
    @Binding var venueLatitude: Double
    @Binding var venueLongitude: Double
    @ObservedObject var locationService: LocationService

    @State private var showingPredictions = false

    var body: some View {
        GeometryReader { geometry in
            let _ = geometry.size.width > geometry.size.height

            ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Poster picker
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Event Poster")
                        .font(AppTypography.headline)

                    PhotosPicker(selection: $selectedPosterItem, matching: .images) {
                        ZStack {
                            if let uiImage = posterUIImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: min(260, geometry.size.width * 0.65)) // Max 260px, 4:5 ratio
                                    .clipped()
                                    .cornerRadius(AppCornerRadius.medium)
                                    .shadow(
                                        color: Color.black.opacity(0.15),
                                        radius: 12,
                                        x: 0,
                                        y: 6
                                    )
                            } else if let posterName = posterImageName {
                                EventPosterImage(
                                    posterURL: posterName,
                                    height: min(260, geometry.size.width * 0.65),
                                    cornerRadius: AppCornerRadius.medium
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: min(260, geometry.size.width * 0.65))
                                .shadow(
                                    color: Color.black.opacity(0.15),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            } else {
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(Color(UIColor.systemGray6))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: min(260, geometry.size.width * 0.65))
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary)
                                            Text("Tap to select poster")
                                                .font(AppTypography.callout)
                                                .foregroundColor(.secondary)
                                        }
                                    )
                                    .shadow(
                                        color: Color.black.opacity(0.08),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            }
                        }
                        .padding(.horizontal, AppSpacing.xs)
                    }
                    .onChange(of: selectedPosterItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                let imageName = "event_poster_\(UUID().uuidString).jpg"

                                // Save image to documents directory
                                let saveSuccess = ImageStorageManager.shared.saveImage(uiImage, withName: imageName)

                                await MainActor.run {
                                    posterUIImage = uiImage
                                    if saveSuccess {
                                        posterImageName = imageName
                                        print("✅ Poster saved successfully: \(imageName)")
                                    } else {
                                        print("❌ Failed to save poster")
                                    }
                                }
                            }
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

                // Venue with autocomplete
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Venue Name")
                        .font(AppTypography.headline)

                    TextField("Enter venue name", text: $venueName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: venueName) { newValue in
                            locationService.searchLocations(query: newValue)
                            showingPredictions = !newValue.isEmpty
                        }

                    // Autocomplete predictions
                    if showingPredictions && !locationService.predictions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(locationService.predictions.prefix(5)) { prediction in
                                Button(action: {
                                    let location = locationService.selectLocation(prediction)
                                    venueName = location.name
                                    venueAddress = location.address
                                    venueCity = location.city
                                    venueLatitude = location.coordinate.lat
                                    venueLongitude = location.coordinate.lon
                                    showingPredictions = false
                                    HapticFeedback.selection()
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(prediction.title)
                                            .font(AppTypography.callout)
                                            .foregroundColor(.primary)
                                        Text(prediction.subtitle)
                                            .font(AppTypography.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(AppSpacing.sm)
                                }

                                if prediction.id != locationService.predictions.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(AppCornerRadius.small)
                        .shadow(color: Color.black.opacity(0.1), radius: 8)
                    }
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
            .padding(ResponsiveSpacing.md(geometry))
            }
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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                        Text("Review Your Event")
                            .font(AppDesign.Typography.hero)
                            .foregroundColor(.primary)

                        Text("Double-check everything looks perfect before publishing")
                            .font(AppDesign.Typography.secondary)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppDesign.Spacing.md)
                    .padding(.top, AppDesign.Spacing.md)
                    .padding(.bottom, AppDesign.Spacing.lg)

                    // Preview Card (looks like real event card)
                    VStack(spacing: 0) {
                        eventPreviewCard(geometry: geometry)
                    }
                    .padding(.horizontal, AppDesign.Spacing.md)

                    // Ticket Details Section
                    ticketDetailsSection
                        .padding(.horizontal, AppDesign.Spacing.md)
                        .padding(.top, AppDesign.Spacing.lg)

                    // Extra bottom padding for scroll
                    Spacer(minLength: AppDesign.Spacing.xl * 2)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    // MARK: - Event Preview Card

    @ViewBuilder
    private func eventPreviewCard(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster Image with proper sizing
            ZStack(alignment: .topTrailing) {
                if let posterName = posterImageName {
                    EventPosterImage(
                        posterURL: posterName,
                        height: 200,
                        cornerRadius: 0
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No poster selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }

                // Edit button overlay
                Button(action: { onEdit(1) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(AppDesign.Typography.caption)
                        Text("Edit")
                            .font(AppDesign.Typography.captionEmphasized)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppDesign.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(AppDesign.CornerRadius.badge)
                }
                .padding(AppDesign.Spacing.sm)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: AppDesign.CornerRadius.card,
                    topTrailingRadius: AppDesign.CornerRadius.card
                )
            )

            // Event Details
            VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                // Title
                Text(title)
                    .font(AppDesign.Typography.section)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Category
                HStack(spacing: 6) {
                    Image(systemName: category.iconName)
                        .font(AppDesign.Typography.caption)
                    Text(category.rawValue)
                        .font(AppDesign.Typography.captionEmphasized)
                }
                .foregroundColor(AppDesign.Colors.primary)
                .padding(.horizontal, AppDesign.Spacing.sm)
                .padding(.vertical, 6)
                .background(AppDesign.Colors.primary.opacity(0.1))
                .cornerRadius(AppDesign.CornerRadius.badge)

                Divider()
                    .padding(.vertical, AppDesign.Spacing.xs)

                // Date
                HStack(alignment: .top, spacing: AppDesign.Spacing.md) {
                    Image(systemName: "calendar")
                        .font(AppDesign.Typography.callout)
                        .foregroundColor(AppDesign.Colors.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("When")
                            .font(AppDesign.Typography.captionEmphasized)
                            .foregroundColor(.secondary)
                        Text(DateUtilities.formatEventFullDateTime(startDate, endDate: endDate))
                            .font(AppDesign.Typography.body)
                            .foregroundColor(.primary)
                    }
                }

                // Location
                HStack(alignment: .top, spacing: AppDesign.Spacing.md) {
                    Image(systemName: "location.fill")
                        .font(AppDesign.Typography.callout)
                        .foregroundColor(AppDesign.Colors.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Where")
                            .font(AppDesign.Typography.captionEmphasized)
                            .foregroundColor(.secondary)
                        Text(venueName)
                            .font(AppDesign.Typography.bodyEmphasized)
                            .foregroundColor(.primary)
                        Text(venueAddress)
                            .font(AppDesign.Typography.secondary)
                            .foregroundColor(.secondary)
                    }
                }

                // Description
                if !description.isEmpty {
                    Divider()
                        .padding(.vertical, AppDesign.Spacing.xs)

                    VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
                        Text("About")
                            .font(AppDesign.Typography.captionEmphasized)
                            .foregroundColor(.secondary)
                        Text(description)
                            .font(AppDesign.Typography.body)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    }
                }
            }
            .padding(AppDesign.Spacing.md)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppDesign.CornerRadius.card)
        .cardShadow()
    }

    // MARK: - Ticket Details Section

    @ViewBuilder
    private var ticketDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ticket Types")
                        .font(.system(size: 20, weight: .bold))

                    Text("\(ticketTypes.count) \(ticketTypes.count == 1 ? "type" : "types") available")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { onEdit(2) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Edit")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(RoleConfig.organizerPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoleConfig.organizerPrimary.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small)
                }
            }

            VStack(spacing: AppSpacing.sm) {
                ForEach(ticketTypes) { type in
                    ticketTypeCard(type)
                }
            }
        }
    }

    // MARK: - Ticket Type Card

    @ViewBuilder
    private func ticketTypeCard(_ type: TicketType) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(type.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    // Quantity badge
                    HStack(spacing: 4) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 11))
                        Text(type.isUnlimitedQuantity ? "Unlimited" : "\(type.quantity) available")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Price or Sold Out
                Text(type.formattedPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(type.isSoldOut ? .red : RoleConfig.organizerPrimary)
            }

            // Sale Window with auto-end logic
            saleWindowInfo(for: type)

            // Perks (if any)
            if !type.perks.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Includes")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    ForEach(type.perks.prefix(3), id: \.self) { perk in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text(perk)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                        }
                    }

                    if type.perks.count > 3 {
                        Text("+\(type.perks.count - 3) more")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }

    // MARK: - Sale Window Info

    @ViewBuilder
    private func saleWindowInfo(for type: TicketType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(RoleConfig.organizerPrimary)

                Text("Sale Period")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Start
                HStack {
                    Text("Starts:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(type.saleStartDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }

                // End - automatically set to event start or when sold out
                HStack {
                    Text("Ends:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if type.isSoldOut {
                        Text("Sold Out")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                    } else if type.saleEndDate > startDate {
                        // Sale end should not exceed event start
                        Text(startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                        Text("(Event starts)")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    } else {
                        Text(type.saleEndDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.leading, 18)
        }
        .padding(AppSpacing.xs)
        .background(Color(UIColor.systemGray6).opacity(0.5))
        .cornerRadius(AppCornerRadius.small)
    }
}

#Preview {
    CreateEventWizard()
        .environmentObject(MockAuthRepository())
        .environmentObject(ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        ))
}

//
//  ManageEventTicketsView.swift
//  EventPassUG
//
//  Allows organizers to manage tickets for existing events:
//  - Add new ticket types
//  - Increase ticket quantities for existing types
//  - Edit ticket details
//

import SwiftUI

struct ManageEventTicketsView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var services: ServiceContainer

    @State private var ticketTypes: [TicketType] = []
    @State private var showingAddTicket = false
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Event Header
                        eventHeaderSection

                        // Instructions
                        instructionsSection

                        // Existing Tickets
                        existingTicketsSection

                        // Add New Ticket Button
                        addTicketButton
                    }
                    .padding(AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Manage Tickets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || !hasChanges)
                }
            }
            .onAppear {
                ticketTypes = event.ticketTypes
            }
            .sheet(isPresented: $showingAddTicket) {
                AddTicketTypeView(
                    eventStartDate: event.startDate,
                    eventEndDate: event.endDate,
                    onAdd: { newTicket in
                        ticketTypes.append(newTicket)
                        showingAddTicket = false
                    }
                )
            }
            .alert("Success", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Ticket changes saved successfully!")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Sections

    private var eventHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(event.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            HStack {
                Label(
                    DateUtilities.formatEventDateTime(event.startDate),
                    systemImage: "calendar"
                )
                .font(.system(size: 14))
                .foregroundColor(.secondary)

                Spacer()

                Label(event.venue.city, systemImage: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }

    private var instructionsSection: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Manage Your Tickets")
                    .font(.system(size: 14, weight: .semibold))

                Text("You can add new ticket types or increase quantities for existing types. Changes will be visible to attendees immediately.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(AppCornerRadius.medium)
    }

    private var existingTicketsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Ticket Types")
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                Text("\(ticketTypes.count) type\(ticketTypes.count != 1 ? "s" : "")")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            if ticketTypes.isEmpty {
                emptyTicketsView
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach($ticketTypes) { $ticketType in
                        EditableTicketCard(
                            ticketType: $ticketType,
                            originalTicketType: event.ticketTypes.first(where: { $0.id == ticketType.id }),
                            onDelete: {
                                ticketTypes.removeAll { $0.id == ticketType.id }
                            }
                        )
                    }
                }
            }
        }
    }

    private var emptyTicketsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "ticket")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Tickets Yet")
                .font(.system(size: 18, weight: .semibold))

            Text("Add your first ticket type to start selling tickets")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }

    private var addTicketButton: some View {
        Button(action: {
            showingAddTicket = true
            HapticFeedback.light()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))

                Text("Add New Ticket Type")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(RoleConfig.organizerPrimary)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(RoleConfig.organizerPrimary.opacity(0.1))
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(RoleConfig.organizerPrimary, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Computed Properties

    private var hasChanges: Bool {
        // Check if ticket types have changed
        if ticketTypes.count != event.ticketTypes.count {
            return true
        }

        for ticketType in ticketTypes {
            if let original = event.ticketTypes.first(where: { $0.id == ticketType.id }) {
                if ticketType.quantity != original.quantity ||
                   ticketType.name != original.name ||
                   ticketType.price != original.price {
                    return true
                }
            } else {
                // New ticket type
                return true
            }
        }

        return false
    }

    // MARK: - Actions

    private func saveChanges() {
        isSaving = true

        Task {
            do {
                try await services.eventService.updateEventTickets(eventId: event.id, ticketTypes: ticketTypes)

                await MainActor.run {
                    isSaving = false
                    showingSaveSuccess = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Editable Ticket Card

struct EditableTicketCard: View {
    @Binding var ticketType: TicketType
    let originalTicketType: TicketType?
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticketType.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(ticketType.formattedPrice)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                if originalTicketType == nil {
                    Text("NEW")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                } else if hasChanges {
                    Text("MODIFIED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(4)
                }

                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                    HapticFeedback.light()
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }
            }

            // Quick Stats
            HStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sold")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(ticketType.sold)")
                        .font(.system(size: 14, weight: .semibold))
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Available")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(ticketType.isUnlimitedQuantity ? "∞" : "\(ticketType.quantity)")
                        .font(.system(size: 14, weight: .semibold))
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Remaining")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(ticketType.isUnlimitedQuantity ? "∞" : "\(ticketType.remaining)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ticketType.remaining < 10 && !ticketType.isUnlimitedQuantity ? .red : .primary)
                }
            }

            // Expanded Editor
            if isExpanded {
                Divider()
                    .padding(.vertical, AppSpacing.xs)

                editSection
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }

    private var editSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Quantity Editor (can only increase for existing tickets)
            if !ticketType.isUnlimitedQuantity {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Ticket Quantity")
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: AppSpacing.md) {
                        Button(action: {
                            if ticketType.quantity > (originalTicketType?.quantity ?? 0) {
                                ticketType.quantity -= 1
                                HapticFeedback.light()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(ticketType.quantity > (originalTicketType?.quantity ?? 0) ? RoleConfig.organizerPrimary : .gray)
                        }
                        .disabled(ticketType.quantity <= (originalTicketType?.quantity ?? 0))

                        VStack(spacing: 2) {
                            Text("\(ticketType.quantity)")
                                .font(.system(size: 24, weight: .bold))

                            if let original = originalTicketType, ticketType.quantity > original.quantity {
                                Text("+\(ticketType.quantity - original.quantity) added")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(minWidth: 80)

                        Button(action: {
                            ticketType.quantity += 1
                            HapticFeedback.light()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(RoleConfig.organizerPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if let original = originalTicketType {
                        Text("Original quantity: \(original.quantity)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Delete Button (only for new tickets or drafts)
            if originalTicketType == nil {
                Button(action: {
                    onDelete()
                    HapticFeedback.light()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove Ticket Type")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.sm)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small)
                }
            }
        }
    }

    private var hasChanges: Bool {
        guard let original = originalTicketType else { return false }
        return ticketType.quantity != original.quantity ||
               ticketType.name != original.name ||
               ticketType.price != original.price
    }
}

// MARK: - Add Ticket Type View

struct AddTicketTypeView: View {
    let eventStartDate: Date
    let eventEndDate: Date
    let onAdd: (TicketType) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price = ""
    @State private var quantity = ""
    @State private var isUnlimited = false
    @State private var description = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Ticket Details") {
                    TextField("Ticket Name (e.g., VIP, General)", text: $name)

                    TextField("Price (UGX)", text: $price)
                        .keyboardType(.numberPad)
                }

                Section("Availability") {
                    Toggle("Unlimited Quantity", isOn: $isUnlimited)

                    if !isUnlimited {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Description (Optional)") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Ticket Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTicket()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.isEmpty &&
        !price.isEmpty &&
        (isUnlimited || !quantity.isEmpty)
    }

    private func addTicket() {
        guard let priceValue = Double(price) else {
            return
        }

        let finalQuantity: Int
        if isUnlimited {
            finalQuantity = 1000000 // Large number for unlimited
        } else {
            guard let quantityValue = Int(quantity) else {
                return
            }
            finalQuantity = quantityValue
        }

        let newTicket = TicketType(
            id: UUID(),
            name: name,
            price: priceValue,
            quantity: finalQuantity,
            sold: 0,
            description: description.isEmpty ? nil : description,
            perks: [],
            saleStartDate: Date(),
            saleEndDate: eventStartDate,
            isUnlimitedQuantity: isUnlimited
        )

        onAdd(newTicket)
        HapticFeedback.success()
    }
}

// MARK: - Preview

#Preview {
    ManageEventTicketsView(event: Event.samples[0])
        .environmentObject(ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        ))
}

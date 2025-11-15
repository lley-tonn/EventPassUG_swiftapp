//
//  TicketSuccessView.swift
//  EventPassUG
//
//  Success screen after ticket purchase with QR code
//

import SwiftUI

struct TicketSuccessView: View {
    let event: Event
    let ticketType: TicketType
    let quantity: Int
    let tickets: [Ticket]

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .padding(.top, AppSpacing.xl)

                    VStack(spacing: AppSpacing.sm) {
                        Text("Purchase Successful!")
                            .font(AppTypography.title1)
                            .fontWeight(.bold)

                        Text("Your ticket\(quantity > 1 ? "s are" : " is") ready")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                    }

                    // Event summary
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.md) {
                            if let posterURL = event.posterURL {
                                Image(posterURL)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(AppCornerRadius.small)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(AppTypography.headline)
                                    .lineLimit(2)

                                Text(DateUtilities.formatEventDateTime(event.startDate))
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.secondary)

                                Text(event.venue.name)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)

                        // Ticket details
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                Text("Ticket Type")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(ticketType.name)
                                    .fontWeight(.semibold)
                            }

                            Divider()

                            HStack {
                                Text("Quantity")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(quantity)")
                                    .fontWeight(.semibold)
                            }

                            Divider()

                            HStack {
                                Text("Total Amount")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("UGX \(Int(ticketType.price * Double(quantity)).formatted())")
                                    .fontWeight(.bold)
                                    .foregroundColor(RoleConfig.attendeePrimary)
                            }
                        }
                        .font(AppTypography.body)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)
                    }

                    // QR Codes
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Your Ticket\(quantity > 1 ? "s" : "")")
                            .font(AppTypography.title3)
                            .fontWeight(.semibold)

                        Text("Show \(quantity > 1 ? "these QR codes" : "this QR code") at the entrance")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        ForEach(tickets) { ticket in
                            VStack(spacing: AppSpacing.md) {
                                // QR Code
                                if let qrImage = QRCodeGenerator.generate(
                                    from: ticket.qrCodeData,
                                    size: CGSize(width: 250, height: 250)
                                ) {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .frame(width: 250, height: 250)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(AppCornerRadius.medium)
                                        .shadow(color: .black.opacity(0.1), radius: 10)
                                }

                                // Ticket ID
                                Text(ticket.id.uuidString.prefix(8).uppercased())
                                    .font(AppTypography.caption)
                                    .monospaced()
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                        }
                    }

                    // Action buttons
                    VStack(spacing: AppSpacing.md) {
                        Button(action: {
                            // TODO: Implement ticket saving/download
                            HapticFeedback.success()
                        }) {
                            Label("Save Tickets", systemImage: "arrow.down.circle.fill")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoleConfig.attendeePrimary)
                                .cornerRadius(AppCornerRadius.medium)
                        }

                        Button(action: {
                            // TODO: Add to Apple Wallet
                            HapticFeedback.light()
                        }) {
                            Label("Add to Wallet", systemImage: "wallet.pass")
                                .font(AppTypography.headline)
                                .foregroundColor(RoleConfig.attendeePrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                        }

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .font(AppTypography.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(AppCornerRadius.medium)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Share tickets
                        HapticFeedback.light()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

#Preview {
    let sampleEvent = Event.samples[0]
    let orderNumber = "ORD-123456789"
    return TicketSuccessView(
        event: sampleEvent,
        ticketType: sampleEvent.ticketTypes[0],
        quantity: 2,
        tickets: [
            Ticket(
                ticketNumber: "TKT-001234",
                orderNumber: orderNumber,
                eventId: sampleEvent.id,
                eventTitle: sampleEvent.title,
                eventDate: sampleEvent.startDate,
                eventEndDate: sampleEvent.endDate,
                eventVenue: sampleEvent.venue.name,
                eventVenueAddress: sampleEvent.venue.address,
                eventVenueCity: sampleEvent.venue.city,
                venueLatitude: sampleEvent.venue.coordinate.latitude,
                venueLongitude: sampleEvent.venue.coordinate.longitude,
                eventDescription: sampleEvent.description,
                eventOrganizerName: sampleEvent.organizerName,
                eventPosterURL: sampleEvent.posterURL,
                ticketType: sampleEvent.ticketTypes[0],
                userId: UUID(),
                purchaseDate: Date(),
                scanStatus: .unused,
                qrCodeData: "TKT:TKT-001234|ORD:\(orderNumber)"
            ),
            Ticket(
                ticketNumber: "TKT-001235",
                orderNumber: orderNumber,
                eventId: sampleEvent.id,
                eventTitle: sampleEvent.title,
                eventDate: sampleEvent.startDate,
                eventEndDate: sampleEvent.endDate,
                eventVenue: sampleEvent.venue.name,
                eventVenueAddress: sampleEvent.venue.address,
                eventVenueCity: sampleEvent.venue.city,
                venueLatitude: sampleEvent.venue.coordinate.latitude,
                venueLongitude: sampleEvent.venue.coordinate.longitude,
                eventDescription: sampleEvent.description,
                eventOrganizerName: sampleEvent.organizerName,
                eventPosterURL: sampleEvent.posterURL,
                ticketType: sampleEvent.ticketTypes[0],
                userId: UUID(),
                purchaseDate: Date(),
                scanStatus: .unused,
                qrCodeData: "TKT:TKT-001235|ORD:\(orderNumber)"
            )
        ]
    )
}

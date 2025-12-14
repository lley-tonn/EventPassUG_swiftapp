//
//  TicketDetailView.swift
//  EventPassUG
//
//  Detailed ticket view with event info, map, QR codes, and rating
//

import SwiftUI
import MapKit

struct TicketDetailView: View {
    let ticket: Ticket

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var services: ServiceContainer

    @State private var userRating: Double
    @State private var showingRatingConfirmation = false
    @State private var region: MKCoordinateRegion
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false

    init(ticket: Ticket) {
        self.ticket = ticket
        _userRating = State(initialValue: ticket.userRating ?? 0)
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: ticket.venueLatitude,
                longitude: ticket.venueLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Event poster
                    ZStack(alignment: .topLeading) {
                        if let posterURL = ticket.eventPosterURL {
                            Image(posterURL)
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(height: 240)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .overlay(
                                    Image(systemName: "ticket.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                )
                        }

                        // Status badge
                        statusBadge
                            .padding(AppSpacing.md)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Event title and organizer
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(ticket.eventTitle)
                                .font(AppTypography.title1)
                                .fontWeight(.bold)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("by \(ticket.eventOrganizerName)")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        // Ticket info card
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ticket Type")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                    Text(ticket.ticketType.name)
                                        .font(AppTypography.headline)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Price")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                    Text(ticket.ticketType.formattedPrice)
                                        .font(AppTypography.headline)
                                        .foregroundColor(RoleConfig.attendeePrimary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)

                        Divider()

                        // Date and time
                        InfoRow(
                            icon: "calendar",
                            title: "Date & Time",
                            value: DateUtilities.formatEventFullDateTime(ticket.eventDate, endDate: ticket.eventEndDate)
                        )

                        Divider()

                        // Venue with map
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            InfoRow(
                                icon: "location.fill",
                                title: "Venue",
                                value: "\(ticket.eventVenue)\n\(ticket.eventVenueAddress), \(ticket.eventVenueCity)"
                            )

                            // Map
                            Map(coordinateRegion: .constant(region), annotationItems: [ticket]) { ticket in
                                MapMarker(
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: ticket.venueLatitude,
                                        longitude: ticket.venueLongitude
                                    ),
                                    tint: RoleConfig.attendeePrimary
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .cornerRadius(AppCornerRadius.medium)
                            .allowsHitTesting(false)

                            Button(action: openInMaps) {
                                Label("Open in Maps", systemImage: "map.fill")
                                    .font(AppTypography.callout)
                                    .foregroundColor(RoleConfig.attendeePrimary)
                            }
                        }

                        Divider()

                        // Event description
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("About the Event")
                                .font(AppTypography.title3)
                                .fontWeight(.semibold)

                            Text(ticket.eventDescription)
                                .font(AppTypography.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()

                        // QR Code section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text(ticket.canBeScanned ? "Your Ticket QR Code" : "Ticket QR Code")
                                .font(AppTypography.title3)
                                .fontWeight(.semibold)

                            if !ticket.canBeScanned && !ticket.isExpired {
                                Text("This ticket has already been scanned")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            } else if ticket.isExpired {
                                Text("This ticket has expired")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Show this QR code at the entrance")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }

                            // QR Code
                            if let qrImage = QRCodeGenerator.generate(
                                from: ticket.qrCodeData,
                                size: CGSize(width: 280, height: 280)
                            ) {
                                VStack(spacing: AppSpacing.md) {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .frame(width: 280, height: 280)
                                        .padding(AppSpacing.lg)
                                        .background(Color.white)
                                        .cornerRadius(AppCornerRadius.medium)
                                        .shadow(color: .black.opacity(0.1), radius: 10)

                                    Text(ticket.qrCodeData.suffix(12).uppercased())
                                        .font(AppTypography.caption)
                                        .monospaced()
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        // Rating section for expired tickets
                        if ticket.isExpired {
                            Divider()

                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text("Rate this Event")
                                    .font(AppTypography.title3)
                                    .fontWeight(.semibold)

                                if let rating = ticket.userRating {
                                    VStack(spacing: AppSpacing.sm) {
                                        HStack(spacing: 8) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.yellow)
                                            }
                                        }

                                        Text("You rated this event \(Int(rating)) star\(Int(rating) == 1 ? "" : "s")")
                                            .font(AppTypography.body)
                                            .foregroundColor(.secondary)

                                        Button(action: {
                                            userRating = 0
                                            HapticFeedback.light()
                                        }) {
                                            Text("Change Rating")
                                                .font(AppTypography.callout)
                                                .foregroundColor(RoleConfig.attendeePrimary)
                                        }
                                    }
                                } else {
                                    VStack(spacing: AppSpacing.md) {
                                        HStack(spacing: 8) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: star <= Int(userRating) ? "star.fill" : "star")
                                                    .font(.system(size: 36))
                                                    .foregroundColor(.yellow)
                                                    .onTapGesture {
                                                        userRating = Double(star)
                                                        HapticFeedback.light()
                                                    }
                                            }
                                        }

                                        if userRating > 0 {
                                            Button(action: submitRating) {
                                                Text("Submit Rating")
                                                    .font(AppTypography.headline)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(RoleConfig.attendeePrimary)
                                                    .cornerRadius(AppCornerRadius.medium)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Purchase info
                        Divider()

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Purchase Information")
                                .font(AppTypography.title3)
                                .fontWeight(.semibold)

                            HStack {
                                Text("Purchased on")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(DateUtilities.formatEventDateTime(ticket.purchaseDate))
                            }
                            .font(AppTypography.body)

                            HStack {
                                Text("Ticket ID")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(ticket.id.uuidString.prefix(8).uppercased())
                                    .monospaced()
                            }
                            .font(AppTypography.body)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: shareTicket) {
                        HStack(spacing: 4) {
                            if isGeneratingPDF {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                                    .font(AppTypography.callout)
                            }
                        }
                    }
                    .disabled(isGeneratingPDF)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url]) { completed in
                        if completed {
                            HapticFeedback.success()
                        }
                    }
                }
            }
        }
        .alert("Rating Submitted", isPresented: $showingRatingConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thank you for rating this event!")
        }
    }

    private var statusBadge: some View {
        Group {
            if ticket.scanStatus == .scanned {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("SCANNED")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(AppCornerRadius.small)
            } else if ticket.isExpired {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                    Text("EVENT ENDED")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray)
                .cornerRadius(AppCornerRadius.small)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("ACTIVE")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RoleConfig.attendeePrimary)
                .cornerRadius(AppCornerRadius.small)
            }
        }
    }

    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: ticket.venueLatitude,
            longitude: ticket.venueLongitude
        )
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = ticket.eventVenue
        mapItem.openInMaps(launchOptions: nil)
        HapticFeedback.light()
    }

    private func submitRating() {
        Task {
            do {
                try await services.ticketService.rateTicket(ticketId: ticket.id, rating: userRating)

                // Also rate the event
                try? await services.eventService.rateEvent(
                    id: ticket.eventId,
                    rating: userRating,
                    review: nil
                )

                await MainActor.run {
                    HapticFeedback.success()
                    showingRatingConfirmation = true
                }
            } catch {
                print("Error submitting rating: \(error)")
                await MainActor.run {
                    HapticFeedback.error()
                }
            }
        }
    }

    private func shareTicket() {
        isGeneratingPDF = true
        HapticFeedback.light()

        Task {
            // Generate PDF in background
            let url = await Task.detached(priority: .userInitiated) {
                PDFGenerator.generateTicketPDF(ticket: ticket)
            }.value

            await MainActor.run {
                isGeneratingPDF = false
                if let url = url {
                    pdfURL = url
                    showingShareSheet = true
                } else {
                    HapticFeedback.error()
                }
            }
        }
    }
}

// Make Ticket conform to Identifiable for Map annotations
extension Ticket {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: venueLatitude, longitude: venueLongitude)
    }
}

#Preview {
    TicketDetailView(
        ticket: Ticket(
            ticketNumber: "TKT-789456",
            orderNumber: "ORD-987654321",
            eventId: UUID(),
            eventTitle: "Sample Music Festival 2024",
            eventDate: Date().addingTimeInterval(86400 * 7),
            eventEndDate: Date().addingTimeInterval(86400 * 7 + 3600 * 6),
            eventVenue: "Kololo Independence Grounds",
            eventVenueAddress: "Independence Avenue",
            eventVenueCity: "Kampala",
            venueLatitude: 0.3301,
            venueLongitude: 32.5811,
            eventDescription: "Join us for the biggest music festival of the year featuring top artists from across East Africa. Experience amazing performances, food, and entertainment all day long.",
            eventOrganizerName: "Premier Events Uganda",
            eventPosterURL: "sample_poster",
            ticketType: TicketType(name: "VIP", price: 150000, quantity: 100),
            userId: UUID()
        )
    )
    .environmentObject(ServiceContainer(
        authService: MockAuthService(),
        eventService: MockEventService(),
        ticketService: MockTicketService(),
        paymentService: MockPaymentService()
    ))
}

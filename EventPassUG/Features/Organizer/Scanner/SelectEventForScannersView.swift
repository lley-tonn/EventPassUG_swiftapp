//
//  SelectEventForScannersView.swift
//  EventPassUG
//
//  Event picker for scanner device management
//  Scanner access is event-scoped, so organizer must select an event first
//

import SwiftUI

struct SelectEventForScannersView: View {
    @EnvironmentObject var services: ServiceContainer
    @State private var events: [Event] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading events...")
            } else if events.isEmpty {
                emptyState
            } else {
                eventList
            }
        }
        .navigationTitle("Scanner Devices")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadEvents()
        }
    }

    // MARK: - Event List

    @ViewBuilder
    private var eventList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Info header
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text("Select an event to manage its scanner devices")
                        .font(AppTypography.callout)
                        .foregroundColor(.secondary)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(AppCornerRadius.md)

                // Active/Upcoming events first
                let activeEvents = events.filter { $0.status == .ongoing || $0.status == .published }
                let pastEvents = events.filter { $0.status == .completed }

                if !activeEvents.isEmpty {
                    eventSection(title: "ACTIVE & UPCOMING", events: activeEvents)
                }

                if !pastEvents.isEmpty {
                    eventSection(title: "PAST EVENTS", events: pastEvents)
                }
            }
            .padding(AppSpacing.md)
        }
    }

    @ViewBuilder
    private func eventSection(title: String, events: [Event]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.xs)

            VStack(spacing: AppSpacing.sm) {
                ForEach(events) { event in
                    NavigationLink(destination: ManageScannerDevicesView(event: event)) {
                        eventRowContent(event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func eventRowContent(_ event: Event) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Event poster thumbnail
            if let posterURL = event.posterURL, let url = URL(string: posterURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 56, height: 56)
                .cornerRadius(AppCornerRadius.sm)
                .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(RoleConfig.organizerPrimary.opacity(0.15))

                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(RoleConfig.organizerPrimary)
                }
                .frame(width: 56, height: 56)
                .cornerRadius(AppCornerRadius.sm)
            }

            // Event info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formatEventDate(event.startDate))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(for: event.status))
                        .frame(width: 6, height: 6)

                    Text(event.status.rawValue.capitalized)
                        .font(AppTypography.caption)
                        .foregroundColor(statusColor(for: event.status))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundColor(.secondary)

            Text("No Events")
                .font(AppTypography.title3)
                .foregroundColor(.primary)

            Text("Create an event first to manage scanner devices for it.")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            NavigationLink(destination: CreateEventWizard()) {
                Text("Create Event")
                    .font(AppTypography.buttonPrimary)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.md)
            }
        }
    }

    // MARK: - Helpers

    private func loadEvents() async {
        isLoading = true
        do {
            // Simulate loading events
            try await Task.sleep(nanoseconds: 300_000_000)
            events = Event.samples
        } catch {
            events = []
        }
        isLoading = false
    }

    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func statusColor(for status: EventStatus) -> Color {
        switch status {
        case .ongoing: return .green
        case .published: return .blue
        case .completed: return .gray
        case .cancelled: return .red
        case .draft: return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SelectEventForScannersView()
            .environmentObject(ServiceContainer(
                authService: MockAuthRepository(),
                eventService: MockEventRepository(),
                ticketService: MockTicketRepository(),
                paymentService: MockPaymentRepository()
            ))
    }
}

//
//  ExportAttendeesButton.swift
//  EventPassUG
//
//  Button component for exporting attendee lists
//  Exports data for the CURRENT event only
//

import SwiftUI

struct ExportAttendeesButton: View {
    let event: Event
    @EnvironmentObject var services: ServiceContainer

    @State private var showingOptionsSheet = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showingError = false
    @State private var selectedFilter: AttendeeExportFilter = .all
    @State private var attendeeCount: Int = 0

    var body: some View {
        Button(action: {
            showingOptionsSheet = true
            HapticFeedback.light()
        }) {
            HStack(spacing: AppSpacing.xs) {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "person.3")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text("Export Attendees")
                    .font(AppTypography.captionEmphasized)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.blue)
            .cornerRadius(AppCornerRadius.md)
        }
        .disabled(isExporting)
        .sheet(isPresented: $showingOptionsSheet) {
            AttendeeExportOptionsSheet(
                event: event,
                onExport: { filter in
                    selectedFilter = filter
                    showingOptionsSheet = false
                    exportAttendees(filter: filter)
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url]) { completed in
                    if completed {
                        HapticFeedback.success()
                    }
                    // Clean up temp file after sharing
                    try? FileManager.default.removeItem(at: url)
                    exportedFileURL = nil
                }
            }
        }
        .alert("Export Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "An unknown error occurred")
        }
    }

    private func exportAttendees(filter: AttendeeExportFilter) {
        isExporting = true

        Task {
            do {
                let exportService = AttendeeExportService(ticketService: services.ticketService)

                let fileURL = try await exportService.exportAttendees(
                    eventId: event.id,
                    eventTitle: event.title,
                    filter: filter
                )

                await MainActor.run {
                    isExporting = false
                    if let url = fileURL {
                        exportedFileURL = url
                        showingShareSheet = true
                    } else {
                        exportError = "Failed to generate export file"
                        showingError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                    showingError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Toolbar Version

struct ExportAttendeesToolbarButton: View {
    let event: Event
    @EnvironmentObject var services: ServiceContainer

    @State private var showingOptionsSheet = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showingError = false

    var body: some View {
        Button(action: {
            showingOptionsSheet = true
            HapticFeedback.light()
        }) {
            if isExporting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Label("Export Attendees", systemImage: "person.3")
            }
        }
        .disabled(isExporting)
        .sheet(isPresented: $showingOptionsSheet) {
            AttendeeExportOptionsSheet(
                event: event,
                onExport: { filter in
                    showingOptionsSheet = false
                    exportAttendees(filter: filter)
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url]) { completed in
                    if completed {
                        HapticFeedback.success()
                    }
                    try? FileManager.default.removeItem(at: url)
                    exportedFileURL = nil
                }
            }
        }
        .alert("Export Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "An unknown error occurred")
        }
    }

    private func exportAttendees(filter: AttendeeExportFilter) {
        isExporting = true

        Task {
            do {
                let exportService = AttendeeExportService(ticketService: services.ticketService)

                let fileURL = try await exportService.exportAttendees(
                    eventId: event.id,
                    eventTitle: event.title,
                    filter: filter
                )

                await MainActor.run {
                    isExporting = false
                    if let url = fileURL {
                        exportedFileURL = url
                        showingShareSheet = true
                    } else {
                        exportError = "Failed to generate export file"
                        showingError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                    showingError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExportAttendeesButton(event: Event.samples[0])
        .environmentObject(ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        ))
        .padding()
}

//
//  ExportReportButton.swift
//  EventPassUG
//
//  Button component for exporting event analytics reports
//  Exports data for the CURRENT event only
//

import SwiftUI

struct ExportReportButton: View {
    let event: Event
    let analytics: OrganizerAnalytics

    @State private var showingFormatSheet = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showingError = false

    private let exportService = EventReportExportService()

    var body: some View {
        Button(action: {
            showingFormatSheet = true
            HapticFeedback.light()
        }) {
            HStack(spacing: AppSpacing.xs) {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text("Export Report")
                    .font(AppTypography.captionEmphasized)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(RoleConfig.organizerPrimary)
            .cornerRadius(AppCornerRadius.md)
        }
        .disabled(isExporting)
        .confirmationDialog(
            "Export Format",
            isPresented: $showingFormatSheet,
            titleVisibility: .visible
        ) {
            Button("PDF (Recommended)") {
                exportReport(format: .pdf)
            }
            Button("CSV") {
                exportReport(format: .csv)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose export format for \"\(event.title)\" analytics report")
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

    private func exportReport(format: EventReportExportFormat) {
        // Verify analytics belongs to current event
        guard analytics.eventId == event.id else {
            exportError = "Cannot export: Analytics data mismatch"
            showingError = true
            return
        }

        isExporting = true

        Task {
            do {
                let fileURL = try await exportService.exportReport(
                    for: event,
                    analytics: analytics,
                    format: format
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

struct ExportReportToolbarButton: View {
    let event: Event
    let analytics: OrganizerAnalytics

    @State private var showingFormatSheet = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showingError = false

    private let exportService = EventReportExportService()

    var body: some View {
        Button(action: {
            showingFormatSheet = true
            HapticFeedback.light()
        }) {
            if isExporting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Label("Export Report", systemImage: "square.and.arrow.up")
            }
        }
        .disabled(isExporting)
        .confirmationDialog(
            "Export Format",
            isPresented: $showingFormatSheet,
            titleVisibility: .visible
        ) {
            Button("PDF (Recommended)") {
                exportReport(format: .pdf)
            }
            Button("CSV") {
                exportReport(format: .csv)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose export format for \"\(event.title)\" analytics report")
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

    private func exportReport(format: EventReportExportFormat) {
        guard analytics.eventId == event.id else {
            exportError = "Cannot export: Analytics data mismatch"
            showingError = true
            return
        }

        isExporting = true

        Task {
            do {
                let fileURL = try await exportService.exportReport(
                    for: event,
                    analytics: analytics,
                    format: format
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
    VStack(spacing: 20) {
        ExportReportButton(
            event: Event.samples[0],
            analytics: OrganizerAnalytics.mock
        )

        ExportReportToolbarButton(
            event: Event.samples[0],
            analytics: OrganizerAnalytics.mock
        )
    }
    .padding()
}

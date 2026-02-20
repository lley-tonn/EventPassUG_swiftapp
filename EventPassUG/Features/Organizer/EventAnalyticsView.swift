//
//  EventAnalyticsView.swift
//  EventPassUG
//
//  Production-ready event analytics view with proper layout and responsive design
//

import SwiftUI

struct EventAnalyticsView: View {
    @StateObject private var viewModel: EventAnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: MockAuthRepository
    @EnvironmentObject var services: ServiceContainer
    @State private var showingManageTickets = false
    @State private var showingEditEvent = false
    @State private var showDeleteConfirmation = false
    @State private var showingExportReportSheet = false
    @State private var showingExportAttendeesSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showingExportError = false

    init(event: Event) {
        _viewModel = StateObject(wrappedValue: EventAnalyticsViewModel(event: event))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Event Hero Section
                    eventHeroSection(geometry: geometry)

                    // Analytics Content
                    analyticsContent(geometry: geometry)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Export Section
                    Section("Export") {
                        Button(action: {
                            showingExportReportSheet = true
                            HapticFeedback.light()
                        }) {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }

                        Button(action: {
                            showingExportAttendeesSheet = true
                            HapticFeedback.light()
                        }) {
                            Label("Export Attendees", systemImage: "person.3")
                        }
                    }

                    Divider()

                    // Management Section
                    Button(action: {
                        showingEditEvent = true
                        HapticFeedback.light()
                    }) {
                        Label("Edit Event", systemImage: "pencil")
                    }

                    Button(action: {
                        showingManageTickets = true
                        HapticFeedback.light()
                    }) {
                        Label("Manage Tickets", systemImage: "ticket")
                    }

                    if viewModel.event.status != .ongoing {
                        Divider()

                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                            HapticFeedback.light()
                        }) {
                            Label("Delete Event", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(RoleConfig.organizerPrimary)
                }
            }
        }
        .sheet(isPresented: $showingManageTickets) {
            ManageEventTicketsView(event: viewModel.event)
                .environmentObject(ServiceContainer(
                    authService: MockAuthRepository(),
                    eventService: MockEventRepository(),
                    ticketService: MockTicketRepository(),
                    paymentService: MockPaymentRepository()
                ))
        }
        .sheet(isPresented: $showingEditEvent) {
            CreateEventWizard(existingDraft: viewModel.event)
                .environmentObject(authService)
                .environmentObject(services)
        }
        .alert("Delete Event?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            let ticketsSold = viewModel.totalTicketsSold
            if ticketsSold > 0 {
                Text("This will permanently delete '\(viewModel.event.title)' and affect \(ticketsSold) attendee\(ticketsSold == 1 ? "" : "s") with active tickets.")
            } else {
                Text("This will permanently delete '\(viewModel.event.title)'.")
            }
        }
        // MARK: - Export Report Sheet
        .confirmationDialog(
            "Export Report Format",
            isPresented: $showingExportReportSheet,
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
            Text("Export analytics report for \"\(viewModel.event.title)\"")
        }
        // MARK: - Export Attendees Sheet
        .sheet(isPresented: $showingExportAttendeesSheet) {
            AttendeeExportOptionsSheet(event: viewModel.event) { filter in
                showingExportAttendeesSheet = false
                exportAttendees(filter: filter)
            }
            .environmentObject(services)
            .presentationDetents([.medium])
        }
        // MARK: - Share Sheet for Export
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url]) { completed in
                    if completed {
                        HapticFeedback.success()
                    }
                    // Clean up temp file
                    try? FileManager.default.removeItem(at: url)
                    exportedFileURL = nil
                }
            }
        }
        .alert("Export Failed", isPresented: $showingExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "An unknown error occurred")
        }
        .task {
            await viewModel.loadAnalytics()
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private func eventHeroSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Event Poster with Gradient Overlay
            ZStack(alignment: .bottomLeading) {
                if let posterURL = viewModel.event.posterURL {
                    EventPosterImage(posterURL: posterURL, height: 220, cornerRadius: 0)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                }

                // Gradient overlay for better text readability
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)

                // Event Title & Status
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(viewModel.event.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(radius: 2)

                    statusBadge
                }
                .padding(AppSpacing.md)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            // Event Date Info
            eventDateBar
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.event.status.iconName)
                .font(.system(size: 12, weight: .semibold))
            Text(viewModel.event.status.rawValue.capitalized)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(viewModel.event.status.color)
        .cornerRadius(AppCornerRadius.small)
    }

    private var eventDateBar: some View {
        HStack {
            Label(
                DateUtilities.formatEventDateTime(viewModel.event.startDate),
                systemImage: "calendar"
            )
            .font(.system(size: 14))
            .foregroundColor(.secondary)

            Spacer()

            Label(viewModel.event.venue.city, systemImage: "location.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    // MARK: - Analytics Content

    @ViewBuilder
    private func analyticsContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: AppSpacing.lg) {
            // Export Actions (Quick Access)
            exportActionsSection

            // Overview Metrics Grid
            overviewMetricsGrid(geometry: geometry)

            // Revenue Section
            revenueSection

            // Ticket Sales Breakdown
            ticketSalesSection

            // Engagement Metrics
            engagementSection
        }
        .padding(AppSpacing.md)
        .padding(.bottom, AppSpacing.xl) // Extra bottom padding for scroll
    }

    // MARK: - Export Actions Section

    @ViewBuilder
    private var exportActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Export Data")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: AppSpacing.sm) {
                // Export Report Button
                Button(action: {
                    showingExportReportSheet = true
                    HapticFeedback.light()
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Image(systemName: "chart.bar.doc.horizontal")
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

                // Export Attendees Button
                Button(action: {
                    showingExportAttendeesSheet = true
                    HapticFeedback.light()
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.3")
                            .font(.system(size: 14, weight: .semibold))
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

                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }

    // MARK: - Overview Metrics

    @ViewBuilder
    private func overviewMetricsGrid(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Overview")

            LazyVGrid(
                columns: ResponsiveGrid.gridItems(
                    isLandscape: geometry.size.width > geometry.size.height,
                    baseColumns: 2,
                    spacing: AppSpacing.md
                ),
                spacing: AppSpacing.md
            ) {
                MetricCard(
                    title: "Impressions",
                    value: "\(viewModel.impressions)",
                    icon: "eye.fill",
                    subtitle: "\(viewModel.uniqueViews) unique",
                    color: .blue
                )

                MetricCard(
                    title: "Likes",
                    value: "\(viewModel.event.likeCount)",
                    icon: "heart.fill",
                    color: .pink
                )

                MetricCard(
                    title: "Tickets Sold",
                    value: "\(viewModel.totalTicketsSold)",
                    icon: "ticket.fill",
                    subtitle: "\(Int(viewModel.overallSalesPercentage * 100))% of capacity",
                    color: RoleConfig.organizerPrimary
                )

                MetricCard(
                    title: "Shares",
                    value: "\(viewModel.shareCount)",
                    icon: "square.and.arrow.up.fill",
                    color: .green
                )
            }
        }
    }

    // MARK: - Revenue Section

    @ViewBuilder
    private var revenueSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Revenue")

            // Revenue Card
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("UGX \(Int(viewModel.totalRevenue).formatted())")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Total Revenue")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()
                        .padding(.vertical, AppSpacing.xs)

                    // Additional stats
                    HStack(spacing: AppSpacing.lg) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg. Ticket")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("UGX \(Int(viewModel.averageTicketPrice).formatted())")
                                .font(.system(size: 14, weight: .semibold))
                        }

                        Divider()
                            .frame(height: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Conversion")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", viewModel.conversionRate))
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
        }
    }

    // MARK: - Ticket Sales Section

    @ViewBuilder
    private var ticketSalesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Ticket Sales by Type")

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.event.ticketTypes) { ticketType in
                    TicketSalesCard(ticketType: ticketType, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Engagement Section

    @ViewBuilder
    private var engagementSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Engagement")

            VStack(spacing: AppSpacing.sm) {
                // Rating
                engagementRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Average Rating",
                    value: viewModel.event.totalRatings > 0
                        ? String(format: "%.1f (%d reviews)", viewModel.event.rating, viewModel.event.totalRatings)
                        : "No ratings yet"
                )

                Divider()

                // Views to Sales Ratio
                engagementRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .purple,
                    title: "View-to-Sale Ratio",
                    value: String(format: "1:%.1f", Double(viewModel.impressions) / max(Double(viewModel.totalTicketsSold), 1))
                )
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.primary)
    }

    private func engagementRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 32)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Actions

    private func deleteEvent() {
        Task {
            do {
                try await services.eventService.deleteEvent(id: viewModel.event.id)

                await MainActor.run {
                    HapticFeedback.success()
                    dismiss()
                }
            } catch {
                print("Error deleting event: \(error)")
                await MainActor.run {
                    HapticFeedback.error()
                }
            }
        }
    }

    // MARK: - Export Functions

    /// Exports analytics report for the CURRENT event only
    private func exportReport(format: EventReportExportFormat) {
        // Safety check: Ensure we're exporting for the correct event
        guard viewModel.analytics?.eventId == viewModel.event.id else {
            // If analytics haven't loaded, generate from event data
            Task {
                await exportReportWithGeneratedAnalytics(format: format)
            }
            return
        }

        isExporting = true

        Task {
            do {
                let exportService = EventReportExportService()
                guard let analytics = viewModel.analytics else {
                    await MainActor.run {
                        exportError = "Analytics not available"
                        showingExportError = true
                        isExporting = false
                    }
                    return
                }

                let fileURL = try await exportService.exportReport(
                    for: viewModel.event,
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
                        showingExportError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                    showingExportError = true
                    HapticFeedback.error()
                }
            }
        }
    }

    /// Fallback export using generated analytics from event data
    private func exportReportWithGeneratedAnalytics(format: EventReportExportFormat) async {
        await MainActor.run {
            isExporting = true
        }

        do {
            // Generate analytics from event data
            let analytics = viewModel.generateAnalyticsFromEvent()
            let exportService = EventReportExportService()

            let fileURL = try await exportService.exportReport(
                for: viewModel.event,
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
                    showingExportError = true
                }
            }
        } catch {
            await MainActor.run {
                isExporting = false
                exportError = error.localizedDescription
                showingExportError = true
                HapticFeedback.error()
            }
        }
    }

    /// Exports attendee list for the CURRENT event only
    private func exportAttendees(filter: AttendeeExportFilter) {
        isExporting = true

        Task {
            do {
                let exportService = AttendeeExportService(
                    ticketService: services.ticketService
                )

                // CRITICAL: Export only attendees for THIS event
                let fileURL = try await exportService.exportAttendees(
                    eventId: viewModel.event.id,
                    eventTitle: viewModel.event.title,
                    filter: filter
                )

                await MainActor.run {
                    isExporting = false
                    if let url = fileURL {
                        exportedFileURL = url
                        showingShareSheet = true
                    } else {
                        exportError = "Failed to generate export file"
                        showingExportError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                    showingExportError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Supporting Views
// Note: MetricCard is now defined in AnalyticsDashboardComponents.swift

struct TicketSalesCard: View {
    let ticketType: TicketType
    let viewModel: EventAnalyticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
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

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(ticketType.sold)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(RoleConfig.organizerPrimary)

                        Image(systemName: "ticket.fill")
                            .font(.system(size: 14))
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }

                    if ticketType.isUnlimitedQuantity {
                        Text("Unlimited")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(ticketType.sold) / \(ticketType.quantity)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress Bar
            if !ticketType.isUnlimitedQuantity {
                ProgressBar(
                    progress: viewModel.salesPercentage(for: ticketType),
                    color: RoleConfig.organizerPrimary
                )
            }

            // Revenue
            HStack {
                Text("Revenue:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Spacer()

                Text("UGX \(Int(viewModel.revenue(for: ticketType)).formatted())")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct ProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Extensions

extension EventStatus {
    var iconName: String {
        switch self {
        case .draft: return "doc.text"
        case .published: return "checkmark.circle.fill"
        case .ongoing: return "play.circle.fill"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .draft: return .orange
        case .published: return .green
        case .ongoing: return .blue
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        EventAnalyticsView(event: Event.samples[0])
    }
}

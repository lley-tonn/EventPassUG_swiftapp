//
//  AttendeeExportOptionsSheet.swift
//  EventPassUG
//
//  Sheet for selecting attendee export filter options
//  Displays filter options for a SPECIFIC event's attendees
//

import SwiftUI

struct AttendeeExportOptionsSheet: View {
    let event: Event
    let onExport: (AttendeeExportFilter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: AttendeeExportFilter = .all

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    // Header with event info
                    headerSection

                    // Filter Options
                    filterOptionsSection
                }
                .padding(.bottom, 100) // Space for fixed bottom button
            }
            .safeAreaInset(edge: .bottom) {
                // Export Button - fixed at bottom
                exportButtonSection
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Export Attendees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(RoleConfig.organizerPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("Select attendees to export")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.md)
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Filter Options Section

    @ViewBuilder
    private var filterOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("FILTER OPTIONS")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

            VStack(spacing: 0) {
                ForEach(AttendeeExportFilter.allCases) { filter in
                    filterOptionRow(filter: filter)

                    if filter != AttendeeExportFilter.allCases.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.md)
            .padding(.horizontal, AppSpacing.md)
        }
    }

    @ViewBuilder
    private func filterOptionRow(filter: AttendeeExportFilter) -> some View {
        Button(action: {
            selectedFilter = filter
            HapticFeedback.selection()
        }) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                Image(systemName: filter.icon)
                    .font(.system(size: 20))
                    .foregroundColor(filterColor(for: filter))
                    .frame(width: 32)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(filter.rawValue)
                        .font(AppTypography.callout)
                        .foregroundColor(.primary)

                    Text(filter.description)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if selectedFilter == filter {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(RoleConfig.organizerPrimary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func filterColor(for filter: AttendeeExportFilter) -> Color {
        switch filter {
        case .all:
            return .blue
        case .checkedIn:
            return .green
        case .vip:
            return .yellow
        case .marketingConsented:
            return .purple
        }
    }

    // MARK: - Export Button Section

    @ViewBuilder
    private var exportButtonSection: some View {
        VStack(spacing: AppSpacing.sm) {
            // Privacy Notice
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)

                Text("Contact info (email/phone) is never exported")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            // Export Button
            Button(action: {
                HapticFeedback.medium()
                onExport(selectedFilter)
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Export as CSV")
                        .font(AppTypography.buttonPrimary)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoleConfig.organizerPrimary)
                .cornerRadius(AppCornerRadius.md)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

// MARK: - Preview

#Preview {
    AttendeeExportOptionsSheet(event: Event.samples[0]) { filter in
        print("Export with filter: \(filter)")
    }
}

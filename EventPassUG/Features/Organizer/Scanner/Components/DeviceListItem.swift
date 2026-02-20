//
//  DeviceListItem.swift
//  EventPassUG
//
//  Row component for displaying a connected scanner device
//

import SwiftUI

struct DeviceListItem: View {
    let scanner: ConnectedScanner
    let onRemove: () -> Void
    let onRename: () -> Void

    @State private var showingRemoveConfirmation = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Device icon
            deviceIcon

            // Device info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(scanner.device.deviceName)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    ScannerStatusBadge(status: scanner.session.status)
                }

                HStack(spacing: AppSpacing.sm) {
                    // Last active
                    Label {
                        Text(scanner.lastActivity)
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    // Scan count
                    Label {
                        Text("\(scanner.session.scanCount) scans")
                    } icon: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions menu
            Menu {
                Button(action: onRename) {
                    Label("Rename Device", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive, action: {
                    showingRemoveConfirmation = true
                }) {
                    Label("Remove Device", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.md)
        .confirmationDialog(
            "Remove Scanner",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive, action: onRemove)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will immediately disconnect \"\(scanner.device.deviceName)\" and prevent it from scanning tickets.")
        }
    }

    @ViewBuilder
    private var deviceIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: scanner.device.platform.icon)
                .font(.system(size: 20))
                .foregroundColor(statusColor)
        }
    }

    private var statusColor: Color {
        switch scanner.session.status {
        case .active: return .green
        case .pending: return .yellow
        case .revoked: return .red
        case .expired: return .gray
        }
    }
}

// MARK: - Compact Device List Item

struct CompactDeviceListItem: View {
    let scanner: ConnectedScanner
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: scanner.device.platform.icon)
                .font(.system(size: 16))
                .foregroundColor(scanner.isActive ? .green : .gray)

            Text(scanner.device.deviceName)
                .font(AppTypography.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            if scanner.isActive {
                Text(scanner.lastActivity)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(scanner.session.status.displayName)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Empty State

struct NoScannersEmptyState: View {
    let onAddScanner: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))

            Text("No Scanner Devices")
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(.primary)

            Text("Connect staff phones to scan tickets at your event entrance.")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onAddScanner) {
                Label("Add Scanner Device", systemImage: "plus.circle.fill")
                    .font(AppTypography.buttonPrimary)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.md)
            }
            .padding(.top, AppSpacing.sm)
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Previews

#Preview("Device List Item") {
    VStack(spacing: 12) {
        DeviceListItem(
            scanner: ConnectedScanner.mockScanners[0],
            onRemove: {},
            onRename: {}
        )

        DeviceListItem(
            scanner: ConnectedScanner.mockScanners[1],
            onRemove: {},
            onRename: {}
        )

        DeviceListItem(
            scanner: ConnectedScanner.mockScanners[2],
            onRemove: {},
            onRename: {}
        )
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Empty State") {
    NoScannersEmptyState(onAddScanner: {})
        .background(Color(UIColor.systemGroupedBackground))
}

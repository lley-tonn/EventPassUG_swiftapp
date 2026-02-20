//
//  ScannerStatusBadge.swift
//  EventPassUG
//
//  Status badge component for scanner session status
//

import SwiftUI

struct ScannerStatusBadge: View {
    let status: ScannerSessionStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .semibold))

            Text(status.displayName)
                .font(AppTypography.captionEmphasized)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(AppCornerRadius.sm)
    }

    private var backgroundColor: Color {
        switch status {
        case .pending:
            return Color.yellow.opacity(0.15)
        case .active:
            return Color.green.opacity(0.15)
        case .revoked:
            return Color.red.opacity(0.15)
        case .expired:
            return Color.gray.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .pending:
            return Color.yellow
        case .active:
            return Color.green
        case .revoked:
            return Color.red
        case .expired:
            return Color.gray
        }
    }
}

// MARK: - Scan Result Badge

struct ScanResultBadge: View {
    let status: ScanResultStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.system(size: 14, weight: .semibold))

            Text(status.displayMessage)
                .font(AppTypography.calloutEmphasized)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(AppCornerRadius.md)
    }

    private var backgroundColor: Color {
        switch status {
        case .valid:
            return Color.green.opacity(0.15)
        case .alreadyUsed:
            return Color.orange.opacity(0.15)
        default:
            return Color.red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .valid:
            return Color.green
        case .alreadyUsed:
            return Color.orange
        default:
            return Color.red
        }
    }
}

// MARK: - Connection Status Indicator

struct ConnectionStatusIndicator: View {
    let isConnected: Bool
    let eventTitle: String?

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(isConnected ? "Connected" : "Disconnected")
                    .font(AppTypography.captionEmphasized)
                    .foregroundColor(isConnected ? .green : .red)

                if let eventTitle = eventTitle, isConnected {
                    Text(eventTitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    VStack(spacing: 16) {
        Text("Session Status")
            .font(.headline)

        HStack(spacing: 12) {
            ScannerStatusBadge(status: .pending)
            ScannerStatusBadge(status: .active)
            ScannerStatusBadge(status: .revoked)
            ScannerStatusBadge(status: .expired)
        }

        Divider()
            .padding(.vertical)

        Text("Scan Results")
            .font(.headline)

        VStack(spacing: 8) {
            ScanResultBadge(status: .valid)
            ScanResultBadge(status: .alreadyUsed)
            ScanResultBadge(status: .invalidTicket)
            ScanResultBadge(status: .wrongEvent)
        }

        Divider()
            .padding(.vertical)

        Text("Connection Status")
            .font(.headline)

        VStack(spacing: 8) {
            ConnectionStatusIndicator(isConnected: true, eventTitle: "Kampala Music Festival")
            ConnectionStatusIndicator(isConnected: false, eventTitle: nil)
        }
    }
    .padding()
}

//
//  ScannerConnectView.swift
//  EventPassUG
//
//  Scanner phone view for connecting as a ticket scanner device
//  CRITICAL: No login required - connects via QR or pairing code
//

import SwiftUI
import AVFoundation

struct ScannerConnectView: View {
    @StateObject private var viewModel = ScannerConnectViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showingCodeEntry = false
    @State private var showingQRScanner = false
    @State private var pairingCode = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isConnected {
                    connectedContent
                } else if viewModel.isConnecting {
                    connectingContent
                } else {
                    connectPromptContent
                }
            }
            .navigationTitle("Scanner Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.isConnected {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCodeEntry) {
                PairingCodeEntrySheet(
                    code: $pairingCode,
                    isConnecting: viewModel.isConnecting,
                    onConnect: {
                        Task {
                            await viewModel.connectWithCode(pairingCode)
                            if viewModel.isConnected {
                                showingCodeEntry = false
                            }
                        }
                    },
                    onCancel: {
                        pairingCode = ""
                        showingCodeEntry = false
                    }
                )
            }
            .sheet(isPresented: $showingQRScanner) {
                QRScannerSheet(onScanned: { qrData in
                    showingQRScanner = false
                    Task {
                        await viewModel.connectWithQR(qrData)
                    }
                })
            }
            .alert("Connection Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Connect Prompt Content

    @ViewBuilder
    private var connectPromptContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(RoleConfig.organizerPrimary.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(RoleConfig.organizerPrimary)
            }

            // Title and description
            VStack(spacing: AppSpacing.sm) {
                Text("Connect as Scanner")
                    .font(AppTypography.title2)
                    .foregroundColor(.primary)

                Text("Scan the pairing QR code shown on the organizer's device, or enter the 6-digit code.")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.md) {
                // Scan QR button (primary)
                Button(action: { showingQRScanner = true }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Scan Pairing QR")
                            .font(AppTypography.buttonPrimary)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.md)
                }

                // Enter code button (secondary)
                Button(action: { showingCodeEntry = true }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "number")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Enter Code Manually")
                            .font(AppTypography.buttonSecondary)
                    }
                    .foregroundColor(RoleConfig.organizerPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(RoleConfig.organizerPrimary.opacity(0.15))
                    .cornerRadius(AppCornerRadius.md)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Connecting Content

    @ViewBuilder
    private var connectingContent: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Connecting...")
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(.primary)

            Text("Please wait while we verify the pairing code.")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Connected Content

    @ViewBuilder
    private var connectedContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("Connected!")
                    .font(AppTypography.title2)
                    .foregroundColor(.primary)

                if let eventTitle = viewModel.connectedEventTitle {
                    Text(eventTitle)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.secondary)
                }
            }

            // Connection status
            ConnectionStatusIndicator(
                isConnected: true,
                eventTitle: viewModel.connectedEventTitle
            )

            Spacer()

            // Actions
            VStack(spacing: AppSpacing.md) {
                // Start scanning button
                NavigationLink(destination: TicketScannerView()) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Start Scanning Tickets")
                            .font(AppTypography.buttonPrimary)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(Color.green)
                    .cornerRadius(AppCornerRadius.md)
                }

                // Disconnect button
                Button(action: {
                    viewModel.disconnect()
                }) {
                    Text("Disconnect")
                        .font(AppTypography.buttonSecondary)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
    }
}

// MARK: - Pairing Code Entry Sheet

struct PairingCodeEntrySheet: View {
    @Binding var code: String
    let isConnecting: Bool
    let onConnect: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Text("Enter the 6-digit pairing code shown on the organizer's device.")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppSpacing.lg)

                // Code input display
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        let character = index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""

                        Text(character)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 56)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                    .stroke(
                                        index == code.count ? RoleConfig.organizerPrimary : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                }

                // Hidden text field for input
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .opacity(0)
                    .frame(height: 1)
                    .onChange(of: code) { newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            code = String(newValue.prefix(6))
                        }
                        // Filter non-numeric
                        code = code.filter { $0.isNumber }

                        // Auto-connect when complete
                        if code.count == 6 {
                            onConnect()
                        }
                    }

                Spacer()

                // Connect button
                Button(action: onConnect) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Connect")
                            .font(AppTypography.buttonPrimary)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(code.count == 6 ? RoleConfig.organizerPrimary : Color.gray)
                .cornerRadius(AppCornerRadius.md)
                .disabled(code.count != 6 || isConnecting)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)
            }
            .padding(AppSpacing.md)
            .navigationTitle("Enter Pairing Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - QR Scanner Sheet

struct QRScannerSheet: View {
    let onScanned: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var torchOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Camera preview would go here
                // For now, show a mock scanner view
                VStack(spacing: AppSpacing.lg) {
                    Spacer()

                    // Scanner frame
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            // Corner accents
                            GeometryReader { geometry in
                                let size = geometry.size
                                let cornerLength: CGFloat = 30
                                let lineWidth: CGFloat = 4

                                Path { path in
                                    // Top left
                                    path.move(to: CGPoint(x: 0, y: cornerLength))
                                    path.addLine(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: cornerLength, y: 0))

                                    // Top right
                                    path.move(to: CGPoint(x: size.width - cornerLength, y: 0))
                                    path.addLine(to: CGPoint(x: size.width, y: 0))
                                    path.addLine(to: CGPoint(x: size.width, y: cornerLength))

                                    // Bottom right
                                    path.move(to: CGPoint(x: size.width, y: size.height - cornerLength))
                                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                                    path.addLine(to: CGPoint(x: size.width - cornerLength, y: size.height))

                                    // Bottom left
                                    path.move(to: CGPoint(x: cornerLength, y: size.height))
                                    path.addLine(to: CGPoint(x: 0, y: size.height))
                                    path.addLine(to: CGPoint(x: 0, y: size.height - cornerLength))
                                }
                                .stroke(RoleConfig.organizerPrimary, lineWidth: lineWidth)
                            }
                        )

                    Text("Point camera at pairing QR code")
                        .font(AppTypography.callout)
                        .foregroundColor(.white)

                    Spacer()

                    // Torch toggle
                    Button(action: { torchOn.toggle() }) {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.bottom, AppSpacing.xl)

                    // Mock: Simulate successful scan after delay
                    // In production, this would use AVCaptureSession
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                // Simulate QR scan for preview/testing
                #if DEBUG
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let mockQR = "eventpass://pair?session=\(UUID().uuidString)&event=\(UUID().uuidString)"
                    onScanned(mockQR)
                }
                #endif
            }
        }
    }
}

// MARK: - Ticket Scanner View (Placeholder)

struct TicketScannerView: View {
    @StateObject private var viewModel = TicketScannerViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                // Scanner frame
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .stroke(viewModel.lastResult?.isSuccess == true ? Color.green :
                            viewModel.lastResult != nil ? Color.red : Color.white,
                            lineWidth: 3)
                    .frame(width: 280, height: 280)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.lastResult?.status)

                // Status display
                if let result = viewModel.lastResult {
                    ScanResultCard(result: result)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Scan ticket QR code")
                        .font(AppTypography.callout)
                        .foregroundColor(.white)
                }

                // Stats
                HStack(spacing: AppSpacing.xl) {
                    StatDisplay(label: "Scanned", value: "\(viewModel.scanCount)")
                    StatDisplay(label: "Valid", value: "\(viewModel.validCount)")
                }
                .padding(.top, AppSpacing.lg)
            }
        }
        .navigationTitle("Scanning")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

// MARK: - Scan Result Card

private struct ScanResultCard: View {
    let result: ScanResult

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: result.status.icon)
                .font(.system(size: 48))
                .foregroundColor(result.isSuccess ? .green : .red)

            Text(result.status.displayMessage)
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(.white)

            if let name = result.attendeeName {
                Text(name)
                    .font(AppTypography.title3)
                    .foregroundColor(.white)
            }

            if let type = result.ticketType {
                Text(type)
                    .font(AppTypography.callout)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(AppSpacing.lg)
        .background(result.isSuccess ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        .cornerRadius(AppCornerRadius.lg)
    }
}

// MARK: - Stat Display

private struct StatDisplay: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - View Models

@MainActor
class ScannerConnectViewModel: ObservableObject {
    @Published var isConnecting = false
    @Published var isConnected = false
    @Published var connectedEventTitle: String?
    @Published var errorMessage: String?

    private let scannerService = ScannerSessionService()

    func connectWithQR(_ qrData: String) async {
        isConnecting = true
        errorMessage = nil

        do {
            _ = try await scannerService.connectWithQR(
                qrData,
                deviceId: DeviceIdentification.deviceId,
                deviceName: DeviceIdentification.deviceName
            )

            isConnected = true
            connectedEventTitle = "Connected Event" // Would fetch actual title
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }

        isConnecting = false
    }

    func connectWithCode(_ code: String) async {
        isConnecting = true
        errorMessage = nil

        do {
            _ = try await scannerService.connectWithCode(
                code,
                deviceId: DeviceIdentification.deviceId,
                deviceName: DeviceIdentification.deviceName
            )

            isConnected = true
            connectedEventTitle = "Connected Event" // Would fetch actual title
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }

        isConnecting = false
    }

    func disconnect() {
        scannerService.clearCurrentSession()
        isConnected = false
        connectedEventTitle = nil
    }

    func clearError() {
        errorMessage = nil
    }
}

@MainActor
class TicketScannerViewModel: ObservableObject {
    @Published var lastResult: ScanResult?
    @Published var scanCount = 0
    @Published var validCount = 0

    private let scannerService = ScannerSessionService()

    func processScan(_ qrData: String) async {
        guard let session = scannerService.getCurrentSession() else {
            lastResult = ScanResult(
                ticketId: UUID(),
                status: .sessionInvalid,
                message: "No active scanner session"
            )
            return
        }

        let request = ScanRequest(
            scannerSessionId: session.id,
            eventId: session.eventId,
            ticketQR: qrData,
            deviceId: DeviceIdentification.deviceId
        )

        do {
            let result = try await scannerService.validateScan(request)
            lastResult = result
            scanCount += 1

            if result.isSuccess {
                validCount += 1
                HapticFeedback.success()
            } else {
                HapticFeedback.error()
            }
        } catch {
            lastResult = ScanResult(
                ticketId: UUID(),
                status: .sessionInvalid,
                message: error.localizedDescription
            )
            HapticFeedback.error()
        }
    }
}

// MARK: - Previews

#Preview("Connect View") {
    ScannerConnectView()
}

#Preview("Code Entry") {
    PairingCodeEntrySheet(
        code: .constant("123"),
        isConnecting: false,
        onConnect: {},
        onCancel: {}
    )
}

#Preview("QR Scanner") {
    QRScannerSheet(onScanned: { _ in })
}

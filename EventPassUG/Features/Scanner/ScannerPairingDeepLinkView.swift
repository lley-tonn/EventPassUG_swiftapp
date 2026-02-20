//
//  ScannerPairingDeepLinkView.swift
//  EventPassUG
//
//  View presented when app is opened via scanner pairing deep link
//  Prompts user to enter the 6-digit pairing code
//

import SwiftUI

struct ScannerPairingDeepLinkView: View {
    let pairingData: ScannerPairingDeepLinkData?
    let onDismiss: () -> Void

    @StateObject private var viewModel = ScannerPairingDeepLinkViewModel()
    @State private var pairingCode = ""
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        RoleConfig.organizerPrimary.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                if viewModel.isConnected {
                    connectedContent
                } else {
                    codeEntryContent
                }
            }
            .navigationTitle("Connect Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
            .alert("Connection Error", isPresented: $viewModel.showError) {
                Button("Try Again", role: .cancel) {
                    pairingCode = ""
                    isCodeFocused = true
                }
            } message: {
                Text(viewModel.errorMessage ?? "Failed to connect. Please check the code and try again.")
            }
            .onAppear {
                // Auto-focus code input
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isCodeFocused = true
                }
            }
        }
    }

    // MARK: - Code Entry Content

    @ViewBuilder
    private var codeEntryContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(RoleConfig.organizerPrimary.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "link.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(RoleConfig.organizerPrimary)
            }

            // Title
            VStack(spacing: AppSpacing.sm) {
                Text("Enter Pairing Code")
                    .font(AppTypography.title2)
                    .foregroundColor(.primary)

                Text("Enter the 6-digit code shown on the organizer's device")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            // Code input boxes
            codeInputSection

            Spacer()

            // Connect button
            connectButton
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Code Input Section

    @ViewBuilder
    private var codeInputSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Visual code boxes
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    codeDigitBox(at: index)
                }
            }

            // Hidden text field for keyboard input
            TextField("", text: $pairingCode)
                .keyboardType(.numberPad)
                .focused($isCodeFocused)
                .opacity(0)
                .frame(height: 1)
                .onChange(of: pairingCode) { newValue in
                    // Limit to 6 digits and filter non-numeric
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 6 {
                        pairingCode = String(filtered.prefix(6))
                    } else if filtered != newValue {
                        pairingCode = filtered
                    }

                    // Auto-connect when 6 digits entered
                    if pairingCode.count == 6 {
                        connect()
                    }
                }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private func codeDigitBox(at index: Int) -> some View {
        let digit = index < pairingCode.count ?
            String(pairingCode[pairingCode.index(pairingCode.startIndex, offsetBy: index)]) : ""
        let isCurrentIndex = index == pairingCode.count

        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(Color(UIColor.secondarySystemGroupedBackground))

            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .stroke(
                    isCurrentIndex ? RoleConfig.organizerPrimary : Color.clear,
                    lineWidth: 2
                )

            Text(digit)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(width: 48, height: 60)
        .animation(.easeInOut(duration: 0.15), value: pairingCode)
    }

    // MARK: - Connect Button

    @ViewBuilder
    private var connectButton: some View {
        Button(action: connect) {
            HStack(spacing: AppSpacing.sm) {
                if viewModel.isConnecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "link")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Connect as Scanner")
                        .font(AppTypography.buttonPrimary)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(pairingCode.count == 6 ? RoleConfig.organizerPrimary : Color.gray)
            .cornerRadius(AppCornerRadius.md)
        }
        .disabled(pairingCode.count != 6 || viewModel.isConnecting)
    }

    // MARK: - Connected Content

    @ViewBuilder
    private var connectedContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Success icon with animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }
            .scaleEffect(viewModel.isConnected ? 1.0 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isConnected)

            VStack(spacing: AppSpacing.sm) {
                Text("Connected!")
                    .font(AppTypography.title2)
                    .foregroundColor(.primary)

                if let eventTitle = viewModel.connectedEventTitle {
                    Text(eventTitle)
                        .font(AppTypography.calloutEmphasized)
                        .foregroundColor(.secondary)
                }

                Text("This device is now authorized to scan tickets")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()

            // Actions
            VStack(spacing: AppSpacing.md) {
                Button(action: {
                    // Navigate to scanner view
                    // For now, just dismiss and let user access scanner mode
                    onDismiss()
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Start Scanning")
                            .font(AppTypography.buttonPrimary)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(Color.green)
                    .cornerRadius(AppCornerRadius.md)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Actions

    private func connect() {
        guard pairingCode.count == 6 else { return }

        isCodeFocused = false
        HapticFeedback.medium()

        Task {
            await viewModel.connect(withCode: pairingCode)
        }
    }
}

// MARK: - View Model

@MainActor
class ScannerPairingDeepLinkViewModel: ObservableObject {
    @Published var isConnecting = false
    @Published var isConnected = false
    @Published var connectedEventTitle: String?
    @Published var showError = false
    @Published var errorMessage: String?

    private let scannerService = ScannerSessionService()

    func connect(withCode code: String) async {
        isConnecting = true
        showError = false
        errorMessage = nil

        do {
            _ = try await scannerService.connectWithCode(
                code,
                deviceId: DeviceIdentification.deviceId,
                deviceName: DeviceIdentification.deviceName
            )

            isConnected = true
            connectedEventTitle = "Event" // Would fetch actual title from service
            HapticFeedback.success()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticFeedback.error()
        }

        isConnecting = false
    }
}

// MARK: - Preview

#Preview("Code Entry") {
    ScannerPairingDeepLinkView(
        pairingData: ScannerPairingDeepLinkData(
            sessionId: UUID(),
            eventId: UUID()
        ),
        onDismiss: {}
    )
}

#Preview("Connected") {
    let view = ScannerPairingDeepLinkView(
        pairingData: nil,
        onDismiss: {}
    )
    return view
}

//
//  PairScannerView.swift
//  EventPassUG
//
//  View for generating pairing QR code and code for scanner devices
//  CRITICAL: Pairing sessions expire after 5 minutes
//

import SwiftUI

struct PairScannerView: View {
    let event: Event
    let onScannerConnected: (ConnectedScanner) -> Void

    @StateObject private var viewModel: PairScannerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingCodeInput = false

    init(event: Event, onScannerConnected: @escaping (ConnectedScanner) -> Void) {
        self.event = event
        self.onScannerConnected = onScannerConnected
        self._viewModel = StateObject(wrappedValue: PairScannerViewModel(event: event))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isGenerating {
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating pairing code...")
                            .font(AppTypography.callout)
                            .foregroundColor(.secondary)
                    }
                } else if let pairingSession = viewModel.pairingSession {
                    pairingContent(pairingSession)
                } else if let error = viewModel.errorMessage {
                    errorContent(error)
                } else {
                    generatePrompt
                }
            }
            .navigationTitle("Add Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.generatePairingSession()
            }
        }
    }

    // MARK: - Pairing Content

    @ViewBuilder
    private func pairingContent(_ session: PairingSession) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Event context
                eventHeader

                // QR Code
                qrCodeSection(session)

                // Pairing code
                pairingCodeSection(session)

                // Instructions
                instructionsSection

                // Expiry timer
                expirySection(session)
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Event Header

    @ViewBuilder
    private var eventHeader: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: 20))
                .foregroundColor(RoleConfig.organizerPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pairing for")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Text(event.title)
                    .font(AppTypography.calloutEmphasized)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - QR Code Section

    @ViewBuilder
    private func qrCodeSection(_ session: PairingSession) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text("Scan this QR code")
                .font(AppTypography.bodyEmphasized)
                .foregroundColor(.primary)

            PairingQRCodeView(pairingSession: session, size: 220)
                .padding(AppSpacing.md)
                .background(Color.white)
                .cornerRadius(AppCornerRadius.lg)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            Text("Open EventPass app → Scanner Mode → Connect as Scanner")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Pairing Code Section

    @ViewBuilder
    private func pairingCodeSection(_ session: PairingSession) -> some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Text("Or enter this code")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    UIPasteboard.general.string = session.pairingCode
                    HapticFeedback.success()
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(AppTypography.caption)
                        .foregroundColor(RoleConfig.organizerPrimary)
                }
            }

            // Large pairing code display
            HStack(spacing: 8) {
                ForEach(Array(session.pairingCode), id: \.self) { digit in
                    Text(String(digit))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 56)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.sm)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.md)
    }

    // MARK: - Instructions Section

    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("INSTRUCTIONS")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                InstructionRow(number: 1, text: "Open EventPass on the scanner phone")
                InstructionRow(number: 2, text: "Tap \"Scanner Mode\" at the bottom")
                InstructionRow(number: 3, text: "Tap \"Connect as Scanner\"")
                InstructionRow(number: 4, text: "Scan QR or enter the code above")
            }
            .padding(AppSpacing.md)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.md)
        }
    }

    // MARK: - Expiry Section

    @ViewBuilder
    private func expirySection(_ session: PairingSession) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(expiryColor(for: session))

            Text("Code expires in \(viewModel.formattedTimeRemaining)")
                .font(AppTypography.callout)
                .foregroundColor(expiryColor(for: session))

            Spacer()

            Button(action: {
                Task {
                    await viewModel.generatePairingSession()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(AppTypography.caption)
                    .foregroundColor(RoleConfig.organizerPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background(expiryColor(for: session).opacity(0.1))
        .cornerRadius(AppCornerRadius.md)
    }

    private func expiryColor(for session: PairingSession) -> Color {
        if session.timeRemaining < 60 {
            return .red
        } else if session.timeRemaining < 120 {
            return .orange
        }
        return .green
    }

    // MARK: - Generate Prompt

    @ViewBuilder
    private var generatePrompt: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "qrcode")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Generate a pairing code to connect a scanner device.")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await viewModel.generatePairingSession()
                }
            }) {
                Text("Generate Pairing Code")
                    .font(AppTypography.buttonPrimary)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.md)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Error Content

    @ViewBuilder
    private func errorContent(_ error: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text(error)
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await viewModel.generatePairingSession()
                }
            }) {
                Text("Try Again")
                    .font(AppTypography.buttonPrimary)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.md)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Instruction Row

private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(RoleConfig.organizerPrimary)
                .clipShape(Circle())

            Text(text)
                .font(AppTypography.callout)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - View Model

@MainActor
class PairScannerViewModel: ObservableObject {
    @Published var pairingSession: PairingSession?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var formattedTimeRemaining: String = "5:00"

    private let event: Event
    private let scannerService: ScannerSessionService
    private var timer: Timer?

    init(event: Event) {
        self.event = event
        self.scannerService = ScannerSessionService()
    }

    deinit {
        timer?.invalidate()
    }

    func generatePairingSession() async {
        isGenerating = true
        errorMessage = nil

        do {
            let session = try await scannerService.createPairingSession(
                eventId: event.id,
                organizerId: event.organizerId
            )
            pairingSession = session
            startExpiryTimer()
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    private func startExpiryTimer() {
        timer?.invalidate()
        updateTimeRemaining()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimeRemaining()
            }
        }
    }

    private func updateTimeRemaining() {
        guard let session = pairingSession else {
            formattedTimeRemaining = "0:00"
            return
        }

        let remaining = session.timeRemaining
        if remaining <= 0 {
            formattedTimeRemaining = "Expired"
            timer?.invalidate()
            // Auto-regenerate
            Task {
                await generatePairingSession()
            }
        } else {
            formattedTimeRemaining = session.formattedTimeRemaining
        }
    }
}

// MARK: - Preview

#Preview {
    PairScannerView(event: Event.samples[0]) { scanner in
        print("Scanner connected: \(scanner)")
    }
}

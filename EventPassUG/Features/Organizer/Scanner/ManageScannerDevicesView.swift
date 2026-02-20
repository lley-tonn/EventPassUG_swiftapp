//
//  ManageScannerDevicesView.swift
//  EventPassUG
//
//  Organizer view for managing scanner devices for an event
//  CRITICAL: Scanner access is event-scoped and revocable
//

import SwiftUI

struct ManageScannerDevicesView: View {
    let event: Event

    @StateObject private var viewModel: ManageScannerDevicesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddScanner = false
    @State private var showingRevokeAllConfirmation = false
    @State private var deviceToRename: ConnectedScanner?
    @State private var newDeviceName = ""

    init(event: Event) {
        self.event = event
        self._viewModel = StateObject(wrappedValue: ManageScannerDevicesViewModel(event: event))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.connectedScanners.isEmpty {
                    ProgressView("Loading scanners...")
                } else if viewModel.connectedScanners.isEmpty {
                    NoScannersEmptyState(onAddScanner: {
                        showingAddScanner = true
                    })
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Stats header
                            statsHeader

                            // Connected devices section
                            connectedDevicesSection

                            // Quick add section
                            quickAddSection
                        }
                        .padding(AppSpacing.md)
                    }
                }
            }
            .navigationTitle("Scanner Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddScanner = true }) {
                            Label("Add Scanner", systemImage: "plus")
                        }

                        if !viewModel.connectedScanners.isEmpty {
                            Divider()

                            Button(role: .destructive, action: {
                                showingRevokeAllConfirmation = true
                            }) {
                                Label("Remove All Scanners", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddScanner) {
                PairScannerView(event: event) { newScanner in
                    viewModel.addScanner(newScanner)
                    showingAddScanner = false
                }
            }
            .alert("Rename Device", isPresented: .init(
                get: { deviceToRename != nil },
                set: { if !$0 { deviceToRename = nil } }
            )) {
                TextField("Device Name", text: $newDeviceName)
                Button("Cancel", role: .cancel) {
                    deviceToRename = nil
                    newDeviceName = ""
                }
                Button("Save") {
                    if let scanner = deviceToRename {
                        Task {
                            await viewModel.renameDevice(scanner.device.deviceId, newName: newDeviceName)
                        }
                    }
                    deviceToRename = nil
                    newDeviceName = ""
                }
            } message: {
                Text("Enter a new name for this scanner device.")
            }
            .confirmationDialog(
                "Remove All Scanners",
                isPresented: $showingRevokeAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove All", role: .destructive) {
                    Task {
                        await viewModel.revokeAllSessions()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will immediately disconnect all scanner devices. They will no longer be able to scan tickets.")
            }
            .refreshable {
                await viewModel.loadScanners()
            }
            .task {
                await viewModel.loadScanners()
            }
        }
    }

    // MARK: - Stats Header

    @ViewBuilder
    private var statsHeader: some View {
        HStack(spacing: AppSpacing.md) {
            StatCard(
                icon: "checkmark.circle.fill",
                title: "Active",
                value: "\(viewModel.activeScannerCount)",
                color: .green
            )

            StatCard(
                icon: "qrcode.viewfinder",
                title: "Total Scans",
                value: "\(viewModel.totalScanCount)",
                color: RoleConfig.organizerPrimary
            )
        }
    }

    // MARK: - Connected Devices Section

    @ViewBuilder
    private var connectedDevicesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("CONNECTED DEVICES")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, AppSpacing.xs)

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.connectedScanners) { scanner in
                    DeviceListItem(
                        scanner: scanner,
                        onRemove: {
                            Task {
                                await viewModel.revokeSession(scanner.session.id)
                            }
                        },
                        onRename: {
                            deviceToRename = scanner
                            newDeviceName = scanner.device.deviceName
                        }
                    )
                }
            }
        }
    }

    // MARK: - Quick Add Section

    @ViewBuilder
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("ADD NEW SCANNER")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.xs)

            Button(action: { showingAddScanner = true }) {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(RoleConfig.organizerPrimary.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Scanner Device")
                            .font(AppTypography.calloutEmphasized)
                            .foregroundColor(.primary)

                        Text("Generate QR code or pairing code")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
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
            .buttonStyle(.plain)
        }
    }
}

// MARK: - View Model

@MainActor
class ManageScannerDevicesViewModel: ObservableObject {
    @Published var connectedScanners: [ConnectedScanner] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let event: Event
    private let scannerService: ScannerSessionService

    var activeScannerCount: Int {
        connectedScanners.filter { $0.session.status == .active }.count
    }

    var totalScanCount: Int {
        connectedScanners.reduce(0) { $0 + $1.session.scanCount }
    }

    init(event: Event) {
        self.event = event
        self.scannerService = ScannerSessionService()
    }

    func loadScanners() async {
        isLoading = true
        defer { isLoading = false }

        do {
            connectedScanners = try await scannerService.getConnectedScanners(for: event.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addScanner(_ scanner: ConnectedScanner) {
        connectedScanners.insert(scanner, at: 0)
    }

    func revokeSession(_ sessionId: UUID) async {
        do {
            try await scannerService.revokeSession(sessionId, by: event.organizerId)
            connectedScanners.removeAll { $0.session.id == sessionId }
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }

    func revokeAllSessions() async {
        do {
            try await scannerService.revokeAllSessions(for: event.id, by: event.organizerId)
            connectedScanners.removeAll()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }

    func renameDevice(_ deviceId: String, newName: String) async {
        do {
            try await scannerService.renameDevice(deviceId, newName: newName)
            if let index = connectedScanners.firstIndex(where: { $0.device.deviceId == deviceId }) {
                let existing = connectedScanners[index]
                var updatedDevice = existing.device
                updatedDevice.deviceName = newName
                connectedScanners[index] = ConnectedScanner(
                    id: existing.id,
                    device: updatedDevice,
                    session: existing.session
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    ManageScannerDevicesView(event: Event.samples[0])
}

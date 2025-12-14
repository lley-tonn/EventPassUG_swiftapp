//
//  PermissionsView.swift
//  EventPassUG
//
//  Onboarding view for requesting Location, Notifications, Calendar, and other permissions
//  Privacy-first approach with clear explanations and optional permissions
//

import SwiftUI
import CoreLocation
import Contacts
import Photos
import CoreBluetooth
import AppTrackingTransparency
import AVFoundation

struct PermissionsView: View {
    @StateObject private var viewModel = PermissionsViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Permission cards
            ScrollView {
                VStack(spacing: AppDesign.Spacing.lg) {
                    // Location permission
                    PermissionCard(
                        icon: "location.fill",
                        title: "Location",
                        description: "Find events happening near you. We only use approximate location (city-level), never precise GPS tracking.",
                        status: viewModel.locationStatus,
                        isEnabled: viewModel.isLocationEnabled,
                        action: {
                            await viewModel.requestLocationPermission()
                        }
                    )

                    // Notifications permission
                    PermissionCard(
                        icon: "bell.fill",
                        title: "Notifications",
                        description: "Get reminders for your events and discover new events you might like. You can customize notification preferences anytime.",
                        status: viewModel.notificationStatus,
                        isEnabled: viewModel.isNotificationsEnabled,
                        action: {
                            await viewModel.requestNotificationPermission()
                        }
                    )

                    // Calendar permission
                    PermissionCard(
                        icon: "calendar",
                        title: "Calendar",
                        description: "Add events to your calendar and avoid scheduling conflicts. We'll warn you about overlapping events.",
                        status: viewModel.calendarStatus,
                        isEnabled: viewModel.isCalendarEnabled,
                        action: {
                            await viewModel.requestCalendarPermission()
                        }
                    )

                    // Contacts permission
                    PermissionCard(
                        icon: "person.2.fill",
                        title: "Contacts",
                        description: "Invite friends to events and find contacts who are also using EventPass.",
                        status: viewModel.contactsStatus,
                        isEnabled: viewModel.isContactsEnabled,
                        action: {
                            await viewModel.requestContactsPermission()
                        }
                    )

                    // Photos permission
                    PermissionCard(
                        icon: "photo.fill",
                        title: "Photos",
                        description: "Upload event photos and set your profile picture from your photo library.",
                        status: viewModel.photosStatus,
                        isEnabled: viewModel.isPhotosEnabled,
                        action: {
                            await viewModel.requestPhotosPermission()
                        }
                    )

                    // Camera permission
                    PermissionCard(
                        icon: "camera.fill",
                        title: "Camera",
                        description: "Scan QR codes for ticket validation and take photos at events.",
                        status: viewModel.cameraStatus,
                        isEnabled: viewModel.isCameraEnabled,
                        action: {
                            await viewModel.requestCameraPermission()
                        }
                    )

                    // Bluetooth permission
                    PermissionCard(
                        icon: "wave.3.right",
                        title: "Bluetooth",
                        description: "Connect to nearby devices for contactless ticket scanning and check-in.",
                        status: viewModel.bluetoothStatus,
                        isEnabled: viewModel.isBluetoothEnabled,
                        action: {
                            await viewModel.requestBluetoothPermission()
                        }
                    )

                    // App Tracking permission
                    PermissionCard(
                        icon: "chart.bar.fill",
                        title: "Tracking",
                        description: "Help us improve your experience with personalized recommendations. Your data stays private.",
                        status: viewModel.trackingStatus,
                        isEnabled: viewModel.isTrackingEnabled,
                        action: {
                            await viewModel.requestTrackingPermission()
                        }
                    )

                    // Privacy note
                    privacyNote
                }
                .padding(AppDesign.Spacing.edge)
            }

            // Footer
            footer
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Components

    private var header: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.top, AppDesign.Spacing.xl)

            Text("Personalize Your Experience")
                .font(AppTypography.title2)
                .fontWeight(.bold)

            Text("Enable features to get the most out of EventPass")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppDesign.Spacing.edge)
        }
        .padding(.bottom, AppDesign.Spacing.lg)
    }

    private var privacyNote: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            HStack(spacing: AppDesign.Spacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                Text("Your Privacy Matters")
                    .font(AppTypography.subheadline)
                    .fontWeight(.semibold)
            }

            Text("All permissions are optional. You can change them anytime in Settings. We never share your data with third parties.")
                .font(AppTypography.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.medium)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private var footer: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            Button(action: {
                onComplete()
            }) {
                Text("Continue")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppDesign.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppDesign.CornerRadius.medium)
                            .fill(Color.accentColor)
                    )
            }

            Button(action: {
                onComplete()
            }) {
                Text("Skip for Now")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppDesign.Spacing.edge)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionStatus
    let isEnabled: Bool
    let action: () async -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.headline)

                    Text(statusText)
                        .font(AppTypography.caption)
                        .foregroundColor(statusColor)
                }

                Spacer()

                statusIndicator
            }

            Text(description)
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if status == .notDetermined || status == .denied {
                actionButton
            }
        }
        .padding(AppDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.medium)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private var statusColor: Color {
        switch status {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        }
    }

    private var statusText: String {
        switch status {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied - Change in Settings"
        case .notDetermined:
            return "Not enabled"
        }
    }

    private var statusIndicator: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                Image(systemName: status == .authorized ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(statusColor)
                    .font(.title2)
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        }) {
            Text(status == .denied ? "Open Settings" : "Enable")
                .font(AppTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppDesign.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppDesign.CornerRadius.small)
                        .fill(statusColor)
                )
        }
        .disabled(isLoading)
    }
}

// MARK: - Permissions View Model

@MainActor
class PermissionsViewModel: ObservableObject {
    @Published var locationStatus: PermissionStatus = .notDetermined
    @Published var notificationStatus: PermissionStatus = .notDetermined
    @Published var calendarStatus: PermissionStatus = .notDetermined
    @Published var contactsStatus: PermissionStatus = .notDetermined
    @Published var photosStatus: PermissionStatus = .notDetermined
    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var bluetoothStatus: PermissionStatus = .notDetermined
    @Published var trackingStatus: PermissionStatus = .notDetermined

    private let locationService = UserLocationService.shared
    private let notificationService = AppNotificationService.shared
    private let calendarService = CalendarService.shared

    var isLocationEnabled: Bool {
        locationStatus == .authorized
    }

    var isNotificationsEnabled: Bool {
        notificationStatus == .authorized
    }

    var isCalendarEnabled: Bool {
        calendarStatus == .authorized
    }

    var isContactsEnabled: Bool {
        contactsStatus == .authorized
    }

    var isPhotosEnabled: Bool {
        photosStatus == .authorized
    }

    var isCameraEnabled: Bool {
        cameraStatus == .authorized
    }

    var isBluetoothEnabled: Bool {
        bluetoothStatus == .authorized
    }

    var isTrackingEnabled: Bool {
        trackingStatus == .authorized
    }

    init() {
        checkAllStatuses()
    }

    func checkAllStatuses() {
        // Check location status
        locationStatus = convertLocationStatus(locationService.authorizationStatus)

        // Check notification status
        notificationStatus = convertNotificationStatus(notificationService.authorizationStatus)

        // Check calendar status
        calendarStatus = convertCalendarStatus(calendarService.authorizationStatus)

        // Check contacts status
        contactsStatus = convertContactsStatus(CNContactStore.authorizationStatus(for: .contacts))

        // Check photos status
        photosStatus = convertPhotosStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))

        // Check camera status
        cameraStatus = convertCameraStatus(AVCaptureDevice.authorizationStatus(for: .video))

        // Check tracking status
        if #available(iOS 14, *) {
            trackingStatus = convertTrackingStatus(ATTrackingManager.trackingAuthorizationStatus)
        }

        // Bluetooth status will be checked when the manager is initialized
        bluetoothStatus = .notDetermined
    }

    func requestLocationPermission() async {
        locationService.requestPermission()

        // Give it a moment to update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        checkAllStatuses()
    }

    func requestNotificationPermission() async {
        do {
            _ = try await notificationService.requestPermission()
            checkAllStatuses()
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }

    func requestCalendarPermission() async {
        do {
            _ = try await calendarService.requestPermission()
            checkAllStatuses()
        } catch {
            print("Failed to request calendar permission: \(error)")
        }
    }

    func requestContactsPermission() async {
        let contactStore = CNContactStore()
        do {
            _ = try await contactStore.requestAccess(for: .contacts)
            checkAllStatuses()
        } catch {
            print("Failed to request contacts permission: \(error)")
        }
    }

    func requestPhotosPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photosStatus = convertPhotosStatus(status)
    }

    func requestCameraPermission() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = status ? .authorized : .denied
    }

    func requestBluetoothPermission() async {
        // Bluetooth permission is requested automatically when CBCentralManager is initialized
        // For now, just open settings
        print("Bluetooth permission is managed by the system")
        // User should enable it in Settings if needed
        bluetoothStatus = .notDetermined
    }

    func requestTrackingPermission() async {
        if #available(iOS 14, *) {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            trackingStatus = convertTrackingStatus(status)
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Status Conversion

    private func convertLocationStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private func convertNotificationStatus(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private func convertCalendarStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private func convertContactsStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private func convertPhotosStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private func convertCameraStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    @available(iOS 14, *)
    private func convertTrackingStatus(_ status: ATTrackingManager.AuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

// MARK: - Permission Status

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
}

// MARK: - Preview

#Preview {
    PermissionsView {
        print("Permissions completed")
    }
}

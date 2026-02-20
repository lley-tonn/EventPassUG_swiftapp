//
//  ScannerModels.swift
//  EventPassUG
//
//  Models for BYOS (Bring-Your-Own-Scanner) device pairing system
//  CRITICAL: Scanner access is strictly event-scoped and temporary
//

import Foundation

// MARK: - Scanner Device

/// Represents a physical device that can be used as a ticket scanner
struct ScannerDevice: Identifiable, Codable, Equatable {
    let id: UUID
    let deviceId: String
    var deviceName: String
    let platform: DevicePlatform
    var lastActiveAt: Date
    let registeredAt: Date

    enum DevicePlatform: String, Codable, CaseIterable {
        case iOS = "iOS"
        case android = "Android"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .iOS: return "iphone"
            case .android: return "candybarphone"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    init(
        id: UUID = UUID(),
        deviceId: String,
        deviceName: String,
        platform: DevicePlatform = .iOS,
        lastActiveAt: Date = Date(),
        registeredAt: Date = Date()
    ) {
        self.id = id
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.platform = platform
        self.lastActiveAt = lastActiveAt
        self.registeredAt = registeredAt
    }
}

// MARK: - Scanner Session

/// Represents an authorized scanning session for a SPECIFIC event
/// CRITICAL: Sessions are event-scoped and expire automatically
struct ScannerSession: Identifiable, Codable, Equatable {
    let id: UUID
    let eventId: UUID
    let organizerId: UUID
    let deviceId: String
    var status: ScannerSessionStatus
    let pairedAt: Date
    let expiresAt: Date
    var revokedAt: Date?
    var revokedBy: UUID?
    var lastScanAt: Date?
    var scanCount: Int

    /// Permissions granted to this scanner session
    let permissions: ScannerPermissions

    /// Check if session is currently valid for scanning
    var isValid: Bool {
        status == .active && Date() < expiresAt
    }

    /// Time remaining until expiry
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }

    init(
        id: UUID = UUID(),
        eventId: UUID,
        organizerId: UUID,
        deviceId: String,
        status: ScannerSessionStatus = .pending,
        pairedAt: Date = Date(),
        expiresAt: Date,
        revokedAt: Date? = nil,
        revokedBy: UUID? = nil,
        lastScanAt: Date? = nil,
        scanCount: Int = 0,
        permissions: ScannerPermissions = .default
    ) {
        self.id = id
        self.eventId = eventId
        self.organizerId = organizerId
        self.deviceId = deviceId
        self.status = status
        self.pairedAt = pairedAt
        self.expiresAt = expiresAt
        self.revokedAt = revokedAt
        self.revokedBy = revokedBy
        self.lastScanAt = lastScanAt
        self.scanCount = scanCount
        self.permissions = permissions
    }
}

// MARK: - Scanner Session Status

enum ScannerSessionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case active = "active"
    case revoked = "revoked"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .revoked: return "Revoked"
        case .expired: return "Expired"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .active: return "checkmark.circle.fill"
        case .revoked: return "xmark.circle.fill"
        case .expired: return "clock.badge.xmark.fill"
        }
    }

    var color: String {
        switch self {
        case .pending: return "yellow"
        case .active: return "green"
        case .revoked: return "red"
        case .expired: return "gray"
        }
    }
}

// MARK: - Scanner Permissions

/// Defines what a scanner session is allowed to do
/// CRITICAL: Scanners have minimal permissions - no dashboard/financial/export access
struct ScannerPermissions: Codable, Equatable {
    let scanTickets: Bool
    let viewBasicAttendee: Bool
    let viewDetailedAttendee: Bool
    let manualCheckIn: Bool

    // Explicitly denied permissions (documented for clarity)
    var dashboardAccess: Bool { false }
    var financialData: Bool { false }
    var exportAccess: Bool { false }
    var deviceManagement: Bool { false }

    static let `default` = ScannerPermissions(
        scanTickets: true,
        viewBasicAttendee: true,
        viewDetailedAttendee: false,
        manualCheckIn: false
    )

    static let extended = ScannerPermissions(
        scanTickets: true,
        viewBasicAttendee: true,
        viewDetailedAttendee: true,
        manualCheckIn: true
    )
}

// MARK: - Pairing Session

/// Temporary pairing session used to connect a scanner device
/// CRITICAL: Expires after 5 minutes for security
struct PairingSession: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let organizerId: UUID
    let qrCodeData: String
    let pairingCode: String
    let createdAt: Date
    let expiresAt: Date
    var usedAt: Date?
    var usedByDeviceId: String?

    /// Check if pairing session is still valid
    var isValid: Bool {
        usedAt == nil && Date() < expiresAt
    }

    /// Time remaining until expiry
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }

    /// Formatted time remaining (MM:SS)
    var formattedTimeRemaining: String {
        let remaining = Int(timeRemaining)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Default expiry duration (5 minutes)
    static let defaultExpiryDuration: TimeInterval = 5 * 60

    init(
        id: UUID = UUID(),
        eventId: UUID,
        organizerId: UUID,
        qrCodeData: String? = nil,
        pairingCode: String? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        usedAt: Date? = nil,
        usedByDeviceId: String? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.organizerId = organizerId
        self.qrCodeData = qrCodeData ?? PairingSession.generateQRData(sessionId: id, eventId: eventId)
        self.pairingCode = pairingCode ?? PairingSession.generatePairingCode()
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? createdAt.addingTimeInterval(PairingSession.defaultExpiryDuration)
        self.usedAt = usedAt
        self.usedByDeviceId = usedByDeviceId
    }

    /// Generates QR code data payload
    private static func generateQRData(sessionId: UUID, eventId: UUID) -> String {
        // Format: eventpass://pair?session={sessionId}&event={eventId}
        return "eventpass://pair?session=\(sessionId.uuidString)&event=\(eventId.uuidString)"
    }

    /// Generates a 6-digit numeric pairing code
    private static func generatePairingCode() -> String {
        let code = Int.random(in: 100000...999999)
        return String(code)
    }
}

// MARK: - Scan Request

/// Request payload for validating a ticket scan
struct ScanRequest: Codable {
    let scannerSessionId: UUID
    let eventId: UUID
    let ticketQR: String
    let scannedAt: Date
    let deviceId: String

    init(
        scannerSessionId: UUID,
        eventId: UUID,
        ticketQR: String,
        scannedAt: Date = Date(),
        deviceId: String
    ) {
        self.scannerSessionId = scannerSessionId
        self.eventId = eventId
        self.ticketQR = ticketQR
        self.scannedAt = scannedAt
        self.deviceId = deviceId
    }
}

// MARK: - Scan Result

/// Result of a ticket scan validation
struct ScanResult: Codable, Identifiable {
    let id: UUID
    let ticketId: UUID
    let status: ScanResultStatus
    let attendeeName: String?
    let ticketType: String?
    let message: String
    let scannedAt: Date

    var isSuccess: Bool {
        status == .valid
    }

    init(
        id: UUID = UUID(),
        ticketId: UUID,
        status: ScanResultStatus,
        attendeeName: String? = nil,
        ticketType: String? = nil,
        message: String,
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.ticketId = ticketId
        self.status = status
        self.attendeeName = attendeeName
        self.ticketType = ticketType
        self.message = message
        self.scannedAt = scannedAt
    }
}

enum ScanResultStatus: String, Codable {
    case valid = "valid"
    case alreadyUsed = "already_used"
    case invalidTicket = "invalid_ticket"
    case wrongEvent = "wrong_event"
    case refunded = "refunded"
    case expired = "expired"
    case sessionInvalid = "session_invalid"

    var icon: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .alreadyUsed: return "exclamationmark.triangle.fill"
        case .invalidTicket: return "xmark.circle.fill"
        case .wrongEvent: return "arrow.left.arrow.right.circle.fill"
        case .refunded: return "dollarsign.arrow.circlepath"
        case .expired: return "clock.badge.xmark.fill"
        case .sessionInvalid: return "lock.fill"
        }
    }

    var color: String {
        switch self {
        case .valid: return "green"
        case .alreadyUsed: return "orange"
        default: return "red"
        }
    }

    var displayMessage: String {
        switch self {
        case .valid: return "Valid Ticket"
        case .alreadyUsed: return "Already Scanned"
        case .invalidTicket: return "Invalid Ticket"
        case .wrongEvent: return "Wrong Event"
        case .refunded: return "Ticket Refunded"
        case .expired: return "Ticket Expired"
        case .sessionInvalid: return "Session Invalid"
        }
    }
}

// MARK: - Connected Scanner Info

/// Information about a connected scanner shown to the organizer
struct ConnectedScanner: Identifiable {
    let id: UUID
    let device: ScannerDevice
    let session: ScannerSession

    var isActive: Bool {
        session.status == .active
    }

    var lastActivity: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: device.lastActiveAt, relativeTo: Date())
    }
}

// MARK: - Scanner Analytics Event

struct ScannerAnalyticsEvent: Codable {
    let name: String
    let eventId: UUID
    let sessionId: UUID?
    let deviceId: String?
    let timestamp: Date
    var metadata: [String: String]?

    static func paired(eventId: UUID, sessionId: UUID, deviceId: String) -> ScannerAnalyticsEvent {
        ScannerAnalyticsEvent(
            name: "scanner_paired",
            eventId: eventId,
            sessionId: sessionId,
            deviceId: deviceId,
            timestamp: Date()
        )
    }

    static func revoked(eventId: UUID, sessionId: UUID) -> ScannerAnalyticsEvent {
        ScannerAnalyticsEvent(
            name: "scanner_revoked",
            eventId: eventId,
            sessionId: sessionId,
            deviceId: nil,
            timestamp: Date()
        )
    }

    static func scanSuccess(eventId: UUID, sessionId: UUID, ticketId: UUID) -> ScannerAnalyticsEvent {
        ScannerAnalyticsEvent(
            name: "scanner_scan_success",
            eventId: eventId,
            sessionId: sessionId,
            deviceId: nil,
            timestamp: Date(),
            metadata: ["ticketId": ticketId.uuidString]
        )
    }

    static func scanInvalid(eventId: UUID, sessionId: UUID, reason: String) -> ScannerAnalyticsEvent {
        ScannerAnalyticsEvent(
            name: "scanner_scan_invalid",
            eventId: eventId,
            sessionId: sessionId,
            deviceId: nil,
            timestamp: Date(),
            metadata: ["reason": reason]
        )
    }

    static func sessionExpired(eventId: UUID, sessionId: UUID) -> ScannerAnalyticsEvent {
        ScannerAnalyticsEvent(
            name: "scanner_session_expired",
            eventId: eventId,
            sessionId: sessionId,
            deviceId: nil,
            timestamp: Date()
        )
    }
}

// MARK: - Mock Data

extension ScannerDevice {
    static let mockDevices: [ScannerDevice] = [
        ScannerDevice(
            deviceId: "device-001",
            deviceName: "Gate 1 iPhone",
            platform: .iOS,
            lastActiveAt: Date().addingTimeInterval(-120)
        ),
        ScannerDevice(
            deviceId: "device-002",
            deviceName: "VIP Entrance",
            platform: .iOS,
            lastActiveAt: Date().addingTimeInterval(-45)
        ),
        ScannerDevice(
            deviceId: "device-003",
            deviceName: "Staff Android",
            platform: .android,
            lastActiveAt: Date().addingTimeInterval(-300)
        )
    ]
}

extension ScannerSession {
    static func mockSession(for eventId: UUID, status: ScannerSessionStatus = .active) -> ScannerSession {
        ScannerSession(
            eventId: eventId,
            organizerId: UUID(),
            deviceId: "device-001",
            status: status,
            pairedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(7200),
            scanCount: 47
        )
    }

    static let mockSessions: [ScannerSession] = [
        ScannerSession(
            eventId: UUID(),
            organizerId: UUID(),
            deviceId: "device-001",
            status: .active,
            pairedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(7200),
            lastScanAt: Date().addingTimeInterval(-120),
            scanCount: 47
        ),
        ScannerSession(
            eventId: UUID(),
            organizerId: UUID(),
            deviceId: "device-002",
            status: .active,
            pairedAt: Date().addingTimeInterval(-1800),
            expiresAt: Date().addingTimeInterval(7200),
            lastScanAt: Date().addingTimeInterval(-45),
            scanCount: 23
        ),
        ScannerSession(
            eventId: UUID(),
            organizerId: UUID(),
            deviceId: "device-003",
            status: .revoked,
            pairedAt: Date().addingTimeInterval(-7200),
            expiresAt: Date().addingTimeInterval(3600),
            revokedAt: Date().addingTimeInterval(-600),
            scanCount: 12
        )
    ]
}

extension ConnectedScanner {
    static let mockScanners: [ConnectedScanner] = {
        let devices = ScannerDevice.mockDevices
        let sessions = ScannerSession.mockSessions

        return zip(devices, sessions).map { device, session in
            ConnectedScanner(id: session.id, device: device, session: session)
        }
    }()
}

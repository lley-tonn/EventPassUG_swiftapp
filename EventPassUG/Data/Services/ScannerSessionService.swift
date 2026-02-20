//
//  ScannerSessionService.swift
//  EventPassUG
//
//  Service for managing BYOS scanner device pairing and sessions
//  CRITICAL: All scanner access is event-scoped, temporary, and revocable
//

import Foundation
import Combine
import UIKit

// MARK: - Scanner Session Service Protocol

@MainActor
protocol ScannerSessionServiceProtocol {
    // Pairing (Organizer side)
    func createPairingSession(eventId: UUID, organizerId: UUID) async throws -> PairingSession
    func cancelPairingSession(_ pairingId: UUID) async throws

    // Connection (Scanner side)
    func connectWithQR(_ qrData: String, deviceId: String, deviceName: String) async throws -> ScannerSession
    func connectWithCode(_ code: String, deviceId: String, deviceName: String) async throws -> ScannerSession

    // Session Management
    func getActiveSessions(for eventId: UUID) async throws -> [ScannerSession]
    func getConnectedScanners(for eventId: UUID) async throws -> [ConnectedScanner]
    func revokeSession(_ sessionId: UUID, by organizerId: UUID) async throws
    func revokeAllSessions(for eventId: UUID, by organizerId: UUID) async throws
    func renameDevice(_ deviceId: String, newName: String) async throws

    // Scanning
    func validateScan(_ request: ScanRequest) async throws -> ScanResult

    // Session State
    func getCurrentSession() -> ScannerSession?
    func clearCurrentSession()
    func refreshSession() async throws -> ScannerSession?

    // Expiry
    func expireSessionsForEndedEvent(_ eventId: UUID) async throws
}

// MARK: - Scanner Session Service Implementation

@MainActor
class ScannerSessionService: ObservableObject, ScannerSessionServiceProtocol {

    // MARK: - Published State

    @Published private(set) var currentSession: ScannerSession?
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectedEventTitle: String?

    // MARK: - Private State

    private var pairingSessions: [UUID: PairingSession] = [:]
    private var scannerSessions: [UUID: ScannerSession] = [:]
    private var devices: [String: ScannerDevice] = [:]
    private var sessionExpiryTimers: [UUID: Timer] = [:]

    private let ticketService: TicketRepositoryProtocol

    // MARK: - Initialization

    init(ticketService: TicketRepositoryProtocol = MockTicketRepository()) {
        self.ticketService = ticketService
        loadMockData()
    }

    // MARK: - Pairing Session Management (Organizer Side)

    /// Creates a new pairing session for an event
    /// CRITICAL: Pairing sessions expire after 5 minutes
    func createPairingSession(eventId: UUID, organizerId: UUID) async throws -> PairingSession {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)

        let session = PairingSession(
            eventId: eventId,
            organizerId: organizerId
        )

        pairingSessions[session.id] = session

        // Schedule automatic expiry
        scheduleExpiryCheck(for: session)

        // Track analytics
        trackAnalytics(.init(
            name: "pairing_session_created",
            eventId: eventId,
            sessionId: session.id,
            deviceId: nil,
            timestamp: Date()
        ))

        return session
    }

    /// Cancels an active pairing session
    func cancelPairingSession(_ pairingId: UUID) async throws {
        pairingSessions.removeValue(forKey: pairingId)
    }

    // MARK: - Scanner Connection (Scanner Phone Side)

    /// Connects a device using QR code data
    /// CRITICAL: Validates pairing session before creating scanner session
    func connectWithQR(_ qrData: String, deviceId: String, deviceName: String) async throws -> ScannerSession {
        // Parse QR data: eventpass://pair?session={sessionId}&event={eventId}
        guard let url = URL(string: qrData),
              url.scheme == "eventpass",
              url.host == "pair",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let sessionIdString = components.queryItems?.first(where: { $0.name == "session" })?.value,
              let sessionId = UUID(uuidString: sessionIdString),
              let eventIdString = components.queryItems?.first(where: { $0.name == "event" })?.value,
              let eventId = UUID(uuidString: eventIdString) else {
            throw ScannerError.invalidQRCode
        }

        return try await connectWithPairingSession(
            sessionId: sessionId,
            eventId: eventId,
            deviceId: deviceId,
            deviceName: deviceName
        )
    }

    /// Connects a device using numeric pairing code
    func connectWithCode(_ code: String, deviceId: String, deviceName: String) async throws -> ScannerSession {
        // Find pairing session with matching code
        guard let pairingSession = pairingSessions.values.first(where: { $0.pairingCode == code && $0.isValid }) else {
            throw ScannerError.invalidPairingCode
        }

        return try await connectWithPairingSession(
            sessionId: pairingSession.id,
            eventId: pairingSession.eventId,
            deviceId: deviceId,
            deviceName: deviceName
        )
    }

    /// Internal method to complete pairing
    private func connectWithPairingSession(
        sessionId: UUID,
        eventId: UUID,
        deviceId: String,
        deviceName: String
    ) async throws -> ScannerSession {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Validate pairing session exists and is valid
        guard var pairingSession = pairingSessions[sessionId] else {
            throw ScannerError.pairingSessionNotFound
        }

        guard pairingSession.isValid else {
            throw ScannerError.pairingSessionExpired
        }

        // Mark pairing session as used
        pairingSession.usedAt = Date()
        pairingSession.usedByDeviceId = deviceId
        pairingSessions[sessionId] = pairingSession

        // Register or update device
        _ = registerDevice(deviceId: deviceId, deviceName: deviceName)

        // Create scanner session - expires when event ends
        // For mock, we set expiry to 8 hours from now
        let scannerSession = ScannerSession(
            eventId: eventId,
            organizerId: pairingSession.organizerId,
            deviceId: deviceId,
            status: .active,
            pairedAt: Date(),
            expiresAt: Date().addingTimeInterval(8 * 60 * 60), // 8 hours
            scanCount: 0
        )

        scannerSessions[scannerSession.id] = scannerSession

        // Update current session state
        currentSession = scannerSession
        isConnected = true
        connectedEventTitle = "Sample Event" // In production, fetch from event service

        // Track analytics
        trackAnalytics(.paired(eventId: eventId, sessionId: scannerSession.id, deviceId: deviceId))

        return scannerSession
    }

    /// Registers or updates a scanner device
    private func registerDevice(deviceId: String, deviceName: String) -> ScannerDevice {
        if var existingDevice = devices[deviceId] {
            existingDevice.lastActiveAt = Date()
            devices[deviceId] = existingDevice
            return existingDevice
        }

        let newDevice = ScannerDevice(
            deviceId: deviceId,
            deviceName: deviceName,
            platform: .iOS
        )
        devices[deviceId] = newDevice
        return newDevice
    }

    // MARK: - Session Management

    /// Gets all active scanner sessions for an event
    func getActiveSessions(for eventId: UUID) async throws -> [ScannerSession] {
        try await Task.sleep(nanoseconds: 200_000_000)

        return scannerSessions.values
            .filter { $0.eventId == eventId && $0.status == .active }
            .sorted { $0.pairedAt > $1.pairedAt }
    }

    /// Gets connected scanners with device info for an event
    func getConnectedScanners(for eventId: UUID) async throws -> [ConnectedScanner] {
        try await Task.sleep(nanoseconds: 200_000_000)

        let sessions = scannerSessions.values.filter { $0.eventId == eventId }

        return sessions.compactMap { session -> ConnectedScanner? in
            guard let device = devices[session.deviceId] else { return nil }
            return ConnectedScanner(id: session.id, device: device, session: session)
        }.sorted { $0.session.pairedAt > $1.session.pairedAt }
    }

    /// Revokes a scanner session
    /// CRITICAL: Revocation is instant and permanent
    func revokeSession(_ sessionId: UUID, by organizerId: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard var session = scannerSessions[sessionId] else {
            throw ScannerError.sessionNotFound
        }

        // Verify organizer owns this session
        guard session.organizerId == organizerId else {
            throw ScannerError.unauthorized
        }

        // Revoke the session
        session.status = .revoked
        session.revokedAt = Date()
        session.revokedBy = organizerId
        scannerSessions[sessionId] = session

        // If this was the current session, clear it
        if currentSession?.id == sessionId {
            currentSession = nil
            isConnected = false
            connectedEventTitle = nil
        }

        // Track analytics
        trackAnalytics(.revoked(eventId: session.eventId, sessionId: sessionId))
    }

    /// Revokes all scanner sessions for an event
    func revokeAllSessions(for eventId: UUID, by organizerId: UUID) async throws {
        let sessions = scannerSessions.values.filter {
            $0.eventId == eventId && $0.status == .active
        }

        for session in sessions {
            try await revokeSession(session.id, by: organizerId)
        }
    }

    /// Renames a scanner device
    func renameDevice(_ deviceId: String, newName: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard var device = devices[deviceId] else {
            throw ScannerError.deviceNotFound
        }

        device.deviceName = newName
        devices[deviceId] = device
    }

    // MARK: - Scanning

    /// Validates a ticket scan request
    /// CRITICAL: Validates session, event match, and ticket status
    func validateScan(_ request: ScanRequest) async throws -> ScanResult {
        try await Task.sleep(nanoseconds: 400_000_000)

        // 1. Validate scanner session
        guard let session = scannerSessions[request.scannerSessionId] else {
            return ScanResult(
                ticketId: UUID(),
                status: .sessionInvalid,
                message: "Scanner session not found"
            )
        }

        guard session.isValid else {
            return ScanResult(
                ticketId: UUID(),
                status: .sessionInvalid,
                message: "Scanner session has expired or been revoked"
            )
        }

        // 2. Validate event match
        guard session.eventId == request.eventId else {
            trackAnalytics(.scanInvalid(eventId: request.eventId, sessionId: session.id, reason: "wrong_event"))
            return ScanResult(
                ticketId: UUID(),
                status: .wrongEvent,
                message: "This ticket is for a different event"
            )
        }

        // 3. Parse and validate ticket QR
        // Format expected: eventpass://ticket?id={ticketId}&event={eventId}
        guard let ticketId = parseTicketQR(request.ticketQR) else {
            trackAnalytics(.scanInvalid(eventId: request.eventId, sessionId: session.id, reason: "invalid_ticket"))
            return ScanResult(
                ticketId: UUID(),
                status: .invalidTicket,
                message: "Invalid ticket QR code"
            )
        }

        // 4. Fetch and validate ticket (mock implementation)
        let result = await validateTicket(ticketId: ticketId, eventId: request.eventId, session: session)

        // 5. Update session stats
        if result.isSuccess {
            var updatedSession = session
            updatedSession.scanCount += 1
            updatedSession.lastScanAt = Date()
            scannerSessions[session.id] = updatedSession

            if currentSession?.id == session.id {
                currentSession = updatedSession
            }

            trackAnalytics(.scanSuccess(eventId: request.eventId, sessionId: session.id, ticketId: ticketId))
        }

        // Update device last active
        if var device = devices[request.deviceId] {
            device.lastActiveAt = Date()
            devices[request.deviceId] = device
        }

        return result
    }

    /// Parses ticket QR code data
    private func parseTicketQR(_ qrData: String) -> UUID? {
        // Format: eventpass://ticket?id={ticketId}&event={eventId}
        guard let url = URL(string: qrData),
              url.scheme == "eventpass",
              url.host == "ticket",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let ticketIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let ticketId = UUID(uuidString: ticketIdString) else {
            return nil
        }
        return ticketId
    }

    /// Validates a ticket (mock implementation)
    private func validateTicket(ticketId: UUID, eventId: UUID, session: ScannerSession) async -> ScanResult {
        // Mock validation - in production, this would call the ticket service

        // Simulate different scenarios based on random
        let scenario = Int.random(in: 0...10)

        switch scenario {
        case 0:
            return ScanResult(
                ticketId: ticketId,
                status: .alreadyUsed,
                attendeeName: "John Mukasa",
                ticketType: "VIP",
                message: "Scanned at 2:30 PM"
            )
        case 1:
            return ScanResult(
                ticketId: ticketId,
                status: .refunded,
                message: "This ticket has been refunded"
            )
        default:
            // Most scans succeed
            let names = ["Sarah Nakamya", "David Ochieng", "Grace Atwine", "Peter Ssempala", "Mary Kirabo"]
            let types = ["General Admission", "VIP", "VVIP", "Early Bird"]
            return ScanResult(
                ticketId: ticketId,
                status: .valid,
                attendeeName: names.randomElement(),
                ticketType: types.randomElement(),
                message: "Welcome to the event!"
            )
        }
    }

    // MARK: - Session State

    /// Returns the current scanner session
    func getCurrentSession() -> ScannerSession? {
        return currentSession
    }

    /// Clears the current session (logout)
    func clearCurrentSession() {
        currentSession = nil
        isConnected = false
        connectedEventTitle = nil
    }

    /// Refreshes the current session status
    func refreshSession() async throws -> ScannerSession? {
        guard let session = currentSession else { return nil }

        try await Task.sleep(nanoseconds: 300_000_000)

        // Check if session is still valid
        if let updatedSession = scannerSessions[session.id] {
            if updatedSession.isValid {
                currentSession = updatedSession
                return updatedSession
            } else {
                // Session expired or revoked
                clearCurrentSession()
                return nil
            }
        }

        clearCurrentSession()
        return nil
    }

    // MARK: - Expiry Management

    /// Expires all sessions for an event that has ended
    func expireSessionsForEndedEvent(_ eventId: UUID) async throws {
        var expiredCount = 0

        for (id, var session) in scannerSessions where session.eventId == eventId && session.status == .active {
            session.status = .expired
            scannerSessions[id] = session
            expiredCount += 1

            trackAnalytics(.sessionExpired(eventId: eventId, sessionId: id))
        }

        print("ScannerSessionService: Expired \(expiredCount) sessions for event \(eventId)")
    }

    /// Schedules expiry check for a pairing session
    private func scheduleExpiryCheck(for session: PairingSession) {
        // In production, this would use a proper timer or background task
        Task {
            try? await Task.sleep(nanoseconds: UInt64(session.timeRemaining * 1_000_000_000))
            pairingSessions.removeValue(forKey: session.id)
        }
    }

    // MARK: - Analytics

    private func trackAnalytics(_ event: ScannerAnalyticsEvent) {
        print("Analytics: \(event.name) - eventId: \(event.eventId), sessionId: \(event.sessionId?.uuidString ?? "nil")")
        // TODO: Send to analytics service
    }

    // MARK: - Mock Data

    private func loadMockData() {
        // Load mock devices
        for device in ScannerDevice.mockDevices {
            devices[device.deviceId] = device
        }

        // Load mock sessions
        for session in ScannerSession.mockSessions {
            scannerSessions[session.id] = session
        }
    }
}

// MARK: - Scanner Errors

enum ScannerError: LocalizedError {
    case invalidQRCode
    case invalidPairingCode
    case pairingSessionNotFound
    case pairingSessionExpired
    case sessionNotFound
    case deviceNotFound
    case unauthorized
    case networkError
    case scanFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidQRCode:
            return "Invalid QR code. Please scan the pairing QR from the organizer."
        case .invalidPairingCode:
            return "Invalid pairing code. Please check and try again."
        case .pairingSessionNotFound:
            return "Pairing session not found. Ask the organizer to generate a new code."
        case .pairingSessionExpired:
            return "Pairing session has expired. Ask the organizer to generate a new code."
        case .sessionNotFound:
            return "Scanner session not found."
        case .deviceNotFound:
            return "Device not found."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .networkError:
            return "Network error. Please check your connection."
        case .scanFailed(let reason):
            return "Scan failed: \(reason)"
        }
    }
}

// MARK: - Device Identification Helper

enum DeviceIdentification {
    /// Gets the current device's unique identifier
    static var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    /// Gets the current device's name
    static var deviceName: String {
        UIDevice.current.name
    }

    /// Gets the current device's platform
    static var platform: ScannerDevice.DevicePlatform {
        .iOS
    }
}

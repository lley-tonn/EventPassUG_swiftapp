//
//  DeepLinkManager.swift
//  EventPassUG
//
//  Handles deep link URL routing for the app
//  Supports scanner pairing via eventpass:// URL scheme
//

import Foundation
import SwiftUI
import Combine

// MARK: - Deep Link Types

enum DeepLink: Equatable {
    case scannerPairing(sessionId: UUID, eventId: UUID)
    case event(eventId: UUID)
    case ticket(ticketId: UUID)
    case unknown

    /// Parse a URL into a DeepLink
    static func from(url: URL) -> DeepLink {
        guard url.scheme == "eventpass" else { return .unknown }

        switch url.host {
        case "pair":
            // Format: eventpass://pair?session={sessionId}&event={eventId}
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return .unknown
            }

            let sessionIdString = queryItems.first(where: { $0.name == "session" })?.value
            let eventIdString = queryItems.first(where: { $0.name == "event" })?.value

            guard let sessionIdString = sessionIdString,
                  let sessionId = UUID(uuidString: sessionIdString),
                  let eventIdString = eventIdString,
                  let eventId = UUID(uuidString: eventIdString) else {
                return .unknown
            }

            return .scannerPairing(sessionId: sessionId, eventId: eventId)

        case "event":
            // Format: eventpass://event?id={eventId}
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let eventIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                  let eventId = UUID(uuidString: eventIdString) else {
                return .unknown
            }
            return .event(eventId: eventId)

        case "ticket":
            // Format: eventpass://ticket?id={ticketId}
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let ticketIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                  let ticketId = UUID(uuidString: ticketIdString) else {
                return .unknown
            }
            return .ticket(ticketId: ticketId)

        default:
            return .unknown
        }
    }
}

// MARK: - Deep Link Manager

@MainActor
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    /// Currently pending deep link to handle
    @Published var pendingDeepLink: DeepLink?

    /// Scanner pairing data extracted from deep link
    @Published var scannerPairingData: ScannerPairingDeepLinkData?

    /// Whether to show the scanner connect view
    @Published var showScannerConnect: Bool = false

    private init() {}

    /// Handle an incoming URL
    func handle(url: URL) {
        let deepLink = DeepLink.from(url: url)
        pendingDeepLink = deepLink

        switch deepLink {
        case .scannerPairing(let sessionId, let eventId):
            handleScannerPairing(sessionId: sessionId, eventId: eventId)

        case .event(let eventId):
            // Handle event deep link
            print("DeepLinkManager: Open event \(eventId)")

        case .ticket(let ticketId):
            // Handle ticket deep link
            print("DeepLinkManager: Open ticket \(ticketId)")

        case .unknown:
            print("DeepLinkManager: Unknown deep link URL: \(url)")
        }
    }

    /// Handle scanner pairing deep link
    private func handleScannerPairing(sessionId: UUID, eventId: UUID) {
        print("DeepLinkManager: Scanner pairing - session: \(sessionId), event: \(eventId)")

        // Store pairing data
        scannerPairingData = ScannerPairingDeepLinkData(
            sessionId: sessionId,
            eventId: eventId
        )

        // Trigger scanner connect view
        showScannerConnect = true
    }

    /// Clear pending deep link
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }

    /// Clear scanner pairing data
    func clearScannerPairing() {
        scannerPairingData = nil
        showScannerConnect = false
    }
}

// MARK: - Scanner Pairing Deep Link Data

struct ScannerPairingDeepLinkData: Equatable {
    let sessionId: UUID
    let eventId: UUID
}

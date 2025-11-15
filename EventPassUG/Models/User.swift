//
//  User.swift
//  EventPassUG
//
//  User model representing an authenticated user
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case attendee
    case organizer

    var displayName: String {
        switch self {
        case .attendee: return "Attendee"
        case .organizer: return "Organizer"
        }
    }
}

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String?
    var role: UserRole
    var profileImageURL: String?
    var phoneNumber: String?
    var dateJoined: Date
    var favoriteEventIds: [UUID]

    // Contact Verification
    var isEmailVerified: Bool
    var isPhoneVerified: Bool

    // Auth Providers
    var authProviders: [String] // "email", "google.com", "apple.com", "phone"

    // National ID Verification
    var isVerified: Bool
    var nationalIDNumber: String?
    var nationalIDFrontImageURL: String?
    var nationalIDBackImageURL: String?
    var verificationDate: Date?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    // Check if user needs verification for organizer actions
    var needsVerificationForOrganizerActions: Bool {
        isOrganizer && !isVerified
    }

    // Role capabilities - for future dual-role support
    var availableRoles: [UserRole] {
        // Currently single role, but structure allows for future expansion
        [role]
    }

    var isAttendee: Bool {
        availableRoles.contains(.attendee)
    }

    var isOrganizer: Bool {
        availableRoles.contains(.organizer)
    }

    var hasBothRoles: Bool {
        availableRoles.contains(.attendee) && availableRoles.contains(.organizer)
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String? = nil,
        role: UserRole,
        profileImageURL: String? = nil,
        phoneNumber: String? = nil,
        dateJoined: Date = Date(),
        favoriteEventIds: [UUID] = [],
        isEmailVerified: Bool = false,
        isPhoneVerified: Bool = false,
        authProviders: [String] = [],
        isVerified: Bool = false,
        nationalIDNumber: String? = nil,
        nationalIDFrontImageURL: String? = nil,
        nationalIDBackImageURL: String? = nil,
        verificationDate: Date? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.profileImageURL = profileImageURL
        self.phoneNumber = phoneNumber
        self.dateJoined = dateJoined
        self.favoriteEventIds = favoriteEventIds
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
        self.authProviders = authProviders
        self.isVerified = isVerified
        self.nationalIDNumber = nationalIDNumber
        self.nationalIDFrontImageURL = nationalIDFrontImageURL
        self.nationalIDBackImageURL = nationalIDBackImageURL
        self.verificationDate = verificationDate
    }
}

// Sample users for development
extension User {
    static let attendeeSample = User(
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        role: .attendee
    )

    static let organizerSample = User(
        firstName: "Jane",
        lastName: "Smith",
        email: "jane.smith@example.com",
        role: .organizer
    )
}

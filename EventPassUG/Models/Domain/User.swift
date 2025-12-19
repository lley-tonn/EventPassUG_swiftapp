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

enum ContactMethod: String, Codable {
    case email
    case phone

    var displayName: String {
        switch self {
        case .email: return "Email"
        case .phone: return "Phone"
        }
    }
}

enum VerificationDocumentType: String, Codable {
    case nationalID = "national_id"
    case passport = "passport"

    var displayName: String {
        switch self {
        case .nationalID: return "National ID"
        case .passport: return "Passport"
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
    var followedOrganizerIds: [UUID]

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
    var verificationDocumentType: VerificationDocumentType?

    // Contact Preferences
    var primaryContactMethod: ContactMethod?

    // Pending contact changes (awaiting verification)
    var pendingEmail: String?
    var pendingPhoneNumber: String?

    // User Preferences
    var favoriteEventTypes: [String]
    var hasCompletedOnboarding: Bool

    // Age & Location for Personalization
    var dateOfBirth: Date?
    var city: String?
    var country: String?
    var location: UserLocation?
    var allowLocationTracking: Bool

    // Interaction Tracking for Recommendations
    var viewedEventIds: [UUID] // Events user has viewed
    var likedEventIds: [UUID] // Events user explicitly liked
    var purchasedEventIds: [UUID] // Events user purchased tickets for

    // Notification Preferences
    var notificationPreferences: UserNotificationPreferences

    // User Interests for Recommendations
    var interests: UserInterests

    // Dual-Role Support (single account supports both roles)
    var isAttendeeRole: Bool // Can act as attendee
    var isOrganizerRole: Bool // Can act as organizer (completed onboarding)
    var isVerifiedOrganizer: Bool // ID verification completed
    var currentActiveRole: UserRole // Currently active role for UI

    // Organizer-specific data
    var organizerProfile: OrganizerProfile?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    // Computed age from date of birth (privacy-safe: never store raw age)
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year
    }

    // Check if user needs verification for organizer actions
    var needsVerificationForOrganizerActions: Bool {
        isOrganizer && !isVerified
    }

    // Role capabilities - dual-role support
    var availableRoles: [UserRole] {
        var roles: [UserRole] = []
        if isAttendeeRole { roles.append(.attendee) }
        if isOrganizerRole { roles.append(.organizer) }
        return roles.isEmpty ? [role] : roles // Fallback to legacy role field
    }

    var isAttendee: Bool {
        isAttendeeRole || role == .attendee
    }

    var isOrganizer: Bool {
        isOrganizerRole || role == .organizer
    }

    var hasBothRoles: Bool {
        isAttendeeRole && isOrganizerRole
    }

    var canBecomeOrganizer: Bool {
        !isOrganizerRole
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
        followedOrganizerIds: [UUID] = [],
        isEmailVerified: Bool = false,
        isPhoneVerified: Bool = false,
        authProviders: [String] = [],
        isVerified: Bool = false,
        nationalIDNumber: String? = nil,
        nationalIDFrontImageURL: String? = nil,
        nationalIDBackImageURL: String? = nil,
        verificationDate: Date? = nil,
        verificationDocumentType: VerificationDocumentType? = nil,
        primaryContactMethod: ContactMethod? = nil,
        pendingEmail: String? = nil,
        pendingPhoneNumber: String? = nil,
        favoriteEventTypes: [String] = [],
        hasCompletedOnboarding: Bool = false,
        dateOfBirth: Date? = nil,
        city: String? = nil,
        country: String? = nil,
        location: UserLocation? = nil,
        allowLocationTracking: Bool = false,
        viewedEventIds: [UUID] = [],
        likedEventIds: [UUID] = [],
        purchasedEventIds: [UUID] = [],
        notificationPreferences: UserNotificationPreferences = .default,
        interests: UserInterests = .default,
        isAttendeeRole: Bool? = nil,
        isOrganizerRole: Bool = false,
        isVerifiedOrganizer: Bool = false,
        currentActiveRole: UserRole? = nil,
        organizerProfile: OrganizerProfile? = nil
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
        self.followedOrganizerIds = followedOrganizerIds
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
        self.authProviders = authProviders
        self.isVerified = isVerified
        self.nationalIDNumber = nationalIDNumber
        self.nationalIDFrontImageURL = nationalIDFrontImageURL
        self.nationalIDBackImageURL = nationalIDBackImageURL
        self.verificationDate = verificationDate
        self.verificationDocumentType = verificationDocumentType
        self.primaryContactMethod = primaryContactMethod
        self.pendingEmail = pendingEmail
        self.pendingPhoneNumber = pendingPhoneNumber
        self.favoriteEventTypes = favoriteEventTypes
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.dateOfBirth = dateOfBirth
        self.city = city
        self.country = country
        self.location = location
        self.allowLocationTracking = allowLocationTracking
        self.viewedEventIds = viewedEventIds
        self.likedEventIds = likedEventIds
        self.purchasedEventIds = purchasedEventIds
        self.notificationPreferences = notificationPreferences
        self.interests = interests
        // Dual-role support: default to attendee role if role == .attendee, else based on passed value
        self.isAttendeeRole = isAttendeeRole ?? (role == .attendee)
        self.isOrganizerRole = isOrganizerRole || (role == .organizer)
        self.isVerifiedOrganizer = isVerifiedOrganizer
        self.currentActiveRole = currentActiveRole ?? role
        self.organizerProfile = organizerProfile
    }
}

// Sample users for development
extension User {
    static let attendeeSample = User(
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        role: UserRole.attendee
    )

    static let organizerSample = User(
        firstName: "Jane",
        lastName: "Smith",
        email: "jane.smith@example.com",
        role: UserRole.organizer
    )
}

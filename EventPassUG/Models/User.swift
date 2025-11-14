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
    var email: String
    var role: UserRole
    var profileImageURL: String?
    var phoneNumber: String?
    var dateJoined: Date
    var favoriteEventIds: [UUID]

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        role: UserRole,
        profileImageURL: String? = nil,
        phoneNumber: String? = nil,
        dateJoined: Date = Date(),
        favoriteEventIds: [UUID] = []
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

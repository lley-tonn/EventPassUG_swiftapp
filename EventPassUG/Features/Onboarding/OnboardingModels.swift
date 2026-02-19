//
//  OnboardingModels.swift
//  EventPassUG
//
//  Data models for the onboarding flow
//

import Foundation
import SwiftUI

// MARK: - UserRole Extensions for Onboarding

extension UserRole: Identifiable {
    var id: String { rawValue }

    var description: String {
        switch self {
        case .attendee:
            return "Discover events, buy tickets, and enjoy experiences"
        case .organizer:
            return "Create events, sell tickets, and grow your audience"
        }
    }

    var icon: String {
        switch self {
        case .attendee: return "ticket.fill"
        case .organizer: return "calendar.badge.plus"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .attendee:
            return [Color("AttendeeGradientStart", bundle: nil), Color("AttendeeGradientEnd", bundle: nil)]
        case .organizer:
            return [Color("OrganizerGradientStart", bundle: nil), Color("OrganizerGradientEnd", bundle: nil)]
        }
    }
}

// MARK: - Interest Categories (for Attendees)

enum InterestCategory: String, Codable, CaseIterable, Identifiable {
    case music = "music"
    case festivals = "festivals"
    case concerts = "concerts"
    case nightlife = "nightlife"
    case sports = "sports"
    case arts = "arts"
    case comedy = "comedy"
    case food = "food"
    case networking = "networking"
    case technology = "technology"
    case education = "education"
    case wellness = "wellness"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .music: return "Music"
        case .festivals: return "Festivals"
        case .concerts: return "Concerts"
        case .nightlife: return "Nightlife"
        case .sports: return "Sports"
        case .arts: return "Arts & Culture"
        case .comedy: return "Comedy"
        case .food: return "Food & Drinks"
        case .networking: return "Networking"
        case .technology: return "Technology"
        case .education: return "Education"
        case .wellness: return "Wellness"
        }
    }

    var icon: String {
        switch self {
        case .music: return "music.note"
        case .festivals: return "party.popper.fill"
        case .concerts: return "mic.fill"
        case .nightlife: return "moon.stars.fill"
        case .sports: return "figure.run"
        case .arts: return "paintpalette.fill"
        case .comedy: return "theatermasks.fill"
        case .food: return "fork.knife"
        case .networking: return "person.3.fill"
        case .technology: return "laptopcomputer"
        case .education: return "graduationcap.fill"
        case .wellness: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .music: return .purple
        case .festivals: return .orange
        case .concerts: return .pink
        case .nightlife: return .indigo
        case .sports: return .green
        case .arts: return .cyan
        case .comedy: return .yellow
        case .food: return .brown
        case .networking: return .teal
        case .technology: return .blue
        case .education: return .mint
        case .wellness: return .red
        }
    }
}

// MARK: - Event Types (for Organizers)

enum OrganizerEventType: String, Codable, CaseIterable, Identifiable {
    case concerts = "concerts"
    case festivals = "festivals"
    case clubNights = "club_nights"
    case conferences = "conferences"
    case workshops = "workshops"
    case exhibitions = "exhibitions"
    case sports = "sports"
    case charity = "charity"
    case corporate = "corporate"
    case private_ = "private"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concerts: return "Concerts"
        case .festivals: return "Festivals"
        case .clubNights: return "Club Nights"
        case .conferences: return "Conferences"
        case .workshops: return "Workshops"
        case .exhibitions: return "Exhibitions"
        case .sports: return "Sports Events"
        case .charity: return "Charity Events"
        case .corporate: return "Corporate Events"
        case .private_: return "Private Events"
        }
    }

    var icon: String {
        switch self {
        case .concerts: return "music.mic"
        case .festivals: return "sparkles"
        case .clubNights: return "moon.stars.fill"
        case .conferences: return "person.3.sequence.fill"
        case .workshops: return "hammer.fill"
        case .exhibitions: return "photo.artframe"
        case .sports: return "sportscourt.fill"
        case .charity: return "heart.circle.fill"
        case .corporate: return "building.2.fill"
        case .private_: return "lock.fill"
        }
    }

    var color: Color {
        switch self {
        case .concerts: return .pink
        case .festivals: return .orange
        case .clubNights: return .purple
        case .conferences: return .blue
        case .workshops: return .green
        case .exhibitions: return .cyan
        case .sports: return .mint
        case .charity: return .red
        case .corporate: return .gray
        case .private_: return .indigo
        }
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case roleSelection = 1
    case basicInfo = 2
    case personalization = 3
    case permissions = 4
    case completion = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .roleSelection: return "Choose Your Role"
        case .basicInfo: return "About You"
        case .personalization: return "Your Preferences"
        case .permissions: return "Stay Updated"
        case .completion: return "You're All Set!"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "Discover amazing events in Uganda"
        case .roleSelection: return "How will you use EventPass?"
        case .basicInfo: return "Tell us a bit about yourself"
        case .personalization: return "Help us personalize your experience"
        case .permissions: return "Never miss an event"
        case .completion: return "Let's get started"
        }
    }
}

// MARK: - Onboarding Profile

struct OnboardingProfile: Codable, Equatable {
    var id: UUID
    var fullName: String
    var dateOfBirth: Date?
    var role: UserRole?
    var interests: Set<InterestCategory>
    var eventTypes: Set<OrganizerEventType>
    var notificationsEnabled: Bool
    var completed: Bool

    init(
        id: UUID = UUID(),
        fullName: String = "",
        dateOfBirth: Date? = nil,
        role: UserRole? = nil,
        interests: Set<InterestCategory> = [],
        eventTypes: Set<OrganizerEventType> = [],
        notificationsEnabled: Bool = false,
        completed: Bool = false
    ) {
        self.id = id
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.role = role
        self.interests = interests
        self.eventTypes = eventTypes
        self.notificationsEnabled = notificationsEnabled
        self.completed = completed
    }

    // Computed age from date of birth
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dob, to: now)
        return ageComponents.year
    }

    var isAgeValid: Bool {
        guard let age = age else { return false }
        return age >= 13
    }

    var isBasicInfoComplete: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        dateOfBirth != nil &&
        isAgeValid
    }

    var isPersonalizationComplete: Bool {
        switch role {
        case .attendee:
            return !interests.isEmpty
        case .organizer:
            return !eventTypes.isEmpty
        case .none:
            return false
        }
    }
}

// MARK: - Transition Direction

enum SlideDirection {
    case forward
    case backward

    var offset: CGFloat {
        switch self {
        case .forward: return 1
        case .backward: return -1
        }
    }
}

// MARK: - Onboarding Theme

struct OnboardingTheme {
    // Adaptive colors for light/dark mode
    static var primaryBackground: Color {
        Color("OnboardingBackground", bundle: nil)
    }

    static var cardBackground: Color {
        Color("OnboardingCardBackground", bundle: nil)
    }

    static var primaryText: Color {
        Color("OnboardingPrimaryText", bundle: nil)
    }

    static var secondaryText: Color {
        Color("OnboardingSecondaryText", bundle: nil)
    }

    static var accentColor: Color {
        Color("OnboardingAccent", bundle: nil)
    }

    static var divider: Color {
        Color("OnboardingDivider", bundle: nil)
    }

    // Fallback colors if assets not available
    static var backgroundAdaptive: Color {
        Color(UIColor.systemBackground)
    }

    static var cardBackgroundAdaptive: Color {
        Color(UIColor.secondarySystemBackground)
    }

    static var primaryTextAdaptive: Color {
        Color(UIColor.label)
    }

    static var secondaryTextAdaptive: Color {
        Color(UIColor.secondaryLabel)
    }

    static var tertiaryTextAdaptive: Color {
        Color(UIColor.tertiaryLabel)
    }

    // Spacing
    static let horizontalPadding: CGFloat = 24
    static let verticalSpacing: CGFloat = 24
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12

    // Animation
    static let transitionDuration: Double = 0.4
    static let transitionAnimation: Animation = .easeInOut(duration: transitionDuration)
}

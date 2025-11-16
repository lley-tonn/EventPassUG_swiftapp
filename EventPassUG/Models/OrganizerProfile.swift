//
//  OrganizerProfile.swift
//  EventPassUG
//
//  Organizer-specific profile data
//

import Foundation

enum PayoutMethodType: String, Codable, CaseIterable {
    case mtnMomo = "mtn_momo"
    case airtelMoney = "airtel_money"
    case bankAccount = "bank_account"

    var displayName: String {
        switch self {
        case .mtnMomo: return "MTN Mobile Money"
        case .airtelMoney: return "Airtel Money"
        case .bankAccount: return "Bank Account"
        }
    }

    var iconName: String {
        switch self {
        case .mtnMomo: return "phone.fill"
        case .airtelMoney: return "phone.fill"
        case .bankAccount: return "building.columns.fill"
        }
    }
}

struct PayoutMethod: Codable, Equatable {
    var type: PayoutMethodType
    var phoneNumber: String? // For mobile money
    var bankName: String? // For bank account
    var accountNumber: String? // For bank account
    var accountName: String? // For bank account
    var isVerified: Bool

    init(
        type: PayoutMethodType,
        phoneNumber: String? = nil,
        bankName: String? = nil,
        accountNumber: String? = nil,
        accountName: String? = nil,
        isVerified: Bool = false
    ) {
        self.type = type
        self.phoneNumber = phoneNumber
        self.bankName = bankName
        self.accountNumber = accountNumber
        self.accountName = accountName
        self.isVerified = isVerified
    }
}

struct OrganizerProfile: Codable, Equatable {
    // Public Contact Information
    var publicEmail: String
    var publicPhone: String

    // Brand Information (optional)
    var brandName: String?
    var website: String?
    var instagramHandle: String?
    var twitterHandle: String?
    var facebookPage: String?

    // Payout Information
    var payoutMethod: PayoutMethod?

    // Terms Agreement
    var agreedToTermsDate: Date?
    var termsVersion: String?

    // Onboarding Progress
    var completedOnboardingSteps: Set<OrganizerOnboardingStep>

    init(
        publicEmail: String = "",
        publicPhone: String = "",
        brandName: String? = nil,
        website: String? = nil,
        instagramHandle: String? = nil,
        twitterHandle: String? = nil,
        facebookPage: String? = nil,
        payoutMethod: PayoutMethod? = nil,
        agreedToTermsDate: Date? = nil,
        termsVersion: String? = nil,
        completedOnboardingSteps: Set<OrganizerOnboardingStep> = []
    ) {
        self.publicEmail = publicEmail
        self.publicPhone = publicPhone
        self.brandName = brandName
        self.website = website
        self.instagramHandle = instagramHandle
        self.twitterHandle = twitterHandle
        self.facebookPage = facebookPage
        self.payoutMethod = payoutMethod
        self.agreedToTermsDate = agreedToTermsDate
        self.termsVersion = termsVersion
        self.completedOnboardingSteps = completedOnboardingSteps
    }
}

enum OrganizerOnboardingStep: String, Codable, CaseIterable {
    case profileCompletion = "profile_completion"
    case identityVerification = "identity_verification"
    case contactInformation = "contact_information"
    case payoutSetup = "payout_setup"
    case termsAgreement = "terms_agreement"

    var displayName: String {
        switch self {
        case .profileCompletion: return "Profile Completion"
        case .identityVerification: return "Identity Verification"
        case .contactInformation: return "Contact Information"
        case .payoutSetup: return "Payout Setup"
        case .termsAgreement: return "Terms Agreement"
        }
    }

    var stepNumber: Int {
        switch self {
        case .profileCompletion: return 1
        case .identityVerification: return 2
        case .contactInformation: return 3
        case .payoutSetup: return 4
        case .termsAgreement: return 5
        }
    }

    var iconName: String {
        switch self {
        case .profileCompletion: return "person.fill"
        case .identityVerification: return "checkmark.shield.fill"
        case .contactInformation: return "envelope.fill"
        case .payoutSetup: return "banknote.fill"
        case .termsAgreement: return "doc.text.fill"
        }
    }
}

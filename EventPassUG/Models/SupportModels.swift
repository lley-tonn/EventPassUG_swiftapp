//
//  SupportModels.swift
//  EventPassUG
//
//  Models for help center, FAQs, and support tickets
//

import Foundation

// MARK: - FAQ Models

struct FAQCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let items: [FAQItem]
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - Troubleshooting Guide

struct TroubleshootingGuide: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let steps: [String]
    let additionalInfo: String?
}

// MARK: - App Guide

struct AppGuide: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let description: String
    let steps: [GuideStep]
}

struct GuideStep: Identifiable {
    let id = UUID()
    let stepNumber: Int
    let title: String
    let description: String
    let imageName: String?
}

// MARK: - Support Ticket

struct SupportTicket: Identifiable, Codable {
    let id: UUID
    var name: String
    var contactInfo: String
    var category: SupportCategory
    var description: String
    var attachmentURL: String?
    var appVersion: String
    var deviceModel: String
    var iosVersion: String
    var userId: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        contactInfo: String,
        category: SupportCategory,
        description: String,
        attachmentURL: String? = nil,
        appVersion: String = "",
        deviceModel: String = "",
        iosVersion: String = "",
        userId: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.contactInfo = contactInfo
        self.category = category
        self.description = description
        self.attachmentURL = attachmentURL
        self.appVersion = appVersion
        self.deviceModel = deviceModel
        self.iosVersion = iosVersion
        self.userId = userId
        self.createdAt = createdAt
    }
}

enum SupportCategory: String, Codable, CaseIterable {
    case payments = "Payments"
    case ticketNotFound = "Ticket Not Found"
    case qrScanning = "QR Scanning Issues"
    case accountIssues = "Account Issues"
    case organizerSupport = "Organizer Support"
    case other = "Other"

    var iconName: String {
        switch self {
        case .payments: return "creditcard.fill"
        case .ticketNotFound: return "ticket.fill"
        case .qrScanning: return "qrcode.viewfinder"
        case .accountIssues: return "person.fill"
        case .organizerSupport: return "briefcase.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Feature Explanation

struct FeatureExplanation: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let description: String
    let benefits: [String]
}

// MARK: - Sample Data

extension FAQCategory {
    static let samples: [FAQCategory] = [
        FAQCategory(
            title: "Tickets",
            icon: "ticket.fill",
            items: [
                FAQItem(
                    question: "Where are my tickets?",
                    answer: "Your tickets can be found in the 'Tickets' tab at the bottom of the app. All your purchased tickets are stored there with their QR codes. Make sure you're logged into the same account you used to purchase."
                ),
                FAQItem(
                    question: "What do I do if my ticket QR isn't scanning?",
                    answer: "Try increasing your screen brightness to maximum. If that doesn't work, show the ticket number to the organizer. You can also try refreshing the ticket by pulling down on the screen. Contact support if issues persist."
                )
            ]
        ),
        FAQCategory(
            title: "Payments",
            icon: "creditcard.fill",
            items: [
                FAQItem(
                    question: "MTN MoMo / Airtel Money payment failed?",
                    answer: "Check that you have sufficient balance and that you entered the correct PIN. The STK push expires after 60 seconds. Try again and ensure you approve the payment promptly on your phone."
                ),
                FAQItem(
                    question: "Card charged but ticket missing?",
                    answer: "Wait 5-10 minutes as processing can be delayed. Check your email for confirmation. If the ticket still doesn't appear, contact support with your payment reference number."
                )
            ]
        ),
        FAQCategory(
            title: "Events",
            icon: "calendar",
            items: [
                FAQItem(
                    question: "What is the refund policy?",
                    answer: "Refunds depend on the organizer's policy. Generally, refunds are available up to 48 hours before the event. Contact the event organizer directly for refund requests."
                ),
                FAQItem(
                    question: "How to view event details?",
                    answer: "Tap on any event card to see full details including venue, time, ticket types, and organizer information. You can also view the venue location on the map."
                )
            ]
        ),
        FAQCategory(
            title: "Account",
            icon: "person.circle.fill",
            items: [
                FAQItem(
                    question: "How to edit my profile?",
                    answer: "Go to Profile > Settings > Edit Profile. You can update your name, profile photo, email, and phone number. Some changes require verification."
                ),
                FAQItem(
                    question: "Verifying email or phone?",
                    answer: "For email: Check your inbox (and spam folder) for a verification link. For phone: Enter the 6-digit SMS code sent to your number. Codes expire after 10 minutes."
                ),
                FAQItem(
                    question: "Why is ID verification required?",
                    answer: "ID verification is mandatory for organizers to ensure community safety, prevent fraud, and build trust. Attendees can optionally verify for a verified badge on their profile."
                )
            ]
        )
    ]
}

extension TroubleshootingGuide {
    static let samples: [TroubleshootingGuide] = [
        TroubleshootingGuide(
            title: "App not loading",
            icon: "wifi.exclamationmark",
            steps: [
                "Check your internet connection",
                "Force quit the app and reopen",
                "Clear app cache in Settings",
                "Update to the latest version",
                "Reinstall the app if issues persist"
            ],
            additionalInfo: "If problems continue, contact support with your device info."
        ),
        TroubleshootingGuide(
            title: "Push notifications not appearing",
            icon: "bell.slash.fill",
            steps: [
                "Go to iPhone Settings > EventPass UG",
                "Enable 'Allow Notifications'",
                "Check notification preferences in the app",
                "Ensure Do Not Disturb is off",
                "Restart your device"
            ],
            additionalInfo: nil
        ),
        TroubleshootingGuide(
            title: "Payment not going through",
            icon: "creditcard.trianglebadge.exclamationmark",
            steps: [
                "Verify sufficient account balance",
                "Check internet connectivity",
                "Try a different payment method",
                "Wait 5 minutes and retry",
                "Contact your bank/mobile money provider"
            ],
            additionalInfo: "For MTN MoMo/Airtel Money, ensure you approve the STK push within 60 seconds."
        ),
        TroubleshootingGuide(
            title: "Ticket not showing after purchase",
            icon: "ticket.fill",
            steps: [
                "Wait 5-10 minutes for processing",
                "Pull down to refresh your tickets",
                "Check your email for confirmation",
                "Verify you're logged into the correct account",
                "Contact support with payment reference"
            ],
            additionalInfo: nil
        ),
        TroubleshootingGuide(
            title: "SMS/email verification not arriving",
            icon: "envelope.badge.fill",
            steps: [
                "Check spam/junk folders",
                "Verify correct email/phone entered",
                "Wait up to 5 minutes",
                "Request a new code",
                "Try alternative verification method"
            ],
            additionalInfo: "Codes expire after 10 minutes. You can request up to 3 codes per hour."
        )
    ]
}

extension AppGuide {
    static let samples: [AppGuide] = [
        AppGuide(
            title: "How to Buy a Ticket",
            icon: "ticket.fill",
            description: "Complete guide to purchasing event tickets",
            steps: [
                GuideStep(stepNumber: 1, title: "Find an Event", description: "Browse events on Home or use Search to find specific events", imageName: nil),
                GuideStep(stepNumber: 2, title: "View Details", description: "Tap on the event to see full information, venue, and available tickets", imageName: nil),
                GuideStep(stepNumber: 3, title: "Select Tickets", description: "Choose your ticket type and quantity", imageName: nil),
                GuideStep(stepNumber: 4, title: "Choose Payment", description: "Select MTN MoMo, Airtel Money, or Card", imageName: nil),
                GuideStep(stepNumber: 5, title: "Complete Payment", description: "Approve the payment on your device", imageName: nil),
                GuideStep(stepNumber: 6, title: "Get Your Ticket", description: "Your ticket with QR code appears in the Tickets tab", imageName: nil)
            ]
        ),
        AppGuide(
            title: "How to Scan a Ticket",
            icon: "qrcode.viewfinder",
            description: "For organizers: Validate attendee tickets at entry",
            steps: [
                GuideStep(stepNumber: 1, title: "Open Dashboard", description: "Go to your Organizer Dashboard", imageName: nil),
                GuideStep(stepNumber: 2, title: "Select Event", description: "Choose the event you're managing", imageName: nil),
                GuideStep(stepNumber: 3, title: "Tap Scan", description: "Press the 'Scan Tickets' button", imageName: nil),
                GuideStep(stepNumber: 4, title: "Point Camera", description: "Align the QR code within the frame", imageName: nil),
                GuideStep(stepNumber: 5, title: "Verify Result", description: "Green = Valid, Red = Invalid or Already Scanned", imageName: nil)
            ]
        ),
        AppGuide(
            title: "How to Enable Notifications",
            icon: "bell.badge.fill",
            description: "Stay updated with event reminders and updates",
            steps: [
                GuideStep(stepNumber: 1, title: "Go to Settings", description: "Tap Profile > Notifications", imageName: nil),
                GuideStep(stepNumber: 2, title: "Choose Categories", description: "Enable notifications for events, purchases, etc.", imageName: nil),
                GuideStep(stepNumber: 3, title: "Set Channels", description: "Choose Push, Email, or SMS for each type", imageName: nil),
                GuideStep(stepNumber: 4, title: "Allow System Permission", description: "Enable in iPhone Settings if prompted", imageName: nil)
            ]
        ),
        AppGuide(
            title: "Onboarding Process",
            icon: "person.badge.plus",
            description: "Getting started with EventPass UG",
            steps: [
                GuideStep(stepNumber: 1, title: "Create Account", description: "Sign up with email, phone, Google, or Apple", imageName: nil),
                GuideStep(stepNumber: 2, title: "Choose Role", description: "Select Attendee or Organizer", imageName: nil),
                GuideStep(stepNumber: 3, title: "Select Interests", description: "Pick your favorite event categories", imageName: nil),
                GuideStep(stepNumber: 4, title: "Verify Contact", description: "Confirm your email or phone number", imageName: nil),
                GuideStep(stepNumber: 5, title: "Start Exploring", description: "Browse events tailored to your interests", imageName: nil)
            ]
        )
    ]
}

extension FeatureExplanation {
    static let samples: [FeatureExplanation] = [
        FeatureExplanation(
            title: "Event Reminders",
            icon: "bell.badge.fill",
            description: "Never miss an event with automated reminders sent before your events start.",
            benefits: [
                "Receive alerts 24 hours and 1 hour before events",
                "Get notified of any schedule changes",
                "View event location and directions",
                "Quick access to your ticket QR code"
            ]
        ),
        FeatureExplanation(
            title: "Organizer Dashboard",
            icon: "chart.bar.fill",
            description: "Comprehensive tools for event organizers to manage their events effectively.",
            benefits: [
                "Real-time ticket sales analytics",
                "Revenue tracking and reports",
                "QR code scanner for entry management",
                "Attendee communication tools",
                "Event performance insights"
            ]
        ),
        FeatureExplanation(
            title: "Favorite Categories",
            icon: "heart.fill",
            description: "Personalize your event feed by selecting categories that interest you.",
            benefits: [
                "Get recommendations based on preferences",
                "Discover relevant events faster",
                "Receive targeted notifications",
                "Customize your home feed"
            ]
        ),
        FeatureExplanation(
            title: "Payment Methods",
            icon: "creditcard.fill",
            description: "Multiple secure payment options for convenient ticket purchases.",
            benefits: [
                "MTN Mobile Money integration",
                "Airtel Money support",
                "Credit/Debit card payments",
                "Save payment methods for quick checkout",
                "Secure encrypted transactions"
            ]
        )
    ]
}

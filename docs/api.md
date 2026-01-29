# API & Backend Integration Guide

## Overview

EventPassUG is architected with a clean separation between the frontend iOS app and backend services. All services use protocols for easy backend swapping, making it straightforward to integrate with Firebase, REST APIs, or GraphQL backends.

---

## Table of Contents

1. [Service Architecture](#service-architecture)
2. [Repository Protocols](#repository-protocols)
3. [Backend Integration Options](#backend-integration-options)
4. [Payment Integration](#payment-integration)
5. [Push Notifications](#push-notifications)
6. [File Storage](#file-storage)
7. [API Security](#api-security)

---

## Service Architecture

### Protocol-Based Design

All data access uses protocols to enable:
- Easy backend swapping (mock → production)
- Comprehensive testing with mocks
- Multiple backend support
- Gradual migration strategies

**Pattern**:
```
Repository Protocol → Mock Implementation (Development)
                   → Real Implementation (Production)
```

### Current State

**Development**: Mock repositories using `TestDatabase.swift`
**Production**: Ready for backend integration

**Migration Strategy**:
1. Replace mock repository with real implementation
2. Update `ServiceContainer` initialization
3. No changes required in ViewModels or Views

---

## Repository Protocols

### 1. AuthRepository

**Location**: `Data/Repositories/AuthRepository.swift`

**Protocol**:
```swift
protocol AuthRepositoryProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signUp(name: String, email: String, password: String, role: UserRole) async throws -> User
    func signInWithPhone(phoneNumber: String) async throws -> String // Returns verification ID
    func verifyPhoneCode(verificationId: String, code: String) async throws -> User
    func signInWithApple(token: String) async throws -> User
    func signInWithGoogle(token: String) async throws -> User
    func signInWithFacebook(token: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    func updateUser(_ user: User) async throws
    func deleteAccount(userId: UUID) async throws
}
```

**Implementation Notes**:
- Hash passwords with SHA256 + salt before sending
- Store auth tokens securely (Keychain)
- Handle session persistence
- Implement token refresh logic

---

### 2. EventRepository

**Location**: `Data/Repositories/EventRepository.swift`

**Protocol**:
```swift
protocol EventRepositoryProtocol {
    func fetchEvents() async throws -> [Event]
    func fetchEvent(id: UUID) async throws -> Event
    func createEvent(_ event: Event) async throws -> Event
    func updateEvent(_ event: Event) async throws
    func deleteEvent(id: UUID) async throws
    func searchEvents(query: String) async throws -> [Event]
    func filterEvents(category: EventCategory?, timeFilter: TimeFilter?) async throws -> [Event]
    func fetchOrganizerEvents(organizerId: UUID) async throws -> [Event]
    func fetchEventsByStatus(status: EventStatus) async throws -> [Event]
}
```

**Implementation Notes**:
- Support pagination for event lists
- Implement caching for frequently accessed events
- Handle image URLs for posters
- Support query parameters for filtering
- Implement search with fuzzy matching

---

### 3. TicketRepository

**Location**: `Data/Repositories/TicketRepository.swift`

**Protocol**:
```swift
protocol TicketRepositoryProtocol {
    func purchaseTickets(eventId: UUID, ticketTypeId: UUID, quantity: Int, userId: UUID, paymentMethod: PaymentMethod) async throws -> [Ticket]
    func getUserTickets(userId: UUID) async throws -> [Ticket]
    func getTicket(id: UUID) async throws -> Ticket
    func scanTicket(qrCode: String) async throws -> TicketScanResult
    func getEventTickets(eventId: UUID) async throws -> [Ticket]
    func refundTicket(id: UUID) async throws
}
```

**Ticket Scan Result**:
```swift
struct TicketScanResult {
    let ticket: Ticket
    let status: ScanStatus
    let scannedAt: Date?
    let message: String
}

enum ScanStatus {
    case valid
    case alreadyScanned
    case invalid
    case wrongEvent
    case notStarted
}
```

**Implementation Notes**:
- Generate unique QR codes server-side
- Validate tickets against event dates
- Track scan timestamps
- Support offline validation with sync

---

### 4. PaymentRepository

**Location**: `Data/Repositories/PaymentRepository.swift`

**Protocol**:
```swift
protocol PaymentRepositoryProtocol {
    func initiatePayment(amount: Double, method: PaymentMethod, userId: UUID, eventId: UUID) async throws -> Payment
    func processPayment(paymentId: UUID) async throws -> PaymentStatus
    func getPaymentStatus(paymentId: UUID) async throws -> PaymentStatus
    func getUserPayments(userId: UUID) async throws -> [Payment]
    func refundPayment(paymentId: UUID, amount: Double) async throws
}
```

**Payment Model**:
```swift
struct Payment: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let eventId: UUID
    let amount: Double
    let currency: String // UGX
    let method: PaymentMethod
    let status: PaymentStatus
    let createdAt: Date
    let completedAt: Date?
}

enum PaymentMethod: String, Codable {
    case mtnMobileMoney
    case airtelMoney
    case card
}

enum PaymentStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
    case refunded
}
```

---

### 5. NotificationRepository

**Location**: `Data/Repositories/NotificationRepository.swift`

**Protocol**:
```swift
protocol NotificationRepositoryProtocol {
    func sendNotification(userId: UUID, notification: NotificationModel) async throws
    func sendBulkNotifications(userIds: [UUID], notification: NotificationModel) async throws
    func getUserNotifications(userId: UUID) async throws -> [NotificationModel]
    func markAsRead(notificationId: UUID) async throws
    func deleteNotification(id: UUID) async throws
    func updateNotificationPreferences(userId: UUID, preferences: NotificationPreferences) async throws
    func getNotificationPreferences(userId: UUID) async throws -> NotificationPreferences
}
```

---

### 6. LocationRepository

**Location**: `Data/Repositories/LocationRepository.swift`

**Protocol**:
```swift
protocol LocationRepositoryProtocol {
    func getCurrentLocation() async throws -> UserLocation
    func getNearbyEvents(location: UserLocation, radius: Double) async throws -> [Event]
    func getEventsInCity(city: String) async throws -> [Event]
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String
}
```

---

### 7. RecommendationRepository

**Location**: `Data/Repositories/RecommendationRepository.swift`

**Protocol**:
```swift
protocol RecommendationRepositoryProtocol {
    func getRecommendedEvents(for user: User, from events: [Event], limit: Int) async -> [ScoredEvent]
    func recordInteraction(userId: UUID, eventId: UUID, type: InteractionType) async throws
    func getUserInterests(userId: UUID) async throws -> UserInterests
    func updateUserInterests(userId: UUID, interests: UserInterests) async throws
}
```

---

### 8. AppNotificationRepository

**Location**: `Data/Repositories/AppNotificationRepository.swift`

**Description**: Push notification service for scheduling, delivering, and tracking event notifications. Integrates with iOS UserNotifications framework and respects user preferences and quiet hours.

**Service Class** (Singleton Pattern):
```swift
@MainActor
class AppNotificationService: NSObject, ObservableObject {
    static let shared = AppNotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled = false

    // Permission management
    func requestPermission() async throws -> Bool
    func checkAuthorizationStatus()

    // Event reminders (scheduled)
    func scheduleEventReminder24h(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws
    func scheduleEventReminder2h(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws
    func scheduleEventReminder30m(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws
    func scheduleEventStartingSoon(event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws
    func scheduleAllReminders(for event: Event, userId: UUID, preferences: UserNotificationPreferences) async throws
    func cancelReminders(for eventId: UUID)

    // Instant notifications
    func sendTicketPurchaseConfirmation(event: Event, ticketType: TicketType, quantity: Int, userId: UUID, preferences: UserNotificationPreferences) async throws
    func sendEventUpdate(event: Event, updateMessage: String, userId: UUID, preferences: UserNotificationPreferences) async throws
    func sendRecommendation(events: [Event], userId: UUID, preferences: UserNotificationPreferences) async throws

    // Organizer notifications
    func notifyOrganizerTicketSold(event: Event, ticketType: TicketType, quantity: Int, organizerId: UUID, preferences: UserNotificationPreferences) async throws
    func notifyOrganizerLowInventory(event: Event, ticketType: TicketType, remainingCount: Int, organizerId: UUID, preferences: UserNotificationPreferences) async throws
    func notifyOrganizerCheckIn(event: Event, attendeeName: String, ticketType: TicketType, organizerId: UUID, preferences: UserNotificationPreferences) async throws
    func notifyOrganizerEventStarting(event: Event, organizerId: UUID, preferences: UserNotificationPreferences) async throws

    // Notification management
    func getPendingNotifications() async -> [UNNotificationRequest]
    func getDeliveredNotifications() async -> [UNNotification]
    func removeAllPendingNotifications()
    func removeAllDeliveredNotifications()
}
```

**Notification Types**:
```swift
enum PushNotificationType: String {
    // Attendee notifications
    case eventReminder24h
    case eventReminder2h
    case eventReminder30m
    case eventStartingSoon
    case ticketPurchase
    case eventUpdate
    case recommendation
    case marketing

    // Organizer notifications
    case ticketSold
    case lowTicketInventory
    case attendeeCheckIn
    case eventAboutToStartOrganizer
}
```

**Implementation Notes**:
- Uses UNUserNotificationCenter for local/remote notifications
- Supports iOS 15+ Focus Mode with interruption levels (passive, active, timeSensitive)
- Relevance scoring for notification prioritization
- Respects quiet hours (checks UserNotificationPreferences)
- Rich notifications with event poster images
- Deep linking support for notification taps
- Analytics tracking integration
- Category-based notification actions (View Event, Get Directions, etc.)

**Usage Example**:
```swift
let notificationService = AppNotificationService.shared

// Request permission
let granted = try await notificationService.requestPermission()

// Schedule event reminders
try await notificationService.scheduleAllReminders(
    for: event,
    userId: user.id,
    preferences: user.notificationPreferences
)

// Send instant notification
try await notificationService.sendTicketPurchaseConfirmation(
    event: event,
    ticketType: ticketType,
    quantity: 2,
    userId: user.id,
    preferences: user.notificationPreferences
)
```

---

### 9. CalendarRepository

**Location**: `Data/Repositories/CalendarRepository.swift`

**Description**: Calendar integration service using EventKit for adding events to user's calendar and detecting scheduling conflicts.

**Service Class** (Singleton Pattern):
```swift
@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var hasPermission = false

    // Permission management
    func requestPermission() async throws -> Bool
    func checkAuthorizationStatus()

    // Calendar event management
    func addEventToCalendar(event: Event, showAlert: Bool = true) async throws -> String?
    func removeEventFromCalendar(calendarEventId: String) throws

    // Conflict detection
    func checkConflicts(for event: Event, bufferMinutes: Int = 0) async throws -> [CalendarConflict]
    func hasEventsInTimeRange(from startDate: Date, to endDate: Date) async throws -> Bool
    func getEventsForDay(_ date: Date) async throws -> [EKEvent]
    func checkOrganizerConflicts(startDate: Date, endDate: Date, bufferMinutes: Int = 30) async throws -> [CalendarConflict]
    func getConflictSummary(conflicts: [CalendarConflict]) -> String
    func isSafeToAddEvent(conflicts: [CalendarConflict]) -> Bool
}
```

**Calendar Conflict Model**:
```swift
struct CalendarConflict: Identifiable {
    let id: UUID
    let event: EKEvent
    let conflictType: ConflictType

    enum ConflictType {
        case exact      // Same time
        case partial    // Overlapping time
        case adjacent   // Back-to-back events
    }
}
```

**Implementation Notes**:
- Uses EventKit framework for iOS calendar integration
- Supports iOS 17+ with requestFullAccessToEvents()
- Adds 2-hour reminder alarms automatically
- Detects exact, partial, and adjacent conflicts
- Buffer time support for travel/transition time
- Privacy-focused: only checks conflicts, doesn't read calendar details
- Organizer conflict checking for event creation

**Usage Example**:
```swift
let calendarService = CalendarService.shared

// Request permission
let granted = try await calendarService.requestPermission()

// Check for conflicts before purchasing ticket
let conflicts = try await calendarService.checkConflicts(for: event, bufferMinutes: 30)

if calendarService.isSafeToAddEvent(conflicts: conflicts) {
    // Add to calendar
    let eventId = try await calendarService.addEventToCalendar(event: event)
} else {
    // Show conflict warning
    print(calendarService.getConflictSummary(conflicts: conflicts))
}
```

---

### 10. EnhancedAuthRepository

**Location**: `Data/Repositories/EnhancedAuthRepository.swift`

**Description**: Production-ready authentication service implementing AuthRepositoryProtocol with TestDatabase backend. Replaces MockAuthRepository with persistent database storage.

**Service Class**:
```swift
@MainActor
class EnhancedAuthService: AuthRepositoryProtocol, ObservableObject {
    @Published private(set) var currentUser: User?

    var isAuthenticated: Bool { currentUser != nil }
    var isGuestMode: Bool { currentUser == nil }
    var currentUserPublisher: AnyPublisher<User?, Never>

    // AuthRepositoryProtocol methods
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole) async throws -> User
    func signInWithPhone(phoneNumber: String, firstName: String, lastName: String, role: UserRole) async throws -> String
    func verifyPhoneCode(verificationId: String, code: String) async throws -> User
    func signInWithApple(firstName: String, lastName: String, role: UserRole) async throws -> User
    func signInWithGoogle(firstName: String, lastName: String, role: UserRole) async throws -> User
    func signOut() throws

    // User management
    func updateProfile(_ user: User) async throws
    func switchRole(to role: UserRole) async throws
    func submitVerification(documentType: VerificationDocumentType, documentNumber: String, frontImageData: Data?, backImageData: Data?) async throws

    // Contact method management
    func addEmail(email: String, password: String) async throws
    func addPhoneNumber(phoneNumber: String) async throws -> String
    func updateEmail(newEmail: String, password: String) async throws
    func updatePhoneNumber(newPhoneNumber: String) async throws -> String
    func verifyPhoneUpdate(verificationId: String, code: String) async throws

    // Account linking
    func linkGoogleAccount() async throws
    func linkAppleAccount() async throws
    func linkEmailPassword(email: String, password: String) async throws
}
```

**Implementation Notes**:
- Uses TestDatabase.shared for data persistence
- Implements full AuthRepositoryProtocol interface
- Session management with UserDefaults
- Password hashing with PasswordHasher utility
- Supports all auth providers (Email, Phone, Apple, Google)
- Role switching for organizer/attendee modes
- Mock verification system (production would integrate real ID verification)
- Persisted sessions across app restarts

**Migration from MockAuthRepository**:
```swift
// Old: MockAuthRepository
services = ServiceContainer(
    authRepository: MockAuthRepository()
)

// New: EnhancedAuthService
services = ServiceContainer(
    authRepository: EnhancedAuthService()
)
```

---

### 11. EventFilterRepository

**Location**: `Data/Repositories/EventFilterRepository.swift`

**Description**: Service for filtering and validating events based on user eligibility, age restrictions, location, categories, and discovery logic.

**Service Class** (Singleton Pattern):
```swift
@MainActor
class EventFilterService {
    nonisolated static let shared = EventFilterService()

    // Age validation
    nonisolated func canUserAccessEvent(_ event: Event, user: User) -> Bool
    nonisolated func accessDenialReason(for event: Event, user: User) -> String?

    // Event filtering
    func filterEligibleEvents(_ events: [Event], for user: User) -> [Event]
    func filterByLocation(_ events: [Event], userLocation: UserLocation?, sameCity: Bool = false, maxDistanceKm: Double? = nil) -> [Event]
    func filterByCategories(_ events: [Event], categories: [String]) -> [Event]
    func filterByDateRange(_ events: [Event], from startDate: Date, to endDate: Date) -> [Event]
    func filterToday(_ events: [Event]) -> [Event]
    func filterThisWeek(_ events: [Event]) -> [Event]
    func filterThisMonth(_ events: [Event]) -> [Event]
    func filterUpcoming(_ events: [Event]) -> [Event]
    func filterOngoing(_ events: [Event]) -> [Event]

    // Discovery logic
    func sortByDiscoveryPriority(_ events: [Event], user: User, userLocation: UserLocation?) -> [Event]
    func getDiscoveryFeed(from events: [Event], user: User, userLocation: UserLocation?, limit: Int = 20) -> [Event]
    func getNearbyEvents(from events: [Event], user: User, userLocation: UserLocation, radiusKm: Double = 50.0, limit: Int = 10) -> [Event]
    func getEventsInCity(from events: [Event], user: User, userLocation: UserLocation, limit: Int = 20) -> [Event]
}
```

**Discovery Priority Algorithm**:
```
Priority Order:
1. Age eligibility (eligible events first)
2. Same city (events in user's city first)
3. Proximity (closer events first)
4. Category interest (user's favorite categories first)
5. Popularity (rating × total ratings + like count)
6. Time (upcoming events, soonest first)
```

**Implementation Notes**:
- Age restriction validation (18+, 21+, etc.)
- Location-based filtering with distance calculations
- Multi-factor discovery algorithm for personalized feeds
- Support for time-based filters (today, this week, this month)
- Published/draft/cancelled status filtering
- Distance calculation using UserLocation

**Usage Example**:
```swift
let filterService = EventFilterService.shared

// Check age eligibility
if filterService.canUserAccessEvent(event, user: user) {
    // User can access event
} else {
    let reason = filterService.accessDenialReason(for: event, user: user)
    print(reason) // "This event is restricted to ages 18+..."
}

// Get personalized discovery feed
let feed = filterService.getDiscoveryFeed(
    from: allEvents,
    user: user,
    userLocation: userLocation,
    limit: 20
)

// Get nearby events
let nearby = filterService.getNearbyEvents(
    from: allEvents,
    user: user,
    userLocation: userLocation,
    radiusKm: 50.0
)
```

---

### 12. NotificationAnalyticsRepository

**Location**: `Data/Repositories/NotificationAnalyticsRepository.swift`

**Description**: Notification analytics tracking service for monitoring engagement metrics and optimizing notification delivery.

**Service Class** (Singleton Pattern):
```swift
@MainActor
class NotificationAnalytics: ObservableObject {
    static let shared = NotificationAnalytics()

    @Published private(set) var events: [NotificationEvent] = []

    // Tracking methods
    func trackNotificationScheduled(type: String, eventId: UUID?, userId: UUID, timestamp: Date)
    func trackNotificationDelivered(type: String, eventId: UUID?, userId: UUID, timestamp: Date)
    func trackNotificationOpened(type: String, eventId: UUID?, userId: UUID, timestamp: Date)
    func trackNotificationDismissed(type: String, eventId: UUID?, userId: UUID, timestamp: Date)

    // Analytics queries
    func getOpenRate(for type: String, in timeRange: TimeRange = .last7Days) -> Double
    func getDeliveryRate(for type: String, in timeRange: TimeRange = .last7Days) -> Double
    func getCount(for action: NotificationEvent.NotificationAction, in timeRange: TimeRange = .last7Days) -> Int
    func getEngagementMetrics(in timeRange: TimeRange = .last7Days) -> [NotificationTypeMetrics]
    func getBestTimeSlots(in timeRange: TimeRange = .last7Days) -> [TimeSlotMetrics]

    // Data management
    func clearOldEvents(olderThan days: Int = 30)
    func exportAnalytics() -> Data?
}
```

**Notification Event Model**:
```swift
struct NotificationEvent: Codable, Identifiable {
    let id: UUID
    let type: String
    let action: NotificationAction
    let eventId: UUID?
    let userId: UUID
    let timestamp: Date

    enum NotificationAction: String, Codable {
        case scheduled
        case delivered
        case opened
        case dismissed
    }
}
```

**Metrics Models**:
```swift
struct NotificationTypeMetrics {
    let type: String
    let scheduled: Int
    let delivered: Int
    let opened: Int
    let dismissed: Int
    let openRate: Double
    let deliveryRate: Double
}

struct TimeSlotMetrics {
    let hour: Int  // 0-23
    let engagementCount: Int
}

enum TimeRange {
    case last24Hours
    case last7Days
    case last30Days
    case custom(from: Date, to: Date)
}
```

**Implementation Notes**:
- Stores last 1000 events in UserDefaults
- Tracks full notification lifecycle (scheduled → delivered → opened/dismissed)
- Calculates open rates, delivery rates, and engagement metrics
- Identifies best time slots for sending notifications
- Auto-cleanup of old events (>30 days)
- Export capability for backend sync
- Privacy-focused: aggregated metrics only

**Usage Example**:
```swift
let analytics = NotificationAnalytics.shared

// Track notification lifecycle
analytics.trackNotificationScheduled(
    type: "event_reminder_2h",
    eventId: event.id,
    userId: user.id,
    timestamp: Date()
)

// Get metrics
let openRate = analytics.getOpenRate(for: "event_reminder_2h", in: .last7Days)
print("Open rate: \(openRate * 100)%")

let bestTimes = analytics.getBestTimeSlots(in: .last30Days)
print("Best time to send: \(bestTimes.first?.timeRangeDisplay ?? "Unknown")")

// Get all engagement metrics
let metrics = analytics.getEngagementMetrics(in: .last7Days)
for metric in metrics {
    print("\(metric.type): \(metric.formattedOpenRate) open rate")
}
```

---

### 13. UserLocationRepository

**Location**: `Data/Repositories/UserLocationRepository.swift`

**Description**: Privacy-first user location tracking service for proximity-based event recommendations. Uses approximate location only (city-level), not precise GPS tracking.

**Service Class** (Singleton Pattern):
```swift
@MainActor
class UserLocationService: NSObject, ObservableObject {
    static let shared = UserLocationService()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: UserLocation?
    @Published var isUpdatingLocation = false
    @Published var locationError: LocationError?

    var isLocationAvailable: Bool
    var hasPermission: Bool

    // Permission management
    func requestPermission()

    // Location updates
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func updateLocation(city: String, country: String, coordinate: UserLocation.LocationCoordinate)

    // Distance calculation
    func distance(to venue: Venue) -> Double?  // Returns km
    func isWithinRadius(event: Event, radiusKm: Double) -> Bool
}
```

**Location Error**:
```swift
enum LocationError: LocalizedError {
    case servicesDisabled
    case permissionDenied
    case geocodingFailed
    case networkError
    case unknown
}
```

**Implementation Notes**:
- Uses CoreLocation framework
- Privacy-first: approximate location only (kCLLocationAccuracyKilometer)
- Updates only when moved 1km+ (distanceFilter)
- Reverse geocoding to city/country
- Supports manual location entry
- Distance calculations for nearby events
- No background location tracking
- Clear error messages with recovery suggestions

**Usage Example**:
```swift
let locationService = UserLocationService.shared

// Request permission
locationService.requestPermission()

// Get current location
locationService.startUpdatingLocation()

// Check if event is nearby
if let distance = locationService.distance(to: event.venue) {
    print("Event is \(distance) km away")
}

if locationService.isWithinRadius(event: event, radiusKm: 50.0) {
    print("Event is within 50km")
}

// Manual location entry
locationService.updateLocation(
    city: "Kampala",
    country: "Uganda",
    coordinate: UserLocation.LocationCoordinate(latitude: 0.3476, longitude: 32.5825)
)
```

---

### 14. UserPreferencesRepository

**Location**: `Data/Repositories/UserPreferencesRepository.swift`

**Protocol**:
```swift
protocol UserPreferencesRepositoryProtocol {
    var notificationPreferences: NotificationPreferences { get }
    var savedPaymentMethods: [SavedPaymentMethod] { get }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws
    func resetNotificationPreferences() async throws
    func savePaymentMethod(_ method: SavedPaymentMethod) async throws
    func removePaymentMethod(_ methodId: UUID) async throws
    func setDefaultPaymentMethod(_ methodId: UUID) async throws
    func fetchPreferences() async throws
}
```

**Mock Implementation**:
```swift
class MockUserPreferencesRepository: UserPreferencesRepositoryProtocol, ObservableObject {
    @Published private(set) var notificationPreferences: NotificationPreferences = .defaultPreferences
    @Published private(set) var savedPaymentMethods: [SavedPaymentMethod] = []

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws
    func resetNotificationPreferences() async throws
    func savePaymentMethod(_ method: SavedPaymentMethod) async throws
    func removePaymentMethod(_ methodId: UUID) async throws
    func setDefaultPaymentMethod(_ methodId: UUID) async throws
    func fetchPreferences() async throws
}
```

**Notification Preferences Model** (see NotificationRepository for full model):
```swift
struct NotificationPreferences: Codable {
    var isEnabled: Bool
    var eventReminders24h: Bool
    var eventReminders2h: Bool
    var eventReminders30m: Bool?
    var eventStartingSoon: Bool
    var ticketPurchaseConfirmation: Bool
    var eventUpdates: Bool
    var recommendations: Bool
    var marketing: Bool
    var quietHoursStart: Int  // Hour (0-23)
    var quietHoursEnd: Int    // Hour (0-23)
    // ... organizer preferences
}
```

**Saved Payment Method Model**:
```swift
struct SavedPaymentMethod: Identifiable, Codable {
    let id: UUID
    let type: PaymentMethodType
    let displayName: String
    let lastFourDigits: String?
    let expiryDate: String?
    var isDefault: Bool
}
```

**Implementation Notes**:
- Persists to UserDefaults with JSON encoding
- Supports notification preferences by type
- Manages saved payment methods (add, remove, set default)
- Auto-unsets previous default when new default is set
- Respects quiet hours for notifications
- Ready for backend sync (just replace mock implementation)

**Usage Example**:
```swift
let prefsRepository = MockUserPreferencesRepository()

// Update notification preferences
var prefs = prefsRepository.notificationPreferences
prefs.eventReminders2h = true
prefs.quietHoursStart = 22  // 10 PM
prefs.quietHoursEnd = 7     // 7 AM
try await prefsRepository.updateNotificationPreferences(prefs)

// Save payment method
let method = SavedPaymentMethod(
    id: UUID(),
    type: .card,
    displayName: "Visa ending in 1234",
    lastFourDigits: "1234",
    expiryDate: "12/25",
    isDefault: true
)
try await prefsRepository.savePaymentMethod(method)

// Reset to defaults
try await prefsRepository.resetNotificationPreferences()
```

---

## Backend Integration Options

### Option 1: Firebase Backend

Firebase provides a complete backend solution with minimal setup.

#### Setup

**1. Install Firebase SDK**:
```bash
# Add Firebase packages to Xcode
# File → Add Package Dependencies
# https://github.com/firebase/firebase-ios-sdk
```

**2. Configure Firebase**:
```swift
// In EventPassUGApp.swift
import Firebase

@main
struct EventPassUGApp: App {
    init() {
        FirebaseApp.configure()
    }
}
```

#### Auth Implementation

```swift
import FirebaseAuth

class FirebaseAuthRepository: AuthRepositoryProtocol {
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)

        // Fetch user data from Firestore
        let userData = try await fetchUserData(uid: result.user.uid)
        return userData
    }

    func signUp(name: String, email: String, password: String, role: UserRole) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // Create user document in Firestore
        let user = User(
            id: UUID(uuidString: result.user.uid) ?? UUID(),
            name: name,
            email: email,
            isOrganizer: role == .organizer
        )

        try await saveUserData(user)
        return user
    }

    // Implement other methods...
}
```

#### Firestore Event Repository

```swift
import FirebaseFirestore

class FirestoreEventRepository: EventRepositoryProtocol {
    private let db = Firestore.firestore()

    func fetchEvents() async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "published")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Event.self)
        }
    }

    func createEvent(_ event: Event) async throws -> Event {
        try await db.collection("events")
            .document(event.id.uuidString)
            .setData(from: event)

        return event
    }

    // Implement other methods...
}
```

#### Firebase Storage for Posters

```swift
import FirebaseStorage

class FirebaseStorageService {
    private let storage = Storage.storage()

    func uploadPoster(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        let filename = "\(UUID().uuidString).jpg"
        let ref = storage.reference().child("posters/\(filename)")

        _ = try await ref.putDataAsync(imageData)
        let url = try await ref.downloadURL()

        return url.absoluteString
    }
}
```

**Update ServiceContainer**:
```swift
// In EventPassUGApp.swift
services = ServiceContainer(
    authRepository: FirebaseAuthRepository(),
    eventRepository: FirestoreEventRepository(),
    ticketRepository: FirestoreTicketRepository(),
    paymentRepository: StripePaymentRepository() // or Flutterwave
)
```

---

### Option 2: REST API Backend

For a custom backend or existing API.

#### Setup

**1. Create API Client**:
```swift
// Data/Networking/APIClient.swift
class APIClient {
    private let baseURL = "https://api.eventpass.ug"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        let request = try endpoint.makeRequest(baseURL: baseURL)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

**2. Define Endpoints**:
```swift
// Data/Networking/Endpoints/EventEndpoints.swift
enum EventEndpoints: Endpoint {
    case fetchEvents(query: EventQuery?)
    case fetchEvent(id: UUID)
    case createEvent(Event)
    case updateEvent(Event)
    case deleteEvent(id: UUID)

    var path: String {
        switch self {
        case .fetchEvents: return "/events"
        case .fetchEvent(let id): return "/events/\(id)"
        case .createEvent: return "/events"
        case .updateEvent(let event): return "/events/\(event.id)"
        case .deleteEvent(let id): return "/events/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchEvents, .fetchEvent: return .get
        case .createEvent: return .post
        case .updateEvent: return .put
        case .deleteEvent: return .delete
        }
    }
}
```

#### Auth Implementation

```swift
class RESTAuthRepository: AuthRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func signIn(email: String, password: String) async throws -> User {
        struct SignInRequest: Codable {
            let email: String
            let password: String
        }

        struct SignInResponse: Codable {
            let user: User
            let token: String
        }

        let response: SignInResponse = try await apiClient.request(
            AuthEndpoints.signIn(email: email, password: password)
        )

        // Store token securely
        try await KeychainService.shared.saveToken(response.token)

        return response.user
    }

    // Implement other methods...
}
```

#### Event Repository

```swift
class RESTEventRepository: EventRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchEvents() async throws -> [Event] {
        struct EventsResponse: Codable {
            let events: [Event]
        }

        let response: EventsResponse = try await apiClient.request(
            EventEndpoints.fetchEvents(query: nil)
        )

        return response.events
    }

    func createEvent(_ event: Event) async throws -> Event {
        let response: Event = try await apiClient.request(
            EventEndpoints.createEvent(event)
        )

        return response
    }

    // Implement other methods...
}
```

---

## Payment Integration

### Recommended: Flutterwave (Uganda)

Flutterwave is optimized for African markets with native support for MTN Mobile Money and Airtel Money.

#### Setup

**1. Install Flutterwave SDK**:
```swift
// Add to Package Dependencies
// https://github.com/Flutterwave/FlutterwaveSDK
```

**2. Configure**:
```swift
import Flutterwave

class FlutterwavePaymentRepository: PaymentRepositoryProtocol {
    private let publicKey = "YOUR_FLUTTERWAVE_PUBLIC_KEY"
    private let encryptionKey = "YOUR_ENCRYPTION_KEY"

    func initiatePayment(amount: Double, method: PaymentMethod, userId: UUID, eventId: UUID) async throws -> Payment {
        let config = FlutterwaveConfig.Builder()
            .setAmount(amount)
            .setCurrency("UGX")
            .setEmail(user.email)
            .setIsStaging(false) // Set to true for testing
            .setTxRef(UUID().uuidString)
            .setPublicKey(publicKey)
            .build()

        let paymentLink = try await Flutterwave.initiatePayment(config: config)

        // Open payment link or use in-app payment
        return Payment(
            id: UUID(),
            userId: userId,
            eventId: eventId,
            amount: amount,
            currency: "UGX",
            method: method,
            status: .pending,
            createdAt: Date()
        )
    }

    func processPayment(paymentId: UUID) async throws -> PaymentStatus {
        // Handle callback from Flutterwave
        // Verify transaction status
        let status = try await Flutterwave.verifyTransaction(transactionId: paymentId.uuidString)

        return status == "successful" ? .completed : .failed
    }
}
```

#### Payment Methods Supported

**MTN Mobile Money**:
```swift
let config = FlutterwaveConfig.Builder()
    .setPaymentOptions("mobilemoneyuganda")
    .setPhoneNumber(user.phoneNumber)
    .build()
```

**Airtel Money**:
```swift
let config = FlutterwaveConfig.Builder()
    .setPaymentOptions("airtelmoney")
    .setPhoneNumber(user.phoneNumber)
    .build()
```

**Card Payment**:
```swift
let config = FlutterwaveConfig.Builder()
    .setPaymentOptions("card")
    .build()
```

#### Payment Flow

```
1. User selects tickets
2. User chooses payment method
3. App calls initiatePayment()
4. Flutterwave returns payment link
5. User completes payment (mobile money prompt or card form)
6. Flutterwave sends webhook to backend
7. Backend verifies transaction
8. App calls processPayment() to confirm
9. Tickets issued on success
```

---

### Alternative: Paystack

Paystack is another popular option for Africa.

```swift
import Paystack

class PaystackPaymentRepository: PaymentRepositoryProtocol {
    private let publicKey = "YOUR_PAYSTACK_PUBLIC_KEY"

    func initiatePayment(amount: Double, method: PaymentMethod, userId: UUID, eventId: UUID) async throws -> Payment {
        let charge = PSTCKTransactionParams()
        charge.email = user.email
        charge.amount = Int(amount * 100) // Convert to kobo/cents
        charge.currency = "UGX"

        let transaction = try await PSTCKAPIClient.shared.chargeCard(charge)

        return Payment(
            id: UUID(uuidString: transaction.reference) ?? UUID(),
            userId: userId,
            eventId: eventId,
            amount: amount,
            currency: "UGX",
            method: method,
            status: .pending,
            createdAt: Date()
        )
    }
}
```

---

## Push Notifications

### Firebase Cloud Messaging (FCM)

**1. Setup FCM**:
```swift
import FirebaseMessaging

class FCMNotificationService: NotificationRepositoryProtocol {
    func registerForPushNotifications() async throws {
        let authStatus = await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        )

        guard authStatus.0 else {
            throw NotificationError.permissionDenied
        }

        await UIApplication.shared.registerForRemoteNotifications()
    }

    func sendNotification(userId: UUID, notification: NotificationModel) async throws {
        // Get user's FCM token
        let token = try await fetchUserFCMToken(userId: userId)

        // Send via FCM API
        let message = [
            "to": token,
            "notification": [
                "title": notification.title,
                "body": notification.body,
                "sound": "default"
            ],
            "data": notification.data
        ]

        try await sendFCMRequest(message: message)
    }
}
```

**2. Handle Notifications**:
```swift
// In AppDelegate or EventPassUGApp
extension EventPassUGApp: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle deep link
        if let eventId = userInfo["eventId"] as? String {
            navigateToEvent(id: UUID(uuidString: eventId)!)
        }

        completionHandler()
    }
}
```

---

## File Storage

### Firebase Storage

```swift
class FirebaseStorageRepository {
    private let storage = Storage.storage()

    func uploadEventPoster(_ image: UIImage, eventId: UUID) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        let path = "events/\(eventId)/poster.jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()

        return url.absoluteString
    }

    func downloadPoster(url: String) async throws -> UIImage {
        let ref = storage.reference(forURL: url)
        let data = try await ref.data(maxSize: 10 * 1024 * 1024) // 10MB

        guard let image = UIImage(data: data) else {
            throw StorageError.invalidImageData
        }

        return image
    }
}
```

### AWS S3

```swift
import AWSS3

class S3StorageRepository {
    func uploadEventPoster(_ image: UIImage, eventId: UUID) async throws -> String {
        // Configure AWS SDK
        // Upload to S3
        // Return public URL
    }
}
```

---

## API Security

### Best Practices

**1. API Key Management**:
```swift
// Store in xcconfig or environment variables
// NEVER commit keys to Git

struct APIConfig {
    static let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? ""
    static let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
}
```

**2. Authentication**:
```swift
// Add auth token to all requests
extension URLRequest {
    mutating func addAuthToken() async throws {
        let token = try await KeychainService.shared.getToken()
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
```

**3. SSL Pinning**:
```swift
class SecureURLSession: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Implement certificate pinning
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Verify against pinned certificate
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
```

**4. Rate Limiting**:
```swift
class RateLimiter {
    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]

    func canMakeRequest(endpoint: String, limit: Int, window: TimeInterval) -> Bool {
        let now = Date()

        if let entry = requestCounts[endpoint] {
            if now > entry.resetTime {
                requestCounts[endpoint] = (1, now.addingTimeInterval(window))
                return true
            } else if entry.count < limit {
                requestCounts[endpoint] = (entry.count + 1, entry.resetTime)
                return true
            } else {
                return false
            }
        } else {
            requestCounts[endpoint] = (1, now.addingTimeInterval(window))
            return true
        }
    }
}
```

---

## Integration Checklist

### Phase 1: Authentication
- [ ] Choose backend (Firebase/REST API)
- [ ] Implement AuthRepository
- [ ] Set up secure token storage (Keychain)
- [ ] Test login/signup flows
- [ ] Implement session refresh
- [ ] Add logout functionality

### Phase 2: Events
- [ ] Implement EventRepository
- [ ] Set up file storage for posters
- [ ] Test CRUD operations
- [ ] Implement search and filters
- [ ] Add caching layer

### Phase 3: Tickets & Payments
- [ ] Choose payment provider (Flutterwave/Paystack)
- [ ] Implement PaymentRepository
- [ ] Configure payment methods
- [ ] Test payment flows
- [ ] Implement TicketRepository
- [ ] Set up QR code validation

### Phase 4: Notifications
- [ ] Set up FCM or similar
- [ ] Implement NotificationRepository
- [ ] Register device tokens
- [ ] Test notification delivery
- [ ] Implement deep linking

### Phase 5: Additional Features
- [ ] Implement LocationRepository
- [ ] Set up RecommendationRepository
- [ ] Add analytics tracking
- [ ] Implement error reporting
- [ ] Set up monitoring

---

## Testing Backend Integration

### Unit Tests

```swift
class MockEventRepository: EventRepositoryProtocol {
    var mockEvents: [Event] = []
    var shouldFail = false

    func fetchEvents() async throws -> [Event] {
        if shouldFail {
            throw APIError.networkError
        }
        return mockEvents
    }
}

// In tests
func testFetchEvents() async throws {
    let mockRepo = MockEventRepository()
    mockRepo.mockEvents = [testEvent1, testEvent2]

    let viewModel = EventListViewModel(repository: mockRepo)
    await viewModel.loadEvents()

    XCTAssertEqual(viewModel.events.count, 2)
}
```

### Integration Tests

```swift
func testRealAPIFetchEvents() async throws {
    let config = URLSessionConfiguration.default
    let apiClient = APIClient(session: URLSession(configuration: config))
    let repository = RESTEventRepository(apiClient: apiClient)

    let events = try await repository.fetchEvents()
    XCTAssertFalse(events.isEmpty)
}
```

---

## Documentation Resources

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Flutterwave iOS SDK](https://developer.flutterwave.com/docs/ios-sdk)
- [Paystack iOS SDK](https://paystack.com/docs/payments/accept-payments/#ios)
- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications)

---

**API Version**: 2.0
**Last Updated**: January 2026
**Integration Status**: Ready for production backend

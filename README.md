# EventPassUG - Native iOS Event Management App

A complete, production-ready native iOS application for discovering and managing events across Uganda. Built with **Swift** and **SwiftUI** targeting iOS 16+.

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue)

---

## 📋 Table of Contents

1. [Features](#-features)
2. [Quick Start](#-quick-start)
3. [Architecture](#-architecture)
4. [Project Structure](#-project-structure)
5. [Design System](#-design-system)
6. [Authentication](#-authentication)
7. [Backend Integration](#-backend-integration)
8. [Testing](#-testing)
9. [Deployment](#-deployment)
10. [Troubleshooting](#-troubleshooting)

---

## 🎯 Features

### Dual Role Support
- **Attendee Mode**: Discover events, purchase tickets, view QR codes
- **Organizer Mode**: Create events, manage tickets, track analytics
- Seamless role switching from profile settings

### Attendee Features
- ✅ Event discovery with category and time-based filters
- ✅ Interactive MapKit integration for venue locations
- ✅ Ticket purchase with multiple payment methods
- ✅ QR code generation for tickets
- ✅ Search events by name, location, and category
- ✅ Favorite events with persistent storage
- ✅ Event ratings and reviews
- ✅ Real-time "Happening now" indicators
- ✅ **Time-based ticket sales** (automatically stops when event starts)

### Organizer Features
- ✅ 3-step event creation wizard with draft saving
- ✅ Multiple ticket types with pricing configuration
- ✅ Analytics dashboard (revenue, tickets sold, active events)
- ✅ QR code scanner for ticket validation
- ✅ Event management (published/draft/ongoing states)
- ✅ Earnings withdrawal UI

### Authentication System
- ✅ Modern authentication UI with pill-style toggle
- ✅ Email/password login and registration
- ✅ OTP phone authentication with 6-digit code entry
- ✅ Social login (Apple, Google, Facebook)
- ✅ **Production-grade test database** with multi-user support
- ✅ Password hashing (SHA256 + salt)
- ✅ Session persistence across app launches

### UI/UX Polish
- ✅ Platform-native iOS design with SwiftUI
- ✅ **Unified SF Pro typography system**
- ✅ **Centralized design tokens** (colors, spacing, shadows)
- ✅ Dark/light mode support
- ✅ Role-based theming (Attendee: #FF7A00, Organizer: #FFA500)
- ✅ Haptic feedback for interactions
- ✅ Smooth animations
- ✅ Accessibility support (VoiceOver, Dynamic Type)
- ✅ Responsive layout (iPhone & iPad)

---

## 🚀 Quick Start

### Prerequisites
- macOS 13.0+ (Ventura or later)
- Xcode 15.0+
- iOS 16.0+ deployment target
- Swift 5.9+

### 1. Open the Project

```bash
cd /Users/lley-tonn/Documents/projects/EventPassUG-MobileApp
open EventPassUG.xcodeproj
```

### 2. Build and Run

1. Select a simulator: **iPhone 15 Pro** (or any iOS 16+ device)
2. Press **⌘ + R** to build and run
3. The app will launch with test data

### 3. Test Authentication

**Email Login (Test Users):**
- Attendees:
  - john@example.com / password123
  - jane@example.com / password123
  - alice@example.com / password123

- Organizers:
  - bob@events.com / organizer123
  - sarah@events.com / organizer123

**Phone Login:**
- Phone: +256700123456
- OTP: 123456 (any 6-digit code works in mock mode)

**Create New Account:**
- Click "Register" and fill in the form
- Choose role (Attendee or Organizer)
- Account is created immediately in test database

### 4. Explore Features

**As Attendee:**
- Browse events with category filters
- Search events (tap search icon)
- Favorite events (tap heart icon)
- Purchase tickets (automatically stops when event starts)
- View QR codes in Tickets tab

**As Organizer:**
- Switch role from Profile tab
- Create events (3-step wizard)
- View analytics dashboard
- Scan tickets with QR scanner

---

## 🏗 Architecture

### Design Pattern
- **MVVM** (Model-View-ViewModel)
- **Protocol-Oriented** programming for services
- **Dependency Injection** via ServiceContainer
- **Reactive** state management with Combine and async/await

### Core Technologies
- **SwiftUI** - 100% SwiftUI UI framework
- **Combine** - Reactive data binding
- **async/await** - Modern concurrency
- **CryptoKit** - SHA256 password hashing
- **UserDefaults** - Data persistence (test database)
- **CoreImage** - QR code generation
- **MapKit** - Venue mapping
- **AVFoundation** - Camera for QR scanning
- **PhotosUI** - Image picker

### Layer Separation

```
┌─────────────────────────────────────┐
│         Views (SwiftUI)              │  ← UI Layer
├─────────────────────────────────────┤
│    ViewModels (@Published state)     │  ← Presentation Logic
├─────────────────────────────────────┤
│  Services (Protocol-based)           │  ← Business Logic
├─────────────────────────────────────┤
│  Models (Codable, Identifiable)      │  ← Data Layer
├─────────────────────────────────────┤
│  TestDatabase / Core Data            │  ← Persistence
└─────────────────────────────────────┘
```

---

## 📁 Project Structure

```
EventPassUG/
├── EventPassUGApp.swift          # App entry point
├── ContentView.swift             # Root view with auth routing
├── Info.plist                    # App configuration
│
├── Models/                       # Data Models
│   ├── User.swift                # User with dual-role support
│   ├── Event.swift               # Event and venue models
│   ├── Ticket.swift              # Ticket purchase records
│   ├── TicketType.swift          # Ticket tier definitions
│   └── NotificationModel.swift   # Notification model
│
├── Services/                     # Business Logic Layer
│   ├── ServiceContainer.swift    # DI container
│   ├── AuthService.swift         # Auth protocol + Mock
│   ├── EventService.swift        # Event CRUD + Mock
│   ├── TicketService.swift       # Ticket operations + Mock
│   ├── PaymentService.swift      # Payment processing + Mock
│   └── Database/
│       └── TestDatabase.swift    # Multi-user test database
│
├── Views/
│   ├── Components/               # Reusable UI Components
│   │   ├── EventCard.swift
│   │   ├── CategoryTile.swift
│   │   ├── QRCodeView.swift
│   │   ├── SalesCountdownTimer.swift  # NEW: Real-time countdown
│   │   └── ...
│   │
│   ├── Auth/
│   │   ├── ModernAuthView.swift  # NEW: Modern auth UI
│   │   ├── AuthComponents.swift  # NEW: Reusable components
│   │   └── AuthViewModel.swift   # NEW: State management
│   │
│   ├── Attendee/
│   │   ├── AttendeeHomeView.swift
│   │   ├── EventDetailsView.swift
│   │   ├── TicketPurchaseView.swift
│   │   ├── TicketsView.swift
│   │   ├── SearchView.swift
│   │   └── FavoriteEventsView.swift
│   │
│   ├── Organizer/
│   │   ├── OrganizerHomeView.swift
│   │   ├── CreateEventWizard.swift
│   │   ├── OrganizerDashboardView.swift
│   │   └── QRScannerView.swift
│   │
│   └── Common/
│       ├── ProfileView.swift
│       └── NotificationsView.swift
│
├── Config/
│   └── AppDesignSystem.swift    # NEW: Complete design tokens
│
├── Extensions/
│   └── Event+TicketSales.swift  # NEW: Time-based sales logic
│
├── Utilities/
│   ├── DateUtilities.swift
│   ├── QRCodeGenerator.swift
│   ├── HapticFeedback.swift
│   └── FavoriteManager.swift
│
└── Assets.xcassets/             # Images and colors
```

---

## 🎨 Design System

### AppDesign Tokens

The app uses a centralized design system in `AppDesignSystem.swift`:

```swift
// Colors
AppDesign.Colors.primary          // #FF7A00
AppDesign.Colors.success          // Green
AppDesign.Colors.error            // Red
AppDesign.Colors.warning          // Orange

// Typography (SF Pro)
AppDesign.Typography.hero         // .largeTitle + .bold
AppDesign.Typography.section      // .title3 + .semibold
AppDesign.Typography.cardTitle    // .headline + .semibold
AppDesign.Typography.body         // .body
AppDesign.Typography.secondary    // .subheadline
AppDesign.Typography.caption      // .caption

// Spacing
AppDesign.Spacing.xs              // 4pt
AppDesign.Spacing.sm              // 8pt
AppDesign.Spacing.md              // 16pt
AppDesign.Spacing.lg              // 24pt
AppDesign.Spacing.xl              // 32pt

// Corner Radius
AppDesign.CornerRadius.card       // 12pt
AppDesign.CornerRadius.button     // 12pt
AppDesign.CornerRadius.input      // 10pt

// Shadows
view.cardShadow()                 // Standard card shadow
view.elevatedShadow()             // Elevated component shadow
```

### Role-Based Theming

```swift
// Attendee: #FF7A00 (Orange)
// Organizer: #FFA500 (Light Orange)
RoleConfig.getPrimaryColor(for: userRole)
```

---

## 🔐 Authentication

### Test Database

The app includes a production-grade test database (`TestDatabase.swift`) with:

- **Multi-user support** - Register and login multiple users
- **Password hashing** - SHA256 with random salt
- **Session persistence** - Survives app restarts
- **6 pre-seeded test users** (see Quick Start section)

### Authentication Methods

1. **Email/Password**
   - Full registration with validation
   - Secure password hashing

2. **Phone OTP**
   - 6-digit code verification
   - Mock OTP: "123456"

3. **Social Login**
   - Apple Sign In (mock)
   - Google Sign In (mock)
   - Facebook Sign In (mock)

### Modern Auth UI

Located in `Views/Auth/ModernAuthView.swift`:
- Pill-style toggle (Login/Register/OTP)
- Real-time form validation
- Inline error messages
- Loading states
- Haptic feedback

---

## 🎫 Time-Based Ticket Sales

### Automatic Sales Cutoff

Events automatically stop ticket sales when the event starts:

```swift
// Event+TicketSales.swift
extension Event {
    var isTicketSalesOpen: Bool {
        guard status == .published else { return false }
        guard !hasStarted else { return false }
        return true
    }

    var hasStarted: Bool {
        Date() >= startDate
    }

    var timeUntilSalesClose: TimeInterval? {
        guard isTicketSalesOpen else { return nil }
        return startDate.timeIntervalSinceNow
    }
}
```

### Real-Time Countdown Timer

`SalesCountdownTimer` component shows urgency:
- **Badge style**: Compact countdown (e.g., "2h 30m")
- **Inline style**: "Sales end in 2 hours 30 minutes"
- **Card style**: Full card with icon and details
- **Color-coded urgency**:
  - Red: < 1 hour
  - Orange: < 1 day
  - Green: > 1 day

---

## 🔌 Backend Integration

All services use protocols for easy backend swapping:

### Service Protocols

```swift
protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signUp(...) async throws -> User
    func signInWithPhone(...) async throws -> String
    func verifyPhoneCode(...) async throws -> User
}

protocol EventServiceProtocol {
    func fetchEvents() async throws -> [Event]
    func createEvent(_ event: Event) async throws -> Event
    func updateEvent(_ event: Event) async throws
    func deleteEvent(_ id: UUID) async throws
}

protocol TicketServiceProtocol {
    func purchaseTicket(...) async throws -> [Ticket]
    func scanTicket(qrCode: String) async throws -> Ticket
    func getUserTickets(userId: UUID) async throws -> [Ticket]
}

protocol PaymentServiceProtocol {
    func initiatePayment(...) async throws -> Payment
    func processPayment(paymentId: UUID) async throws -> PaymentStatus
}
```

### Option 1: Firebase Backend

```swift
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseAuthService: AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        // Map Firebase user to your User model
        return mapToUser(result.user)
    }
    // Implement other methods...
}

// Update ServiceContainer in EventPassUGApp.swift
services = ServiceContainer(
    authService: FirebaseAuthService(),
    eventService: FirestoreEventService(),
    ticketService: FirestoreTicketService(),
    paymentService: StripePaymentService()
)
```

### Option 2: REST API Backend

```swift
class RESTAuthService: AuthServiceProtocol {
    private let baseURL = "https://api.eventpass.ug"

    func signIn(email: String, password: String) async throws -> User {
        let url = URL(string: "\(baseURL)/auth/signin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }

        return try JSONDecoder().decode(User.self, from: data)
    }
    // Implement other methods...
}
```

### Payment Integration

#### Flutterwave (Recommended for Uganda)

```swift
class FlutterwavePaymentService: PaymentServiceProtocol {
    private let publicKey = "YOUR_FLUTTERWAVE_PUBLIC_KEY"

    func initiatePayment(amount: Double, method: PaymentMethod, userId: UUID, eventId: UUID) async throws -> Payment {
        // Integrate Flutterwave Standard SDK
        // See: https://developer.flutterwave.com/docs/ios-sdk
    }
}
```

Payment methods supported:
- **MTN Mobile Money** (Yellow branding)
- **Airtel Money** (Red branding)
- **Card** (Visa/Mastercard)

---

## 🧪 Testing

### Run Unit Tests

```bash
# From command line
xcodebuild test -scheme EventPassUG -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode
⌘ + U
```

### Test Coverage

- ✅ Date formatting utilities
- ✅ Greeting logic (time-based)
- ✅ Event category filtering
- ✅ "Happening now" detection
- ✅ Price range calculation

### Manual Testing

**Test Data:**
- 6 pre-seeded users (see Authentication section)
- Sample events with various categories
- Test ticket purchases
- QR code generation

---

## 📱 Device Support

### iPhone
- iPhone SE (2nd gen) and later
- iOS 16.0+

### iPad
- All iPads supporting iOS 16.0+
- Optimized split-view layouts

### Accessibility
- ✅ VoiceOver labels on all interactive elements
- ✅ Dynamic Type support
- ✅ High contrast support
- ✅ Reduce Motion support

---

## 🔐 Permissions

The app requests the following permissions (configured in `Info.plist`):

| Permission | Usage | Required |
|------------|-------|----------|
| Camera | QR code scanning for ticket validation | Yes (Organizers) |
| Photo Library | Selecting event posters | Yes (Organizers) |
| Notifications | Event reminders and updates | Optional |
| Location (When In Use) | Showing nearby events | Optional |

---

## 🚀 Deployment

### Production Checklist

#### 1. Backend Integration
- [ ] Replace `TestDatabase` with real database
- [ ] Replace mock services with real API calls
- [ ] Add API endpoint configuration
- [ ] Implement error handling and retry logic

#### 2. Security
- [ ] Enable SSL pinning for API calls
- [ ] Secure storage for auth tokens (Keychain)
- [ ] Implement rate limiting
- [ ] Add fraud detection

#### 3. Payment Integration
- [ ] Integrate Flutterwave/Paystack SDK
- [ ] Configure API keys (secure storage)
- [ ] Test payment flows
- [ ] Implement refund handling

#### 4. App Store
- [ ] Create App Store listing
- [ ] Prepare screenshots (all device sizes)
- [ ] Write app description
- [ ] Add privacy policy URL
- [ ] Submit for review

---

## 🐛 Troubleshooting

### Build Errors

**Error: "No such module 'MapKit'"**
```bash
# Solution: Clean build folder
⌘ + Shift + K
# Then rebuild
⌘ + B
```

**Error: "Cannot find type 'Event' in scope"**
```bash
# Solution: Ensure all files are added to target
# Select file → File Inspector → Target Membership → Check EventPassUG
```

**Error: Asset Catalog Compilation Failed**
```bash
# Solution: Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/EventPassUG-*
# Then rebuild
```

### Runtime Issues

**Camera not working in simulator**
```bash
# Solution: Test on a physical device
# Simulator doesn't support camera capture
```

**QR codes not rendering**
```bash
# Solution: Ensure CoreImage framework is linked
# Build Phases → Link Binary With Libraries → Add CoreImage.framework
```

**Test users not appearing**
```bash
# Solution: Reset test database
# Delete app from device/simulator
# Reinstall - database will reseed automatically
```

---

## 📊 Project Statistics

- **Total Files**: 50+ Swift source files
- **Lines of Code**: ~10,000 LOC
- **Models**: 6 (User, Event, Ticket, TicketType, NotificationModel, Payment)
- **Services**: 5 protocols with mock implementations
- **Views**: 30+ SwiftUI views
- **Components**: 10+ reusable UI components
- **Tests**: 2 test suites with 10+ test cases

---

## 🎓 Key Features Documentation

### 1. Auto-Scroll Fix
The app uses MVVM with `@StateObject` ViewModels to prevent auto-scrolling issues:
- Uses `.task` instead of `.onAppear` for data loading
- Implements `withAnimation(.none)` for state updates
- Stable scroll positions with ScrollViewReader
- Prevents re-loading with `hasLoadedInitialData` flag

### 2. Onboarding Flow
- Shows only once on first app install
- Uses `@AppStorage` for persistence
- Proper flow: Onboarding → Login → Main App
- Never shows again for logged-in or returning users

### 3. Poster Management System
- Image validation (minimum 900×1125px)
- JPEG compression with quality settings
- Protocol-based architecture (easy backend swap)
- Ready for Firebase Storage integration

---

## 🌟 Best Practices Used

### Code Quality
- ✅ Consistent naming conventions
- ✅ Clear separation of concerns
- ✅ Reusable components
- ✅ Protocol-oriented design
- ✅ Dependency injection
- ✅ Error handling with Swift Result types
- ✅ Async/await for concurrency

### SwiftUI Patterns
- ✅ @State for local state
- ✅ @Binding for two-way binding
- ✅ @EnvironmentObject for dependency injection
- ✅ @Published for observable state
- ✅ @StateObject for ViewModels
- ✅ Views are declarative and composable

### iOS Platform Integration
- ✅ Haptic feedback for user actions
- ✅ Native animations (spring, easing)
- ✅ SF Symbols for icons
- ✅ System fonts with Dynamic Type
- ✅ Accessibility labels and hints
- ✅ VoiceOver support
- ✅ Dark mode adaptation

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- **Apple** - SwiftUI, MapKit, AVFoundation, CryptoKit
- **SF Symbols** - Icon system
- **Uganda Tech Community** - Inspiration and support

---

## 📧 Contact

For questions, suggestions, or support:
- **Email**: support@eventpass.ug
- **GitHub**: [@yourusername](https://github.com/yourusername)

---

**Built with ❤️ for Uganda's event community**

---

## 🏗 Project Refactoring (Completed)

**Date:** December 19, 2025  
**Status:** ✅ Complete - Professional MVVM structure implemented

### Refactoring Overview

The project has been refactored from a flat structure to a professional, scalable MVVM architecture following iOS industry best practices.

### New Project Structure

```
EventPassUG/
├── App/                          # App lifecycle (2 files)
├── Core/                         # Configuration, CoreData, Storage (4 files)
│   ├── Configuration/
│   └── Data/
│       ├── CoreData/
│       └── Storage/
├── Models/                       # Data models (10 files)
│   ├── Domain/                   # User, Event, Ticket, etc.
│   ├── Notifications/
│   ├── Preferences/              # UserInterests, UserPreferences
│   └── Support/
├── Services/                     # Business logic (16 files)
│   ├── Authentication/
│   ├── Events/
│   ├── Tickets/
│   ├── Notifications/
│   ├── Recommendations/          # NEW: Personalization engine
│   ├── Location/
│   ├── Payment/
│   ├── Calendar/
│   └── UserPreferences/
├── ViewModels/                   # Presentation logic (5 files)
│   ├── Auth/
│   ├── Attendee/
│   ├── Organizer/
│   └── Settings/
├── Views/                        # UI components (63 files)
│   ├── Auth/
│   ├── Attendee/
│   ├── Organizer/
│   ├── Profile/
│   ├── Notifications/
│   ├── Support/
│   ├── Shared/
│   ├── Components/
│   └── Navigation/
├── DesignSystem/                 # Design tokens (1 file)
│   └── Theme/
├── Utilities/                    # Helpers and managers (18 files)
│   ├── Managers/
│   └── Helpers/
└── Resources/                    # Assets
```

### Benefits Achieved

**For Development:**
- ✅ Easier navigation - files organized by feature and responsibility
- ✅ Faster onboarding - clear structure for new developers
- ✅ Better maintainability - proper separation of concerns
- ✅ Reduced conflicts - feature-based organization

**For Scalability:**
- ✅ Ready for growth - structure supports adding new features
- ✅ Modular architecture - can extract packages later
- ✅ Multi-platform ready - supports iOS, iPadOS, watchOS, macOS
- ✅ Team collaboration - clear ownership of layers

**For Code Quality:**
- ✅ Consistent patterns - MVVM enforced through structure
- ✅ Design system - centralized, consistent UI tokens
- ✅ No duplicates - single source of truth
- ✅ Type safety - proper Swift types throughout

---

## 🤖 Personalized Recommendation System (NEW)

**Status:** ✅ Complete - Production-ready intelligent event discovery

### Overview

EventPass now features a comprehensive, deterministic recommendation engine that personalizes event discovery based on user interests, behavior, location, and temporal signals. The system uses a multi-factor scoring algorithm (no ML required) that's explainable, tunable, and production-ready.

### Key Features

#### 1. User Interests Model

Located in `EventPassUG/Models/Preferences/UserInterests.swift`

**Captured Interests:**
- ✅ Preferred event categories (explicit selection)
- ✅ Inferred categories (from behavior)
- ✅ Preferred cities and travel distance
- ✅ Price preferences (Free, Budget, Moderate, Premium)
- ✅ Temporal preferences (days of week, time of day)
- ✅ Social signals (followed organizers)
- ✅ Behavioral tracking (purchases, likes, views)

**Key Properties:**
```swift
struct UserInterests {
    var preferredCategories: [EventCategory]
    var maxTravelDistance: Double?
    var pricePreference: PricePreference?
    var preferredDaysOfWeek: [Int]
    var preferredTimeOfDay: [TimeOfDayPreference]
    var followedOrganizerIds: [UUID]
    
    // Behavioral data
    var purchasedEventCategories: [EventCategory: Int]
    var likedEventCategories: [EventCategory: Int]
    var viewedEventCategories: [EventCategory: Int]
    
    // Computed properties
    var confidenceScore: Double      // 0.0 - 1.0
    var isNewUser: Bool              // Cold start detection
}
```

#### 2. Event Relevance Scoring

Located in `EventPassUG/Services/Recommendations/RecommendationService.swift`

**Scoring Weights (Tunable for A/B testing):**

| Signal | Weight | Description |
|--------|--------|-------------|
| **Category Match** | 40 pts | Exact match with preferred categories |
| **Purchase History** | 35 pts | Similar events user attended |
| **Like History** | 25 pts | Similar events user liked |
| **Followed Organizer** | 30 pts | Event from organizer you follow |
| **Happening Now** | 25 pts | Event is currently ongoing |
| **Same City** | 20 pts | Event in user's city |
| **Nearby Event** | 15 pts | Within travel distance |
| **Upcoming Soon** | 15 pts | Event within 7 days |
| **Popular Event** | 10 pts | High ticket sales ratio |
| **This Weekend** | 10 pts | Event on Saturday/Sunday |
| **Price Match** | 8 pts | Matches price preference |
| **High Rating** | 5 pts | Rating >= 4.0 |
| **Free Event** | 5 pts | Bonus for free events |
| **Recently Added** | 5 pts | Created in last 7 days |
| **Far Event** | -10 pts | Outside max travel distance |

**Example Scoring:**
```
Event: "Tech Summit 2024" (Technology)
User: Has attended 2 tech events, in Kampala, likes moderate pricing

Score calculation:
+ 40 pts (Category match - Technology)
+ 35 pts (Attended similar tech events)
+ 20 pts (Same city - Kampala)
+ 15 pts (Upcoming in 5 days)
+ 8 pts (Price matches moderate preference)
+ 5 pts (Highly rated 4.8⭐)
─────────────────────────────
= 123 pts total

Reasons generated:
1. "Matches your Technology interests"
2. "Similar to events you've attended"
3. "In Kampala"
4. "In 5 days"
```

#### 3. Intelligent Home Sections

The Home feed now displays events in intelligent sections based on user context:

**Recommendation Categories:**
1. **Recommended for You** - Top personalized matches (highest scores)
2. **Happening Now** - Events currently in progress
3. **Based on Your Interests** - Matches preferred categories
4. **Events Near You** - Proximity-based recommendations
5. **Popular Right Now** - High ticket sales / engagement
6. **This Weekend** - Saturday/Sunday events
7. **Free Events** - No-cost opportunities

**Smart Section Display:**
- ✅ Dynamically shows/hides based on available content
- ✅ Prioritizes most relevant sections
- ✅ Adapts to new vs. returning users
- ✅ Honors location privacy preferences

#### 4. Cold Start Handling

For new users with no interaction history:

**Strategy:**
1. Show **popular events** (high ticket sales)
2. Show **upcoming soon** events (next 3 days)
3. Show **diverse categories** (2 events per category)
4. Gradually learn preferences as user interacts

**Benefits:**
- ✅ Immediate value even for first-time users
- ✅ Introduces variety to discover interests
- ✅ Learns quickly from initial interactions

#### 5. Interaction Tracking

Automatic learning from user behavior:

```swift
// Automatically recorded when user:
viewModel.recordEventInteraction(event: event, type: .view)      // Views event
viewModel.recordEventInteraction(event: event, type: .like)      // Likes event  
viewModel.recordEventInteraction(event: event, type: .purchase)  // Buys ticket
viewModel.recordEventInteraction(event: event, type: .share)     // Shares event
```

**Weights:**
- Purchase: 5.0 (strongest signal)
- Like/Favorite: 3.0
- Share: 2.0
- View: 1.0 (weakest signal)

#### 6. Recommendation Explanations

Users can see why events were recommended:

```swift
let reason = viewModel.getRecommendationReason(for: event)
// Returns: "Matches your Music interests"
// Or: "Similar to events you've attended"
// Or: "Only 5km away"
```

**Benefits:**
- ✅ Transparency - users understand recommendations
- ✅ Trust - clear reasoning builds confidence
- ✅ Control - users can adjust preferences

### Implementation Details

**ViewModel Integration** (`AttendeeHomeViewModel.swift`):
```swift
@MainActor
class AttendeeHomeViewModel: ObservableObject {
    @Published private(set) var recommendedEvents: [ScoredEvent] = []
    
    // Automatically ranks events by relevance
    var rankedEvents: [Event] {
        recommendedEvents.map { $0.event }
    }
    
    // Generate recommendations for user
    func generateRecommendations(for user: User) async {
        let scored = await recommendationService.getRecommendedEvents(
            for: user,
            from: events,
            limit: 50
        )
        self.recommendedEvents = scored
    }
}
```

**View Integration** (`AttendeeHomeView.swift`):
```swift
// Events are automatically ranked by recommendations
ForEach(viewModel.rankedEvents, id: \.id) { event in
    EventCard(
        event: event,
        onLikeTap: {
            viewModel.recordEventInteraction(event: event, type: .like)
        },
        onCardTap: {
            viewModel.recordEventInteraction(event: event, type: .view)
        }
    )
}
```

### Why This Approach Scales

**1. Deterministic & Explainable**
- No black-box ML models
- Clear scoring logic
- Easy to debug and tune
- Users understand recommendations

**2. Tunable Weights**
- Easy A/B testing
- Adjust weights based on metrics
- Fine-tune for your audience
- No retraining required

**3. Fast & Efficient**
- No server-side processing needed
- Runs locally on device
- Instant results
- Works offline

**4. Easy to Upgrade**
- Can add ML layer later
- Current system provides baseline
- Scoring data trains future models
- Smooth migration path

**5. Privacy-Friendly**
- All processing on-device
- No behavior tracking to server
- User controls their data
- GDPR compliant

### Future Enhancements

**Optional Improvements:**
- 🔲 Collaborative filtering (users like you also liked...)
- 🔲 Time decay on old interactions
- 🔲 Seasonal event boosting
- 🔲 Friend network recommendations
- 🔲 Weather-based adjustments
- 🔲 ML model integration (if needed)

---

## 📈 Project Statistics (Updated)

- **Total Files**: 119 Swift files
- **Lines of Code**: ~15,000 LOC
- **Models**: 10 (User, Event, Ticket, UserInterests, etc.)
- **Services**: 9 protocols with implementations
- **Views**: 63 SwiftUI views
- **Components**: 15+ reusable UI components
- **ViewModels**: 5 MVVM view models
- **Build Status**: ✅ SUCCESS
- **Architecture**: Professional MVVM + Services
- **Recommendation Engine**: ✅ Fully integrated

---

## 🎯 Quick Start (Updated)

### Experience Personalized Recommendations

1. **Login** as a test user (see Authentication section)
2. **Browse events** - Events are now ranked by relevance
3. **Interact** - Like events, view details
4. **Watch** - Recommendations improve with each interaction
5. **Check sections** - See "Recommended for You", "Near You", etc.

### Test Recommendations

```swift
// Test users have different interests pre-configured
john@example.com    → Likes Music, Technology
jane@example.com    → Likes Arts & Culture, Food
alice@example.com   → Likes Sports, Fundraising
```

---


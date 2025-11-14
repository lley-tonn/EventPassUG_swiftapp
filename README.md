# EventPass UG - Native iOS App

A complete, production-ready native iOS application for discovering and managing events across Uganda. Built with **Swift** and **SwiftUI** targeting iOS 16+.

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🎯 Features

### Dual Role Support
- **Attendee Mode**: Discover events, purchase tickets, view QR codes
- **Organizer Mode**: Create events, manage tickets, track analytics
- Seamless role switching from profile settings

### Attendee Features
- ✅ Event discovery with category and time-based filters
- ✅ Interactive MapKit integration for venue locations
- ✅ Ticket purchase with multiple payment methods (Mobile Money, Credit Card, Bank Transfer)
- ✅ QR code generation for tickets (CoreImage)
- ✅ Event ratings and reviews
- ✅ Favorite events
- ✅ Real-time "Happening now" indicators with pulsing animation
- ✅ Add to Apple Wallet (stub with instructions)

### Organizer Features
- ✅ 3-step event creation wizard with draft saving
- ✅ Multiple ticket types with pricing configuration
- ✅ Analytics dashboard (revenue, tickets sold, active events)
- ✅ QR code scanner for ticket validation (AVFoundation)
- ✅ Event management (published/draft/ongoing states)
- ✅ Earnings withdrawal UI

### UI/UX Polish
- ✅ Platform-native iOS design with SwiftUI
- ✅ Dark/light mode support
- ✅ Role-based theming (Attendee: #FF7A00, Organizer: #FFA500)
- ✅ Haptic feedback for interactions
- ✅ Smooth animations (pulsing dot, like button, notification badge)
- ✅ Accessibility support (VoiceOver, Dynamic Type)
- ✅ Reduce Motion support
- ✅ Responsive layout (iPhone & iPad)

### Architecture
- **MVVM** architecture pattern
- **Combine** & **async/await** for reactive state management
- **Protocol-oriented** services layer for easy backend swapping
- **Core Data** for local persistence
- **Dependency Injection** via ServiceContainer

---

## 📋 Requirements

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+
- iOS 16.0+ deployment target
- Swift 5.9+
- CocoaPods or Swift Package Manager (SPM)

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/EventPassUG-MobileApp.git
cd EventPassUG-MobileApp
```

### 2. Open in Xcode

```bash
open EventPassUG.xcodeproj
```

If you don't have an `.xcodeproj` file, create one:
1. Open Xcode
2. File → New → Project
3. Choose **iOS** → **App**
4. Product Name: `EventPassUG`
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Use Core Data: **Yes**
8. Bundle Identifier: `com.eventpass.ug`
9. Drag all source files from this repository into the project

### 3. Build and Run

1. Select a simulator or connected device (iOS 16.0+)
2. Press **⌘ + R** to build and run
3. The app will launch with mock data

### 4. Test Onboarding

- Enter any email/password and choose a role (Attendee or Organizer)
- Mock authentication will create a session automatically
- You can switch roles anytime from the Profile tab

---

## 🔑 API Keys Configuration

### Google Maps (Optional - Currently using MapKit)

The app currently uses Apple's native **MapKit** which requires no API key. If you want to integrate Google Maps:

#### Option 1: Keep MapKit (Recommended)
No action needed. MapKit works out of the box and provides excellent integration with iOS.

#### Option 2: Add Google Maps SDK

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the following APIs:
   - Maps SDK for iOS
   - Places API (for venue search)

3. Add the API key to `EventPassUGApp.swift`:

```swift
import GoogleMaps

@main
struct EventPassUGApp: App {
    init() {
        GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
        // ...
    }
}
```

4. Add Google Maps SDK via SPM:
```swift
.package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "8.0.0")
```

### Apple Maps Integration

The "Open in Maps" feature uses native Apple Maps - no configuration needed.

### Push Notifications (Optional)

Currently using local notifications (UNUserNotificationCenter). To enable remote push notifications:

1. Enable Push Notifications capability in Xcode
2. Configure APNs in Apple Developer Portal
3. Update `EventPassUGApp.swift` to register for remote notifications
4. Implement `NotificationService` backend integration

---

## 🔄 Backend Integration

The app currently uses **mock services** (`MockAuthService`, `MockEventService`, etc.) for development. Here's how to swap them with real backends:

### Option 1: Firebase Backend

#### Setup Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app with bundle ID: `com.eventpass.ug`
3. Download `GoogleService-Info.plist` and add to Xcode project
4. Add Firebase SPM dependencies:

```swift
// In Xcode: File → Add Packages
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
]
```

#### Implement Real Services

Create `FirebaseAuthService.swift`:

```swift
import Firebase
import FirebaseAuth
import Combine

class FirebaseAuthService: AuthServiceProtocol {
    @Published private(set) var currentUser: User?

    init() {
        FirebaseApp.configure()
        // Implement Firebase Auth methods
    }

    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        // Map Firebase user to your User model
        // ...
    }

    // Implement other protocol methods
}
```

#### Swap Services in `EventPassUGApp.swift`:

```swift
@main
struct EventPassUGApp: App {
    let services: ServiceContainer

    init() {
        services = ServiceContainer(
            authService: FirebaseAuthService(),        // ✅ Real service
            eventService: FirestoreEventService(),     // ✅ Real service
            ticketService: FirestoreTicketService(),   // ✅ Real service
            paymentService: StripePaymentService()     // ✅ Real service
        )
    }
}
```

### Option 2: REST API Backend

Create REST-based services:

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

        let user = try JSONDecoder().decode(User.self, from: data)
        await MainActor.run {
            self.currentUser = user
        }
        return user
    }

    // Implement other protocol methods
}
```

### Payment Gateway Integration

#### Flutterwave (Recommended for Uganda)

```swift
class FlutterwavePaymentService: PaymentServiceProtocol {
    private let publicKey = "YOUR_FLUTTERWAVE_PUBLIC_KEY"  // ⚠️ Add here

    func initiatePayment(amount: Double, method: PaymentMethod, userId: UUID, eventId: UUID) async throws -> Payment {
        // Integrate Flutterwave Standard SDK
        // Documentation: https://developer.flutterwave.com/docs/ios-sdk
    }
}
```

#### Paystack Alternative

```swift
class PaystackPaymentService: PaymentServiceProtocol {
    private let publicKey = "YOUR_PAYSTACK_PUBLIC_KEY"  // ⚠️ Add here

    // Implement Paystack integration
    // Documentation: https://paystack.com/docs/libraries/ios
}
```

---

## 📦 Dependencies

All dependencies are managed via **Swift Package Manager (SPM)**. No third-party dependencies are required for the base app to run, but you can add these for extended functionality:

### Optional Dependencies

#### Firebase (for backend)
```swift
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
```

#### Alamofire (for REST APIs)
```swift
.package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0")
```

#### Flutterwave SDK (for payments)
Follow installation guide: https://developer.flutterwave.com/docs/ios-sdk

#### Google Maps (optional)
```swift
.package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "8.0.0")
```

---

## 💳 Apple Wallet (PassKit) Integration

The app includes a **stub** for "Add to Wallet" functionality. To implement:

### Prerequisites

- Apple Developer Program membership ($99/year)
- Pass Type ID certificate

### Setup Steps

1. **Create Pass Type ID**:
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Certificates, Identifiers & Profiles → Identifiers → Pass Type IDs
   - Create new Pass Type ID: `pass.com.eventpass.ug.ticket`

2. **Generate Certificate**:
   - Create Certificate Signing Request (CSR)
   - Download Pass Type ID Certificate
   - Install in Keychain

3. **Implement PassKit**:

```swift
import PassKit

class PassKitService {
    func createPass(for ticket: Ticket) throws -> PKPass {
        // Create pass JSON
        let passJSON: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": "pass.com.eventpass.ug.ticket",
            "serialNumber": ticket.id.uuidString,
            "teamIdentifier": "YOUR_TEAM_ID",
            "organizationName": "EventPass UG",
            "description": "Event Ticket",
            // ... more fields
        ]

        // Generate .pkpass file
        // See Apple's PassKit documentation
    }
}
```

4. **Update `TicketQRView.swift`**:

```swift
Button(action: {
    let passKitService = PassKitService()
    let pass = try? passKitService.createPass(for: ticket)
    // Present PKAddPassesViewController
}) {
    HStack {
        Image(systemName: "wallet.pass")
        Text("Add to Wallet")
    }
}
.disabled(false)  // Enable the button
```

**Resources**:
- [PassKit Documentation](https://developer.apple.com/documentation/passkit)
- [Wallet Developer Guide](https://developer.apple.com/wallet/)

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

Current unit tests cover:
- ✅ Greeting logic (time-based)
- ✅ Date formatting utilities
- ✅ Event category filtering
- ✅ "Happening now" detection
- ✅ Price range calculation

### UI Testing

A stub UI test is included in `EventPassUGUITests/EventPassUGUITests.swift`:

```swift
func testEventCreationFlow() {
    let app = XCUIApplication()
    app.launch()

    // Test sign-in → role selection → create event → publish
}
```

---

## 🎨 Design Tokens

### Colors

```swift
// Defined in RoleConfig.swift
Attendee Primary: #FF7A00
Organizer Primary: #FFA500
Light Background: #FBFBF7
Dark Background: #000000
Happening Now: #7CFC66
```

### Typography

Uses **SF Pro Rounded** system font with semantic sizes defined in `AppTypography`.

### Spacing

Defined in `AppSpacing`:
- XS: 4pt
- SM: 8pt
- MD: 16pt
- LG: 24pt
- XL: 32pt
- XXL: 48pt

---

## 📱 Device Support

### iPhone
- iPhone SE (2nd gen) and later
- iOS 16.0+

### iPad
- All iPads supporting iOS 16.0+
- Optimized split-view layouts

### Accessibility
- VoiceOver labels on all interactive elements
- Dynamic Type support
- High contrast support
- Reduce Motion support

---

## 🔐 Permissions

The app requests the following permissions (configured in `Info.plist`):

| Permission | Usage | Required |
|------------|-------|----------|
| Camera | QR code scanning for ticket validation | Yes (Organizers) |
| Photo Library | Selecting event posters | Yes (Organizers) |
| Notifications | Event reminders and updates | Optional |
| Location (When In Use) | Showing nearby events (future feature) | Optional |

---

## 🗂 Project Structure

```
EventPassUG/
├── EventPassUGApp.swift          # App entry point
├── ContentView.swift              # Root view with auth routing
│
├── Models/                        # Data models
│   ├── User.swift
│   ├── Event.swift
│   ├── Ticket.swift
│   ├── TicketType.swift
│   └── NotificationModel.swift
│
├── Services/                      # Business logic layer
│   ├── ServiceContainer.swift     # DI container
│   ├── AuthService.swift          # Auth protocol + mock
│   ├── EventService.swift         # Event CRUD + mock
│   ├── TicketService.swift        # Ticket purchase + scanning
│   └── PaymentService.swift       # Payment processing
│
├── Views/
│   ├── Components/                # Reusable UI components
│   │   ├── PulsingDot.swift
│   │   ├── AnimatedLikeButton.swift
│   │   ├── NotificationBadge.swift
│   │   ├── HeaderBar.swift
│   │   ├── CategoryTile.swift
│   │   ├── EventCard.swift
│   │   ├── QRCodeView.swift
│   │   └── LoadingView.swift
│   │
│   ├── Navigation/
│   │   └── MainTabView.swift      # Role-based tab navigation
│   │
│   ├── Auth/
│   │   └── OnboardingView.swift   # Sign up + role selection
│   │
│   ├── Attendee/
│   │   ├── AttendeeHomeView.swift       # Event feed + categories
│   │   ├── EventDetailsView.swift       # Event details + MapKit
│   │   ├── TicketPurchaseView.swift     # Purchase flow
│   │   └── TicketsView.swift            # User's tickets + QR
│   │
│   ├── Organizer/
│   │   ├── OrganizerHomeView.swift      # Event list
│   │   ├── CreateEventWizard.swift      # 3-step event creation
│   │   ├── OrganizerDashboardView.swift # Analytics + QR scanner
│   │   └── QRScannerView.swift          # AVFoundation camera
│   │
│   └── Common/
│       ├── ProfileView.swift            # Profile + role switcher
│       └── NotificationsView.swift      # Notifications list
│
├── Config/
│   └── RoleConfig.swift           # Theme colors and tokens
│
├── Utilities/
│   ├── DateUtilities.swift        # Date formatting + greeting logic
│   ├── QRCodeGenerator.swift      # CoreImage QR generation
│   └── HapticFeedback.swift       # Haptic utilities
│
├── CoreData/
│   ├── PersistenceController.swift
│   └── EventPassUG.xcdatamodeld   # Core Data model
│
├── Info.plist                     # App configuration + permissions
│
└── Assets.xcassets/
    ├── Colors/                    # Role-based colors
    ├── Images/                    # Placeholder event posters
    └── AppIcon.appiconset/        # App icon
```

---

## 🚧 Future Enhancements

### High Priority
- [ ] Real Firebase/REST backend integration
- [ ] Payment gateway integration (Flutterwave/Paystack)
- [ ] PassKit ticket integration
- [ ] Push notifications
- [ ] Social sharing (event details)

### Medium Priority
- [ ] Google Places API for venue search
- [ ] Event search functionality
- [ ] User reviews with photos
- [ ] Organizer analytics export (CSV/PDF)
- [ ] Multi-language support (English, Luganda)

### Low Priority
- [ ] Apple Sign In / Google Sign In
- [ ] Event recommendations based on interests
- [ ] Offline mode improvements
- [ ] Widget support (upcoming events)

---

## 🐛 Troubleshooting

### Build Errors

**Error: "No such module 'Firebase'"**
```bash
# Solution: Add Firebase via SPM
File → Add Packages → https://github.com/firebase/firebase-ios-sdk
```

**Error: "Info.plist not found"**
```bash
# Solution: Ensure Info.plist is added to target
Select Info.plist → File Inspector → Target Membership → Check EventPassUG
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

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Apple** - SwiftUI, MapKit, PassKit, AVFoundation
- **SF Symbols** - Icon system
- **Uganda Tech Community** - Inspiration and support

---

## 📧 Contact

For questions, suggestions, or support:

- **Email**: support@eventpass.ug
- **GitHub**: [@yourusername](https://github.com/yourusername)
- **Twitter**: [@eventpassug](https://twitter.com/eventpassug)

---

## ✅ Acceptance Criteria Checklist

- [x] Install and run on iOS Simulator
- [x] Sign in with mock account and pick role
- [x] **Attendee**:
  - [x] Category grid with filtered event list
  - [x] Event Details with MapKit pin
  - [x] Like event (persists)
  - [x] Buy ticket with mock payment
  - [x] View QR code under Tickets tab
  - [x] Rate event after end time
  - [x] See pulsing "Happening now" for live events
- [x] **Organizer**:
  - [x] 3-step Create Event wizard
  - [x] Publish event to Attendee feed
  - [x] Dashboard analytics
  - [x] QR scanner validates tickets
- [x] Dark/light theme with role-based colors
- [x] All assets and colors match specs

---

**Built with ❤️ for Uganda's event community**

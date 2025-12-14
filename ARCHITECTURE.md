# EventPass UG - Architecture Documentation

## Project Overview

EventPass UG is a dual-role mobile application for event discovery and management in Uganda. Users can act as **Attendees** (discover and purchase event tickets) or **Organizers** (create and manage events).

---

## Table of Contents

1. [App Structure](#app-structure)
2. [Architecture Patterns](#architecture-patterns)
3. [Key Components](#key-components)
4. [Data Flow](#data-flow)
5. [Service Layer](#service-layer)
6. [Authentication Flow](#authentication-flow)
7. [Role-Based System](#role-based-system)
8. [UI Theming](#ui-theming)
9. [Common Patterns](#common-patterns)
10. [File Organization](#file-organization)

---

## App Structure

```
EventPassUG/
├── EventPassUGApp.swift        # App entry point
├── ContentView.swift           # Root view with auth/main switching
├── Info.plist                  # App configuration & permissions
│
├── Models/                     # Data structures
│   ├── User.swift              # User model with dual-role support
│   ├── Event.swift             # Event and venue models
│   ├── Ticket.swift            # Ticket purchase records
│   ├── TicketType.swift        # Ticket tier definitions
│   └── NotificationPreferences.swift  # User settings
│
├── Services/                   # Business logic layer
│   ├── AuthService.swift       # Authentication & user management
│   ├── EventService.swift      # Event CRUD operations
│   ├── TicketService.swift     # Ticket purchases & validation
│   ├── PaymentService.swift    # Payment processing
│   └── ServiceContainer.swift  # Dependency injection container
│
├── Views/                      # UI layer
│   ├── Auth/                   # Authentication screens
│   ├── Attendee/               # Attendee-specific views
│   ├── Organizer/              # Organizer-specific views
│   ├── Common/                 # Shared views (Profile, Settings)
│   ├── Components/             # Reusable UI components
│   ├── Navigation/             # Tab bars and routing
│   └── Support/                # Help center and support
│
├── Config/                     # App configuration
│   └── RoleConfig.swift        # Role-based theming
│
└── Utilities/                  # Helper functions
    ├── HapticFeedback.swift    # Tactile feedback
    ├── QRCodeGenerator.swift   # QR code creation
    └── DateUtilities.swift     # Date formatting
```

---

## Architecture Patterns

### 1. **MVVM (Model-View-ViewModel)**
- **Models**: Data structures in `/Models`
- **Views**: SwiftUI views in `/Views`
- **ViewModels**: Embedded in views using `@StateObject` and `@ObservableObject`

### 2. **Dependency Injection**
```swift
// ServiceContainer holds all app services
@EnvironmentObject var services: ServiceContainer
@EnvironmentObject var authService: MockAuthService
```

### 3. **Protocol-Oriented Design**
Services use protocols for easy testing and mocking:
```swift
protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
}
```

### 4. **Environment Objects**
Services are injected at app root and available throughout:
```swift
// In EventPassUGApp.swift
ContentView()
    .environmentObject(authService)
    .environmentObject(serviceContainer)
```

---

## Key Components

### ContentView.swift
**Purpose**: Root view that switches between authentication and main app based on login state.

```swift
struct ContentView: View {
    @EnvironmentObject var authService: MockAuthService

    var body: some View {
        if authService.isAuthenticated {
            // Show main app (role-based navigation)
            MainTabView(userRole: user.currentActiveRole)
        } else {
            // Show login/signup flow
            OnboardingView()
        }
    }
}
```

### MainTabView.swift
**Purpose**: Role-aware tab bar navigation.

- **Attendee tabs**: Home, Search, Tickets, Profile
- **Organizer tabs**: Dashboard, Events, Scanner, Profile
- Automatically updates when user switches roles

### ProfileView.swift
**Purpose**: User profile and settings hub with collapsible header.

Features:
- Role switching for dual-role users
- Settings navigation (Edit Profile, Interests, Notifications, etc.)
- Account actions (Verify, Become Organizer, Logout)

---

## Data Flow

### Event Discovery (Attendee)
```
AttendeeHomeView
    ↓
EventService.fetchEvents()
    ↓
Event[] (filtered by time/category)
    ↓
EventCard components
    ↓
EventDetailsView → TicketPurchaseView
```

### Event Creation (Organizer)
```
CreateEventWizard
    ↓
Step 1: Basic Info → Step 2: Venue → Step 3: Tickets → Step 4: Review
    ↓
EventService.createEvent()
    ↓
OrganizerDashboardView (shows new event)
```

### Ticket Purchase
```
TicketPurchaseView
    ↓
Select ticket type & quantity
    ↓
PaymentService.processPayment()
    ↓
TicketService.purchaseTicket()
    ↓
Ticket created with QR code
```

---

## Service Layer

### MockAuthService
**File**: `Services/AuthService.swift`

Handles:
- User authentication (email/password, phone, social)
- User registration with role selection
- Profile updates
- Email/phone verification
- Session management

Key methods:
```swift
func signIn(email: String, password: String) async throws -> User
func signUp(user: User) async throws -> User
func updateProfile(_ user: User) async throws
func verifyEmail() async throws
```

### MockEventService
**File**: `Services/EventService.swift`

Handles:
- Fetching events (with filters)
- Creating/updating events
- Event search and discovery
- Category management

### MockTicketService
**File**: `Services/TicketService.swift`

Handles:
- Ticket purchases
- QR code generation
- Ticket validation
- Purchase history

### ServiceContainer
**File**: `Services/ServiceContainer.swift`

Dependency injection container:
```swift
class ServiceContainer: ObservableObject {
    let authService: MockAuthService
    let eventService: MockEventService
    let ticketService: MockTicketService
    let paymentService: MockPaymentService
}
```

---

## Authentication Flow

### 1. New User Registration
```
OnboardingView
    ↓
Welcome screens (swipe through)
    ↓
Sign Up form (email/password or social)
    ↓
Phone verification (optional)
    ↓
Interest selection (FavoriteEventCategoriesView)
    ↓
Main app
```

### 2. Existing User Login
```
OnboardingView
    ↓
Sign In form
    ↓
AuthService.signIn()
    ↓
Check hasCompletedOnboarding
    ↓
Main app (or complete onboarding)
```

### 3. Social Authentication
- **Google**: GoogleLogoView + Google Sign-In SDK
- **Apple**: Native Sign in with Apple
- **Phone**: OTP verification flow

---

## Role-Based System

### User Model (Dual-Role Support)
```swift
struct User {
    var isAttendeeRole: Bool      // Can act as attendee
    var isOrganizerRole: Bool     // Can act as organizer (completed onboarding)
    var currentActiveRole: UserRole  // Currently active role
    var organizerProfile: OrganizerProfile?  // Organizer-specific data
}
```

### Becoming an Organizer
```
ProfileView → "Become an Organizer" button
    ↓
BecomeOrganizerFlow (5 steps):
    1. Profile completion (name, email, phone verified)
    2. Identity verification (National ID/Passport)
    3. Contact information (public email, socials)
    4. Payout setup (MTN MoMo, Airtel, Bank)
    5. Terms agreement
    ↓
User.isOrganizerRole = true
    ↓
Can switch between roles in ProfileView
```

### Role Switching
```swift
func toggleActiveRole() {
    if user.currentActiveRole == .attendee {
        user.currentActiveRole = .organizer
    } else {
        user.currentActiveRole = .attendee
    }
    // UI automatically updates via @Published
}
```

---

## UI Theming

### RoleConfig.swift
**Purpose**: Role-based color theming throughout the app.

```swift
struct RoleConfig {
    static let attendeePrimary = Color.blue
    static let organizerPrimary = Color.purple

    static func getPrimaryColor(for role: UserRole) -> Color {
        role == .organizer ? organizerPrimary : attendeePrimary
    }
}
```

Usage in views:
```swift
.background(RoleConfig.getPrimaryColor(for: userRole))
```

### AppTypography
Standard text styles:
- `AppTypography.title` - Large titles
- `AppTypography.headline` - Section headers
- `AppTypography.body` - Regular text
- `AppTypography.caption` - Small text

### AppSpacing
Consistent spacing values:
- `AppSpacing.xs` = 4
- `AppSpacing.sm` = 8
- `AppSpacing.md` = 16
- `AppSpacing.lg` = 24
- `AppSpacing.xl` = 32

### AppCornerRadius
Standard corner radii:
- `AppCornerRadius.small` = 8
- `AppCornerRadius.medium` = 12
- `AppCornerRadius.large` = 20

---

## Common Patterns

### 1. Async Data Loading
```swift
@State private var isLoading = true
@State private var events: [Event] = []

.onAppear {
    loadData()
}

private func loadData() {
    Task {
        do {
            let data = try await service.fetchData()
            await MainActor.run {
                self.events = data
                self.isLoading = false
            }
        } catch {
            // Handle error
        }
    }
}
```

### 2. Form Validation
```swift
private var isFormValid: Bool {
    !email.isEmpty &&
    email.contains("@") &&
    password.count >= 6
}

Button("Submit")
    .disabled(!isFormValid)
```

### 3. Sheet Presentation
```swift
@State private var showingSheet = false

.sheet(isPresented: $showingSheet) {
    SomeView()
        .environmentObject(authService)
}
```

### 4. Haptic Feedback
```swift
HapticFeedback.success()  // Success vibration
HapticFeedback.error()    // Error vibration
HapticFeedback.selection() // Light tap
HapticFeedback.light()    // Subtle feedback
```

### 5. Navigation Links
```swift
NavigationLink(destination: DetailView(item: item)) {
    ItemRow(item: item)
}
```

### 6. Skeleton Loading
```swift
if isLoading {
    SkeletonEventCard()  // Placeholder animation
} else {
    EventCard(event: event)
}
```

---

## File Organization

### Models/
- **User.swift**: User account with auth info, roles, preferences
- **Event.swift**: Event details, venue, category, status
- **Ticket.swift**: Purchase records with QR codes
- **TicketType.swift**: Ticket tiers (VIP, Regular, etc.)
- **OrganizerProfile.swift**: Organizer-specific business info
- **NotificationPreferences.swift**: Push/email/SMS settings
- **SupportModels.swift**: Help articles, FAQs, support tickets

### Views/Auth/
- **OnboardingView.swift**: Welcome screens, login, signup
- **SocialAuthButtons.swift**: Google, Apple sign-in buttons
- **GoogleLogoView.swift**: Custom Google "G" logo
- **AddContactMethodView.swift**: Add email/phone verification

### Views/Attendee/
- **AttendeeHomeView.swift**: Event discovery feed with filters
- **EventDetailsView.swift**: Full event information
- **TicketPurchaseView.swift**: Buy tickets flow
- **TicketsView.swift**: User's purchased tickets
- **FavoriteEventsView.swift**: Saved/liked events

### Views/Organizer/
- **OrganizerHomeView.swift**: Organizer dashboard
- **CreateEventWizard.swift**: Multi-step event creation
- **QRScannerView.swift**: Ticket validation scanner
- **BecomeOrganizerFlow.swift**: Organizer onboarding

### Views/Common/
- **ProfileView.swift**: User profile and settings
- **EditProfileView.swift**: Update profile info
- **PaymentMethodsView.swift**: Manage payment methods
- **CardScanner.swift**: Credit card OCR scanner
- **FavoriteEventCategoriesView.swift**: Interest selection

### Views/Components/
- **EventCard.swift**: Reusable event display card
- **QRCodeView.swift**: QR code display
- **LoadingView.swift**: Full-screen loader
- **AnimatedLikeButton.swift**: Heart animation
- **CategoryTile.swift**: Event category selector

---

## Important Files to Know

### 1. **ContentView.swift**
App root - decides auth vs main app flow

### 2. **MainTabView.swift**
Tab navigation that changes based on user role

### 3. **ProfileView.swift**
Settings hub with role switching capability

### 4. **MockAuthService.swift**
All authentication logic (replace with real backend)

### 5. **RoleConfig.swift**
Role-based theming colors

### 6. **User.swift**
Core user model with dual-role support

### 7. **Event.swift**
Event data structure with categories and venues

---

## Production Migration Notes

When connecting to a real backend:

1. **Replace Mock Services**: Update `MockAuthService`, `MockEventService`, etc. with real API calls
2. **Add Network Layer**: Implement URLSession or Alamofire for HTTP requests
3. **Secure Storage**: Use Keychain for tokens instead of UserDefaults
4. **Error Handling**: Add proper network error handling and retry logic
5. **Push Notifications**: Integrate Firebase Cloud Messaging
6. **Analytics**: Add Firebase Analytics or similar
7. **Crash Reporting**: Integrate Crashlytics
8. **Payment Gateway**: Replace mock with real payment provider (Flutterwave, etc.)

---

## Testing

### Unit Tests
- Test service methods independently
- Mock network responses
- Validate business logic

### UI Tests
- Test user flows (signup, purchase, etc.)
- Verify role switching
- Check accessibility

### Preview Support
Most views include `#Preview` blocks:
```swift
#Preview {
    SomeView()
        .environmentObject(MockAuthService())
}
```

---

## Performance Considerations

1. **Lazy Loading**: Use `LazyVStack`, `LazyVGrid` for lists
2. **Image Caching**: AsyncImage handles basic caching
3. **State Management**: Keep @State local, use @StateObject for shared state
4. **Background Tasks**: Use `Task { }` for async work
5. **Memory**: Avoid retain cycles with `[weak self]` in closures

---

## Security Features

1. **Card Scanning**: On-device OCR only, no images stored
2. **Luhn Validation**: Card numbers validated client-side
3. **No Hardcoded Secrets**: API keys should be in environment
4. **Secure Text Fields**: `SecureField` for passwords
5. **Input Validation**: All forms validate before submission

---

For questions or clarifications, refer to the inline code comments in each file.

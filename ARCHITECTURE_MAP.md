# EventPassUG - Complete Architecture Map & User Flows

## Table of Contents
1. [Complete Screen Map](#complete-screen-map)
2. [User Interaction Flows](#user-interaction-flows)
3. [Architecture Connections](#architecture-connections)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [Navigation Hierarchy](#navigation-hierarchy)

---

## Complete Screen Map

### All Application Screens (70+ Views)

```
EventPassUG Mobile App
│
├── 🚪 ONBOARDING & AUTH (8 Screens)
│   ├── AppIntroSlidesView (3 slides)
│   │   ├── IntroSlide1: "Find the Hottest Events"
│   │   ├── IntroSlide2: "Buy Tickets in Seconds"
│   │   └── IntroSlide3: "Host Events Like a Pro"
│   │
│   ├── AuthChoiceView [NEW - GUEST BROWSING]
│   │   ├── Login Button → ModernAuthView
│   │   ├── Become Organizer Button → ModernAuthView (signup)
│   │   └── Continue as Guest Button → MainTabView (guest mode)
│   │
│   ├── ModernAuthView
│   │   ├── Login Tab
│   │   ├── Register Tab
│   │   └── Phone Auth Tab
│   │
│   ├── PhoneVerificationView (OTP input)
│   └── OnboardingFlowView (post-login preferences)
│       ├── Interest selection
│       ├── City selection
│       ├── Price preference
│       └── Notification preferences
│
├── 🏠 MAIN APP (Tab-Based Navigation)
│   │
│   ├──┬── 📅 HOME TAB (Attendee - Accessible to Guests)
│   │  │
│   │  ├── AttendeeHomeView [GUEST ACCESSIBLE]
│   │  │   ├── Search bar
│   │  │   ├── Filter chips (Categories, Time-based)
│   │  │   ├── "Favorites" button [AUTH REQUIRED]
│   │  │   ├── Event feed (ranked by recommendations)
│   │  │   └── EventCard components
│   │  │       ├── Event poster
│   │  │       ├── Heart button (like) [AUTH REQUIRED]
│   │  │       ├── Event details (title, date, location)
│   │  │       └── Tap → EventDetailsView
│   │  │
│   │  ├── EventDetailsView [GUEST ACCESSIBLE]
│   │  │   ├── Hero poster image
│   │  │   ├── Event title & category badge
│   │  │   ├── Like button [AUTH REQUIRED]
│   │  │   ├── Share button [GUEST ACCESSIBLE]
│   │  │   ├── Report button [AUTH REQUIRED]
│   │  │   ├── Organizer info section
│   │  │   │   ├── Organizer name & avatar
│   │  │   │   ├── Follow button [AUTH REQUIRED]
│   │  │   │   └── Follower count
│   │  │   ├── Event details section
│   │  │   │   ├── Date & time
│   │  │   │   ├── Location & map
│   │  │   │   └── Description
│   │  │   ├── Ticket types section
│   │  │   │   ├── Ticket cards (name, price, availability)
│   │  │   │   └── Buy button [AUTH REQUIRED] → TicketPurchaseView
│   │  │   ├── Ratings section [AUTH REQUIRED TO RATE]
│   │  │   │   └── RateEventView modal
│   │  │   └── Similar events carousel
│   │  │
│   │  ├── TicketPurchaseView [AUTH REQUIRED]
│   │  │   ├── Ticket selection (quantity spinner)
│   │  │   ├── Order summary
│   │  │   ├── Payment method selection
│   │  │   │   ├── MTN Mobile Money
│   │  │   │   ├── Airtel Money
│   │  │   │   └── Card Payment
│   │  │   ├── Payment confirmation modal
│   │  │   └── On success → TicketSuccessView
│   │  │
│   │  ├── TicketSuccessView
│   │  │   ├── Success animation
│   │  │   ├── QR code display
│   │  │   ├── Ticket details
│   │  │   └── "View All Tickets" button → TicketsView
│   │  │
│   │  ├── SearchView
│   │  │   ├── Search bar
│   │  │   ├── Recent searches
│   │  │   ├── Category filters
│   │  │   └── Results list (EventCard)
│   │  │
│   │  └── FavoritesView [AUTH REQUIRED]
│   │      ├── Favorited events grid
│   │      └── Empty state (no favorites)
│   │
│   ├──┬── 🎫 TICKETS TAB
│   │  │
│   │  ├── TicketsView [AUTH REQUIRED]
│   │  │   ├── Filter tabs (Upcoming, Past, All)
│   │  │   ├── Ticket grid (responsive)
│   │  │   │   └── Ticket cards → TicketDetailView
│   │  │   └── Empty state
│   │  │
│   │  ├── TicketDetailView
│   │  │   ├── Event poster
│   │  │   ├── QR code (scannable)
│   │  │   ├── Ticket info (type, quantity, price)
│   │  │   ├── Purchase date & status
│   │  │   ├── Event details
│   │  │   ├── Venue map
│   │  │   ├── "Add to Wallet" button
│   │  │   └── "Share Ticket" button
│   │  │
│   │  └── GuestTicketsPlaceholder [NEW - FOR GUESTS]
│   │      ├── Empty state icon (ticket)
│   │      ├── "Sign in to view your tickets" message
│   │      ├── Benefits list (QR codes, wallet, history)
│   │      └── "Sign In" button → ModernAuthView
│   │
│   └──┬── 👤 PROFILE TAB
│      │
│      ├── ProfileView [AUTH REQUIRED - Attendee]
│      │   ├── Profile header
│      │   │   ├── Avatar & edit button
│      │   │   ├── Name & email
│      │   │   └── Verification badge
│      │   ├── Role switcher (Attendee ↔ Organizer)
│      │   ├── Account section
│      │   │   ├── Edit Profile → EditProfileView
│      │   │   ├── Followed Organizers → FollowedOrganizersView
│      │   │   ├── Notification Settings → NotificationSettingsView
│      │   │   └── ID Verification → NationalIDVerificationView
│      │   ├── Support section
│      │   │   ├── Support Center → SupportCenterView
│      │   │   ├── FAQs → FAQsView
│      │   │   └── Privacy Policy → PrivacyPolicyView
│      │   └── Logout button
│      │
│      ├── GuestProfilePlaceholder [NEW - FOR GUESTS]
│      │   ├── Section 1: Sign In CTA
│      │   │   ├── Person icon + empty state
│      │   │   ├── "Create your account" title
│      │   │   ├── Benefits list
│      │   │   └── "Create Account" button → ModernAuthView
│      │   │
│      │   └── Section 2: Become an Organizer Teaser
│      │       ├── Megaphone icon + card
│      │       ├── "Host Events & Sell Tickets" title
│      │       └── "Become an Organizer" button → ModernAuthView
│      │
│      └── EditProfileView, NotificationSettingsView, etc.
│
├── 🎤 ORGANIZER MODE
│   ├── OrganizerDashboardView
│   ├── CreateEventWizard (3 steps)
│   ├── ManageEventView
│   ├── QRScannerView
│   └── Analytics & Earnings views
│
└── 🔔 SHARED SCREENS
    ├── AuthPromptSheet [NEW]
    ├── PaymentConfirmationView
    ├── RateEventView
    └── MapView
```

---

## User Interaction Flows

### Flow 1: First-Time User (Guest Mode)

```
App Launch → Onboarding Slides → AuthChoiceView
                                      │
                    ┌─────────────────┼─────────────────┐
                    ↓                 ↓                 ↓
                  Login        Become Organizer    Continue as Guest
                    ↓                 ↓                 ↓
              ModernAuthView    ModernAuthView    MainTabView (Guest)
                    ↓                 ↓
               Authenticated    Organizer Flow
                    ↓
              MainTabView
```

### Flow 2: Guest Browsing with Auth Prompts

```
Guest in MainTabView
    │
    ├─→ Home Tab ✅ Browse events freely
    ├─→ Like Event 🔒 → AuthPromptSheet → Login → Complete action
    ├─→ Buy Ticket 🔒 → AuthPromptSheet → Login → Purchase flow
    ├─→ Tickets Tab 🔒 → GuestTicketsPlaceholder → Login
    └─→ Profile Tab 🔒 → GuestProfilePlaceholder → Login/Signup
```

### Flow 3: Ticket Purchase (Authenticated)

```
EventDetailsView → Buy Ticket → TicketPurchaseView
    ↓
Select quantity & payment method
    ↓
PaymentConfirmationView (mobile money)
    ↓
Payment processing
    ↓
TicketSuccessView (QR code)
    ↓
TicketsView → TicketDetailView
```

### Flow 4: Event Creation (Organizer)

```
OrganizerDashboardView → Create Event
    ↓
[Verification check]
    ↓
CreateEventWizard
    ├─→ Step 1: Event details
    ├─→ Step 2: Ticket config
    ├─→ Step 3: Poster & description
    └─→ Review & Publish
        ↓
    Event Published → ManageEventView
```

---

## Architecture Connections

### Layer Architecture

```
┌─────────────────────────────────────────┐
│  App Layer                              │
│  - EventPassUGApp.swift (Entry)         │
│  - ContentView.swift (Root)             │
│  - MainTabView.swift (Navigation)       │
└─────────────┬───────────────────────────┘
              │
              ↓
┌─────────────┴───────────────────────────┐
│  Features Layer                         │
│  ├─ Auth/ (8 files)                     │
│  ├─ Attendee/ (12 files)                │
│  ├─ Organizer/ (13 files)               │
│  └─ Common/ (22 files)                  │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    ↓                   ↓
┌───┴─────┐      ┌──────┴──────┐
│ Domain  │      │    Data     │
│ Models  │◄─────│ Repositories│
└─────────┘      └──────┬──────┘
                        │
              ┌─────────┴─────────┐
              ↓                   ↓
       ┌──────────┐      ┌────────────┐
       │ UI/      │      │ Core/      │
       │ Components│      │ Utilities  │
       └──────────┘      └────────────┘
```

### Data Flow

```
View → ViewModel → Repository → Domain Models
  ↑                                    │
  └────────────────────────────────────┘
         (Published changes)
```

### Dependency Injection

```
EventPassUGApp creates ServiceContainer
    ↓
ServiceContainer.init() creates all repositories
    ↓
Services injected via .environmentObject()
    ↓
Views access via @EnvironmentObject
    ↓
ViewModels receive services in init()
```

---

## Navigation Hierarchy

### Tab Structure

```
MainTabView
├─── Attendee Mode
│    ├─── Home Tab (NavigationStack)
│    ├─── Tickets Tab (NavigationStack)
│    └─── Profile Tab (NavigationStack)
│
└─── Organizer Mode
     ├─── Dashboard Tab (NavigationStack)
     ├─── Earnings Tab (NavigationStack)
     ├─── Analytics Tab (NavigationStack)
     └─── Profile Tab (NavigationStack)
```

### Modal Presentations

```
Sheets (.sheet)
├─── AuthPromptSheet
├─── TicketPurchaseView
├─── SearchView
└─── CreateEventWizard

Full Screen (.fullScreenCover)
├─── ModernAuthView
├─── OnboardingFlowView
└─── QRScannerView
```

---

## Summary

**Architecture Highlights:**
- ✅ 70+ screens documented
- ✅ Feature-first clean architecture
- ✅ MVVM + Repository pattern
- ✅ Protocol-based DI
- ✅ Guest browsing support
- ✅ Dual-role navigation
- ✅ Complete user flows mapped

**File Locations:**
- Features: `/EventPassUG/Features/`
- Models: `/EventPassUG/Domain/Models/`
- Repositories: `/EventPassUG/Data/Repositories/`
- Components: `/EventPassUG/UI/Components/`
- Utilities: `/EventPassUG/Core/Utilities/`

For detailed implementation, see:
- [README.md](./README.md) - Complete feature documentation
- [ARCHITECTURE.md](./EventPassUG/ARCHITECTURE.md) - Architecture guide
- [QUICK_REFERENCE.md](./EventPassUG/QUICK_REFERENCE.md) - Developer cheat sheet

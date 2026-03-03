# EventPassUG Mobile Application
## Complete Technical Documentation

---

**Version:** 3.0
**Generated:** March 2026
**Platform:** iOS 17+
**Architecture:** SwiftUI + MVVM + Clean Architecture

---

## Table of Contents

1. [Executive Summary](#1-executive-summary) .......................... Page 2
2. [Project Overview](#2-project-overview) ............................ Page 3
3. [System Requirements](#3-system-requirements) ...................... Page 4
4. [Architecture](#4-architecture) .................................... Page 5
5. [Design System & Tokens](#5-design-system--tokens) ................. Page 8
6. [Features](#6-features) ............................................ Page 14
7. [Data Models](#7-data-models) ...................................... Page 32
8. [Repositories & Services](#8-repositories--services) .............. Page 38
9. [UI Components](#9-ui-components) .................................. Page 42
10. [Utilities](#10-utilities) ........................................ Page 46
11. [Configuration](#11-configuration) ................................ Page 48
12. [Testing Strategy](#12-testing-strategy) .......................... Page 49
13. [Deployment](#13-deployment) ...................................... Page 50
14. [Appendix](#14-appendix) .......................................... Page 51

---

# 1. Executive Summary

EventPassUG is a comprehensive mobile event management platform designed for the Ugandan market. It enables users to discover events, purchase tickets, and manage their event experiences as attendees, while empowering organizers to create events, manage ticket sales, scan entries, and analyze performance.

## Key Highlights

- **Dual-Role Support**: Single account operates as both Attendee and Organizer
- **172 Swift Files**: Production-ready codebase
- **55+ Features**: Fully implemented functionality
- **Design System**: Centralized design tokens for consistency
- **Privacy-First**: On-device processing, no unnecessary data collection
- **Offline Support**: Core functionality works without network
- **iPad Responsive**: Adaptive layouts for all screen sizes

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | SwiftUI (100%) |
| Architecture | MVVM + Clean Architecture |
| Concurrency | async/await, Combine |
| Persistence | UserDefaults, CoreData |
| Security | CryptoKit (SHA256) |
| Mapping | MapKit |
| Camera | AVFoundation |
| OCR | Vision Framework |

---

# 2. Project Overview

## 2.1 Purpose

EventPassUG solves key challenges in the Ugandan event ecosystem:

1. **For Attendees**: Discover local events, purchase tickets securely, and manage event experiences
2. **For Organizers**: Create events, sell tickets, validate entries, and analyze business metrics
3. **For the Market**: Provide a trusted, localized platform with Uganda-specific payment methods

## 2.2 Target Market

- **Primary**: Uganda (Kampala focus)
- **Secondary**: East African region
- **Payment Methods**: MTN Mobile Money, Airtel Money, Card payments (Visa/Mastercard)
- **Currency**: UGX (Ugandan Shilling)

## 2.3 User Personas

### Attendee
- Discovers and browses events
- Purchases tickets via mobile money or card
- Views QR codes for event entry
- Rates and reviews attended events

### Organizer
- Creates and publishes events
- Configures ticket types and pricing
- Scans tickets at venue entry
- Views analytics and earnings
- Manages attendee lists

---

# 3. System Requirements

## 3.1 Development Requirements

| Requirement | Version |
|-------------|---------|
| Xcode | 15.0+ |
| macOS | Sonoma 14.0+ |
| Swift | 5.9+ |
| iOS SDK | 17.0+ |

## 3.2 Runtime Requirements

| Requirement | Minimum |
|-------------|---------|
| iOS Version | 17.0 |
| Device | iPhone 12 or newer (recommended) |
| Storage | 100MB |
| Network | Required for initial sync, optional for core features |

## 3.3 Permissions

| Permission | Purpose | Required |
|------------|---------|----------|
| Camera | QR code scanning, Card scanning | Yes (Organizers) |
| Location | Nearby events, venue directions | Optional |
| Notifications | Event reminders, updates | Optional |
| Calendar | Conflict detection | Optional |
| Photos | Event poster upload | Yes (Organizers) |

---

# 4. Architecture

## 4.1 Architecture Pattern

EventPassUG follows **Feature-First + Clean Architecture**:

```
┌─────────────────────────────────────────────────────┐
│                      App Layer                       │
│        (Entry Point, Navigation, DI Container)       │
├─────────────────────────────────────────────────────┤
│                   Features Layer                     │
│    (Auth, Attendee, Organizer, Common, Scanner)     │
├──────────────────┬──────────────────────────────────┤
│   Domain Layer   │           Data Layer             │
│   (Pure Models)  │  (Repositories, Persistence)     │
├──────────────────┴──────────────────────────────────┤
│                      UI Layer                        │
│       (Components, Design System, Modifiers)         │
├─────────────────────────────────────────────────────┤
│                     Core Layer                       │
│        (DI, Utilities, Extensions, Config)           │
└─────────────────────────────────────────────────────┘
```

## 4.2 Project Structure

```
EventPassUG/
├── App/                          # Application Layer (4 files)
│   ├── EventPassUGApp.swift
│   ├── ContentView.swift
│   └── MainTabView.swift
│
├── Features/                     # Feature Modules (55+ files)
│   ├── Auth/                    # Authentication (8 files)
│   ├── Attendee/                # Attendee Features (12 files)
│   ├── Organizer/               # Organizer Features (18 files)
│   ├── Scanner/                 # Scanner Features (4 files)
│   ├── Common/                  # Shared Features (23 files)
│   ├── Onboarding/              # Onboarding (4 files)
│   ├── Refunds/                 # Refund System (4 files)
│   └── Cancellation/            # Cancellation (3 files)
│
├── Domain/                       # Business Logic (17 models)
│   └── Models/
│
├── Data/                         # Data Access (16 repositories)
│   ├── Repositories/
│   └── Persistence/
│
├── UI/                          # UI Components (18 components)
│   ├── Components/
│   └── DesignSystem/
│
├── Core/                        # Infrastructure (21 utilities)
│   ├── DI/
│   ├── Utilities/
│   ├── Extensions/
│   └── Configuration/
│
└── Resources/
    └── Assets.xcassets
```

**Total: 172 Swift files**

## 4.3 Layer Responsibilities

| Layer | Purpose | Can Import |
|-------|---------|------------|
| **App** | Entry point, routing, DI setup | All layers |
| **Features** | UI + ViewModels | Domain, Data, UI, Core |
| **Domain** | Pure business models | Foundation only |
| **Data** | Repositories, API, persistence | Domain, Core |
| **UI** | Reusable components, design system | Core only |
| **Core** | DI, utilities, extensions | Foundation only |

## 4.4 Data Flow

```
User Action (View)
       │
       ▼
   ViewModel (@Published)
       │
       ▼
   Repository (Protocol)
       │
   ┌───┴───┬─────────┐
   ▼       ▼         ▼
  API    Cache    Database
   │       │         │
   └───────┴─────────┘
           │
           ▼
     Domain Model
           │
           ▼
     ViewModel Update
           │
           ▼
     View Re-render
```

## 4.5 Dependency Injection

```swift
class ServiceContainer: ObservableObject {
    let authService: AuthRepositoryProtocol
    let eventService: EventRepositoryProtocol
    let ticketService: TicketRepositoryProtocol
    let paymentService: PaymentRepositoryProtocol
    // ... 12 more repositories
}
```

---

# 5. Design System & Tokens

## 5.1 Overview

The design system is centralized in `AppDesignSystem.swift` to ensure consistency across all UI components. All values are defined as static constants with semantic naming.

**Location**: `EventPassUG/UI/DesignSystem/AppDesignSystem.swift`

## 5.2 Color Tokens

### 5.2.1 Brand Colors

| Token | Hex Value | Usage |
|-------|-----------|-------|
| `primary` | #FF7A00 | Main brand color, CTAs |
| `primaryDark` | #E66D00 | Hover/pressed states |
| `primaryLight` | #FFA040 | Backgrounds, accents |

### 5.2.2 Semantic Colors

| Token | Value | Usage |
|-------|-------|-------|
| `success` | System Green | Success states, confirmations |
| `warning` | System Orange | Warnings, alerts |
| `error` | System Red | Errors, destructive actions |
| `info` | System Blue | Information, links |

### 5.2.3 Background Colors

| Token | System Color | Usage |
|-------|--------------|-------|
| `backgroundPrimary` | systemBackground | Main background |
| `backgroundSecondary` | secondarySystemBackground | Cards, sections |
| `backgroundTertiary` | tertiarySystemBackground | Nested elements |
| `backgroundGrouped` | systemGroupedBackground | Lists, forms |

### 5.2.4 Text Colors

| Token | Value | Usage |
|-------|-------|-------|
| `textPrimary` | primary | Main text |
| `textSecondary` | secondary | Supporting text |
| `textTertiary` | tertiaryLabel | Hints, metadata |
| `textInverse` | white | Text on dark backgrounds |

### 5.2.5 Border Colors

| Token | Value | Usage |
|-------|-------|-------|
| `border` | separator | Standard borders |
| `borderLight` | gray @ 0.2 | Subtle borders |
| `borderDark` | gray @ 0.4 | Emphasized borders |

### 5.2.6 Special Colors

| Token | Hex Value | Usage |
|-------|-----------|-------|
| `happeningNow` | #7CFC66 | Live event indicator |
| `premium` | #FFD700 | Premium/VIP badges |

### 5.2.7 Role-Based Colors

| Role | Primary Color | Hex |
|------|---------------|-----|
| Attendee | `attendeePrimary` | #FF7A00 |
| Organizer | `organizerPrimary` | #FFA500 |

```swift
// Usage
RoleConfig.getPrimaryColor(for: .attendee) // #FF7A00
RoleConfig.getPrimaryColor(for: .organizer) // #FFA500
```

## 5.3 Typography Tokens

### 5.3.1 Semantic Text Styles

| Token | Font | Weight | Usage |
|-------|------|--------|-------|
| `hero` | largeTitle | bold | Hero/screen titles |
| `largeTitle` | largeTitle | bold | Onboarding, empty states |
| `title` | title | semibold | Dialog headers |
| `title2` | title2 | semibold | Subsections |
| `section` | title3 | semibold | Major sections |
| `cardTitle` | headline | semibold | Card headings |
| `body` | body | regular | Primary content |
| `bodyEmphasized` | body | semibold | Important body text |
| `secondary` | subheadline | regular | Supporting info |
| `callout` | callout | regular | Emphasized content |
| `calloutEmphasized` | callout | semibold | Important callouts |
| `caption` | caption | regular | Metadata, timestamps |
| `captionEmphasized` | caption | medium | Important small text |
| `footnote` | footnote | regular | Fine print |

### 5.3.2 Button Typography

| Token | Font | Weight | Usage |
|-------|------|--------|-------|
| `buttonPrimary` | headline | semibold | Primary buttons |
| `buttonSecondary` | subheadline | semibold | Secondary buttons |
| `buttonSmall` | caption | semibold | Compact buttons |

### 5.3.3 Custom Font Sizes

| Token | Size | Design |
|-------|------|--------|
| `title1` | 28pt | rounded, bold |
| `title3` | 20pt | rounded, semibold |
| `headline` | 17pt | rounded, semibold |
| `subheadline` | 15pt | default, regular |
| `buttonLarge` | 17pt | rounded, semibold |
| `buttonMedium` | 15pt | rounded, semibold |

## 5.4 Spacing Tokens

### 5.4.1 Base Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 2pt | Micro spacing |
| `xs` | 4pt | Tight spacing |
| `sm` | 8pt | Small gaps |
| `md` | 16pt | Standard spacing |
| `lg` | 24pt | Section spacing |
| `xl` | 32pt | Large gaps |
| `xxl` | 48pt | Major sections |
| `xxxl` | 64pt | Screen margins |

### 5.4.2 Semantic Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `compact` | 6pt | Compact layouts |
| `section` | 24pt | Between sections |
| `item` | 12pt | List item spacing |
| `edge` | 16pt | Screen edge padding |

## 5.5 Corner Radius Tokens

### 5.5.1 Base Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Badges, tags |
| `sm` | 8pt | Small elements |
| `md` | 12pt | Standard |
| `lg` | 16pt | Cards |
| `xl` | 24pt | Large cards |
| `pill` | 100pt | Pills, toggles |

### 5.5.2 Semantic Radius

| Token | Value | Usage |
|-------|-------|-------|
| `card` | 12pt | Card components |
| `button` | 12pt | Buttons |
| `input` | 10pt | Text fields |
| `badge` | 6pt | Status badges |

## 5.6 Shadow Tokens

### 5.6.1 Shadow Styles

| Token | Color | Radius | Offset | Usage |
|-------|-------|--------|--------|-------|
| `card` | black @ 8% | 8pt | (0, 4) | Cards |
| `elevated` | black @ 12% | 16pt | (0, 8) | Modals, sheets |
| `subtle` | black @ 5% | 4pt | (0, 2) | Subtle depth |
| `button` | black @ 10% | 6pt | (0, 3) | Buttons |
| `floating` | black @ 15% | 20pt | (0, 10) | FABs, overlays |

### 5.6.2 Shadow Usage

```swift
// View modifiers
view.cardShadow()       // Standard card shadow
view.elevatedShadow()   // Elevated component
view.subtleShadow()     // Subtle depth
view.buttonShadow()     // Button shadow
```

## 5.7 Button Dimensions

| Token | Value | Usage |
|-------|-------|-------|
| `heightLarge` | 56pt | Primary CTAs |
| `heightMedium` | 48pt | Standard buttons |
| `heightSmall` | 36pt | Secondary actions |
| `heightCompact` | 32pt | Inline buttons |
| `iconSize` | 44pt | Icon buttons (accessibility) |
| `iconSizeCompact` | 32pt | Compact icon buttons |
| `minimumTouchTarget` | 44pt | Accessibility minimum |
| `paddingHorizontal` | 24pt | Button padding |
| `paddingVertical` | 12pt | Button padding |

## 5.8 Input Field Dimensions

| Token | Value | Usage |
|-------|-------|-------|
| `height` | 52pt | Standard inputs |
| `heightCompact` | 44pt | Compact inputs |
| `paddingHorizontal` | 16pt | Input padding |
| `iconSize` | 20pt | Input icons |

## 5.9 Animation Tokens

| Token | Type | Duration | Usage |
|-------|------|----------|-------|
| `quick` | easeInOut | 0.15s | Micro-interactions |
| `standard` | easeInOut | 0.2s | Standard transitions |
| `slow` | easeInOut | 0.4s | Complex animations |
| `spring` | spring | 0.3s (0.7 damping) | Bouncy feedback |
| `springBouncy` | spring | 0.4s (0.6 damping) | Playful animations |

## 5.10 Border Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `width` | 1pt | Standard borders |
| `selectedWidth` | 2pt | Selected state |
| `thickWidth` | 3pt | Emphasized borders |

---

# 6. Features

## 6.1 Authentication System

### 6.1.1 Email/Password Authentication

**Location**: `Features/Auth/AuthView.swift`

**Features**:
- Full registration with validation
- Secure password hashing (SHA256 + salt)
- Email format validation
- Password strength requirements

**Flow**:
```
Register Tab → Enter Details → Validate → Hash Password → Create User → Login
```

### 6.1.2 Phone OTP Authentication

**Features**:
- 6-digit code verification
- Phone number validation (E.164 format)
- Automatic user creation
- Mock OTP in development (123456)

**Flow**:
```
Phone Auth Tab → Enter Phone → Send OTP → Enter Code → Verify → Login/Register
```

### 6.1.3 Social Login

**Supported Providers**:
- Apple Sign In
- Google Sign In
- Facebook Sign In

**Status**: Mock implementations ready for production SDK integration

### 6.1.4 Test Users

| Email | Password | Role |
|-------|----------|------|
| john@example.com | password123 | Attendee |
| jane@example.com | password123 | Attendee |
| alice@example.com | password123 | Attendee |
| bob@events.com | organizer123 | Organizer |
| sarah@events.com | organizer123 | Organizer |

## 6.2 Dual Role Support

### 6.2.1 Overview

Users operate as both Attendees and Organizers within a single account.

### 6.2.2 Attendee Mode Features

- Discover and browse events
- Purchase tickets
- View QR codes
- Manage favorites
- Rate and review events

### 6.2.3 Organizer Mode Features

- Create and manage events
- Configure ticket types and pricing
- Scan tickets for validation
- View analytics and earnings
- Manage attendees

### 6.2.4 Role Switching

**Location**: Profile Tab → Role Switcher

**UI Changes on Switch**:
- Tab bar icons and labels update
- Theme color adjusts (Attendee: #FF7A00, Organizer: #FFA500)
- Dashboard replaces home feed
- Available features change

## 6.3 Attendee Features

### 6.3.1 Event Discovery

**Location**: `Features/Attendee/AttendeeHomeView.swift`

**Features**:
- Grid/list view of events
- Category filters (16 categories)
- Time-based filters (Today, This Week, This Month)
- "Happening now" indicators
- Ticket availability status
- Sales countdown timers
- Recommendation engine

**Event Card Information**:
- Event poster image
- Title and category badge
- Date and time
- Location and distance
- Price range
- Like/favorite button
- Sold out indicators

### 6.3.2 Search Events

**Location**: `Features/Attendee/SearchView.swift`

**Search Capabilities**:
- Search by event name
- Search by location
- Search by category
- Recent searches
- Search suggestions
- Filter results by date/price

### 6.3.3 Event Details

**Location**: `Features/Attendee/EventDetailsView.swift`

**Information Displayed**:
- Hero poster image
- Event title and category
- Organizer information with follow button
- Date and time
- Location with interactive map
- Full description
- Age restrictions
- Ticket types and pricing
- Availability status
- Ratings and reviews

**Actions Available**:
- Like/favorite event
- Share event
- Report event
- Follow organizer
- Add to calendar
- Buy tickets

### 6.3.4 Ticket Purchasing

**Location**: `Features/Attendee/TicketPurchaseView.swift`

**Purchase Flow**:
```
Select Ticket Type → Choose Quantity → Select Payment Method →
Review Order → Confirm Payment → Success → View QR Code
```

**Payment Methods**:
- MTN Mobile Money (Uganda)
- Airtel Money (Uganda)
- Card payment (Visa/Mastercard)

**Features**:
- Multiple ticket types per event
- Quantity selection
- Real-time price calculation
- Calendar conflict detection
- Order summary
- Terms and conditions

### 6.3.5 Ticket Management

**Location**: `Features/Attendee/TicketsView.swift`

**Features**:
- View all purchased tickets
- Filter by status (Upcoming, Past, All)
- Grid/list view toggle
- Quick QR code access
- Ticket detail view

### 6.3.6 Ticket Detail

**Location**: `Features/Attendee/TicketDetailView.swift`

**Features**:
- Full QR code (scannable)
- Event information
- Ticket type and quantity
- Purchase date and price
- Event venue with map
- PDF generation and sharing
- Request refund option

### 6.3.7 Favorites System

**Location**: `Features/Attendee/FavoriteEventsView.swift`

**Features**:
- Like/unlike events
- View all favorited events
- Persistent storage
- Notification for updates

## 6.4 Organizer Features

### 6.4.1 Organizer Dashboard

**Location**: `Features/Organizer/OrganizerDashboardView.swift`

**Analytics Cards**:
- Total Revenue (all-time)
- Tickets Sold (all-time)
- Active Events (published)
- Upcoming Events (next 7 days)

**Quick Actions**:
- Create New Event
- Scan Tickets
- View Analytics
- Manage Events

### 6.4.2 Event Creation

**Location**: `Features/Organizer/CreateEventWizard.swift`

**3-Step Wizard**:

**Step 1: Basic Info**
- Event title
- Description
- Category selection (16 options)
- Age restriction

**Step 2: Date & Venue**
- Start date and time
- End date and time
- Venue name
- Address
- Location picker (map)

**Step 3: Tickets & Media**
- Ticket types (name, price, quantity, sale dates)
- Event poster upload (min 900×1125px)
- Image validation

**Features**:
- Draft auto-save (every 30 seconds)
- Form validation
- Preview before publish
- Edit mode support

### 6.4.3 Event Management

**Edit Events**:
- Access: Long-press card or toolbar menu
- Pre-filled data from existing event
- Full field editing
- Warning if tickets already sold

**Delete Events**:
- Confirmation required
- Shows attendee count warning
- Soft delete with refund processing
- Blocked for ongoing events

### 6.4.4 QR Code Scanning

**Location**: `Features/Organizer/QRScannerView.swift`

**Features**:
- Camera-based QR code scanning
- Instant validation
- Ticket information display
- Already scanned detection
- Invalid ticket alerts
- Responsive scanning frame

**Validation Results**:
- ✅ Valid: Green success
- ⚠️ Already Scanned: Yellow warning
- ❌ Invalid: Red error
- 🔒 Not Started: Gray warning

### 6.4.5 Event Analytics

**Location**: `Features/Organizer/EventAnalyticsView.swift`

**Metrics**:
- Total Revenue
- Tickets Sold (by type)
- Attendance Rate
- Sales Velocity
- Revenue by Ticket Type
- Sales Timeline
- Peak Sales Periods

**Visualizations**:
- Line chart: Sales over time
- Pie chart: Revenue by ticket type
- Bar chart: Daily ticket sales

### 6.4.6 Analytics Dashboard

**Location**: `Features/Organizer/OrganizerAnalyticsDashboardView.swift`

**Detailed Views**:
- Revenue Analytics Detail
- Ticket Analytics Detail
- Audience Analytics Detail
- Marketing Insights Detail
- Operations Detail
- Predictive Analysis Detail

### 6.4.7 Attendee Management

**Features**:
- View attendee list
- Export attendees (CSV/PDF)
- Check-in status tracking
- VIP identification

### 6.4.8 Scanner Device Management

**Location**: `Features/Organizer/Scanner/`

**Features**:
- Pair scanner devices via deep link
- Manage multiple devices
- Per-event scanner assignment
- Real-time status tracking

## 6.5 Scanner Features

### 6.5.1 Scanner Connect

**Location**: `Features/Scanner/ScannerConnectView.swift`

**Features**:
- Camera-based QR scanning
- Flashlight toggle
- Responsive frame sizing
- Dual camera support
- Real-time validation

### 6.5.2 Deep Link Pairing

**Location**: `Features/Scanner/ScannerPairingDeepLinkView.swift`

**Features**:
- Scan pairing QR code
- Automatic device registration
- Event assignment

## 6.6 Onboarding

### 6.6.1 Onboarding Flow

**Location**: `Features/Onboarding/OnboardingView.swift`

**Steps**:
1. Welcome slide
2. Role selection
3. Basic info
4. Personalization (interests)
5. Permissions
6. Completion

### 6.6.2 Organizer Onboarding

**Location**: `Features/Organizer/BecomeOrganizerFlow.swift`

**5-Step Process**:
1. Profile Completion
2. Identity Verification (National ID)
3. Contact Information
4. Payout Setup (Mobile Money/Bank)
5. Terms Agreement

## 6.7 Refund System

### 6.7.1 Refund Request

**Location**: `Features/Refunds/RefundRequestView.swift`

**Features**:
- Reason selection
- Amount display
- Policy information
- Request tracking

### 6.7.2 Organizer Refund Management

**Location**: `Features/Refunds/OrganizerRefundViews.swift`

**Features**:
- View pending requests
- Approve/reject with notes
- Processing tracking
- Batch operations

## 6.8 Event Cancellation

### 6.8.1 Cancellation Flow

**Location**: `Features/Cancellation/EventCancellationFlowView.swift`

**Features**:
- Reason selection
- Impact preview (attendees, revenue)
- Compensation plan configuration
- Attendee notification
- Automatic refund processing

## 6.9 Support System

### 6.9.1 Support Center

**Location**: `Features/Common/SupportCenterView.swift`

**Features**:
- FAQ sections
- Help articles
- Submit support ticket
- Contact options

### 6.9.2 Help Center

**Location**: `Features/Common/HelpCenterView.swift`

**Features**:
- Searchable help articles
- Category navigation
- Related topics

### 6.9.3 Troubleshooting

**Location**: `Features/Common/TroubleshootingView.swift`

**Features**:
- Common issues
- Step-by-step solutions
- Device diagnostics

## 6.10 Profile & Settings

### 6.10.1 Edit Profile

**Location**: `Features/Common/EditProfileView.swift`

**Features**:
- Name editing
- Profile photo
- Contact methods
- Date of birth
- Location

### 6.10.2 Notification Settings

**Location**: `Features/Common/NotificationSettingsView.swift`

**Categories**:
- Event reminders
- Purchase confirmations
- Event updates
- Recommendations
- Marketing (opt-in)
- Quiet hours

### 6.10.3 Payment Methods

**Location**: `Features/Common/PaymentMethodsView.swift`

**Features**:
- Add/remove payment methods
- Set default method
- Card scanning integration

### 6.10.4 ID Verification

**Location**: `Features/Common/NationalIDVerificationView.swift`

**Features**:
- National ID capture (front/back)
- Image validation
- Verification status tracking

## 6.11 Advanced Features

### 6.11.1 Credit Card Scanner

**Location**: `Core/Utilities/CardScanner.swift` (736 lines)

**Features**:
- On-device OCR (Vision framework)
- Real-time detection
- Card number extraction
- Expiry date extraction
- Cardholder name extraction
- Luhn algorithm validation
- Brand detection (Visa, Mastercard, Amex, Discover)
- Privacy-first (no images stored)

### 6.11.2 PDF Ticket Generator

**Location**: `Core/Utilities/PDFGenerator.swift` (290 lines)

**Features**:
- Color extraction from event poster
- Gradient headers
- QR code embedding
- Professional layout
- Print-optimized (300 DPI)
- Share/export support

### 6.11.3 Calendar Conflict Detection

**Location**: `Features/Common/CalendarConflictView.swift`

**Features**:
- EventKit integration
- Conflict types: exact, partial, adjacent
- Warning UI with details
- Override option
- Privacy-focused (read-only)

### 6.11.4 Recommendation Engine

**Location**: `Features/Attendee/AttendeeHomeViewModel.swift`

**Scoring Factors**:
| Factor | Points |
|--------|--------|
| Category Match | 40 |
| Purchase History | 35 |
| Followed Organizer | 30 |
| Like History | 25 |
| Happening Now | 25 |
| Same City | 20 |
| Nearby Event | 15 |
| Upcoming Soon | 15 |
| Popular Event | 10 |
| This Weekend | 10 |
| Price Match | 8 |
| High Rating | 5 |
| Free Event | 5 |
| Recently Added | 5 |

### 6.11.5 Guest Browsing

**Features**:
- Browse events without account
- View event details
- Authentication prompts for actions
- Contextual sign-in CTAs

---

# 7. Data Models

## 7.1 User

```swift
struct User {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String?
    var phoneNumber: String?
    var profileImageUrl: String?
    var role: UserRole
    var dateJoined: Date
    var isEmailVerified: Bool
    var isPhoneVerified: Bool
    var isVerified: Bool
    var nationalIdNumber: String?
    var isAttendeeRole: Bool
    var isOrganizerRole: Bool
    var currentActiveRole: UserRole
    var favoriteEventIds: [UUID]
    var followedOrganizerIds: [UUID]
    var favoriteEventTypes: [String]
}
```

## 7.2 Event

```swift
struct Event {
    let id: UUID
    var title: String
    var description: String
    var organizerId: UUID
    var organizerName: String
    var posterUrl: String?
    var category: EventCategory
    var startDate: Date
    var endDate: Date
    var venue: Venue
    var ticketTypes: [TicketType]
    var status: EventStatus
    var rating: Double
    var totalRatings: Int
    var likeCount: Int
    var ageRestriction: AgeRestriction
}
```

## 7.3 Ticket

```swift
struct Ticket {
    let id: UUID
    var ticketNumber: String
    var orderNumber: String
    var eventId: UUID
    var eventTitle: String
    var eventDate: Date
    var eventEndDate: Date
    var eventVenue: String
    var ticketType: TicketType
    var userId: UUID
    var purchaseDate: Date
    var scanStatus: TicketScanStatus
    var scanDate: Date?
    var qrCodeData: String
    var userRating: Double?
}
```

## 7.4 TicketType

```swift
struct TicketType {
    let id: UUID
    var name: String
    var price: Double
    var quantity: Int
    var sold: Int
    var description: String?
    var perks: [String]
    var saleStartDate: Date
    var saleEndDate: Date
    var isUnlimitedQuantity: Bool
}
```

## 7.5 OrganizerProfile

```swift
struct OrganizerProfile {
    var publicEmail: String
    var publicPhone: String
    var brandName: String?
    var website: String?
    var instagramHandle: String?
    var twitterHandle: String?
    var facebookPage: String?
    var followerCount: Int
    var completedOnboardingSteps: [OrganizerOnboardingStep]
    var payoutMethod: PayoutMethod?
    var agreedToTermsDate: Date?
}
```

## 7.6 OrganizerAnalytics

```swift
struct OrganizerAnalytics {
    var eventId: UUID
    var eventTitle: String
    var lastUpdated: Date
    var revenue: Double
    var ticketsSold: Int
    var totalCapacity: Int
    var attendanceRate: Double
    var ticketVelocity: Double
    var totalAttendees: Int
    var repeatAttendees: Int
    var eventViews: Int
    var uniqueViews: Int
    var conversionRate: Double
    var checkinRate: Double
    var grossRevenue: Double
    var netRevenue: Double
    var platformFees: Double
    var healthScore: Int
}
```

## 7.7 Enumerations

### UserRole
```swift
enum UserRole: String {
    case attendee
    case organizer
}
```

### EventCategory (16 categories)
```swift
enum EventCategory: String {
    case music, artsCulture, concerts, sportsWellness
    case technology, fundraising, comedy, poetry
    case drama, exhibitions, networking, education
    case food, nightlife, festivals, other
}
```

### EventStatus
```swift
enum EventStatus: String {
    case draft, published, ongoing, completed, cancelled
}
```

### TicketScanStatus
```swift
enum TicketScanStatus: String {
    case unused, scanned, expired
}
```

### PaymentMethod
```swift
enum PaymentMethod: String {
    case mtnMomo, airtelMoney, card
}
```

### RefundStatus
```swift
enum RefundStatus: String {
    case pending, approved, rejected
    case processing, completed, failed
}
```

---

# 8. Repositories & Services

## 8.1 Repository Pattern

All repositories follow the protocol-based pattern for dependency injection and testability.

## 8.2 Core Repositories

### AuthRepository
```swift
protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func register(user: User, password: String) async throws -> User
    func sendOTP(phoneNumber: String) async throws -> Bool
    func verifyOTP(phoneNumber: String, code: String) async throws -> User
    func logout() async throws
    func getCurrentUser() async throws -> User?
}
```

### EventRepository
```swift
protocol EventRepositoryProtocol {
    func fetchEvents() async throws -> [Event]
    func getEvent(id: UUID) async throws -> Event
    func createEvent(_ event: Event) async throws -> Event
    func updateEvent(_ event: Event) async throws
    func deleteEvent(_ id: UUID) async throws
    func searchEvents(query: String) async throws -> [Event]
    func rateEvent(id: UUID, rating: Double, review: String?) async throws
}
```

### TicketRepository
```swift
protocol TicketRepositoryProtocol {
    func purchaseTickets(event: Event, type: TicketType, quantity: Int) async throws -> [Ticket]
    func getUserTickets() async throws -> [Ticket]
    func scanTicket(qrCode: String) async throws -> Ticket
    func validateTicket(code: String) async throws -> TicketValidationResult
    func rateTicket(ticketId: UUID, rating: Double) async throws
}
```

### PaymentRepository
```swift
protocol PaymentRepositoryProtocol {
    func processPayment(amount: Double, method: PaymentMethod) async throws -> Payment
    func verifyPayment(reference: String) async throws -> PaymentStatus
    func getPaymentHistory() async throws -> [Payment]
}
```

## 8.3 Additional Repositories

| Repository | Purpose |
|------------|---------|
| RefundRepository | Refund request and processing |
| AppNotificationRepository | In-app notifications |
| CalendarRepository | Calendar integration |
| UserLocationRepository | Location services |
| UserPreferencesRepository | User settings |
| EventFilterRepository | Event filtering |
| NotificationAnalyticsRepository | Notification tracking |

## 8.4 Service Container

```swift
class ServiceContainer: ObservableObject {
    let authService: AuthRepositoryProtocol
    let eventService: EventRepositoryProtocol
    let ticketService: TicketRepositoryProtocol
    let paymentService: PaymentRepositoryProtocol
    let refundService: RefundRepositoryProtocol
    let notificationService: AppNotificationRepository
    // ... additional services

    init(
        authService: AuthRepositoryProtocol = AuthRepository(),
        eventService: EventRepositoryProtocol = EventRepository(),
        // ...
    )
}
```

---

# 9. UI Components

## 9.1 Event Components

### EventCard
**Location**: `UI/Components/EventCard.swift`

**Features**:
- Poster image with gradient overlay
- Title and category badge
- Date, location, price
- Like button
- Status indicators

### CategoryTile
**Location**: `UI/Components/CategoryTile.swift`

**Features**:
- Icon and label
- Selection state
- Horizontal scroll support

## 9.2 Form Components

### FormInputComponents
**Location**: `UI/Components/FormInputComponents.swift`

**Includes**:
- Text input with validation
- Phone number input
- Email input
- Password input with visibility toggle
- OTP input (6 digits)

## 9.3 Analytics Components

### AnalyticsCharts
**Location**: `UI/Components/AnalyticsCharts.swift`

**Chart Types**:
- Line chart
- Bar chart
- Pie chart
- Progress indicators

### AnalyticsDashboardComponents
**Location**: `UI/Components/AnalyticsDashboardComponents.swift`

**Includes**:
- Metric cards
- Trend indicators
- Comparison views

## 9.4 Common Components

| Component | Purpose |
|-----------|---------|
| LoadingView | Loading states |
| HeaderBar | Navigation headers |
| NotificationBadge | Unread count |
| VerificationRequiredOverlay | ID verification prompt |
| PulsingDot | Live indicators |
| SalesCountdownTimer | Ticket sale countdown |

---

# 10. Utilities

## 10.1 Date Utilities

**Location**: `Core/Utilities/DateUtilities.swift`

**Functions**:
- `formatEventDateTime()` - Event date display
- `formatEventFullDateTime()` - Full date with end time
- `formatRelativeTime()` - "2 hours ago"
- `isToday()`, `isThisWeek()`, `isThisMonth()`

## 10.2 QR Code Generator

**Location**: `Core/Utilities/QRCodeGenerator.swift`

**Functions**:
- `generate(from: String, size: CGSize)` - Create QR code
- Uses CIQRCodeGenerator filter

## 10.3 Haptic Feedback

**Location**: `Core/Utilities/HapticFeedback.swift`

**Functions**:
- `light()` - Light tap
- `medium()` - Medium impact
- `success()` - Success notification
- `error()` - Error notification
- `warning()` - Warning notification

## 10.4 Image Utilities

| Utility | Purpose |
|---------|---------|
| ImageCompressor | JPEG compression |
| ImageValidator | Size/format validation |
| ImageStorage | Local caching |
| ImageColorExtractor | Dominant color extraction |

## 10.5 Responsive Utilities

### ResponsiveSize
**Location**: `Core/Utilities/ResponsiveSize.swift`

**Features**:
- Device-adaptive sizing
- iPad support
- Dynamic type scaling

### DeviceOrientation
**Location**: `Core/Utilities/DeviceOrientation.swift`

**Features**:
- Orientation detection
- Layout adaptation

---

# 11. Configuration

## 11.1 Role Configuration

**Location**: `Core/Configuration/RoleConfig.swift`

```swift
struct RoleConfig {
    static let attendeePrimary = Color(hex: "FF7A00")
    static let organizerPrimary = Color(hex: "FFA500")
    static let lightBackground = Color(hex: "FBFBF7")
    static let darkBackground = Color(hex: "000000")
    static let happeningNow = Color(hex: "7CFC66")

    static func getPrimaryColor(for role: UserRole) -> Color
    static func getAccentColor(for role: UserRole) -> Color
}
```

## 11.2 App Storage Keys

**Location**: `Core/Data/Storage/AppStorageKeys.swift`

**Keys**:
- `hasCompletedOnboarding`
- `currentUserId`
- `userRole`
- `favoriteEventIds`
- `notificationPreferences`

---

# 12. Testing Strategy

## 12.1 Unit Tests

**Target**: ViewModels, Domain Models, Repositories

**Coverage Goals**:
- ViewModels: 80%+
- Domain logic: 90%+
- Repositories: 70%+

## 12.2 Mock Implementations

All repositories have mock implementations for testing:
- `MockAuthRepository`
- `MockEventRepository`
- `MockTicketRepository`
- `MockPaymentRepository`

## 12.3 UI Tests

**Critical Flows**:
- Authentication (login, register, OTP)
- Ticket purchase
- Event creation
- QR scanning

## 12.4 SwiftUI Previews

All views include `#Preview` blocks with mock data.

---

# 13. Deployment

## 13.1 Build Configuration

| Configuration | Purpose |
|---------------|---------|
| Debug | Development, mock data |
| Release | Production, real APIs |

## 13.2 App Store Requirements

- iOS 17.0 minimum deployment
- iPhone and iPad support
- Dark mode support
- Dynamic Type support
- Accessibility compliance

## 13.3 Privacy

**Data Collected**:
- User profile information
- Location (with permission)
- Purchase history
- Event interactions

**Privacy Features**:
- On-device card scanning
- No card images stored
- Calendar read-only access
- Location opt-in only

---

# 14. Appendix

## 14.1 File Count Summary

| Layer | Files |
|-------|-------|
| App | 4 |
| Features | 76 |
| Domain | 17 |
| Data | 16 |
| UI | 18 |
| Core | 21 |
| **Total** | **172** |

## 14.2 Feature Count Summary

| Category | Count |
|----------|-------|
| Authentication | 4 |
| Attendee | 12 |
| Organizer | 15 |
| Scanner | 4 |
| Common | 14 |
| Support | 6 |
| **Total** | **55+** |

## 14.3 Design Token Count

| Category | Count |
|----------|-------|
| Colors | 18 |
| Typography | 18 |
| Spacing | 12 |
| Corner Radius | 10 |
| Shadows | 5 |
| Button Dimensions | 10 |
| Animations | 5 |
| **Total** | **78** |

## 14.4 References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [EventPassUG Data Model Spec](./EventPass_Data_Model_Spec.md)

---

**Document Version**: 3.0
**Last Updated**: March 2026
**Maintained By**: EventPassUG Development Team

---

*This documentation is auto-generated. For updates, modify the source files and regenerate.*

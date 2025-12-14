# EventPass UG - Complete File Structure

## 📁 Directory Tree

```
EventPassUG-MobileApp/
│
├── README.md                          # 📖 Main documentation (comprehensive guide)
├── SETUP_GUIDE.md                     # ⚡ Quick start guide (5 minutes)
├── PROJECT_SUMMARY.md                 # 📊 Project overview and statistics
├── FILE_STRUCTURE.md                  # 📁 This file
│
├── EventPassUG/                       # 🎯 Main application source
│   │
│   ├── EventPassUGApp.swift           # 🚀 App entry point
│   ├── ContentView.swift              # 🏠 Root view with auth routing
│   ├── Info.plist                     # ⚙️ App configuration & permissions
│   │
│   ├── Models/                        # 📦 Data Models (6 files)
│   │   ├── User.swift                 # User model with UserRole enum
│   │   ├── Event.swift                # Event model with samples
│   │   ├── Ticket.swift               # Purchased ticket model
│   │   ├── TicketType.swift           # Pricing tier model
│   │   ├── NotificationModel.swift    # In-app notification model
│   │   └── (PaymentModel in PaymentService.swift)
│   │
│   ├── Services/                      # 🔧 Business Logic Layer (5 files)
│   │   ├── ServiceContainer.swift     # Dependency injection container
│   │   ├── AuthService.swift          # Auth protocol + MockAuthService
│   │   ├── EventService.swift         # Event CRUD + MockEventService
│   │   ├── TicketService.swift        # Ticket purchase/scan + Mock
│   │   └── PaymentService.swift       # Payment processing + Mock
│   │
│   ├── Views/                         # 🎨 UI Components & Screens
│   │   │
│   │   ├── Components/                # 🧩 Reusable UI Components (8 files)
│   │   │   ├── PulsingDot.swift       # Animated pulsing indicator
│   │   │   ├── AnimatedLikeButton.swift # Heart animation
│   │   │   ├── NotificationBadge.swift  # Badge with bounce animation
│   │   │   ├── HeaderBar.swift        # Date + greeting + notifications
│   │   │   ├── CategoryTile.swift     # Filter chip component
│   │   │   ├── EventCard.swift        # Event card with poster
│   │   │   ├── QRCodeView.swift       # QR code display
│   │   │   └── LoadingView.swift      # Skeleton screens
│   │   │
│   │   ├── Navigation/                # 🧭 Navigation (1 file)
│   │   │   └── MainTabView.swift      # Role-based tab bar
│   │   │
│   │   ├── Auth/                      # 🔐 Authentication (1 file)
│   │   │   └── OnboardingView.swift   # Sign up + role selection
│   │   │
│   │   ├── Attendee/                  # 👤 Attendee Screens (4 files)
│   │   │   ├── AttendeeHomeView.swift       # Event feed + categories
│   │   │   ├── EventDetailsView.swift       # Event details + MapKit
│   │   │   ├── TicketPurchaseView.swift     # Multi-step purchase
│   │   │   └── TicketsView.swift            # User's tickets + QR
│   │   │
│   │   ├── Organizer/                 # 💼 Organizer Screens (4 files)
│   │   │   ├── OrganizerHomeView.swift      # Event management
│   │   │   ├── CreateEventWizard.swift      # 3-step wizard
│   │   │   ├── OrganizerDashboardView.swift # Analytics + QR scanner
│   │   │   └── QRScannerView.swift          # AVFoundation camera
│   │   │
│   │   └── Common/                    # 🔄 Shared Screens (2 files)
│   │       ├── ProfileView.swift      # Profile + role switcher
│   │       └── NotificationsView.swift # Notifications list
│   │
│   ├── Config/                        # 🎨 Theme & Configuration (1 file)
│   │   └── RoleConfig.swift           # Colors, typography, spacing
│   │
│   ├── Utilities/                     # 🛠 Helper Functions (3 files)
│   │   ├── DateUtilities.swift        # Date formatting + greeting logic
│   │   ├── QRCodeGenerator.swift      # CoreImage QR generation
│   │   └── HapticFeedback.swift       # Haptic utilities
│   │
│   ├── CoreData/                      # 💾 Persistence Layer (2 files)
│   │   ├── PersistenceController.swift # Core Data setup
│   │   └── EventPassUG.xcdatamodeld/  # Core Data model definition
│   │       └── EventPassUG.xcdatamodel/
│   │           └── contents           # XML model definition
│   │
│   └── Assets.xcassets/               # 🖼 Assets Catalog
│       ├── Contents.json
│       ├── Colors/
│       │   ├── AttendeePrimary.colorset/
│       │   └── OrganizerPrimary.colorset/
│       └── Images/
│           └── sample_poster_1.imageset/
│
└── EventPassUGTests/                  # 🧪 Unit Tests
    ├── DateUtilitiesTests.swift       # Date/greeting logic tests
    └── EventFilterTests.swift         # Event filtering tests
```

## 📊 File Count Summary

| Category | Count | Description |
|----------|-------|-------------|
| **Models** | 6 | Data structures |
| **Services** | 5 | Business logic |
| **Views** | 25+ | UI screens & components |
| **Components** | 8 | Reusable UI elements |
| **Utilities** | 3 | Helper functions |
| **Tests** | 2 | Unit test suites |
| **Config** | 4 | App configuration |
| **Documentation** | 4 | README, guides, summary |
| **Total Swift Files** | 50+ | Source code files |

## 🎯 Key Files to Start With

### For Understanding the App
1. **README.md** - Start here for complete overview
2. **EventPassUGApp.swift** - App entry point
3. **ContentView.swift** - Root navigation logic
4. **Models/User.swift** - Data model examples
5. **Services/ServiceContainer.swift** - DI pattern

### For UI Development
1. **Views/Components/** - Reusable components library
2. **Config/RoleConfig.swift** - Theme system
3. **Views/Attendee/AttendeeHomeView.swift** - Main screen example
4. **Views/Organizer/CreateEventWizard.swift** - Complex wizard example

### For Backend Integration
1. **Services/AuthService.swift** - Auth protocol
2. **Services/EventService.swift** - CRUD operations
3. **Services/PaymentService.swift** - Payment integration
4. **README.md** (Backend Integration section)

## 🔍 File Naming Conventions

### Models
- Format: `[EntityName].swift`
- Examples: `User.swift`, `Event.swift`, `Ticket.swift`

### Services
- Format: `[Feature]Service.swift`
- Examples: `AuthService.swift`, `EventService.swift`

### Views
- Format: `[Feature][Type]View.swift`
- Examples: `AttendeeHomeView.swift`, `CreateEventWizard.swift`

### Components
- Format: `[ComponentName].swift`
- Examples: `PulsingDot.swift`, `AnimatedLikeButton.swift`

### Utilities
- Format: `[Purpose]Utilities.swift` or `[Feature].swift`
- Examples: `DateUtilities.swift`, `QRCodeGenerator.swift`

### Tests
- Format: `[Feature]Tests.swift`
- Examples: `DateUtilitiesTests.swift`, `EventFilterTests.swift`

## 📝 Import Dependencies by File

### Most Files Import
```swift
import SwiftUI  // All views
```

### Service Files Import
```swift
import Foundation  // All services
import Combine     // Services with @Published properties
```

### Special Imports
```swift
// EventDetailsView.swift, MapView components
import MapKit

// QRScannerView.swift
import AVFoundation

// CreateEventWizard.swift
import PhotosUI

// QRCodeGenerator.swift
import CoreImage
import UIKit

// PersistenceController.swift
import CoreData
```

## 🎨 Assets Organization

### Colors
```
Assets.xcassets/Colors/
  ├── AttendeePrimary.colorset/    # #FF7A00
  └── OrganizerPrimary.colorset/   # #FFA500
```

### Images (Placeholder Structure)
```
Assets.xcassets/Images/
  ├── sample_poster_1.imageset/
  ├── sample_poster_2.imageset/
  ├── sample_poster_3.imageset/
  └── sample_poster_4.imageset/
```

## 🔗 File Dependencies Graph

### High-Level Dependencies

```
EventPassUGApp.swift
    ├─> ServiceContainer
    │       ├─> AuthService (MockAuthService)
    │       ├─> EventService (MockEventService)
    │       ├─> TicketService (MockTicketService)
    │       └─> PaymentService (MockPaymentService)
    │
    └─> ContentView
            ├─> OnboardingView (if not authenticated)
            └─> MainTabView (if authenticated)
                    ├─> AttendeeHomeView (Attendee role)
                    ├─> OrganizerHomeView (Organizer role)
                    ├─> TicketsView / OrganizerDashboardView
                    └─> ProfileView (both roles)
```

## 📖 Documentation Files

| File | Purpose | Target Audience |
|------|---------|-----------------|
| **README.md** | Complete documentation, setup, API keys, backend integration | All developers |
| **SETUP_GUIDE.md** | Quick 5-minute setup guide | New developers |
| **PROJECT_SUMMARY.md** | Architecture, statistics, technical details | Technical leads |
| **FILE_STRUCTURE.md** | This file - directory reference | All developers |

## 🚀 Getting Started Checklist

- [ ] Read README.md (10 min)
- [ ] Follow SETUP_GUIDE.md (5 min)
- [ ] Create Xcode project
- [ ] Import all files
- [ ] Build and run (⌘ + R)
- [ ] Explore AttendeeHomeView code
- [ ] Review service protocols
- [ ] Run unit tests (⌘ + U)
- [ ] Read PROJECT_SUMMARY.md
- [ ] Start customizing!

---

**Need help? Start with README.md → SETUP_GUIDE.md → This file → PROJECT_SUMMARY.md**

Happy coding! 🎉

# EventPass iOS - Project Structure Refactoring Plan

## 📊 Current Structure Analysis

**Total Files:** 121 Swift files
**Current Organization:** Partially structured with some inconsistencies

### Current Issues:
- ❌ Utilities folder is a dumping ground (21 mixed files)
- ❌ Root-level files (ContentView, EventPassUGApp) not organized
- ❌ Config contains design system (should be separate)
- ❌ Extensions folder with only one file
- ❌ Some ViewModels not feature-grouped
- ❌ Components could be better organized by type

---

## 🎯 Proposed Professional Structure

```
EventPassUG/
│
├── App/                                    # 📱 App Entry Point
│   ├── EventPassUGApp.swift
│   └── ContentView.swift
│
├── Core/                                   # 🏗️ Core Infrastructure
│   ├── Configuration/
│   │   └── RoleConfig.swift
│   ├── Data/
│   │   ├── CoreData/
│   │   │   ├── PersistenceController.swift
│   │   │   └── EventPassUG.xcdatamodeld/
│   │   └── Storage/
│   │       ├── AppStorage.swift
│   │       └── AppStorageKeys.swift
│   └── Extensions/
│       └── Event+Extensions.swift
│
├── Models/                                 # 📦 Data Models (Pure Swift)
│   ├── Domain/                            # Core business models
│   │   ├── Event.swift
│   │   ├── Ticket.swift
│   │   ├── TicketType.swift
│   │   ├── User.swift
│   │   └── OrganizerProfile.swift
│   ├── Notifications/
│   │   ├── NotificationModel.swift
│   │   └── NotificationPreferences.swift
│   ├── Preferences/
│   │   └── UserPreferences.swift
│   └── Support/
│       ├── SupportModels.swift
│       └── PosterConfiguration.swift
│
├── Services/                               # 🔧 Business Logic & APIs
│   ├── Authentication/
│   │   ├── AuthService.swift
│   │   └── EnhancedAuthService.swift
│   ├── Events/
│   │   ├── EventService.swift
│   │   └── EventFilterService.swift
│   ├── Tickets/
│   │   └── TicketService.swift
│   ├── Notifications/
│   │   ├── AppNotificationService.swift
│   │   ├── NotificationService.swift
│   │   └── NotificationAnalytics.swift
│   ├── Recommendations/
│   │   └── RecommendationService.swift
│   ├── Location/
│   │   ├── LocationService.swift
│   │   └── UserLocationService.swift
│   ├── Payment/
│   │   └── PaymentService.swift
│   ├── Calendar/
│   │   └── CalendarService.swift
│   ├── UserPreferences/
│   │   └── UserPreferencesService.swift
│   ├── Database/
│   │   └── TestDatabase.swift
│   └── ServiceContainer.swift
│
├── ViewModels/                             # 🧠 MVVM ViewModels
│   ├── Auth/
│   │   └── AuthViewModel.swift
│   ├── Attendee/
│   │   ├── AttendeeHomeViewModel.swift
│   │   └── DiscoveryViewModel.swift
│   ├── Organizer/
│   │   └── EventAnalyticsViewModel.swift
│   └── Settings/
│       └── NotificationSettingsViewModel.swift
│
├── Views/                                  # 🎨 SwiftUI Views
│   ├── Auth/                              # Authentication & Onboarding
│   │   ├── Login/
│   │   │   ├── ModernAuthView.swift
│   │   │   ├── PhoneVerificationView.swift
│   │   │   ├── AddContactMethodView.swift
│   │   │   └── AuthComponents.swift
│   │   └── Onboarding/
│   │       ├── OnboardingFlowView.swift
│   │       ├── AppIntroSlidesView.swift
│   │       └── PermissionsView.swift
│   │
│   ├── Attendee/                          # Attendee Features
│   │   ├── Home/
│   │   │   └── AttendeeHomeView.swift
│   │   ├── Events/
│   │   │   ├── EventDetailsView.swift
│   │   │   ├── SearchView.swift
│   │   │   └── FavoriteEventsView.swift
│   │   └── Tickets/
│   │       ├── TicketsView.swift
│   │       ├── TicketDetailView.swift
│   │       ├── TicketPurchaseView.swift
│   │       └── TicketSuccessView.swift
│   │
│   ├── Organizer/                         # Organizer Features
│   │   ├── Home/
│   │   │   ├── OrganizerHomeView.swift
│   │   │   └── OrganizerDashboardView.swift
│   │   ├── Events/
│   │   │   ├── CreateEventWizard.swift
│   │   │   └── EventAnalyticsView.swift
│   │   ├── Notifications/
│   │   │   └── OrganizerNotificationCenterView.swift
│   │   ├── Scanner/
│   │   │   └── QRScannerView.swift
│   │   └── Onboarding/
│   │       ├── BecomeOrganizerFlow.swift
│   │       └── Steps/
│   │           ├── OrganizerContactInfoStep.swift
│   │           ├── OrganizerIdentityVerificationStep.swift
│   │           ├── OrganizerPayoutSetupStep.swift
│   │           ├── OrganizerProfileCompletionStep.swift
│   │           └── OrganizerTermsAgreementStep.swift
│   │
│   ├── Profile/                           # User Profile & Settings
│   │   ├── ProfileView.swift
│   │   ├── ProfileView+ContactVerification.swift
│   │   ├── EditProfileView.swift
│   │   ├── PaymentMethodsView.swift
│   │   ├── NotificationSettingsView.swift
│   │   └── FavoriteEventCategoriesView.swift
│   │
│   ├── Notifications/                     # Notifications Center
│   │   └── NotificationsView.swift
│   │
│   ├── Support/                           # Help & Support
│   │   ├── HelpCenterView.swift
│   │   ├── SupportCenterView.swift
│   │   ├── FAQSectionView.swift
│   │   ├── AppGuidesView.swift
│   │   ├── FeatureExplanationsView.swift
│   │   ├── TroubleshootingView.swift
│   │   ├── SubmitTicketView.swift
│   │   ├── TermsAndPrivacyView.swift
│   │   ├── TermsOfUseView.swift
│   │   ├── PrivacyPolicyView.swift
│   │   └── SecurityInfoView.swift
│   │
│   ├── Shared/                            # Shared/Common Views
│   │   ├── CalendarConflictView.swift
│   │   ├── CardScanner.swift
│   │   └── NationalIDVerificationView.swift
│   │
│   ├── Components/                        # Reusable UI Components
│   │   ├── Cards/
│   │   │   ├── EventCard.swift
│   │   │   └── CategoryTile.swift
│   │   ├── Buttons/
│   │   │   └── AnimatedLikeButton.swift
│   │   ├── Headers/
│   │   │   ├── HeaderBar.swift
│   │   │   └── ProfileHeaderView.swift
│   │   ├── Badges/
│   │   │   ├── NotificationBadge.swift
│   │   │   └── PulsingDot.swift
│   │   ├── Media/
│   │   │   ├── PosterView.swift
│   │   │   └── QRCodeView.swift
│   │   ├── Timers/
│   │   │   └── SalesCountdownTimer.swift
│   │   ├── Overlays/
│   │   │   └── VerificationRequiredOverlay.swift
│   │   ├── Loading/
│   │   │   └── LoadingView.swift
│   │   ├── DashboardComponents.swift
│   │   └── UIComponents.swift
│   │
│   └── Navigation/
│       └── MainTabView.swift
│
├── DesignSystem/                           # 🎨 Design Tokens & Theming
│   └── Theme/
│       └── AppDesignSystem.swift
│
├── Utilities/                              # 🛠️ Helpers & Utilities
│   ├── Managers/
│   │   ├── FavoriteManager.swift
│   │   ├── FollowManager.swift
│   │   ├── InAppNotificationManager.swift
│   │   ├── ImageStorageManager.swift
│   │   └── PosterUploadManager.swift
│   ├── Helpers/
│   │   ├── Date/
│   │   │   └── DateUtilities.swift
│   │   ├── Image/
│   │   │   ├── ImageColorExtractor.swift
│   │   │   ├── ImageCompressor.swift
│   │   │   └── ImageValidator.swift
│   │   ├── Device/
│   │   │   ├── DeviceOrientation.swift
│   │   │   ├── HapticFeedback.swift
│   │   │   └── ResponsiveSize.swift
│   │   ├── Generators/
│   │   │   ├── QRCodeGenerator.swift
│   │   │   └── PDFGenerator.swift
│   │   ├── Validation/
│   │   │   └── Validation.swift
│   │   └── UI/
│   │       ├── ScrollHelpers.swift
│   │       └── ShareSheet.swift
│   └── Debug/
│       └── OnboardingDebugView.swift
│
└── Resources/                              # 📁 Non-Code Assets
    └── Assets.xcassets/
```

---

## 📋 Complete File Migration Map

### App Entry Point
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `EventPassUGApp.swift` | `App/EventPassUGApp.swift` | App entry point |
| `ContentView.swift` | `App/ContentView.swift` | Root view container |

### Core Infrastructure
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Config/RoleConfig.swift` | `Core/Configuration/RoleConfig.swift` | Core configuration |
| `CoreData/PersistenceController.swift` | `Core/Data/CoreData/PersistenceController.swift` | Data persistence |
| `EventPassUG.xcdatamodeld/` | `Core/Data/CoreData/EventPassUG.xcdatamodeld/` | CoreData model |
| `Utilities/AppStorage.swift` | `Core/Data/Storage/AppStorage.swift` | Data storage |
| `Utilities/AppStorageKeys.swift` | `Core/Data/Storage/AppStorageKeys.swift` | Storage keys |
| `Extensions/Event+TicketSales.swift` | `Core/Extensions/Event+Extensions.swift` | Swift extensions |

### Models (Domain Layer)
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Models/Event.swift` | `Models/Domain/Event.swift` | Core domain model |
| `Models/Ticket.swift` | `Models/Domain/Ticket.swift` | Core domain model |
| `Models/TicketType.swift` | `Models/Domain/TicketType.swift` | Core domain model |
| `Models/User.swift` | `Models/Domain/User.swift` | Core domain model |
| `Models/OrganizerProfile.swift` | `Models/Domain/OrganizerProfile.swift` | Core domain model |
| `Models/NotificationModel.swift` | `Models/Notifications/NotificationModel.swift` | Notification model |
| `Models/NotificationPreferences.swift` | `Models/Notifications/NotificationPreferences.swift` | Notification prefs |
| `Models/UserPreferences.swift` | `Models/Preferences/UserPreferences.swift` | User preferences |
| `Models/SupportModels.swift` | `Models/Support/SupportModels.swift` | Supporting types |
| `Models/PosterConfiguration.swift` | `Models/Support/PosterConfiguration.swift` | Supporting types |

### Services (Business Logic)
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Services/AuthService.swift` | `Services/Authentication/AuthService.swift` | Auth service grouping |
| `Services/EnhancedAuthService.swift` | `Services/Authentication/EnhancedAuthService.swift` | Auth service grouping |
| `Services/EventService.swift` | `Services/Events/EventService.swift` | Event service grouping |
| `Services/EventFilterService.swift` | `Services/Events/EventFilterService.swift` | Event service grouping |
| `Services/TicketService.swift` | `Services/Tickets/TicketService.swift` | Ticket service grouping |
| `Services/AppNotificationService.swift` | `Services/Notifications/AppNotificationService.swift` | Notification grouping |
| `Services/NotificationService.swift` | `Services/Notifications/NotificationService.swift` | Notification grouping |
| `Services/NotificationAnalytics.swift` | `Services/Notifications/NotificationAnalytics.swift` | Notification grouping |
| `Services/RecommendationService.swift` | `Services/Recommendations/RecommendationService.swift` | Recommendation service |
| `Services/LocationService.swift` | `Services/Location/LocationService.swift` | Location service grouping |
| `Services/UserLocationService.swift` | `Services/Location/UserLocationService.swift` | Location service grouping |
| `Services/PaymentService.swift` | `Services/Payment/PaymentService.swift` | Payment service |
| `Services/CalendarService.swift` | `Services/Calendar/CalendarService.swift` | Calendar service |
| `Services/UserPreferencesService.swift` | `Services/UserPreferences/UserPreferencesService.swift` | Preferences service |
| `Services/Database/TestDatabase.swift` | `Services/Database/TestDatabase.swift` | No change needed |
| `Services/ServiceContainer.swift` | `Services/ServiceContainer.swift` | No change needed |

### ViewModels
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `ViewModels/AuthViewModel.swift` | `ViewModels/Auth/AuthViewModel.swift` | Feature grouping |
| `ViewModels/AttendeeHomeViewModel.swift` | `ViewModels/Attendee/AttendeeHomeViewModel.swift` | Feature grouping |
| `ViewModels/DiscoveryViewModel.swift` | `ViewModels/Attendee/DiscoveryViewModel.swift` | Feature grouping |
| `ViewModels/EventAnalyticsViewModel.swift` | `ViewModels/Organizer/EventAnalyticsViewModel.swift` | Feature grouping |
| `ViewModels/NotificationSettingsViewModel.swift` | `ViewModels/Settings/NotificationSettingsViewModel.swift` | Feature grouping |

### Views - Auth & Onboarding
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Auth/ModernAuthView.swift` | `Views/Auth/Login/ModernAuthView.swift` | Sub-feature grouping |
| `Views/Auth/PhoneVerificationView.swift` | `Views/Auth/Login/PhoneVerificationView.swift` | Sub-feature grouping |
| `Views/Auth/AddContactMethodView.swift` | `Views/Auth/Login/AddContactMethodView.swift` | Sub-feature grouping |
| `Views/Auth/AuthComponents.swift` | `Views/Auth/Login/AuthComponents.swift` | Sub-feature grouping |
| `Views/Auth/OnboardingFlowView.swift` | `Views/Auth/Onboarding/OnboardingFlowView.swift` | Sub-feature grouping |
| `Views/Onboarding/AppIntroSlidesView.swift` | `Views/Auth/Onboarding/AppIntroSlidesView.swift` | Consolidate onboarding |
| `Views/Onboarding/PermissionsView.swift` | `Views/Auth/Onboarding/PermissionsView.swift` | Consolidate onboarding |

### Views - Attendee
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Attendee/AttendeeHomeView.swift` | `Views/Attendee/Home/AttendeeHomeView.swift` | Sub-feature grouping |
| `Views/Attendee/EventDetailsView.swift` | `Views/Attendee/Events/EventDetailsView.swift` | Sub-feature grouping |
| `Views/Attendee/SearchView.swift` | `Views/Attendee/Events/SearchView.swift` | Sub-feature grouping |
| `Views/Attendee/FavoriteEventsView.swift` | `Views/Attendee/Events/FavoriteEventsView.swift` | Sub-feature grouping |
| `Views/Attendee/TicketsView.swift` | `Views/Attendee/Tickets/TicketsView.swift` | Sub-feature grouping |
| `Views/Attendee/TicketDetailView.swift` | `Views/Attendee/Tickets/TicketDetailView.swift` | Sub-feature grouping |
| `Views/Attendee/TicketPurchaseView.swift` | `Views/Attendee/Tickets/TicketPurchaseView.swift` | Sub-feature grouping |
| `Views/Attendee/TicketSuccessView.swift` | `Views/Attendee/Tickets/TicketSuccessView.swift` | Sub-feature grouping |

### Views - Organizer
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Organizer/OrganizerHomeView.swift` | `Views/Organizer/Home/OrganizerHomeView.swift` | Sub-feature grouping |
| `Views/Organizer/OrganizerDashboardView.swift` | `Views/Organizer/Home/OrganizerDashboardView.swift` | Sub-feature grouping |
| `Views/Organizer/CreateEventWizard.swift` | `Views/Organizer/Events/CreateEventWizard.swift` | Sub-feature grouping |
| `Views/Organizer/EventAnalyticsView.swift` | `Views/Organizer/Events/EventAnalyticsView.swift` | Sub-feature grouping |
| `Views/Organizer/OrganizerNotificationCenterView.swift` | `Views/Organizer/Notifications/OrganizerNotificationCenterView.swift` | Sub-feature grouping |
| `Views/Organizer/QRScannerView.swift` | `Views/Organizer/Scanner/QRScannerView.swift` | Sub-feature grouping |
| `Views/Organizer/BecomeOrganizerFlow.swift` | `Views/Organizer/Onboarding/BecomeOrganizerFlow.swift` | Sub-feature grouping |
| `Views/Organizer/Steps/*` | `Views/Organizer/Onboarding/Steps/*` | No change needed |

### Views - Profile & Settings
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Common/ProfileView.swift` | `Views/Profile/ProfileView.swift` | Feature grouping |
| `Views/Common/ProfileView+ContactVerification.swift` | `Views/Profile/ProfileView+ContactVerification.swift` | Feature grouping |
| `Views/Common/EditProfileView.swift` | `Views/Profile/EditProfileView.swift` | Feature grouping |
| `Views/Common/PaymentMethodsView.swift` | `Views/Profile/PaymentMethodsView.swift` | Feature grouping |
| `Views/Common/NotificationSettingsView.swift` | `Views/Profile/NotificationSettingsView.swift` | Feature grouping |
| `Views/Common/FavoriteEventCategoriesView.swift` | `Views/Profile/FavoriteEventCategoriesView.swift` | Feature grouping |

### Views - Notifications
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Common/NotificationsView.swift` | `Views/Notifications/NotificationsView.swift` | Feature grouping |

### Views - Support (No changes needed)
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Support/*` | `Views/Support/*` | Already well organized |

### Views - Shared/Common
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Common/CalendarConflictView.swift` | `Views/Shared/CalendarConflictView.swift` | Shared across features |
| `Views/Common/CardScanner.swift` | `Views/Shared/CardScanner.swift` | Shared across features |
| `Views/Common/NationalIDVerificationView.swift` | `Views/Shared/NationalIDVerificationView.swift` | Shared across features |

### Views - Components (Organized by Type)
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Components/EventCard.swift` | `Views/Components/Cards/EventCard.swift` | Component type grouping |
| `Views/Components/CategoryTile.swift` | `Views/Components/Cards/CategoryTile.swift` | Component type grouping |
| `Views/Components/AnimatedLikeButton.swift` | `Views/Components/Buttons/AnimatedLikeButton.swift` | Component type grouping |
| `Views/Components/HeaderBar.swift` | `Views/Components/Headers/HeaderBar.swift` | Component type grouping |
| `Views/Components/ProfileHeaderView.swift` | `Views/Components/Headers/ProfileHeaderView.swift` | Component type grouping |
| `Views/Components/NotificationBadge.swift` | `Views/Components/Badges/NotificationBadge.swift` | Component type grouping |
| `Views/Components/PulsingDot.swift` | `Views/Components/Badges/PulsingDot.swift` | Component type grouping |
| `Views/Components/PosterView.swift` | `Views/Components/Media/PosterView.swift` | Component type grouping |
| `Views/Components/QRCodeView.swift` | `Views/Components/Media/QRCodeView.swift` | Component type grouping |
| `Views/Components/SalesCountdownTimer.swift` | `Views/Components/Timers/SalesCountdownTimer.swift` | Component type grouping |
| `Views/Components/VerificationRequiredOverlay.swift` | `Views/Components/Overlays/VerificationRequiredOverlay.swift` | Component type grouping |
| `Views/Components/LoadingView.swift` | `Views/Components/Loading/LoadingView.swift` | Component type grouping |
| `Views/Components/DashboardComponents.swift` | `Views/Components/DashboardComponents.swift` | No change needed |
| `Views/Components/UIComponents.swift` | `Views/Components/UIComponents.swift` | No change needed |

### Views - Navigation (No changes needed)
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Views/Navigation/MainTabView.swift` | `Views/Navigation/MainTabView.swift` | Already correct |

### Design System
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Config/AppDesignSystem.swift` | `DesignSystem/Theme/AppDesignSystem.swift` | Better categorization |

### Utilities - Managers
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Utilities/FavoriteManager.swift` | `Utilities/Managers/FavoriteManager.swift` | Manager grouping |
| `Utilities/FollowManager.swift` | `Utilities/Managers/FollowManager.swift` | Manager grouping |
| `Utilities/InAppNotificationManager.swift` | `Utilities/Managers/InAppNotificationManager.swift` | Manager grouping |
| `Utilities/ImageStorageManager.swift` | `Utilities/Managers/ImageStorageManager.swift` | Manager grouping |
| `Utilities/PosterUploadManager.swift` | `Utilities/Managers/PosterUploadManager.swift` | Manager grouping |

### Utilities - Helpers (Organized by Domain)
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Utilities/DateUtilities.swift` | `Utilities/Helpers/Date/DateUtilities.swift` | Domain grouping |
| `Utilities/ImageColorExtractor.swift` | `Utilities/Helpers/Image/ImageColorExtractor.swift` | Domain grouping |
| `Utilities/ImageCompressor.swift` | `Utilities/Helpers/Image/ImageCompressor.swift` | Domain grouping |
| `Utilities/ImageValidator.swift` | `Utilities/Helpers/Image/ImageValidator.swift` | Domain grouping |
| `Utilities/DeviceOrientation.swift` | `Utilities/Helpers/Device/DeviceOrientation.swift` | Domain grouping |
| `Utilities/HapticFeedback.swift` | `Utilities/Helpers/Device/HapticFeedback.swift` | Domain grouping |
| `Utilities/ResponsiveSize.swift` | `Utilities/Helpers/Device/ResponsiveSize.swift` | Domain grouping |
| `Utilities/QRCodeGenerator.swift` | `Utilities/Helpers/Generators/QRCodeGenerator.swift` | Domain grouping |
| `Utilities/PDFGenerator.swift` | `Utilities/Helpers/Generators/PDFGenerator.swift` | Domain grouping |
| `Utilities/Validation.swift` | `Utilities/Helpers/Validation/Validation.swift` | Domain grouping |
| `Utilities/ScrollHelpers.swift` | `Utilities/Helpers/UI/ScrollHelpers.swift` | Domain grouping |
| `Utilities/ShareSheet.swift` | `Utilities/Helpers/UI/ShareSheet.swift` | Domain grouping |

### Utilities - Debug
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Utilities/OnboardingDebugView.swift` | `Utilities/Debug/OnboardingDebugView.swift` | Debug tooling |

### Resources (No changes needed)
| Current Location | New Location | Reason |
|-----------------|--------------|---------|
| `Assets.xcassets/` | `Resources/Assets.xcassets/` | Resource organization |

---

## 🎓 Why This Structure Scales Well

### 1. **Clear Separation of Concerns**
- **Models** = Pure data (no logic)
- **Services** = Business logic (no UI)
- **ViewModels** = Presentation logic (MVVM)
- **Views** = UI only (no business logic)

### 2. **Feature-Based Organization**
- Easy to find all files related to a feature
- New developers can navigate quickly
- Supports future modularization

### 3. **Logical Grouping**
- Related files are co-located
- Components organized by type (Cards, Buttons, etc.)
- Services grouped by domain (Auth, Events, Notifications)

### 4. **Scalability**
- Can easily extract features into Swift Packages
- Supports multi-target (iOS, iPadOS, watchOS)
- Room for growth without restructuring

### 5. **Maintainability**
- Consistent naming conventions
- Predictable file locations
- Easy to enforce code review standards

---

## 📝 Best Practices for Maintaining Structure

### 1. **File Placement Rules**
```
✅ DO: Place files based on their PRIMARY responsibility
✅ DO: Use descriptive folder names (Events, not Misc)
✅ DO: Keep folder depth to 3-4 levels max
❌ DON'T: Create "Helpers" dumping grounds
❌ DON'T: Mix UI and business logic in same folder
```

### 2. **Naming Conventions**
```swift
// Models
Event.swift              // Singular, no suffix
UserPreferences.swift    // Descriptive

// Services
EventService.swift       // Noun + Service
AuthService.swift

// ViewModels
EventDetailsViewModel.swift  // Screen + ViewModel
AuthViewModel.swift

// Views
EventDetailsView.swift   // Screen + View
ModernAuthView.swift
```

### 3. **When to Create New Folders**
- ✅ When you have 3+ related files
- ✅ When files share a clear domain/feature
- ✅ When it improves discoverability
- ❌ For single files (unless clearly isolated feature)

### 4. **Code Review Checklist**
- [ ] File is in the correct top-level folder (App, Core, Models, etc.)
- [ ] File is in the correct sub-folder for its domain
- [ ] Naming follows conventions (ViewModel, Service, View)
- [ ] No business logic in Views
- [ ] No UI code in ViewModels
- [ ] No networking in Models

---

## 🚀 Future Considerations

### Modularization (Phase 2)
When the app grows, consider:
```
EventPassKit/
├── EventPassCore/          # Core models + utilities
├── EventPassUI/            # Design system + components
├── EventPassServices/      # All services
├── EventPassAuth/          # Auth feature module
└── EventPassTicketing/     # Ticketing feature module
```

### Multi-Platform (Phase 3)
Structure supports future:
- iOS app
- iPad optimizations
- Mac Catalyst
- watchOS companion app
- Widget extensions

---

## ✅ Implementation Checklist

- [ ] Create new folder structure in Xcode
- [ ] Move files to new locations (preserve git history)
- [ ] Update Xcode project references
- [ ] Verify all imports still work
- [ ] Run full build to catch any issues
- [ ] Update documentation
- [ ] Commit with descriptive message

---

**Total Files to Move:** 121
**Estimated Time:** 45-60 minutes
**Risk Level:** Low (mostly file organization, no code changes)
**Benefits:** Massive improvement in maintainability and scalability

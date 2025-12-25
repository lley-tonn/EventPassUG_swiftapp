# EventPassUG Architecture Documentation

## 📐 Architecture Overview

EventPassUG follows a **Feature-First + Clean Architecture** pattern designed for scalability, maintainability, and team productivity.

### Core Principles

1. **Feature-First Organization** - Related code lives together
2. **Clean Architecture Layers** - Clear separation of concerns
3. **MVVM Pattern** - SwiftUI + ViewModels for presentation logic
4. **Protocol-Oriented Design** - Dependency injection via protocols
5. **No Framework Dependencies in Domain** - Pure business logic

---

## 🗂️ Project Structure

```
EventPassUG/
├── App/                          # Application Entry & Configuration
│   ├── EventPassUGApp.swift     # @main entry point
│   ├── AppState/                # Global app state
│   └── Routing/                 # Navigation & routing
│       └── MainTabView.swift    # Main tab navigation
│
├── Features/                     # Feature-Based Modules
│   ├── Auth/                    # Authentication & Onboarding
│   │   ├── AuthView.swift       # Login/Register UI
│   │   ├── AuthViewModel.swift  # Auth business logic
│   │   ├── AuthComponents.swift # Reusable auth components
│   │   └── ...                  # Other auth views
│   │
│   ├── Attendee/                # Attendee-specific features
│   │   ├── AttendeeHomeView.swift
│   │   ├── AttendeeHomeViewModel.swift
│   │   ├── EventDetailsView.swift
│   │   ├── TicketsView.swift
│   │   ├── TicketPurchaseView.swift
│   │   └── ...
│   │
│   ├── Organizer/               # Organizer-specific features
│   │   ├── OrganizerHomeView.swift
│   │   ├── OrganizerDashboardView.swift
│   │   ├── CreateEventWizard.swift
│   │   ├── QRScannerView.swift
│   │   └── ...
│   │
│   └── Common/                  # Shared features (Profile, Settings, Support)
│       ├── ProfileView.swift
│       ├── NotificationSettingsView.swift
│       ├── SupportCenterView.swift
│       └── ...
│
├── Domain/                       # Business Logic Layer (Pure Swift)
│   ├── Models/                  # Core business models
│   │   ├── Event.swift
│   │   ├── Ticket.swift
│   │   ├── User.swift
│   │   ├── OrganizerProfile.swift
│   │   └── ...
│   │
│   └── UseCases/                # Business rules & use cases
│       └── (Future: Complex business logic)
│
├── Data/                         # Data Access Layer
│   ├── Networking/              # API layer
│   │   ├── APIClient.swift
│   │   └── Endpoints/
│   │
│   ├── Persistence/             # Local storage
│   │   └── TestDatabase.swift  # Mock database
│   │
│   └── Repositories/            # Data access implementations
│       ├── AuthRepository.swift
│       ├── EventRepository.swift
│       ├── TicketRepository.swift
│       ├── PaymentRepository.swift
│       └── ...
│
├── UI/                           # Reusable UI Components
│   ├── Components/              # Generic UI components
│   │   ├── EventCard.swift
│   │   ├── HeaderBar.swift
│   │   ├── LoadingView.swift
│   │   ├── QRCodeView.swift
│   │   └── ...
│   │
│   └── DesignSystem/            # Design tokens & theming
│       └── AppDesignSystem.swift
│
├── Core/                         # Core Infrastructure
│   ├── DI/                      # Dependency Injection
│   │   └── ServiceContainer.swift
│   │
│   ├── Data/                    # Core data infrastructure
│   │   ├── CoreData/
│   │   │   └── PersistenceController.swift
│   │   └── Storage/
│   │       ├── AppStorage.swift
│   │       └── AppStorageKeys.swift
│   │
│   ├── Utilities/               # Helpers & utilities
│   │   ├── DateUtilities.swift
│   │   ├── HapticFeedback.swift
│   │   ├── QRCodeGenerator.swift
│   │   ├── PDFGenerator.swift
│   │   └── ...
│   │
│   ├── Extensions/              # Swift extensions
│   │   └── Event+TicketSales.swift
│   │
│   └── Security/                # Security utilities
│       └── (Future: Keychain, encryption)
│
└── Resources/                    # Assets, Info.plist, etc.
    └── Assets.xcassets
```

---

## 🔄 Data Flow

### Standard Flow (MVVM + Clean Architecture)

```
┌─────────────────┐
│  User Action    │
│   (View)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   ViewModel     │ ← Holds presentation logic
│  (SwiftUI @Published)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Repository    │ ← Coordinates data sources
│   (Protocol)    │
└────────┬────────┘
         │
         ├──────────────┬──────────────┐
         ▼              ▼              ▼
   ┌─────────┐    ┌─────────┐   ┌──────────┐
   │   API   │    │  Cache  │   │ Database │
   └─────────┘    └─────────┘   └──────────┘
         │              │              │
         └──────────────┴──────────────┘
                        │
                        ▼
                 ┌─────────────┐
                 │Domain Model │
                 └─────────────┘
                        │
                        ▼
                 ┌─────────────┐
                 │  ViewModel  │
                 └─────────────┘
                        │
                        ▼
                 ┌─────────────┐
                 │    View     │
                 └─────────────┘
```

### Example: User Purchases Ticket

1. **User Interaction**: Taps "Buy Ticket" in `TicketPurchaseView`
2. **ViewModel**: `PaymentConfirmationViewModel.purchaseTicket()` is called
3. **Repository**: ViewModel calls `TicketRepository.purchase()`
4. **Networking**: Repository makes API call via `APIClient`
5. **Model Mapping**: API response → `Ticket` domain model
6. **State Update**: ViewModel updates `@Published` properties
7. **View Reaction**: SwiftUI automatically re-renders

---

## 🧩 Layer Responsibilities

### 1️⃣ App Layer
- **Purpose**: Application entry point and global configuration
- **Contains**: `@main` app struct, routing, global state
- **Rules**:
  - No business logic
  - Minimal code - delegate to features
  - Configure DI container
  - Set up navigation

### 2️⃣ Features Layer
- **Purpose**: Feature-specific UI and presentation logic
- **Contains**: Views + ViewModels + Feature-specific models
- **Rules**:
  - Each feature is self-contained
  - Views are **UI only** (no networking, no persistence)
  - ViewModels handle presentation logic
  - Can import: `Domain`, `Data`, `UI`, `Core`
  - **Cannot** import other Features directly

### 3️⃣ Domain Layer
- **Purpose**: Pure business logic and models
- **Contains**: Business models, use cases, business rules
- **Rules**:
  - **Foundation only** (no SwiftUI, UIKit, or other frameworks)
  - Models are value types (structs) where possible
  - No external dependencies
  - Represents "what the app does" independent of UI

### 4️⃣ Data Layer
- **Purpose**: Data access and persistence
- **Contains**: Repositories, API clients, database access
- **Rules**:
  - Implements repository protocols
  - Handles API calls, caching, persistence
  - Maps API responses → Domain models
  - Shields features from data source changes

### 5️⃣ UI Layer
- **Purpose**: Reusable UI components and design system
- **Contains**: Generic components, design tokens
- **Rules**:
  - Components are **dumb** (no business logic)
  - Design system defines: colors, typography, spacing
  - Can be used by any feature
  - No domain model dependencies

### 6️⃣ Core Layer
- **Purpose**: Foundational utilities and infrastructure
- **Contains**: DI, utilities, extensions, security
- **Rules**:
  - Generic, reusable across features
  - No feature-specific code
  - Can be imported by any layer

---

## 📦 Dependency Rules

```
Features ──────► Domain
   │              ▲
   │              │
   ├────► Data ───┘
   │
   ├────► UI
   │
   └────► Core

UI ──────► Core (only)

Domain ──────► (Nothing - Pure Swift)

Data ──────► Domain
   │
   └────► Core

Core ──────► (Nothing - Foundation only)
```

**Key Principle**: Dependencies point **inward**. Domain has no dependencies.

---

## 🎯 Why This Architecture Scales

### ✅ Benefits

1. **Feature Isolation**
   - Teams can work on different features without conflicts
   - Easy to add/remove features
   - Clear ownership boundaries

2. **Testability**
   - Pure domain logic is easy to unit test
   - Repositories use protocols (easy to mock)
   - ViewModels are testable without UI

3. **Reusability**
   - UI components are shared
   - Domain models are pure and reusable
   - Utilities are generic

4. **Maintainability**
   - Related code lives together
   - Clear layer boundaries
   - Easy to find files (feature-first)

5. **Multi-Platform Ready**
   - Domain layer is UI-agnostic
   - Easy to add iPadOS, macOS, watchOS targets
   - Reuse business logic across platforms

6. **Modularization Path**
   - Features can become SPM packages
   - Domain, Data, UI can be separate modules
   - Clear boundaries make splitting easier

---

## 🛠️ Best Practices

### ✅ DO

- ✅ Keep views **small and focused** (under 300 lines)
- ✅ Use ViewModels for **all state and logic**
- ✅ Use **dependency injection** via protocols
- ✅ Make domain models **Codable, Equatable, Identifiable**
- ✅ Use SF Symbols for icons
- ✅ Reference `AppDesign` tokens (never hardcode colors/spacing)
- ✅ Write **unit tests** for ViewModels and use cases
- ✅ Use `@MainActor` for ViewModels
- ✅ Use `async/await` for asynchronous operations

### ❌ DON'T

- ❌ Put business logic in Views
- ❌ Import UIKit in Views (use SwiftUI wrappers)
- ❌ Hardcode API endpoints in Views or ViewModels
- ❌ Create dependencies between Features
- ❌ Import SwiftUI in Domain layer
- ❌ Make massive ViewModels (split into smaller features)
- ❌ Use singletons (use DI instead)
- ❌ Couple UI to specific data sources

---

## 🚀 Adding a New Feature

### Step-by-Step Guide

#### 1. Create Feature Structure
```
Features/
└── NewFeature/
    ├── NewFeatureView.swift         # Main UI
    ├── NewFeatureViewModel.swift    # Presentation logic
    └── NewFeatureModels.swift       # Feature-specific DTOs
```

#### 2. Add Domain Models (if needed)
```swift
// Domain/Models/NewEntity.swift
struct NewEntity: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    // ... pure business properties
}
```

#### 3. Create Repository Protocol
```swift
// Data/Repositories/NewFeatureRepository.swift
protocol NewFeatureRepositoryProtocol {
    func fetchData() async throws -> [NewEntity]
}

class NewFeatureRepository: NewFeatureRepositoryProtocol {
    func fetchData() async throws -> [NewEntity] {
        // API call logic
    }
}
```

#### 4. Add to DI Container
```swift
// Core/DI/ServiceContainer.swift
class ServiceContainer: ObservableObject {
    let newFeatureRepository: NewFeatureRepositoryProtocol

    init(/* ... */, newFeatureRepository: NewFeatureRepositoryProtocol) {
        self.newFeatureRepository = newFeatureRepository
    }
}
```

#### 5. Create ViewModel
```swift
// Features/NewFeature/NewFeatureViewModel.swift
@MainActor
class NewFeatureViewModel: ObservableObject {
    @Published var items: [NewEntity] = []

    private let repository: NewFeatureRepositoryProtocol

    init(repository: NewFeatureRepositoryProtocol) {
        self.repository = repository
    }

    func loadData() async {
        do {
            items = try await repository.fetchData()
        } catch {
            // Handle error
        }
    }
}
```

#### 6. Build View
```swift
// Features/NewFeature/NewFeatureView.swift
struct NewFeatureView: View {
    @StateObject private var viewModel: NewFeatureViewModel

    init(repository: NewFeatureRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: NewFeatureViewModel(repository: repository))
    }

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.loadData() }
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests
- **Domain Models**: Test business logic, validation
- **ViewModels**: Test state changes, business flows
- **Repositories**: Test data mapping, error handling

### Integration Tests
- Test ViewModel + Repository integration
- Test API client + networking layer

### UI Tests
- Critical user flows (login, purchase, etc.)
- Accessibility testing

---

## 📱 Multi-Platform Strategy

### Current: iPhone
- Single module architecture
- All code in `EventPassUG` target

### Future: iPad Support
- Adaptive layouts already using `ResponsiveSize`
- Can add iPad-specific views in Features/Common
- Reuse all Domain, Data, Core layers

### Future: Modularization (SPM)
```
EventPassUGCore (Package)
├── Domain
├── Data
└── UI

EventPassUGApp (App)
├── App
└── Features
    ├── Auth
    ├── Attendee
    └── Organizer
```

---

## 🔐 Security Considerations

- Sensitive data stored in Keychain (via `Core/Security`)
- API tokens managed by repository layer
- No hardcoded credentials
- User data encrypted at rest

---

## 📚 Further Reading

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SwiftUI MVVM Best Practices](https://www.swiftbysundell.com/articles/swiftui-state-management-guide/)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)

---

**Architecture Version**: 2.0
**Last Updated**: December 2024
**Maintained By**: EventPassUG Team

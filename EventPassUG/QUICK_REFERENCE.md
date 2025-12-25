# EventPassUG Architecture - Quick Reference

## 🎯 At a Glance

**Architecture**: Feature-First + Clean Architecture (MVVM)
**Language**: Swift + SwiftUI
**Pattern**: Repository Pattern + Dependency Injection
**Status**: ✅ Migration Complete

---

## 📂 Folder Structure (Quick Lookup)

```
EventPassUG/
│
├── 📱 App/                         # App entry point
│   ├── EventPassUGApp.swift       # @main
│   ├── ContentView.swift          # Root view
│   └── Routing/MainTabView.swift  # Navigation
│
├── 🎨 Features/                    # All UI & ViewModels
│   ├── Auth/                      # Login, Register, Onboarding (8 files)
│   ├── Attendee/                  # Events, Tickets, Payment (12 files)
│   ├── Organizer/                 # Dashboard, Create Event, Scanner (13 files)
│   └── Common/                    # Profile, Settings, Support (22 files)
│
├── 💼 Domain/                      # Pure business logic
│   ├── Models/                    # Event, Ticket, User, etc. (11 files)
│   └── UseCases/                  # (Future: Business rules)
│
├── 💾 Data/                        # Data access layer
│   ├── Repositories/              # AuthRepo, EventRepo, etc. (14 files)
│   ├── Networking/Endpoints/      # API endpoints
│   └── Persistence/               # Local storage
│
├── 🧩 UI/                          # Reusable components
│   ├── Components/                # EventCard, LoadingView, etc. (14 files)
│   └── DesignSystem/              # Colors, Typography, Spacing
│
└── ⚙️ Core/                        # Infrastructure
    ├── DI/ServiceContainer.swift  # Dependency injection
    ├── Utilities/                 # Helpers (19 files)
    ├── Extensions/                # Swift extensions
    └── Data/Storage/              # AppStorage, CoreData
```

---

## 🔍 How to Find Files

### "Where is the login screen?"
→ `Features/Auth/AuthView.swift`

### "Where is the event repository?"
→ `Data/Repositories/EventRepository.swift`

### "Where is the Event model?"
→ `Domain/Models/Event.swift`

### "Where is the design system?"
→ `UI/DesignSystem/AppDesignSystem.swift`

### "Where are UI components?"
→ `UI/Components/`

### "Where are utilities?"
→ `Core/Utilities/`

### "Where is dependency injection?"
→ `Core/DI/ServiceContainer.swift`

---

## 🔄 Data Flow (Visual)

```
┌─────────────────────────────────────────────────────┐
│  User taps "Buy Ticket"                             │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  Features/Attendee/TicketPurchaseView.swift         │ ◄── SwiftUI View
│  - Displays UI                                      │
│  - Handles user interaction                         │
└──────────────────┬──────────────────────────────────┘
                   │ calls
                   ▼
┌─────────────────────────────────────────────────────┐
│  Features/Attendee/PaymentConfirmationViewModel     │ ◄── ViewModel
│  @Published var state: PaymentState                 │
│  func purchaseTicket() async                        │
└──────────────────┬──────────────────────────────────┘
                   │ calls
                   ▼
┌─────────────────────────────────────────────────────┐
│  Data/Repositories/TicketRepository.swift           │ ◄── Repository
│  func purchase(ticket: Ticket) async throws         │
└──────────────────┬──────────────────────────────────┘
                   │
      ┌────────────┼────────────┐
      │            │            │
      ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│   API   │  │  Cache  │  │ CoreData│
└─────────┘  └─────────┘  └─────────┘
      │            │            │
      └────────────┼────────────┘
                   │ returns
                   ▼
┌─────────────────────────────────────────────────────┐
│  Domain/Models/Ticket.swift                         │ ◄── Domain Model
│  struct Ticket: Identifiable, Codable              │
└──────────────────┬──────────────────────────────────┘
                   │ updates
                   ▼
┌─────────────────────────────────────────────────────┐
│  ViewModel @Published properties                    │
└──────────────────┬──────────────────────────────────┘
                   │ SwiftUI auto-updates
                   ▼
┌─────────────────────────────────────────────────────┐
│  View re-renders with new data                      │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Layer Responsibilities

| Layer | Purpose | Can Import | Cannot Import |
|-------|---------|------------|---------------|
| **App** | Entry point, routing | Everything | - |
| **Features** | UI + ViewModels | Domain, Data, UI, Core | Other Features |
| **Domain** | Business models | Foundation only | SwiftUI, UIKit, Features |
| **Data** | Repositories, API | Domain, Core | Features, UI |
| **UI** | Components, Design System | Core only | Features, Domain, Data |
| **Core** | Utilities, DI | Foundation only | Features, Domain, Data, UI |

---

## 📝 Common Tasks

### Add a New Feature Screen

```swift
// 1. Create folder: Features/YourFeature/

// 2. Create View
// Features/YourFeature/YourFeatureView.swift
struct YourFeatureView: View {
    @StateObject private var viewModel: YourFeatureViewModel

    var body: some View {
        // UI here
    }
}

// 3. Create ViewModel
// Features/YourFeature/YourFeatureViewModel.swift
@MainActor
class YourFeatureViewModel: ObservableObject {
    @Published var data: [Item] = []

    private let repository: YourRepositoryProtocol

    init(repository: YourRepositoryProtocol) {
        self.repository = repository
    }

    func loadData() async {
        // Business logic
    }
}
```

### Add a New Domain Model

```swift
// Domain/Models/NewModel.swift
struct NewModel: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    // Pure business properties only
    // NO SwiftUI imports!
}
```

### Add a New Repository

```swift
// Data/Repositories/NewRepository.swift

protocol NewRepositoryProtocol {
    func fetchData() async throws -> [NewModel]
}

class NewRepository: NewRepositoryProtocol {
    func fetchData() async throws -> [NewModel] {
        // API call, caching, etc.
    }
}

class MockNewRepository: NewRepositoryProtocol {
    func fetchData() async throws -> [NewModel] {
        // Mock data for testing/preview
    }
}
```

### Add to DI Container

```swift
// Core/DI/ServiceContainer.swift
class ServiceContainer: ObservableObject {
    let newRepository: NewRepositoryProtocol

    init(
        // ... existing params
        newRepository: NewRepositoryProtocol
    ) {
        self.newRepository = newRepository
    }
}

// App/EventPassUGApp.swift
init() {
    services = ServiceContainer(
        // ... existing services
        newRepository: MockNewRepository() // or RealNewRepository()
    )
}
```

---

## 🎨 Using the Design System

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Hello")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)

            Button("Submit") {
                // action
            }
            .frame(height: AppButtonDimensions.largeHeight)
            .background(AppColors.primary)
            .cornerRadius(AppCornerRadius.button)
            .buttonShadow()
        }
        .padding(AppSpacing.edge)
    }
}
```

**Never hardcode**:
- ❌ `.foregroundColor(.orange)` → ✅ `.foregroundColor(AppColors.primary)`
- ❌ `.padding(16)` → ✅ `.padding(AppSpacing.md)`
- ❌ `.cornerRadius(12)` → ✅ `.cornerRadius(AppCornerRadius.button)`

---

## 🧪 Testing Examples

### Test ViewModel

```swift
@Test
func testLoadData() async {
    // Arrange
    let mockRepo = MockEventRepository()
    let viewModel = EventListViewModel(repository: mockRepo)

    // Act
    await viewModel.loadEvents()

    // Assert
    #expect(viewModel.events.count == 5)
    #expect(viewModel.state == .loaded)
}
```

### Test Repository

```swift
@Test
func testFetchEvents() async throws {
    // Arrange
    let repository = EventRepository()

    // Act
    let events = try await repository.fetchEvents()

    // Assert
    #expect(events.count > 0)
    #expect(events.first?.title != nil)
}
```

---

## 📋 Naming Conventions

### Files
- Views: `*View.swift` (e.g., `EventDetailsView.swift`)
- ViewModels: `*ViewModel.swift` (e.g., `EventDetailsViewModel.swift`)
- Models: Noun (e.g., `Event.swift`, `Ticket.swift`)
- Repositories: `*Repository.swift` (e.g., `EventRepository.swift`)
- Protocols: `*Protocol` (e.g., `EventRepositoryProtocol`)

### Code
- Classes: `PascalCase`
- Properties: `camelCase`
- Functions: `camelCase`
- Constants: `camelCase`
- Enums: `PascalCase`, cases: `camelCase`

---

## 🚨 Common Mistakes to Avoid

### ❌ DON'T: Put logic in Views
```swift
// BAD
struct EventListView: View {
    @State private var events: [Event] = []

    var body: some View {
        List(events) { event in
            Text(event.title)
        }
        .task {
            // ❌ API call in view
            events = try? await fetchEvents()
        }
    }
}
```

### ✅ DO: Use ViewModels
```swift
// GOOD
struct EventListView: View {
    @StateObject private var viewModel: EventListViewModel

    var body: some View {
        List(viewModel.events) { event in
            Text(event.title)
        }
        .task {
            await viewModel.loadEvents() // ✅
        }
    }
}
```

### ❌ DON'T: Import SwiftUI in Domain
```swift
// Domain/Models/Event.swift
import SwiftUI // ❌ NEVER!

struct Event {
    let color: Color // ❌ UI concern in Domain
}
```

### ✅ DO: Keep Domain Pure
```swift
// Domain/Models/Event.swift
// ✅ Foundation only
struct Event: Identifiable, Codable {
    let id: UUID
    let title: String
    let categoryColorHex: String // ✅ Store hex, convert in UI layer
}
```

---

## 🔗 Quick Links

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Full architecture guide
- **[MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)** - File mappings
- **[REFACTORING_SUMMARY.md](../REFACTORING_SUMMARY.md)** - Migration summary
- **[UI/DesignSystem/AppDesignSystem.swift](./UI/DesignSystem/AppDesignSystem.swift)** - Design tokens

---

## 💡 Pro Tips

1. **Finding Files**: Use Feature-first - if it's Auth, check `Features/Auth/`
2. **Reusable Components**: Check `UI/Components/` before creating new ones
3. **Design Tokens**: Always use `AppDesign.*` - never hardcode
4. **Testing**: Mock repositories make ViewModels easy to test
5. **Dependencies**: Follow the dependency rules - Features → Domain ← Data

---

## 🎯 Quick Checklist for PRs

- [ ] Views have NO business logic
- [ ] ViewModels use dependency injection
- [ ] Domain models don't import SwiftUI
- [ ] Using AppDesign tokens (no hardcoded values)
- [ ] Repositories return Domain models
- [ ] Tests included for ViewModels
- [ ] No cross-feature dependencies (Features don't import other Features)

---

**Last Updated**: December 2024
**Architecture Version**: 2.0

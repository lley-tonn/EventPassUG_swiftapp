# EventPassUG - Native iOS Event Management App

A complete, production-ready native iOS application for discovering and managing events across Uganda. Built with **Swift** and **SwiftUI** targeting iOS 16+.

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue)
![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Clean-green)

---

## Quick Start

### 1. Open the Project
```bash
cd /Users/lley-tonn/Documents/projects/EventPassUG-MobileApp
open EventPassUG.xcodeproj
```

### 2. Build and Run
- Select a simulator: **iPhone 15 Pro** (or any iOS 16+ device)
- Press **⌘ + R** to build and run

### 3. Test with Demo Account
```
Email: john@example.com
Password: password123
```

---

## Features

### For Attendees
- ✅ Discover events with smart recommendations
- ✅ Purchase tickets with MTN Mobile Money, Airtel Money, or Card
- ✅ QR code tickets for fast entry
- ✅ Search, filter, and favorite events
- ✅ Interactive maps for venue locations

### For Organizers
- ✅ Create and manage events with 3-step wizard
- ✅ Configure multiple ticket types and pricing
- ✅ Scan QR codes for ticket validation
- ✅ Real-time analytics and earnings dashboard
- ✅ Edit and delete events with smart warnings

### Platform Features
- ✅ Dual-role support (seamless Attendee ↔ Organizer switching)
- ✅ Guest browsing (explore without account)
- ✅ Multiple authentication methods (Email, Phone OTP, Social)
- ✅ Dark/light mode with role-based theming
- ✅ Production-grade clean architecture

---

## Documentation

### Getting Started
- **[Installation Guide](./docs/installation.md)** - Setup instructions, requirements, and test users
- **[Overview](./docs/overview.md)** - Project purpose, goals, and core concepts

### Development
- **[Architecture Guide](./docs/architecture.md)** - System design, data flow, and best practices
- **[Features Documentation](./docs/features.md)** - Detailed feature descriptions and user flows (55+ features)
- **[API Integration](./docs/api.md)** - Backend setup, protocols, and payment integration
- **[UI Components Catalog](./docs/ui-components.md)** - Reusable component library with usage examples

### Feature Guides
- **[Organizer Onboarding](./docs/organizer-onboarding.md)** - 5-step organizer verification and setup process
- **[Social Features](./docs/social-features.md)** - Follow system and in-app notifications

### Support
- **[Troubleshooting](./docs/troubleshooting.md)** - Common issues, testing, and debugging
- **[Documentation Status](./docs/DOCUMENTATION_STATUS.md)** - Coverage report and roadmap

---

## Technology Stack

- **SwiftUI** - 100% declarative UI framework
- **MVVM + Clean Architecture** - Feature-first, protocol-oriented design
- **Combine** - Reactive data binding
- **async/await** - Modern concurrency
- **MapKit** - Venue mapping
- **AVFoundation** - QR code scanning
- **CryptoKit** - Secure password hashing

---

## Project Structure

```
EventPassUG/
├── App/              # Entry point & navigation
├── Features/         # Feature modules (Auth, Attendee, Organizer, Common)
├── Domain/           # Business models & logic
├── Data/             # Repositories & networking
├── UI/               # Reusable components & design system
└── Core/             # Utilities, DI, extensions
```

**Architecture**: Feature-First + Clean Architecture (MVVM)
- 123 Swift files organized across 6 layers
- Clear separation of concerns
- Protocol-based dependency injection
- Ready for multi-platform expansion

---

## Key Highlights

### Production-Ready Architecture
- ✅ **Feature-First Organization** - Related code grouped by feature
- ✅ **Clean Architecture Layers** - Clear boundaries and testability
- ✅ **Repository Pattern** - Data access abstraction
- ✅ **Centralized Design System** - Consistent UI tokens
- ✅ **Comprehensive Documentation** - Architecture guides and API docs

### Dual Role Platform
- **Attendees**: Browse, purchase, manage tickets
- **Organizers**: Create, manage events, scan tickets, track analytics
- Seamless role switching from profile settings

### Smart Features
- **Time-Based Ticket Sales** - Automatically closes when event starts
- **Recommendation Engine** - Multi-factor scoring algorithm (no ML required)
- **Push Notification Strategy** - Comprehensive frequency management
- **Event Management** - Edit and delete with data integrity checks
- **QR Code System** - Generation, scanning, offline validation

### Uganda-Optimized
- **Local Payments** - MTN Mobile Money, Airtel Money, Card
- **Quiet Hours** - 10:00 PM - 7:00 AM EAT default
- **Cultural Awareness** - Sunday morning delays, Ramadan considerations
- **Offline-First** - QR codes work without internet

---

## Development Status

### ✅ Complete
- Dual role support (Attendee/Organizer)
- Authentication system (Email, Phone OTP, Social - mock)
- Event discovery with filters and recommendations
- Ticket purchasing (mock payment integration)
- QR code generation and scanning
- Event creation wizard (3 steps)
- Event management (edit & delete)
- Organizer dashboard and analytics
- Design system and theming
- Push notification strategy (documented)

### 🔄 Ready for Integration
- Backend API (protocols defined, mock implementations ready)
- Payment gateway (Flutterwave/Paystack integration guides ready)
- Real push notifications (FCM setup documented)
- Guest browsing mode (architecture complete)

---

## Test Users

### Attendees
| Email | Password | Description |
|-------|----------|-------------|
| john@example.com | password123 | Likes Music, Technology |
| jane@example.com | password123 | Likes Arts, Food |
| alice@example.com | password123 | Likes Sports, Fundraising |

### Organizers
| Email | Password | Description |
|-------|----------|-------------|
| bob@events.com | organizer123 | Has published events |
| sarah@events.com | organizer123 | New organizer |

### Phone OTP
- **Phone**: +256700123456 (or any valid format)
- **OTP Code**: 123456 (any 6-digit code works in mock mode)

---

## Requirements

- **macOS**: 13.0+ (Ventura or later)
- **Xcode**: 15.0+
- **iOS**: 16.0+ deployment target
- **Swift**: 5.9+

---

## License

This project is licensed under the MIT License.

---

## Contact

For questions, suggestions, or support:
- **Email**: support@eventpass.ug
- **Project Location**: /Users/lley-tonn/Documents/projects/EventPassUG-MobileApp

---

## Architecture Resources

The project includes comprehensive architecture documentation:

- **[EventPassUG/ARCHITECTURE.md](./EventPassUG/ARCHITECTURE.md)** - Complete architecture guide
- **[ARCHITECTURE_MAP.md](./ARCHITECTURE_MAP.md)** - Visual screen map & user flows
- **[EventPassUG/QUICK_REFERENCE.md](./EventPassUG/QUICK_REFERENCE.md)** - Developer cheat sheet
- **[EventPassUG/MIGRATION_GUIDE.md](./EventPassUG/MIGRATION_GUIDE.md)** - File mappings
- **[REFACTORING_SUMMARY.md](./REFACTORING_SUMMARY.md)** - Migration summary

---

**Built with ❤️ for Uganda's event community**

*Architecture Version: 2.0 | Last Updated: January 2026*

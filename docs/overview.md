# EventPassUG - Project Overview

## Purpose

EventPassUG is a complete, production-ready native iOS application designed for discovering and managing events across Uganda. The platform serves as a comprehensive event management solution that connects event organizers with attendees through a seamless mobile experience.

## Core Mission

To democratize event discovery and ticketing in Uganda by providing a platform-native iOS application that makes it easy for users to:
- **Discover** events happening in their area
- **Purchase** tickets securely with local payment methods
- **Organize** events with professional tools
- **Manage** attendees efficiently

## Target Audience

### Attendees
- Event enthusiasts looking for local experiences
- People wanting to discover concerts, festivals, fundraisers, sports events, and more
- Users seeking convenient mobile ticket purchasing with MTN Mobile Money and Airtel Money

### Organizers
- Event promoters and producers
- Community organizers
- Venue managers
- Anyone hosting ticketed events in Uganda

## Key Goals

### User Experience
- **Intuitive Discovery**: Browse events with intelligent recommendations and filtering
- **Seamless Transactions**: Purchase tickets in seconds with familiar payment methods
- **Offline-First**: QR codes work without internet connectivity
- **Guest Browsing**: Explore events without requiring an account
- **Accessibility**: Full VoiceOver support and Dynamic Type

### Technical Excellence
- **Production-Ready Architecture**: Feature-first clean architecture with MVVM
- **Native iOS Experience**: 100% SwiftUI targeting iOS 16+
- **Scalability**: Multi-platform ready (iOS, iPadOS, macOS, watchOS)
- **Testability**: Protocol-based dependency injection for comprehensive testing
- **Maintainability**: Clear separation of concerns and documentation

### Business Objectives
- Enable dual-role support (Attendee and Organizer modes)
- Support local payment methods (MTN Mobile Money, Airtel Money)
- Provide analytics and earnings tracking for organizers
- Enable time-based ticket sales (auto-close when event starts)
- Support event management (create, edit, delete functionality)

## Core Concepts

### Dual Role System
Users can seamlessly switch between two roles:
- **Attendee Mode**: Browse events, purchase tickets, manage favorites
- **Organizer Mode**: Create events, scan tickets, view analytics

### Event Lifecycle
Events progress through distinct states:
1. **Draft**: Organizer is creating/editing
2. **Published**: Live and discoverable, tickets on sale
3. **Ongoing**: Event is currently happening
4. **Completed**: Event has ended
5. **Cancelled**: Event was removed

### Ticket Management
- Multiple ticket types per event (e.g., General Admission, VIP)
- QR code generation for each ticket
- Ticket validation via QR scanning
- Time-based sales (automatically stop when event starts)

### Authentication System
- Multiple authentication methods:
  - Email/password with secure hashing
  - Phone OTP verification
  - Social login (Apple, Google, Facebook)
- Guest browsing mode (authentication required only for actions)
- Session persistence across app launches

### Design Philosophy

#### Platform-Native
- 100% SwiftUI for modern, declarative UI
- SF Pro typography system
- SF Symbols for icons
- Native iOS patterns (sheets, alerts, context menus)
- Dark/light mode support

#### Privacy-First
- Guest browsing without account creation
- Approximate location (city-level, not precise GPS)
- Optional permissions with graceful degradation
- Clear data usage explanations

#### Performance
- Smooth animations with haptic feedback
- Responsive layouts for all device sizes
- Efficient data caching
- Async/await for modern concurrency

## Technology Stack

### Frontend
- **SwiftUI**: 100% declarative UI framework
- **Combine**: Reactive data binding
- **async/await**: Modern concurrency patterns
- **MVVM**: Presentation architecture pattern

### Data & Storage
- **UserDefaults**: Test database (to be replaced with backend)
- **CoreData**: Local persistence infrastructure
- **Keychain**: Secure credential storage (future)

### Apple Frameworks
- **MapKit**: Venue location mapping
- **AVFoundation**: QR code scanning via camera
- **PhotosUI**: Image picker for posters
- **CoreImage**: QR code generation
- **CryptoKit**: SHA256 password hashing
- **EventKit**: Calendar integration
- **UserNotifications**: Push notifications

### Architecture
- **Feature-First Organization**: Related code grouped by feature
- **Clean Architecture**: Clear layer separation (App, Features, Domain, Data, UI, Core)
- **Repository Pattern**: Data access abstraction
- **Protocol-Oriented**: Dependency injection via protocols
- **Centralized Design System**: Consistent UI tokens

## Project Status

### Current State
- ✅ **Production-Ready Architecture**: Feature-first clean architecture implemented
- ✅ **Dual Role Support**: Complete attendee and organizer experiences
- ✅ **Authentication**: Multiple methods with test database
- ✅ **Event Discovery**: Category filters, search, recommendations
- ✅ **Ticket Purchasing**: Complete flow with mock payments
- ✅ **QR Code System**: Generation and scanning
- ✅ **Event Management**: Create, edit, delete functionality
- ✅ **Organizer Tools**: Dashboard, analytics, earnings tracking
- ✅ **Design System**: Centralized tokens and components
- ✅ **Recommendations**: Multi-factor scoring algorithm
- ✅ **Push Notifications**: Strategy defined, implementation ready

### What's Next
- Backend API integration (replace test database)
- Payment gateway integration (Flutterwave/Paystack)
- Real push notifications setup
- App Store submission
- Guest browsing mode completion

## Success Metrics

### User Engagement
- Time to first ticket purchase
- Event discovery conversion rate
- Repeat purchase rate
- Organizer retention

### Technical Performance
- App launch time < 2 seconds
- Ticket purchase completion < 30 seconds
- QR code scan time < 1 second
- App Store rating target: 4.5+

### Business Impact
- Number of active organizers
- Total tickets sold
- Transaction volume
- Platform revenue (commission)

## Differentiators

### Why EventPassUG Stands Out

**Local Payment Integration**
- Native support for MTN Mobile Money and Airtel Money
- Card payment option for international cards
- No complex banking setup required

**Offline-First QR Codes**
- Tickets work without internet
- Fast venue entry
- Wallet integration ready

**Guest Browsing**
- Explore without account
- Reduces friction for new users
- Authentication only when needed

**Dual-Role Platform**
- One app for attendees and organizers
- Seamless role switching
- Unified experience

**Production Architecture**
- Enterprise-grade code organization
- Comprehensive documentation
- Test coverage
- Multi-platform ready

## Development Philosophy

### Code Quality
- Clear naming conventions
- Comprehensive comments
- Protocol-oriented design
- Dependency injection
- No framework dependencies in domain layer

### Documentation
- README for quick start
- Architecture guides for deep dives
- Code comments for complex logic
- Migration guides for changes
- API documentation

### Testing
- Unit tests for ViewModels
- Repository mocking
- UI tests for critical flows
- Integration testing

### Scalability
- Feature modules can be extracted to packages
- Domain layer is platform-agnostic
- Clear boundaries for team ownership
- Ready for microservices architecture

## Getting Started

To start working with EventPassUG, see:
- [Installation Guide](./installation.md) - Setup and run instructions
- [Architecture Guide](./architecture.md) - System design and patterns
- [Features Documentation](./features.md) - Detailed feature descriptions
- [API Documentation](./api.md) - Backend integration guide
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions

## Contact

For questions, contributions, or support:
- **Email**: support@eventpass.ug
- **Project Repository**: /Users/lley-tonn/Documents/projects/EventPassUG-MobileApp

---

**Built with ❤️ for Uganda's event community**

*Last Updated: January 2026*

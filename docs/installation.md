# Installation Guide

## Prerequisites

### System Requirements
- **macOS**: 13.0+ (Ventura or later)
- **Xcode**: 15.0+
- **iOS Deployment Target**: 16.0+
- **Swift**: 5.9+

### Hardware Requirements
- Mac with Apple Silicon or Intel processor
- At least 8GB RAM (16GB recommended)
- 10GB free disk space for Xcode and build artifacts

### Developer Account
- Apple Developer account (free tier is sufficient for development)
- Provisioning profile for device testing (optional)

## Installation Steps

### 1. Clone or Navigate to Project

The project is located at:
```bash
/Users/lley-tonn/Documents/projects/EventPassUG-MobileApp
```

Navigate to the project directory:
```bash
cd /Users/lley-tonn/Documents/projects/EventPassUG-MobileApp
```

### 2. Open the Project

Open the Xcode project:
```bash
open EventPassUG.xcodeproj
```

Or double-click `EventPassUG.xcodeproj` in Finder.

### 3. Configure Signing & Capabilities

1. In Xcode, select the **EventPassUG** project in the navigator
2. Select the **EventPassUG** target
3. Go to the **Signing & Capabilities** tab
4. Select your **Team** from the dropdown
5. Xcode will automatically manage signing

**Note**: For development, the free Apple Developer tier is sufficient.

### 4. Select a Simulator or Device

In the Xcode toolbar:
- Click the device selector (near the Run button)
- Choose a simulator: **iPhone 15 Pro** (recommended) or any iOS 16+ device
- Or connect a physical device and select it

### 5. Build and Run

**Keyboard Shortcut**: Press `⌘ + R`

**Or**: Click the **Run** button (▶) in the Xcode toolbar

The app will:
1. Compile (first build takes 2-3 minutes)
2. Install on the selected device/simulator
3. Launch automatically
4. Display the onboarding flow

## Test Users

The app includes a production-grade test database with pre-seeded users. Use these credentials to test different roles and features.

### Attendee Test Users

| Email | Password | Description |
|-------|----------|-------------|
| john@example.com | password123 | Standard attendee, has liked events |
| jane@example.com | password123 | Standard attendee, has purchase history |
| alice@example.com | password123 | New attendee, no history |

**Test User Interests**:
- `john@example.com` - Likes Music, Technology events
- `jane@example.com` - Likes Arts & Culture, Food events
- `alice@example.com` - Likes Sports, Fundraising events

### Organizer Test Users

| Email | Password | Description |
|-------|----------|-------------|
| bob@events.com | organizer123 | Verified organizer, has published events |
| sarah@events.com | organizer123 | New organizer, no events yet |

### Phone Authentication

Phone OTP authentication works with any 6-digit code in mock mode:
- **Phone**: +256700123456 (or any valid format)
- **OTP Code**: 123456 (any 6-digit code works)

### Social Login

Social login buttons are available but use mock authentication in development:
- **Apple Sign In**: Mock user creation
- **Google Sign In**: Mock user creation
- **Facebook Sign In**: Mock user creation

### Creating New Accounts

You can create new test accounts directly in the app:
1. Launch the app
2. On the auth screen, tap **Register**
3. Fill in the form:
   - Name, email, password
   - Select role (Attendee or Organizer)
4. Tap **Sign Up**
5. Account is created immediately in the test database

## First Run Experience

### Onboarding Flow

On first launch, you'll see:

1. **App Introduction Slides** (3 screens)
   - Slide 1: "Find the Hottest Events"
   - Slide 2: "Buy Tickets in Seconds"
   - Slide 3: "Host Events Like a Pro"

2. **Authentication Choice Screen**
   - **Login**: For existing users
   - **Become an Organizer**: Direct organizer signup
   - **Continue as Guest**: Browse without account

3. **Main App**
   - Attendee mode: Home, Tickets, Profile tabs
   - Organizer mode: Dashboard, Analytics, Profile tabs

### Exploring as Attendee

After logging in as an attendee:

```
Home Tab:
├─ Browse events with filters
├─ Search events
├─ View event details
├─ Like/favorite events
└─ Purchase tickets

Tickets Tab:
├─ View purchased tickets
├─ Display QR codes
└─ Filter by status

Profile Tab:
├─ Edit profile
├─ Notification settings
├─ Switch to Organizer mode
└─ Support center
```

**Test Features**:
- Browse events with category filters (Music, Sports, Arts, etc.)
- Search for events by name or location
- Tap heart icon to favorite events
- View event details with map
- Purchase tickets (mock payment)
- View QR codes in Tickets tab

### Exploring as Organizer

After logging in as an organizer:

```
Dashboard Tab:
├─ View analytics (revenue, tickets sold)
├─ Create new events
├─ Manage existing events
└─ View earnings

Analytics Tab:
├─ Event performance metrics
├─ Ticket sales trends
└─ Revenue breakdown

Profile Tab:
├─ Edit organizer profile
├─ Verify identity
├─ Payout setup
└─ Switch to Attendee mode
```

**Test Features**:
- Create an event (3-step wizard)
- Edit existing events (long-press context menu)
- Delete events (confirmation required)
- Scan QR codes (requires camera on physical device)
- View analytics dashboard
- Manage ticket types

## Running Tests

### Unit Tests

Run unit tests from Xcode:
```bash
# Command line
xcodebuild test -scheme EventPassUG -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or in Xcode: Press ⌘ + U
```

**Test Coverage**:
- Date formatting utilities
- Greeting logic (time-based)
- Event category filtering
- "Happening now" detection
- Price range calculation

### Manual Testing Checklist

#### Authentication
- [ ] Login with test user credentials
- [ ] Register new account
- [ ] Phone OTP authentication
- [ ] Social login (mock)
- [ ] Logout and re-login
- [ ] Session persistence after app restart

#### Event Discovery (Attendee)
- [ ] Browse events on home screen
- [ ] Filter by category
- [ ] Search events by name
- [ ] View event details
- [ ] Like/unlike events
- [ ] View favorite events
- [ ] Navigate to event location on map

#### Ticket Purchase
- [ ] Select ticket type
- [ ] Choose quantity
- [ ] Select payment method
- [ ] Complete mock payment
- [ ] View success screen with QR code
- [ ] Find ticket in Tickets tab
- [ ] View ticket details

#### Event Management (Organizer)
- [ ] Create new event (complete wizard)
- [ ] Edit existing event
- [ ] Delete event
- [ ] View event analytics
- [ ] Manage ticket types
- [ ] Save draft event

#### Role Switching
- [ ] Switch from Attendee to Organizer
- [ ] Switch from Organizer to Attendee
- [ ] Verify tab bar updates
- [ ] Verify features are role-appropriate

## Device Support

### iPhone
- **Minimum**: iPhone SE (2nd generation) running iOS 16.0
- **Recommended**: iPhone 12 or later
- **Optimal**: iPhone 15 Pro (latest features)

### iPad
- All iPads supporting iOS 16.0+
- Optimized layouts for larger screens
- Split-view support

### Simulator Testing

**Recommended Simulators**:
- iPhone 15 Pro (iOS 17.0) - Default
- iPhone 14 (iOS 16.0) - Minimum version testing
- iPad Pro 12.9" - Tablet experience
- iPhone SE (3rd generation) - Small screen testing

## Permissions

The app requests the following permissions (configured in `Info.plist`):

### Required Permissions

| Permission | Purpose | When Requested |
|------------|---------|----------------|
| **Camera** | QR code scanning for ticket validation | First QR scan (organizers) |
| **Photo Library** | Selecting event posters | Creating/editing event |

### Optional Permissions

| Permission | Purpose | When Requested |
|------------|---------|----------------|
| **Notifications** | Event reminders and updates | During onboarding or settings |
| **Location** | Showing nearby events | During onboarding or first use |
| **Calendar** | Adding events to calendar | First "Add to Calendar" action |

**Note**: All permissions are optional. The app works without them, but with reduced functionality.

### Simulator Limitations

- **Camera**: Not available in simulator (use physical device for QR scanning)
- **Location**: Can be simulated via Xcode Debug menu
- **Notifications**: Limited functionality in simulator
- **Biometrics**: Not available (Face ID/Touch ID)

## Troubleshooting Installation

### Xcode Build Errors

**"No such module 'MapKit'"**
```bash
Solution:
- Clean build folder: ⌘ + Shift + K
- Rebuild: ⌘ + B
```

**"Cannot find type 'Event' in scope"**
```bash
Solution:
- Ensure all files are added to target
- File Inspector → Target Membership → Check EventPassUG
```

**Asset Catalog Compilation Failed**
```bash
Solution:
rm -rf ~/Library/Developer/Xcode/DerivedData/EventPassUG-*
# Then rebuild in Xcode
```

**File References Missing (Red files)**
```bash
Solution:
This may occur after architecture refactoring.
1. Close Xcode
2. Open EventPassUG.xcodeproj
3. Delete missing file references (red items)
4. Right-click on EventPassUG group
5. "Add Files to EventPassUG..."
6. Select Features/, Domain/, Data/, UI/, Core/ folders
7. Check "Create groups"
8. Click Add
```

### Runtime Issues

**Camera not working**
- Camera is not available in iOS Simulator
- Test QR scanning on a physical device

**Test users not appearing**
```bash
Solution:
- Delete app from device/simulator
- Reinstall (database reseeds automatically)
```

**QR codes not rendering**
- Ensure CoreImage framework is linked
- Build Phases → Link Binary With Libraries → Add CoreImage.framework

## Development Setup

### Recommended Xcode Settings

**Editor**:
- Enable line numbers: Xcode → Settings → Text Editing → Line Numbers
- Show invisible characters: Editor → Invisibles → Show All
- Tab width: 4 spaces, indent using spaces

**Build Settings**:
- Swift Compiler - Code Generation
  - Optimization Level: Debug: -Onone, Release: -O
- Swift Compiler - Language
  - Swift Language Version: Swift 5

### Git Configuration (if using version control)

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### Optional: Fastlane Setup (for CI/CD)

Fastlane files are not included by default. To set up:
```bash
cd /Users/lley-tonn/Documents/projects/EventPassUG-MobileApp
bundle init
bundle add fastlane
bundle exec fastlane init
```

## Next Steps

After successful installation:

1. **Read the Architecture Guide**: [architecture.md](./architecture.md)
2. **Explore Features**: [features.md](./features.md)
3. **Review API Documentation**: [api.md](./api.md)
4. **Backend Integration**: Replace test database with real API
5. **Payment Integration**: Integrate Flutterwave or Paystack

## Getting Help

If you encounter issues:

1. Check [troubleshooting.md](./troubleshooting.md)
2. Review Xcode console for error messages
3. Check file paths and target membership
4. Clean build folder and rebuild
5. Restart Xcode

---

**Installation Version**: 2.0
**Last Updated**: January 2026
**Xcode Compatibility**: 15.0+
**iOS Version**: 16.0+

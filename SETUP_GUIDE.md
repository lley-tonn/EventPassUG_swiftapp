# EventPass UG - Quick Setup Guide

Get the app running in **5 minutes**! ⚡

## Prerequisites
- macOS 13.0+
- Xcode 15.0+
- iOS 16.0+ device or simulator

## Quick Start

### 1. Create Xcode Project

Since this is source code only, you need to create an Xcode project first:

```bash
# Open Xcode
# File → New → Project
# Choose: iOS → App
# Fill in:
#   - Product Name: EventPassUG
#   - Team: Your Team
#   - Organization Identifier: com.eventpass
#   - Interface: SwiftUI
#   - Language: Swift
#   - Use Core Data: ✅ (checked)
#   - Include Tests: ✅ (checked)
```

### 2. Add Source Files

1. Delete the default `ContentView.swift` and `EventPassUGApp.swift` created by Xcode
2. Drag the entire `EventPassUG/` folder from this repository into your Xcode project
3. When prompted, choose:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to target: EventPassUG

### 3. Configure Build Settings

#### Target Settings
- **Deployment Target**: iOS 16.0
- **Bundle Identifier**: com.eventpass.ug
- **Display Name**: EventPass UG

#### Capabilities
Enable the following capabilities (select target → Signing & Capabilities → + Capability):
- ❌ Push Notifications (optional - for later)
- ❌ Wallet (optional - requires Apple Developer Program)

#### Info.plist
Replace the default Info.plist with the one provided in this repository.

### 4. Build and Run

1. Select target: **EventPassUG**
2. Select device: **iPhone 15 Pro** (simulator) or your physical device
3. Press **⌘ + B** to build
4. Press **⌘ + R** to run

### 5. Test the App

**Sign Up Flow:**
1. Enter any email (e.g., `john@example.com`)
2. Enter any password (min 6 characters)
3. Enter first name: `John`
4. Enter last name: `Doe`
5. Choose role: **Attendee** or **Organizer**
6. Tap **Get Started**

**Explore as Attendee:**
- Browse events on Home tab
- Tap category chips to filter
- Tap event card → View details
- Tap a ticket type → Buy Ticket
- Choose payment method → Pay
- View QR code in Tickets tab

**Explore as Organizer:**
- Switch role from Profile tab
- Tap + button to create event
- Fill 3-step wizard
- Publish event
- View analytics in Dashboard tab
- Tap "Scan Ticket" to test QR scanner

---

## Troubleshooting

### Build Error: "No such module 'MapKit'"
**Solution:** MapKit is a system framework. Clean build folder (⌘ + Shift + K) and rebuild.

### Build Error: "Cannot find type 'Event' in scope"
**Solution:** Ensure all `.swift` files are added to the target. Select each file → File Inspector → Target Membership → Check EventPassUG.

### Runtime Error: "Core Data model not found"
**Solution:** Ensure `EventPassUG.xcdatamodeld` is added to target and Copy Bundle Resources phase.

### Camera Not Working
**Solution:** Test on a physical device. Simulator doesn't support camera capture.

### App Crashes on Launch
**Solution:** Check Console for errors. Most likely cause: Info.plist not properly configured.

---

## Next Steps

Once the app is running:

1. **Read README.md** - Complete documentation
2. **Explore the code** - Well-commented and organized
3. **Run unit tests** - ⌘ + U
4. **Customize branding** - Update colors in Assets.xcassets
5. **Add backend** - Follow "Backend Integration" section in README

---

## File Structure Reference

```
EventPassUG.xcodeproj/          # Create this in Xcode
EventPassUG/
  ├── EventPassUGApp.swift      # ✅ Main entry point
  ├── ContentView.swift          # ✅ Root navigation
  ├── Info.plist                 # ✅ Permissions & config
  │
  ├── Models/                    # ✅ 6 model files
  ├── Services/                  # ✅ 5 service files
  ├── Views/                     # ✅ 20+ view files
  ├── Config/                    # ✅ Theme configuration
  ├── Utilities/                 # ✅ Helper functions
  ├── CoreData/                  # ✅ Persistence layer
  └── Assets.xcassets/           # ✅ Images & colors
```

---

## Quick Commands

```bash
# Build from command line
xcodebuild -scheme EventPassUG -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -scheme EventPassUG -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Clean build
xcodebuild clean -scheme EventPassUG

# Archive for distribution
xcodebuild archive -scheme EventPassUG -archivePath ./build/EventPassUG.xcarchive
```

---

## Support

Need help? Check:
- 📖 [Full README](README.md) - Comprehensive documentation
- 🐛 [GitHub Issues](https://github.com/yourusername/EventPassUG-MobileApp/issues)
- 💬 [Discussions](https://github.com/yourusername/EventPassUG-MobileApp/discussions)

---

**Happy Coding! 🎉**

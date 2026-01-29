# Troubleshooting Guide

## Overview

This guide covers common issues, solutions, testing procedures, and debugging techniques for EventPassUG development.

---

## Table of Contents

1. [Build Errors](#build-errors)
2. [Runtime Issues](#runtime-issues)
3. [Testing](#testing)
4. [Common Problems](#common-problems)
5. [Debugging Techniques](#debugging-techniques)
6. [Performance Issues](#performance-issues)

---

## Build Errors

### "No such module 'MapKit'"

**Symptoms**: Import statement fails, module not found

**Solution**:
```bash
# Clean build folder
⌘ + Shift + K

# Rebuild
⌘ + B
```

**If problem persists**:
1. Quit Xcode
2. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/EventPassUG-*
   ```
3. Reopen project and rebuild

---

### "Cannot find type 'Event' in scope"

**Symptoms**: Domain models not found, type errors

**Solution**:
1. Check file is added to target
2. File Inspector → Target Membership → Check "EventPassUG"
3. Ensure file is in correct location (`Domain/Models/`)

**Verification**:
```bash
# Check if file is in project
find EventPassUG -name "Event.swift"
```

---

### Asset Catalog Compilation Failed

**Symptoms**: Build fails with asset errors, corrupted Assets.xcassets

**Solution**:
```bash
# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/EventPassUG-*

# Clean build folder in Xcode
⌘ + Shift + K

# Rebuild
⌘ + B
```

**If assets are corrupted**:
1. Check `Resources/Assets.xcassets` in Finder
2. Ensure all image sets are valid
3. Remove and re-add problematic assets

---

### File References Missing (Red Files)

**Symptoms**: Files shown in red in Project Navigator, "file not found" errors

**Cause**: Usually occurs after architecture refactoring or moving files

**Solution 1: Re-add Files**:
1. Close Xcode
2. Open `EventPassUG.xcodeproj`
3. Delete missing file references (red items)
4. Right-click on `EventPassUG` group
5. Select "Add Files to EventPassUG..."
6. Select folders: `Features/`, `Domain/`, `Data/`, `UI/`, `Core/`
7. Check "Create groups" (not "Create folder references")
8. Click "Add"
9. Rebuild (⌘ + B)

**Solution 2: Automatic Fix (Advanced)**:
```bash
# Close Xcode first
cd /Users/lley-tonn/Documents/projects/EventPassUG-MobileApp

# Find all Swift files
find EventPassUG -name "*.swift" -type f | while read file; do
    xcodebuild -project EventPassUG.xcodeproj -target EventPassUG -add "$file" 2>/dev/null
done
```

---

### Swift Compiler Errors

**"Ambiguous use of..."**

**Solution**: Specify type explicitly
```swift
// Before
let date = Date()

// After
let date: Date = Date()
```

**"Cannot convert value of type..."**

**Solution**: Check type compatibility, add explicit casting
```swift
// Ensure types match
let userId: UUID = user.id
let userIdString: String = userId.uuidString
```

---

## Runtime Issues

### Camera Not Working

**Symptoms**: Camera doesn't open, black screen in QR scanner

**Cause**: iOS Simulator doesn't support camera

**Solution**:
- Test on physical device
- Simulator doesn't support AVFoundation camera capture

**Workaround for Development**:
```swift
#if targetEnvironment(simulator)
// Use mock QR code scanner
#else
// Use real camera
#endif
```

---

### QR Codes Not Rendering

**Symptoms**: QR code view is blank, no image displayed

**Solution 1: Check CoreImage Framework**:
1. Project Navigator → EventPassUG target
2. Build Phases → Link Binary With Libraries
3. Click "+" → Add `CoreImage.framework`

**Solution 2: Verify QR Generation**:
```swift
// Check if QR code data is valid
let qrCode = QRCodeGenerator.generate(from: ticketId)
print("QR Code generated: \(qrCode != nil)")
```

**Solution 3: Check Image View**:
```swift
// Ensure proper sizing
Image(uiImage: qrCode)
    .resizable()
    .interpolation(.none) // Important for QR codes
    .frame(width: 200, height: 200)
```

---

### Test Users Not Appearing

**Symptoms**: Pre-seeded test users don't exist, login fails

**Cause**: Test database not initialized or corrupted

**Solution**:
```bash
# Delete app from device/simulator
# Long press app icon → Remove App

# Reinstall from Xcode
⌘ + R
```

**Manual Reset**:
```swift
// In TestDatabase.swift, force reseed
TestDatabase.shared.resetDatabase()
```

---

### App Crashes on Launch

**Symptoms**: App opens then immediately crashes

**Debugging Steps**:

1. **Check Console**:
   - Open Console.app (macOS)
   - Filter for "EventPassUG"
   - Look for crash logs

2. **Check Xcode Debugger**:
   ```
   Debug Navigator → Select crash
   View stack trace
   ```

3. **Common Causes**:
   - Missing required assets
   - Corrupt UserDefaults
   - Unhandled exceptions in initialization

**Solution**:
```bash
# Reset simulator
xcrun simctl erase all

# Or reset specific simulator
xcrun simctl erase "iPhone 15 Pro"
```

---

### Navigation Not Working

**Symptoms**: Tapping buttons doesn't navigate, sheets don't appear

**Cause**: Missing NavigationStack or incorrect navigation setup

**Solution**:
```swift
// Ensure views are wrapped in NavigationStack
NavigationStack {
    YourView()
}

// For sheets
.sheet(isPresented: $showSheet) {
    SheetContentView()
}
```

---

### Data Not Persisting

**Symptoms**: User data lost after app restart, settings reset

**Cause**: UserDefaults not saving, incorrect keys

**Solution**:
```swift
// Ensure proper save
UserDefaults.standard.set(value, forKey: "key")
UserDefaults.standard.synchronize() // Force save

// Verify key names match
let storedValue = UserDefaults.standard.object(forKey: "key")
print("Stored value: \(storedValue)")
```

---

## Testing

### Running Unit Tests

**Command Line**:
```bash
xcodebuild test \
    -scheme EventPassUG \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

**Xcode**:
- Press `⌘ + U`
- Or Test Navigator → Click diamond icon

---

### Test Coverage

**Current Tests**:
- ✅ Date formatting utilities
- ✅ Greeting logic (time-based)
- ✅ Event category filtering
- ✅ "Happening now" detection
- ✅ Price range calculation

**Running Specific Tests**:
```bash
# Run specific test class
xcodebuild test \
    -scheme EventPassUG \
    -only-testing:EventPassUGTests/DateUtilitiesTests

# Run specific test method
xcodebuild test \
    -scheme EventPassUG \
    -only-testing:EventPassUGTests/DateUtilitiesTests/testDateFormatting
```

---

### Writing New Tests

**ViewMo del Tests**:
```swift
import XCTest
@testable import EventPassUG

@MainActor
class AttendeeHomeViewModelTests: XCTestCase {
    var viewModel: AttendeeHomeViewModel!
    var mockRepository: MockEventRepository!

    override func setUp() {
        mockRepository = MockEventRepository()
        viewModel = AttendeeHomeViewModel(repository: mockRepository)
    }

    func testLoadEvents() async throws {
        // Arrange
        mockRepository.mockEvents = [testEvent1, testEvent2]

        // Act
        await viewModel.loadEvents()

        // Assert
        XCTAssertEqual(viewModel.events.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

**Repository Tests**:
```swift
class EventRepositoryTests: XCTestCase {
    var repository: EventRepository!

    override func setUp() {
        repository = EventRepository()
    }

    func testFetchEvents() async throws {
        let events = try await repository.fetchEvents()
        XCTAssertFalse(events.isEmpty)
    }
}
```

---

### UI Tests

**Setup**:
```swift
import XCTest

class EventPassUGUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testLoginFlow() {
        // Tap login tab
        app.buttons["Login"].tap()

        // Enter credentials
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("john@example.com")

        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")

        // Submit
        app.buttons["Sign In"].tap()

        // Verify logged in
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    }
}
```

---

## Common Problems

### Slow Build Times

**Cause**: Large project, incremental builds not working

**Solutions**:

1. **Clean Build Folder**:
   ```bash
   ⌘ + Shift + K
   ```

2. **Delete DerivedData**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. **Enable Parallel Building**:
   - Xcode → Settings → Locations → Derived Data → Advanced
   - Choose "Unique"

4. **Optimize Compilation**:
   - Build Settings → Swift Compiler - Code Generation
   - Optimization Level: Debug: -Onone, Release: -O

---

### Memory Issues

**Symptoms**: App crashes with memory warnings, sluggish performance

**Debugging**:
1. Run with Instruments (⌘ + I)
2. Select "Allocations" or "Leaks"
3. Identify memory hotspots

**Common Causes**:
- Retain cycles in closures
- Large images not released
- Observers not removed

**Solutions**:
```swift
// Use [weak self] in closures
viewModel.fetchData { [weak self] result in
    self?.updateUI(result)
}

// Release large objects
defer {
    largeImage = nil
}

// Remove observers
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

---

### Dark Mode Issues

**Symptoms**: UI elements not visible in dark mode

**Solution**:
```swift
// Use semantic colors
.foregroundColor(.primary) // Adapts to dark mode
.background(.background)

// Or use AppDesign tokens
.foregroundColor(AppDesign.Colors.textPrimary)
```

---

### Localization Not Working

**Symptoms**: Text not translating, wrong language displayed

**Solution**:
1. Check Localizable.strings exists
2. Verify language in scheme settings
3. Use NSLocalizedString:
   ```swift
   Text(NSLocalizedString("key", comment: ""))
   ```

---

## Debugging Techniques

### Print Debugging

```swift
// View lifecycle
struct MyView: View {
    var body: some View {
        Text("Hello")
            .onAppear { print("View appeared") }
            .onDisappear { print("View disappeared") }
    }
}

// ViewModel state
@Published var events: [Event] = [] {
    didSet {
        print("Events updated: \(events.count) items")
    }
}
```

---

### Breakpoints

**Set Breakpoint**: Click line number in Xcode
**Conditional Breakpoint**: Right-click breakpoint → Edit Breakpoint
**Symbolic Breakpoint**: Debug → Breakpoints → Create Symbolic Breakpoint

**Useful Symbolic Breakpoints**:
- `UIViewAlertForUnsatisfiableConstraints` - Layout issues
- `objc_exception_throw` - Objective-C exceptions

---

### LLDB Commands

```bash
# Print variable
(lldb) po events

# Print type
(lldb) expr type(of: user)

# Continue execution
(lldb) c

# Step over
(lldb) n

# Step into
(lldb) s

# Print all local variables
(lldb) frame variable
```

---

### View Hierarchy Debugging

**Enable**:
1. Run app
2. Debug → View Debugging → Capture View Hierarchy
3. Inspect 3D view of UI

**Use Cases**:
- Find hidden views
- Identify layout issues
- Inspect view properties

---

### Network Debugging

**Enable Network Logging**:
```swift
class DebugAPIClient: APIClient {
    override func request<T>(_ endpoint: Endpoint) async throws -> T {
        print("📤 Request: \(endpoint.path)")
        print("Method: \(endpoint.method)")

        let result = try await super.request(endpoint)

        print("📥 Response: \(result)")

        return result
    }
}
```

**Use Charles Proxy**:
1. Install Charles (https://www.charlesproxy.com)
2. Configure iOS device to use proxy
3. Install SSL certificate
4. Monitor all network traffic

---

## Performance Issues

### SwiftUI Performance

**Symptoms**: Laggy scrolling, slow animations

**Solutions**:

1. **Use .id() for List Updates**:
   ```swift
   List(events, id: \.id) { event in
       EventCard(event: event)
   }
   ```

2. **Avoid Heavy Computation in Body**:
   ```swift
   // ❌ Bad
   var body: some View {
       let processedData = heavyComputation()
       Text(processedData)
   }

   // ✅ Good
   var processedData: String {
       heavyComputation()
   }

   var body: some View {
       Text(processedData)
   }
   ```

3. **Use @StateObject for ViewModels**:
   ```swift
   // ✅ Correct
   @StateObject private var viewModel = MyViewModel()

   // ❌ Wrong (recreates on every render)
   @ObservedObject private var viewModel = MyViewModel()
   ```

---

### Image Loading

**Symptoms**: Slow image loading, memory spikes

**Solutions**:

1. **Downscale Images**:
   ```swift
   func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
       UIGraphicsImageRenderer(size: size).image { _ in
           image.draw(in: CGRect(origin: .zero, size: size))
       }
   }
   ```

2. **Use AsyncImage**:
   ```swift
   AsyncImage(url: posterURL) { image in
       image.resizable()
   } placeholder: {
       ProgressView()
   }
   ```

3. **Cache Images**:
   ```swift
   class ImageCache {
       static let shared = ImageCache()
       private var cache = NSCache<NSString, UIImage>()

       func get(_ key: String) -> UIImage? {
           cache.object(forKey: key as NSString)
       }

       func set(_ image: UIImage, for key: String) {
           cache.setObject(image, forKey: key as NSString)
       }
   }
   ```

---

## Device-Specific Issues

### iPhone SE (Small Screen)

**Issue**: UI cutoff, overlapping elements

**Solution**:
```swift
// Use responsive sizing
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var spacing: CGFloat {
    horizontalSizeClass == .compact ? 8 : 16
}
```

---

### iPad Issues

**Issue**: Layout doesn't adapt to larger screen

**Solution**:
```swift
// Use adaptive layouts
if UIDevice.current.userInterfaceIdiom == .pad {
    // iPad-specific layout
} else {
    // iPhone layout
}
```

---

## Getting Help

### Resources

1. **Project Documentation**:
   - [Overview](./overview.md)
   - [Installation](./installation.md)
   - [Architecture](./architecture.md)
   - [Features](./features.md)
   - [API](./api.md)

2. **Apple Documentation**:
   - [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
   - [Swift Language Guide](https://docs.swift.org/swift-book/)

3. **Community**:
   - Stack Overflow (tag: swiftui)
   - Swift Forums
   - r/iOSProgramming

### Reporting Bugs

When reporting bugs, include:
- Xcode version
- iOS version (simulator or device)
- Steps to reproduce
- Expected vs actual behavior
- Console logs
- Screenshots/screen recordings

---

## Checklist: Before Asking for Help

- [ ] Clean build folder (⌘ + Shift + K)
- [ ] Delete DerivedData
- [ ] Restart Xcode
- [ ] Check console for errors
- [ ] Review this troubleshooting guide
- [ ] Search for similar issues online
- [ ] Verify file target membership
- [ ] Check all dependencies are linked
- [ ] Test on different simulator/device
- [ ] Review recent code changes

---

**Troubleshooting Guide Version**: 2.0
**Last Updated**: January 2026
**Coverage**: Build, Runtime, Testing, Performance

# UI Components Catalog

## Overview

EventPassUG includes a comprehensive library of reusable UI components built with SwiftUI. All components follow the app's design system (`AppDesignSystem.swift`) and support accessibility features, animations, and dark mode.

**Location**: `/EventPassUG/UI/Components/`

---

## Table of Contents

1. [AnimatedLikeButton](#animatedlikebutton)
2. [AuthPromptSheet](#authpromptsheet)
3. [CategoryTile](#categorytile)
4. [DashboardComponents](#dashboardcomponents)
5. [EventCard](#eventcard)
6. [HeaderBar](#headerbar)
7. [LoadingView](#loadingview)
8. [NotificationBadge](#notificationbadge)
9. [PosterView](#posterview)
10. [ProfileHeaderView](#profileheaderview)
11. [PulsingDot](#pulsingdot)
12. [QRCodeView](#qrcodeview)
13. [SalesCountdownTimer](#salescountdowntimer)
14. [UIComponents (Reusable Kit)](#uicomponents-reusable-kit)
15. [VerificationRequiredOverlay](#verificationrequiredoverlay)

---

## AnimatedLikeButton

**File**: `AnimatedLikeButton.swift`

### Description

Animated heart button with spring animation and haptic feedback. Changes between heart (unliked) and heart.fill (liked) states with a smooth scale animation.

### Features

- Spring animation with bounce effect
- Haptic feedback on tap
- Accessibility support (reduce motion)
- Color changes from gray to red when liked
- Clear accessibility labels

### Usage

```swift
AnimatedLikeButton(isLiked: $isLiked) {
    // Handle like/unlike action
    eventViewModel.toggleLike(event.id)
}
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `isLiked` | `Binding<Bool>` | Current like state |
| `onTap` | `() -> Void` | Callback when button is tapped |

### Accessibility

- Label: "Like" / "Unlike" based on state
- Respects `accessibilityReduceMotion` setting
- Minimum touch target size met

---

## AuthPromptSheet

**File**: `AuthPromptSheet.swift`

### Description

Modal sheet shown to guest users when they attempt restricted actions (like, favorite, purchase, follow, etc.). Provides contextual benefits and quick access to authentication flow.

### Features

- Contextual messaging based on action (like, follow, purchase, rate)
- Dynamic benefit list tailored to the action
- Primary and secondary CTA buttons
- Automatic benefit text generation
- Handles post-authentication callback
- Smooth sheet presentation with delays

### Usage

```swift
.sheet(isPresented: $showingAuthPrompt) {
    AuthPromptSheet(
        reason: "to save favorites",
        icon: "heart.fill",
        onAuthSuccess: {
            // Execute pending action after auth
            favoriteManager.addFavorite(event.id)
        },
        isPresented: $showingAuthPrompt
    )
    .environmentObject(authService)
}
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `reason` | `String` | Why authentication is needed (e.g., "to save favorites") |
| `icon` | `String` | SF Symbol name for the icon |
| `onAuthSuccess` | `(() -> Void)?` | Optional callback after successful auth |
| `isPresented` | `Binding<Bool>` | Controls sheet presentation |

### Contextual Benefits

The component automatically generates 3 contextual benefits based on the `reason` string:

- **Like/Favorite**: Save and sync favorites, personalized recommendations, never miss events
- **Follow**: Get notified, discover similar organizers, build personalized feed
- **Purchase**: Secure checkout, QR codes and Wallet integration, track all tickets
- **Rate**: Share experience, help others discover events, build event history

### Visual Design

- Large circular icon with gradient background
- Title and subtitle explaining the requirement
- Three checkmark benefits in a VStack
- Primary button (Sign In) with gradient
- Secondary button (Create Account) with outline

---

## CategoryTile

**File**: `CategoryTile.swift`

### Description

Circular category filter chip with icon and label. Used for horizontal scrolling category selectors and time filters (Today, This week, etc.).

### Features

- Circular icon button with background
- Selected/unselected states
- Haptic feedback on selection
- Multi-line text support
- Accessibility traits for selected state

### Usage

```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: AppSpacing.md) {
        CategoryTile(
            title: "Today",
            icon: "calendar",
            isSelected: selectedCategory == "today",
            onTap: { selectedCategory = "today" }
        )

        CategoryTile(
            title: "Music",
            icon: "music.note",
            isSelected: selectedCategory == "music",
            onTap: { selectedCategory = "music" }
        )
    }
    .padding()
}
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | `String` | Category label (max 2 lines) |
| `icon` | `String` | SF Symbol name |
| `isSelected` | `Bool` | Selection state |
| `onTap` | `() -> Void` | Callback when tapped |

### Visual States

**Unselected**:
- Gray circular background
- Primary icon color
- Primary text color

**Selected**:
- Primary color circular background
- White icon
- Primary text color

---

## DashboardComponents

**File**: `DashboardComponents.swift`

### Description

Collection of compact dashboard components for organizer views, optimized for information density and readability.

### Components Included

#### 1. CompactMetricCard

Displays a single metric with icon, value, and label.

**Usage**:
```swift
CompactMetricCard(
    title: "Total Revenue",
    value: "UGX 5.2M",
    icon: "dollarsign.circle.fill",
    color: .green
)
```

**Features**:
- Circular icon with colored background
- Large bold value text
- Secondary label text
- Auto-scaling text for small screens
- Subtle shadow

#### 2. ProgressBarView

Horizontal progress bar with label, current/total counts, and percentage.

**Usage**:
```swift
ProgressBarView(
    label: "Tickets Sold",
    current: 320,
    total: 500,
    color: AppDesign.Colors.primary,
    showPercentage: true
)
```

**Features**:
- Animated progress fill
- Current/total display
- Optional percentage
- Customizable colors
- 6pt height progress bar

#### 3. CurrencyProgressBarView

Progress bar specifically for currency/revenue tracking with formatted values.

**Usage**:
```swift
CurrencyProgressBarView(
    label: "Revenue",
    current: 3_200_000,
    total: 5_000_000,
    currency: "UGX",
    color: .green
)
```

**Features**:
- Automatic value formatting (K, M suffixes)
- Currency prefix
- Percentage display
- Animated progress

**Formatting Examples**:
- 1,500 → "1.5K"
- 2,500,000 → "2.5M"
- 500 → "500"

#### 4. EventDashboardCard

Complete event card with title, date, status badge, tickets sold progress, and revenue progress.

**Usage**:
```swift
EventDashboardCard(event: event)
```

**Features**:
- Event title (2-line max)
- Date display
- Status badge (Published, Ongoing, Draft, Completed, Cancelled)
- Ticket sales progress bar
- Revenue progress bar
- Automatic calculations

---

## EventCard

**File**: `EventCard.swift`

### Description

Primary event display card with poster image, event details, like button, and "Happening now" indicator.

### Features

- Event poster with fallback placeholder
- "Happening now" badge with pulsing dot
- Share button overlay
- Like button with animation
- Event title (2-line truncation)
- Date, venue, price, and rating display
- Shadow and corner radius
- Accessibility labels

### Usage

```swift
EventCard(
    event: event,
    isLiked: favoriteManager.isLiked(event.id),
    onLikeTap: {
        favoriteManager.toggleLike(event.id)
    },
    onCardTap: {
        selectedEvent = event
    },
    onShareTap: {
        shareEvent(event)
    }
)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `event` | `Event` | Event model to display |
| `isLiked` | `Bool` | Current like state |
| `onLikeTap` | `() -> Void` | Callback for like button |
| `onCardTap` | `() -> Void` | Callback for card tap |
| `onShareTap` | `(() -> Void)?` | Optional share callback |

### Layout

**Poster Section** (200pt height):
- Event poster or placeholder
- "Happening now" badge (top-left)
- Share button (top-right)

**Details Section**:
- Title + Like button row
- Calendar icon + Date/time
- Location icon + Venue name
- Price + Star rating

### Visual Features

- Rounded top corners for poster
- Minimum scale factor for text (handles long text)
- Shadow for depth
- Accessibility-optimized touch targets

---

## HeaderBar

**File**: `HeaderBar.swift`

### Description

Reusable header bar with date, personalized greeting, and notification badge. Used at the top of home screens.

### Features

- Current date display
- Time-based greeting (Good morning, afternoon, evening)
- User's first name
- Notification badge with count
- Haptic feedback on bell tap

### Usage

```swift
HeaderBar(
    firstName: user.firstName,
    notificationCount: notificationManager.unreadCount,
    onNotificationTap: {
        showingNotifications = true
    }
)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `firstName` | `String` | User's first name for greeting |
| `notificationCount` | `Int` | Unread notification count |
| `onNotificationTap` | `() -> Void` | Callback when bell is tapped |

### Greeting Logic

Uses `DateUtilities.getGreeting()`:
- 5:00 - 11:59 AM: "Good morning"
- 12:00 - 17:59 PM: "Good afternoon"
- 18:00 - 4:59 AM: "Good evening"

### Date Format

Uses `DateUtilities.formatHeaderDate()`:
- Example: "Monday, January 29"

---

## LoadingView

**File**: `LoadingView.swift`

### Description

Loading indicators including standard spinner and skeleton screens for event cards.

### Components

#### 1. LoadingView

Standard centered loading spinner with message.

**Usage**:
```swift
if viewModel.isLoading {
    LoadingView()
}
```

**Features**:
- Scaled progress view (1.5x)
- "Loading..." text
- Full screen coverage

#### 2. SkeletonEventCard

Animated skeleton placeholder for event cards during loading.

**Usage**:
```swift
if isLoading {
    ForEach(0..<3, id: \.self) { _ in
        SkeletonEventCard()
    }
}
```

**Features**:
- Gray rectangles mimicking event card layout
- Animated shimmer effect (left to right)
- Poster placeholder (180pt height)
- Title and subtitle placeholders
- Continuous animation loop

### Animation

The skeleton uses a linear gradient that moves from left to right continuously:

```swift
LinearGradient(
    colors: [.clear, .white.opacity(0.4), .clear],
    startPoint: .leading,
    endPoint: .trailing
)
.offset(x: isAnimating ? 400 : -400)
```

---

## NotificationBadge

**File**: `NotificationBadge.swift`

### Description

Animated notification badge with bounce effect when count increases. Displays bell icon with red circular badge showing unread count.

### Features

- Bell icon with count badge
- Bounce animation on count increase
- Shows "99+" for counts over 99
- Respects reduce motion setting
- Accessibility label with count
- Only shows badge when count > 0

### Usage

```swift
Button(action: { showingNotifications = true }) {
    NotificationBadge(count: notificationManager.unreadCount)
}
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `count` | `Int` | Unread notification count |

### Animation Behavior

- Detects when count increases (not decreases)
- Scales badge to 1.2x then back to 1.0
- Spring animation with 0.5 damping
- 300ms duration
- Respects `accessibilityReduceMotion`

### Visual Design

- Bell icon: 24pt font
- Badge: 16pt minimum size
- Badge text: 10pt bold font
- Badge color: Red
- Badge position: Top-trailing with 8pt offset

---

## PosterView

**File**: `PosterView.swift`

### Description

Responsive event poster components with perfect aspect ratio, placeholders, and error handling. Supports both local images and remote URLs.

### Components

#### 1. PosterView (Local Images)

Displays UIImage posters with proper aspect ratio.

**Usage**:
```swift
PosterView(
    image: eventPosterImage,
    aspectRatio: 3/4,
    cornerRadius: 12,
    showShadow: true
)
.frame(height: 300)
```

**Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image` | `UIImage?` | - | Local poster image |
| `aspectRatio` | `CGFloat` | 3/4 | Width/height ratio |
| `cornerRadius` | `CGFloat` | 12 | Corner radius |
| `showShadow` | `Bool` | true | Show drop shadow |

#### 2. AsyncPosterView (Remote URLs)

Loads poster from URL with loading and error states.

**Usage**:
```swift
AsyncPosterView(
    url: event.posterURL,
    aspectRatio: 3/4,
    cornerRadius: 12,
    showShadow: true
)
```

**States**:
- **Empty**: Shows loading spinner with "Loading..." text
- **Success**: Displays the poster image
- **Failure**: Shows error icon with "Failed to Load" text
- **No URL**: Shows placeholder with "No Poster" text

#### 3. PosterCard

Complete card with poster and event details.

**Usage**:
```swift
PosterCard(
    posterURL: event.posterURL,
    title: event.title,
    date: DateUtilities.formatEventDateTime(event.startDate),
    venue: event.venue.name
)
```

**Features**:
- AsyncPosterView with 3/4 aspect ratio
- Event title (2-line max)
- Calendar icon + date
- Location icon + venue
- Padding and shadow

### Configuration

```swift
struct PosterConfiguration {
    static let defaultAspectRatio: CGFloat = 3/4  // Portrait
    static let cornerRadius: CGFloat = 12
    static let shadowOpacity: CGFloat = 0.15
    static let shadowRadius: CGFloat = 8
}
```

### Placeholder Design

- Gradient background (systemGray5 → systemGray6)
- Photo icon (50pt size)
- "No Poster" caption text
- Maintains aspect ratio

---

## ProfileHeaderView

**File**: `ProfileHeaderView.swift`

### Description

Profile header components optimized for information density. Two layouts available: compact (horizontal) and centered (vertical).

### Components

#### 1. CompactProfileHeader

Horizontal layout with avatar, name, followers, and role.

**Usage**:
```swift
CompactProfileHeader(
    user: user,
    followerCount: followManager.followerCount(for: user.id),
    onAvatarTap: {
        showingAvatarPicker = true
    }
)
```

**Layout**:
```
[Avatar] [Name ✓]
         [123 followers • Organizer]
```

#### 2. CenteredProfileHeader

Vertical layout for profile/settings screens.

**Usage**:
```swift
CenteredProfileHeader(
    user: user,
    followerCount: followerCount,
    onAvatarTap: nil
)
```

**Layout**:
```
    [Avatar]
    [Name ✓]
[123 followers • Organizer]
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `user` | `User?` | User model to display |
| `followerCount` | `Int` | Number of followers (organizers only) |
| `onAvatarTap` | `(() -> Void)?` | Optional avatar tap callback |

### Features

- **Avatar**: 56pt (compact) or 72pt (centered) person.circle icon
- **Verification Badge**: Green checkmark.seal.fill for verified users
- **Follower Count**: Only shown for organizers, formatted (1K, 1M, etc.)
- **Role Badge**: Icon + text, color-coded by role
- **Responsive**: Scales text when constrained

### Follower Count Formatting

- 1-999: "1 follower" or "123 followers"
- 1K-999K: "1.2K followers"
- 1M+: "1.5M followers"

### Role Display

| Role | Icon | Color |
|------|------|-------|
| Attendee | person.fill | Attendee Primary |
| Organizer | briefcase.fill | Organizer Primary |

---

## PulsingDot

**File**: `PulsingDot.swift`

### Description

Animated pulsing dot indicator for "Happening now" badges. Creates a red/orange dot with an expanding/fading halo effect.

### Features

- Continuous pulsing animation (1.5s cycle)
- Outer halo that scales and fades
- Inner solid dot
- Respects reduce motion setting
- Customizable color and size
- Accessibility label

### Usage

```swift
HStack(spacing: AppSpacing.compactSpacing) {
    PulsingDot(size: 10)
    Text("Happening now")
        .font(.system(size: 13))
        .fontWeight(.semibold)
}
.padding(.horizontal, AppSpacing.sm)
.padding(.vertical, AppSpacing.compactSpacing)
.background(Capsule().fill(.ultraThinMaterial))
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `color` | `Color` | `RoleConfig.happeningNow` | Dot color |
| `size` | `CGFloat` | 8 | Inner dot size |

### Animation Details

- **Inner Dot**: Solid circle, no animation
- **Outer Halo**:
  - Size: 2.5x inner dot
  - Animation: easeInOut, repeats forever
  - Scale: 1.0 → 1.3
  - Opacity: 1.0 → 0.0
  - Duration: 1.5 seconds

### Accessibility

- Label: "Live event indicator"
- No animation when `accessibilityReduceMotion` is enabled
- Color contrast maintained

---

## QRCodeView

**File**: `QRCodeView.swift`

### Description

QR code display component with customizable colors and error handling. Generates QR codes from string data using the QRCodeGenerator utility.

### Features

- Generates styled QR codes with custom colors
- Error correction level: Medium
- Scales to specified size
- No interpolation (crisp pixels)
- Fallback error view
- Accessibility labels

### Usage

```swift
QRCodeView(
    data: "TICKET:\(ticket.id.uuidString)",
    size: 250,
    foregroundColor: .black,
    backgroundColor: .white
)
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | `String` | - | Data to encode (ticket ID, URL, etc.) |
| `size` | `CGFloat` | 200 | QR code size (width and height) |
| `foregroundColor` | `Color` | .black | QR code pattern color |
| `backgroundColor` | `Color` | .white | QR code background color |

### Error Handling

If QR code generation fails:
- Shows gray rectangle placeholder
- Displays "QR Code Unavailable" text
- Maintains specified size

### Implementation

Uses `QRCodeGenerator.generateStyled()`:
```swift
QRCodeGenerator.generateStyled(
    from: data,
    size: CGSize(width: size, height: size),
    foregroundColor: UIColor(foregroundColor),
    backgroundColor: UIColor(backgroundColor)
)
```

### Accessibility

- Label: "QR Code for ticket"
- Hint: "Show this code at the event entrance"

### Best Practices

1. **High Contrast**: Use black/white or high-contrast colors for scannability
2. **Minimum Size**: At least 200pt for reliable scanning
3. **Padding**: Add padding around QR code for camera framing
4. **Data Format**: Use consistent format (e.g., "TICKET:UUID" or "EVENT:UUID")

---

## SalesCountdownTimer

**File**: `SalesCountdownTimer.swift`

### Description

Real-time countdown timer for ticket sales with urgency-based color coding. Updates automatically every second and displays remaining time until sales close.

### Features

- Live countdown updates
- Three display styles (badge, inline, card)
- Urgency-based colors (green → yellow → red)
- Auto-stops when sales close
- Formatted time display
- Combine framework integration

### Styles

#### 1. Badge Style

Compact badge with clock icon and short countdown.

**Usage**:
```swift
SalesCountdownTimer(event: event, style: .badge)
```

**Display**: `[Clock] 2h 30m`

**Use Case**: Event cards, list views

#### 2. Inline Style

Single-line text with icon.

**Usage**:
```swift
SalesCountdownTimer(event: event, style: .inline)
```

**Display**: `[Clock] Sales end in 2 hours 30 minutes`

**Use Case**: Event detail headers

#### 3. Card Style

Full-width card with icon, title, and countdown.

**Usage**:
```swift
SalesCountdownTimer(event: event, style: .card)
```

**Display**:
```
[Icon] Ticket sales ending soon
       2 hours 30 minutes remaining
```

**Use Case**: Event detail pages, prominent warnings

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `event` | `Event` | Event with ticket sales window |
| `style` | `CountdownStyle` | Display style (badge, inline, card) |

### Urgency Colors

| Time Remaining | Color | Meaning |
|----------------|-------|---------|
| > 24 hours | Green | Sales open |
| 1-24 hours | Yellow/Orange | Ending soon |
| < 1 hour | Red | Urgent |

### Closed State

When ticket sales are closed:
```
[X] Ticket sales closed
```

Shows red X icon with event's `ticketSalesStatusMessage`.

### Auto-Update

- Starts timer on appear
- Updates every 1 second
- Stops timer when sales close
- Cleans up timer on disappear

### Integration with Event Model

Requires these Event properties:
- `isTicketSalesOpen: Bool`
- `timeUntilSalesClose: TimeInterval?`
- `shortCountdown: String?`
- `formattedTimeUntilSalesClose: String?`
- `ticketSalesStatusMessage: String`

---

## UIComponents (Reusable Kit)

**File**: `UIComponents.swift`

### Description

Comprehensive collection of reusable UI components for consistent design system implementation. Provides buttons, cards, forms, and more.

### Components

#### 1. AppButton

Primary button component with multiple styles and sizes.

**Usage**:
```swift
AppButton(
    title: "Purchase Tickets",
    style: .primary,
    size: .large,
    icon: "ticket.fill",
    iconPosition: .leading,
    isLoading: false,
    role: .attendee,
    action: { purchase() }
)
```

**Styles**:
- **Primary**: Solid color background, white text
- **Secondary**: Gray background, primary text
- **Destructive**: Red background, white text
- **Outline**: Transparent background, colored border
- **Ghost**: Transparent background, colored text

**Sizes**:
- **Large**: 56pt height (responsive, min 44pt)
- **Medium**: 48pt height (responsive, min 44pt)
- **Small**: 44pt height (meets accessibility)

**States**:
- Normal
- Loading (shows progress view)
- Disabled (gray, 60% opacity)

#### 2. AppCard

Reusable card container with padding, shadow, and optional border.

**Usage**:
```swift
AppCard(padding: AppSpacing.md, hasShadow: true) {
    VStack(alignment: .leading) {
        Text("Card Title").font(.headline)
        Text("Card content goes here")
    }
}
```

#### 3. AppSectionHeader

Section header with title, subtitle, action button, and optional icon.

**Usage**:
```swift
AppSectionHeader(
    title: "Upcoming Events",
    subtitle: "Events starting this week",
    action: { showAllEvents() },
    actionTitle: "See All",
    icon: "calendar",
    iconColor: .blue
)
```

#### 4. AppInputField

Text input field with icon, label, error handling, and secure entry.

**Usage**:
```swift
AppInputField(
    title: "Email",
    text: $email,
    placeholder: "Enter your email",
    icon: "envelope",
    keyboardType: .emailAddress,
    errorMessage: emailError
)

AppInputField(
    title: "Password",
    text: $password,
    placeholder: "Enter password",
    icon: "lock",
    isSecure: true
)
```

**Features**:
- Show/hide password toggle
- Error and helper text support
- Icon support
- Keyboard type customization
- Autocapitalization control

#### 5. AppIconButton

Circular icon button with optional badge.

**Usage**:
```swift
AppIconButton(
    icon: "bell.fill",
    size: 44,
    iconSize: 20,
    badge: unreadCount,
    action: { showNotifications() }
)
```

#### 6. AppChip

Filter chip/tag with selection state and optional remove button.

**Usage**:
```swift
AppChip(
    title: "Music",
    icon: "music.note",
    isSelected: true,
    onTap: { selectCategory("music") },
    onRemove: { removeCategory("music") }
)
```

#### 7. AppDivider

Customizable horizontal divider.

**Usage**:
```swift
AppDivider(
    color: AppBorder.color,
    height: 1,
    padding: AppSpacing.md
)
```

#### 8. AppEmptyState

Empty state view with icon, message, and optional action button.

**Usage**:
```swift
AppEmptyState(
    icon: "heart.slash",
    title: "No Favorites Yet",
    message: "Start saving events you're interested in",
    iconColor: .pink,
    buttonTitle: "Browse Events",
    buttonAction: { showEvents() },
    role: .attendee
)
```

#### 9. AppLoadingOverlay

Full-screen loading overlay with progress view and optional message.

**Usage**:
```swift
ZStack {
    MainContentView()

    if isProcessingPayment {
        AppLoadingOverlay(message: "Processing payment...")
    }
}
```

#### 10. AppStatusBadge

Small status badge with icon and text.

**Usage**:
```swift
AppStatusBadge(
    status: "Published",
    color: .green,
    icon: "checkmark.circle.fill"
)
```

---

## VerificationRequiredOverlay

**File**: `VerificationRequiredOverlay.swift`

### Description

Full-screen overlay shown when organizers need to complete identity verification before accessing organizer features. Explains why verification is required and provides quick access to the verification flow.

### Features

- Semi-transparent black background
- Large warning icon (shield)
- Explanation text
- Four verification benefits with checkmarks
- Call-to-action button
- Estimated completion time

### Usage

```swift
ZStack {
    OrganizerDashboardView()

    if !user.isVerified {
        VerificationRequiredOverlay(
            showingVerificationSheet: $showingVerificationSheet
        )
    }
}
.sheet(isPresented: $showingVerificationSheet) {
    VerificationFlow()
}
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `showingVerificationSheet` | `Binding<Bool>` | Controls verification flow sheet |

### Verification Benefits

1. **Ensures community safety** (shield.checkmark.fill)
2. **Builds trust with attendees** (person.badge.shield.checkmark.fill)
3. **Protects against fraud** (lock.shield.fill)
4. **Unlocks all organizer features** (checkmark.seal.fill)

### Visual Design

- Background: 85% black overlay
- Icon: 80pt orange shield with exclamation mark
- Title: White bold text
- Benefits: White text on semi-transparent background
- Button: Organizer primary color
- Footer: "Verification typically takes less than 5 minutes"

### Button Behavior

- Shows haptic feedback on tap
- Sets `showingVerificationSheet` to true
- Dismisses overlay automatically when verification completes

---

## Design System Integration

All components use centralized design tokens from `AppDesignSystem.swift`:

### Colors
- `AppDesign.Colors.primary`
- `AppDesign.Colors.textPrimary`
- `AppDesign.Colors.success`, `.warning`, `.error`

### Typography
- `AppDesign.Typography.title2`, `.headline`, `.body`, `.caption`

### Spacing
- `AppDesign.Spacing.xs`, `.sm`, `.md`, `.lg`, `.xl`

### Corner Radius
- `AppDesign.CornerRadius.small`, `.medium`, `.large`

### Shadows
- `AppDesign.Shadow.card`, `.elevated`

---

## Accessibility Features

All components include:

- ✅ **Minimum Touch Targets**: 44pt minimum (Apple HIG)
- ✅ **Dynamic Type**: Text scales with system settings
- ✅ **VoiceOver Labels**: Clear accessibility labels and hints
- ✅ **Reduce Motion**: Respects `accessibilityReduceMotion`
- ✅ **Color Contrast**: WCAG AA compliant
- ✅ **Semantic Colors**: Adapt to dark mode automatically
- ✅ **Haptic Feedback**: Consistent feedback across interactions

---

## Animation Standards

### Spring Animations
```swift
.spring(response: 0.3, dampingFraction: 0.6)
```

### Linear Animations
```swift
.linear(duration: 1.5).repeatForever(autoreverses: false)
```

### Easing Animations
```swift
.easeInOut(duration: 1.5).repeatForever()
```

---

## Usage Best Practices

### 1. Component Selection

- **EventCard**: Use for event lists and discovery feeds
- **PosterView**: Use for standalone poster displays
- **CompactMetricCard**: Use for dashboard metrics
- **AppButton**: Use for all primary and secondary actions
- **AuthPromptSheet**: Show for all guest user restrictions

### 2. Consistency

- Always use design system tokens (spacing, colors, fonts)
- Apply haptic feedback on interactive elements
- Include accessibility labels for all custom controls
- Respect reduce motion preferences

### 3. Performance

- Use `SkeletonEventCard` during loading
- Implement proper onAppear/onDisappear cleanup (timers, publishers)
- Avoid nested animations
- Use `.id()` modifier for efficient list updates

### 4. Responsive Design

- Use `ResponsiveSize` utility for device-specific sizing
- Implement `minimumScaleFactor` for text that might overflow
- Set minimum touch targets (44pt)
- Test on iPhone SE and iPad sizes

---

## Testing Checklist

When using these components, verify:

- [ ] Light and dark mode appearance
- [ ] Text scaling (Settings → Accessibility → Display → Larger Text)
- [ ] VoiceOver navigation
- [ ] Reduce motion setting (Settings → Accessibility → Motion)
- [ ] Color blindness accessibility
- [ ] iPhone SE (smallest) and iPad Pro (largest) layouts
- [ ] Landscape orientation
- [ ] Right-to-left (RTL) languages (if applicable)

---

## Contributing New Components

When adding new components to this catalog:

1. **File Location**: Place in `/EventPassUG/UI/Components/`
2. **Header Comment**: Include description and purpose
3. **Design System**: Use centralized tokens from `AppDesignSystem.swift`
4. **Accessibility**: Include labels, hints, and reduce motion support
5. **Preview**: Add SwiftUI preview for testing
6. **Documentation**: Add section to this document with usage examples
7. **Parameters Table**: Document all customization options
8. **Reusability**: Design for multiple contexts, not single-use

---

**Component Catalog Version**: 1.0
**Last Updated**: January 2026
**Total Components**: 15+
**Architecture**: Feature-First + Clean Architecture (MVVM)


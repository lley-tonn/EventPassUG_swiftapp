# Notification Preferences System Guide

## Overview

The app now has TWO notification preference systems that coexist:

1. **Original System** (`NotificationPreferences`) - Multi-channel preferences (push, email, SMS)
2. **Personalization System** (`UserNotificationPreferences`) - Simple push notification preferences

## Why Two Systems?

The original `NotificationPreferences` system supports multiple notification channels (push, email, SMS) and is more comprehensive. The new `UserNotificationPreferences` is simpler and focused on the personalization features (event reminders, recommendations, quiet hours).

## Models

### 1. NotificationPreferences (Original)
**Location**: `EventPassUG/Models/NotificationPreferences.swift`

**Structure**:
```swift
struct NotificationPreferences: Codable, Equatable {
    var upcomingEventReminders: ChannelPreferences
    var eventUpdates: ChannelPreferences
    var ticketPurchaseConfirmations: ChannelPreferences
    // ... more fields with multi-channel support
}

struct ChannelPreferences: Codable, Equatable {
    var push: Bool
    var email: Bool
    var sms: Bool
}
```

**Used by**:
- `UserPreferencesService.swift`
- `NotificationSettingsView.swift`
- Original notification system

### 2. UserNotificationPreferences (Personalization)
**Location**: `EventPassUG/Models/UserPreferences.swift`

**Structure**:
```swift
struct UserNotificationPreferences: Codable, Equatable {
    var isEnabled: Bool
    var eventReminders24h: Bool
    var eventReminders2h: Bool
    var eventStartingSoon: Bool
    var ticketPurchaseConfirmation: Bool
    var eventUpdates: Bool
    var recommendations: Bool
    var marketing: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: QuietHourTime
    var quietHoursEnd: QuietHourTime
}
```

**Used by**:
- `User.swift` model (personalization system)
- `AppNotificationService.swift`
- `NotificationSettingsViewModel.swift`
- Personalization and recommendation system

## Usage Guidelines

### When to Use NotificationPreferences (Original)
Use the original `NotificationPreferences` when you need:
- Multi-channel support (push + email + SMS)
- Organizer-specific notifications (ticket sales, low stock alerts)
- Payment and transaction notifications
- Existing features that already use this system

### When to Use UserNotificationPreferences (Personalization)
Use `UserNotificationPreferences` when you need:
- Simple push-only notifications
- Event reminder scheduling (24h, 2h, starting soon)
- Personalized recommendations
- Quiet hours support
- Age and location-based personalization features

## Migration Path (Optional)

If you want to consolidate these systems in the future:

### Option 1: Extend UserNotificationPreferences
Add multi-channel support to `UserNotificationPreferences`:
```swift
struct UserNotificationPreferences {
    // Existing fields...

    // Add channels
    var pushEnabled: Bool
    var emailEnabled: Bool
    var smsEnabled: Bool
}
```

### Option 2: Use NotificationPreferences Everywhere
Map `UserNotificationPreferences` to `NotificationPreferences`:
```swift
extension UserNotificationPreferences {
    func toNotificationPreferences() -> NotificationPreferences {
        // Map fields...
    }
}
```

### Option 3: Keep Both (Recommended for Now)
Keep both systems separate as they serve different purposes:
- Original system: Multi-channel, comprehensive
- Personalization system: Simple, focused on new features

## Files Reference

### Original System
- `EventPassUG/Models/NotificationPreferences.swift`
- `EventPassUG/Services/UserPreferencesService.swift`
- `EventPassUG/Views/Common/NotificationSettingsView.swift`

### Personalization System
- `EventPassUG/Models/UserPreferences.swift`
- `EventPassUG/Models/User.swift` (uses UserNotificationPreferences)
- `EventPassUG/Services/AppNotificationService.swift`
- `EventPassUG/ViewModels/NotificationSettingsViewModel.swift`
- `EventPassUG/Services/EventFilterService.swift`
- `EventPassUG/Services/RecommendationService.swift`

## Best Practices

1. **Don't Mix**: Don't try to use both in the same feature
2. **Clear Separation**: Keep the systems separate for now
3. **Document Usage**: When adding new notification features, document which system you're using
4. **Future Consolidation**: Plan to consolidate when the personalization system is fully tested

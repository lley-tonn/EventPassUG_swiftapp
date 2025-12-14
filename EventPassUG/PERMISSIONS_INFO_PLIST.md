# Required Info.plist Permission Keys

This document lists all the required privacy permission keys that must be added to your app's `Info.plist` file to enable the personalization and permission features.

## Required Keys

Add the following keys to your `Info.plist` file with appropriate privacy descriptions:

### 1. Location Services
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to show you events happening near you. We only use approximate location (city-level) for privacy.</string>
```

### 2. Notifications
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>We'll send you reminders for your events and notify you about new events you might like.</string>
```

### 3. Calendar
```xml
<key>NSCalendarsUsageDescription</key>
<string>We can add events to your calendar and help you avoid scheduling conflicts with your existing events.</string>
```

### 4. Contacts
```xml
<key>NSContactsUsageDescription</key>
<string>Access your contacts to invite friends to events and find people you know who are also using EventPass.</string>
```

### 5. Photo Library
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Access your photos to set your profile picture and upload event photos.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save event photos and tickets to your photo library.</string>
```

### 6. Camera
```xml
<key>NSCameraUsageDescription</key>
<string>Use your camera to scan QR codes for ticket validation and take photos at events.</string>
```

### 7. Bluetooth
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connect to nearby devices for contactless ticket scanning and check-in.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Connect to nearby devices for contactless ticket scanning.</string>
```

### 8. App Tracking (iOS 14+)
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use tracking data to provide you with personalized event recommendations while keeping your data private.</string>
```

## Complete Info.plist Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys here -->

    <!-- Location -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We use your location to show you events happening near you. We only use approximate location (city-level) for privacy.</string>

    <!-- Notifications -->
    <key>NSUserNotificationsUsageDescription</key>
    <string>We'll send you reminders for your events and notify you about new events you might like.</string>

    <!-- Calendar -->
    <key>NSCalendarsUsageDescription</key>
    <string>We can add events to your calendar and help you avoid scheduling conflicts with your existing events.</string>

    <!-- Contacts -->
    <key>NSContactsUsageDescription</key>
    <string>Access your contacts to invite friends to events and find people you know who are also using EventPass.</string>

    <!-- Photo Library -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Access your photos to set your profile picture and upload event photos.</string>

    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Save event photos and tickets to your photo library.</string>

    <!-- Camera -->
    <key>NSCameraUsageDescription</key>
    <string>Use your camera to scan QR codes for ticket validation and take photos at events.</string>

    <!-- Bluetooth -->
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Connect to nearby devices for contactless ticket scanning and check-in.</string>

    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>Connect to nearby devices for contactless ticket scanning.</string>

    <!-- App Tracking (iOS 14+) -->
    <key>NSUserTrackingUsageDescription</key>
    <string>We use tracking data to provide you with personalized event recommendations while keeping your data private.</string>
</dict>
</plist>
```

## Notes

1. **Privacy First**: All permission descriptions clearly explain what the permission is used for and emphasize privacy.

2. **Optional Permissions**: All permissions are optional. The app will work without them, but with reduced functionality.

3. **User Control**: Users can change permission settings at any time through the app's settings or iOS Settings.

4. **App Store Review**: Make sure your actual app usage matches the descriptions provided in Info.plist to pass App Store review.

5. **iOS 14+ Tracking**: The App Tracking Transparency (ATT) framework is required for iOS 14 and later if you want to track users across apps and websites.

## Implementation Checklist

- [ ] Add all required keys to Info.plist
- [ ] Update permission descriptions to match your app's actual usage
- [ ] Test permission flows on a physical device
- [ ] Ensure graceful degradation when permissions are denied
- [ ] Update Privacy Policy to reflect all collected data
- [ ] Test App Store submission with all permissions

## Privacy Policy

Make sure to update your app's Privacy Policy to include:
- What data is collected for each permission
- How the data is used
- How long the data is stored
- Whether data is shared with third parties
- How users can request data deletion

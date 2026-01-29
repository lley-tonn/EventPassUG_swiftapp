# Social Features Documentation

## Overview

EventPassUG includes social features that enable users to follow organizers and receive in-app notifications about their activities. This document covers the Follow Manager system and In-App Notification Manager.

---

## Table of Contents

1. [Follow Manager](#follow-manager)
2. [In-App Notification Manager](#in-app-notification-manager)
3. [Integration](#integration)
4. [User Experience](#user-experience)

---

## Follow Manager

### Overview

The Follow Manager system allows attendees to follow event organizers and receive updates when those organizers create new events or make announcements.

**File**: `/EventPassUG/Core/Utilities/FollowManager.swift`

### Features

- Follow/unfollow organizers with single tap
- Track follower counts per organizer
- Send notifications when someone follows you
- Persistent storage across app sessions
- Guest user support (prompts for authentication)
- Real-time follower count updates

### Implementation

**Data Structure**:
```swift
class FollowManager: ObservableObject {
    @Published var followedOrganizers: Set<UUID> = []
    @Published var followerCounts: [UUID: Int] = [:]

    private let followedOrganizersKey = "followedOrganizers"
    private let followerCountsKey = "followerCounts"
}
```

**Core Methods**:

#### 1. Follow Organizer

```swift
func followOrganizer(
    _ organizerId: UUID,
    organizerName: String,
    currentUserId: UUID?
) {
    // 1. Check if user is authenticated
    guard let userId = currentUserId else {
        // Prompt for authentication
        return
    }

    // 2. Add to followed set
    followedOrganizers.insert(organizerId)

    // 3. Increment follower count
    followerCounts[organizerId, default: 0] += 1

    // 4. Send notification to organizer
    sendFollowNotification(
        to: organizerId,
        from: userId,
        followerName: currentUserName
    )

    // 5. Persist changes
    saveFollowedOrganizers()
    saveFollowerCounts()

    // 6. Haptic feedback
    HapticFeedback.light()
}
```

#### 2. Unfollow Organizer

```swift
func unfollowOrganizer(_ organizerId: UUID) {
    // 1. Remove from followed set
    followedOrganizers.remove(organizerId)

    // 2. Decrement follower count
    if let count = followerCounts[organizerId], count > 0 {
        followerCounts[organizerId] = count - 1
    }

    // 3. Persist changes
    saveFollowedOrganizers()
    saveFollowerCounts()

    // 4. Haptic feedback
    HapticFeedback.light()
}
```

#### 3. Check Follow Status

```swift
func isFollowing(_ organizerId: UUID) -> Bool {
    return followedOrganizers.contains(organizerId)
}
```

#### 4. Get Follower Count

```swift
func followerCount(for organizerId: UUID) -> Int {
    return followerCounts[organizerId] ?? 0
}
```

### Persistence

**Storage Location**: `UserDefaults`

**Keys**:
- `followedOrganizers`: Set of followed organizer UUIDs
- `followerCounts`: Dictionary mapping organizer IDs to follower counts

**Save Methods**:
```swift
private func saveFollowedOrganizers() {
    let array = Array(followedOrganizers)
    let encoded = try? JSONEncoder().encode(array)
    UserDefaults.standard.set(encoded, forKey: followedOrganizersKey)
}

private func saveFollowerCounts() {
    let encoded = try? JSONEncoder().encode(followerCounts)
    UserDefaults.standard.set(encoded, forKey: followerCountsKey)
}
```

**Load Methods**:
```swift
private func loadFollowedOrganizers() {
    guard let data = UserDefaults.standard.data(forKey: followedOrganizersKey),
          let array = try? JSONDecoder().decode([UUID].self, from: data) else {
        return
    }
    followedOrganizers = Set(array)
}

private func loadFollowerCounts() {
    guard let data = UserDefaults.standard.data(forKey: followerCountsKey),
          let counts = try? JSONDecoder().decode([UUID: Int].self, from: data) else {
        return
    }
    followerCounts = counts
}
```

### Notifications

**Sent When**:
- User follows an organizer
- Notification sent to organizer's in-app notification center

**Notification Content**:
```swift
NotificationModel(
    type: .newFollower,
    title: "New Follower",
    message: "\(followerName) started following you",
    timestamp: Date(),
    relatedUserId: followerId
)
```

### Guest User Handling

**Behavior**:
- Guest users can view organizer profiles
- Tapping "Follow" shows authentication prompt
- Prompt explains benefits of following
- After authentication, follow action completes automatically

**Implementation**:
```swift
if currentUserId == nil {
    // Show auth prompt
    showingAuthPrompt = true
    pendingFollowOrganizerId = organizerId
} else {
    // Proceed with follow
    followManager.followOrganizer(organizerId, ...)
}
```

---

## In-App Notification Manager

### Overview

The In-App Notification Manager handles all in-app notifications, separate from push notifications. It provides a notification center where users can view, mark as read, and delete notifications.

**File**: `/EventPassUG/Core/Utilities/InAppNotificationManager.swift`

### Features

- Add notifications with different types
- Mark notifications as read/unread
- Delete individual notifications
- Clear all notifications
- Unread count tracking
- Organizer-specific filtering
- Persistent storage using AppStorage
- Real-time updates via @Published

### Notification Types

```swift
enum NotificationType: String, Codable {
    case eventReminder      // "Event Tomorrow!"
    case ticketPurchased    // "Ticket Purchased"
    case eventUpdate        // "Event Update"
    case newEvent           // "New Event from [Organizer]"
    case ticketScanned      // "Ticket Scanned"
    case paymentReceived    // "Payment Received"
    case newFollower        // "New Follower"
}
```

### Notification Model

```swift
struct NotificationModel: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let relatedEventId: UUID?
    let relatedTicketId: UUID?
    let relatedUserId: UUID?
}
```

### Implementation

**Class Structure**:
```swift
class InAppNotificationManager: ObservableObject {
    @Published var notifications: [NotificationModel] = []

    @AppStorage("notifications")
    private var notificationsData: Data = Data()

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var organizerNotifications: [NotificationModel] {
        notifications.filter { organizerTypes.contains($0.type) }
    }

    private let organizerTypes: Set<NotificationType> = [
        .ticketScanned,
        .paymentReceived,
        .newFollower
    ]
}
```

**Core Methods**:

#### 1. Add Notification

```swift
func addNotification(
    type: NotificationType,
    title: String,
    message: String,
    relatedEventId: UUID? = nil,
    relatedTicketId: UUID? = nil,
    relatedUserId: UUID? = nil
) {
    let notification = NotificationModel(
        id: UUID(),
        type: type,
        title: title,
        message: message,
        timestamp: Date(),
        isRead: false,
        relatedEventId: relatedEventId,
        relatedTicketId: relatedTicketId,
        relatedUserId: relatedUserId
    )

    notifications.insert(notification, at: 0) // Most recent first
    saveNotifications()
}
```

#### 2. Mark as Read

```swift
func markAsRead(_ notificationId: UUID) {
    if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
        notifications[index].isRead = true
        saveNotifications()
    }
}
```

#### 3. Mark All as Read

```swift
func markAllAsRead() {
    for index in notifications.indices {
        notifications[index].isRead = true
    }
    saveNotifications()
}
```

#### 4. Delete Notification

```swift
func deleteNotification(_ notificationId: UUID) {
    notifications.removeAll { $0.id == notificationId }
    saveNotifications()
}
```

#### 5. Clear All Notifications

```swift
func clearAll() {
    notifications.removeAll()
    saveNotifications()
}
```

### Persistence

**Storage**: Uses `@AppStorage` with JSON encoding

**Save Method**:
```swift
private func saveNotifications() {
    if let encoded = try? JSONEncoder().encode(notifications) {
        notificationsData = encoded
    }
}
```

**Load Method**:
```swift
private func loadNotifications() {
    if let decoded = try? JSONDecoder().decode([NotificationModel].self, from: notificationsData) {
        notifications = decoded
    }
}
```

### Notification Center UI

**Location**: `NotificationsView.swift`

**Features**:
- List of all notifications (most recent first)
- Unread indicator (blue dot)
- Swipe to delete
- Pull to refresh
- "Mark all as read" button
- Empty state when no notifications
- Tap notification to navigate to related content

**Implementation**:
```swift
List {
    ForEach(notificationManager.notifications) { notification in
        NotificationRow(notification: notification)
            .swipeActions {
                Button(role: .destructive) {
                    notificationManager.deleteNotification(notification.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .onTapGesture {
                notificationManager.markAsRead(notification.id)
                navigateToRelatedContent(notification)
            }
    }
}
```

**Badge Display**:
- Tab bar badge shows unread count
- Bell icon in navigation bar shows unread count
- Badge disappears when all read

### Notification Triggers

**When Notifications Are Created**:

1. **Event Reminder** (`eventReminder`)
   - 24 hours before event
   - 2 hours before event
   - Created by scheduled job or push notification handler

2. **Ticket Purchased** (`ticketPurchased`)
   - Immediately after successful payment
   - Created in payment confirmation flow

3. **Event Update** (`eventUpdate`)
   - When organizer edits event details
   - When event time/venue changes
   - When event is cancelled

4. **New Event** (`newEvent`)
   - When followed organizer creates new event
   - Created by event creation flow

5. **Ticket Scanned** (`ticketScanned`)
   - When attendee's ticket is scanned at entry
   - Created by QR scanner

6. **Payment Received** (`paymentReceived`)
   - When organizer receives payment for ticket sale
   - Created by payment processing

7. **New Follower** (`newFollower`)
   - When someone follows organizer
   - Created by FollowManager

---

## Integration

### Using Follow Manager

**1. Initialize**:
```swift
@StateObject private var followManager = FollowManager()
```

**2. Follow Button**:
```swift
Button(action: {
    if followManager.isFollowing(organizer.id) {
        followManager.unfollowOrganizer(organizer.id)
    } else {
        followManager.followOrganizer(
            organizer.id,
            organizerName: organizer.name,
            currentUserId: currentUser?.id
        )
    }
}) {
    HStack {
        Image(systemName: followManager.isFollowing(organizer.id) ? "checkmark" : "plus")
        Text(followManager.isFollowing(organizer.id) ? "Following" : "Follow")
    }
}
```

**3. Display Follower Count**:
```swift
HStack {
    Image(systemName: "person.2.fill")
    Text("\(followManager.followerCount(for: organizer.id)) followers")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

### Using In-App Notification Manager

**1. Initialize**:
```swift
@StateObject private var notificationManager = InAppNotificationManager()
```

**2. Add Notification**:
```swift
// When ticket purchased
notificationManager.addNotification(
    type: .ticketPurchased,
    title: "Ticket Purchased",
    message: "Your ticket for \(event.title) has been confirmed",
    relatedEventId: event.id,
    relatedTicketId: ticket.id
)

// When organizer gets follower
notificationManager.addNotification(
    type: .newFollower,
    title: "New Follower",
    message: "\(user.fullName) started following you",
    relatedUserId: user.id
)
```

**3. Display Badge**:
```swift
TabView {
    NotificationsView()
        .tabItem {
            Label("Notifications", systemImage: "bell")
        }
        .badge(notificationManager.unreadCount)
}
```

**4. Navigation Bar Badge**:
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showingNotifications = true }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                if notificationManager.unreadCount > 0 {
                    Text("\(notificationManager.unreadCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
}
```

---

## User Experience

### Follow Flow

**Discovery**:
- Users see organizers on event detail pages
- Organizer profile includes follower count
- "Follow" button prominently displayed

**Following**:
1. Tap "Follow" button
2. Button changes to "Following" with checkmark
3. Follower count increments immediately
4. Organizer receives in-app notification
5. User receives updates when organizer creates events

**Unfollowing**:
1. Tap "Following" button
2. Confirmation dialog: "Unfollow [Organizer Name]?"
3. Confirm → Button changes to "Follow"
4. Follower count decrements
5. Stop receiving organizer updates

### Notification Flow

**Receiving**:
- Badge appears on bell icon
- Pull-down to see notifications
- Most recent at top
- Unread marked with blue dot

**Reading**:
- Tap notification to view details
- Auto-marked as read
- Navigate to related content (event, ticket, profile)

**Managing**:
- Swipe left to delete
- "Mark all as read" button
- "Clear all" option in settings

### Notification Settings

**Location**: Profile → Settings → Notifications

**Options**:
- Enable/disable in-app notifications by type
- Notification sound (on/off)
- Badge display (on/off)
- Preview in notification center

---

## Backend Integration

### Sync Requirements

**Follow Data**:
- Sync followed organizers to backend
- Track follower counts server-side
- Handle follow/unfollow across devices
- Notify organizers via push notification

**Notification Data**:
- Send notifications via push when app closed
- Sync notification read status
- Clear notifications across devices
- Archive old notifications (>30 days)

**API Endpoints Needed**:

```
POST /api/users/{userId}/follow
Body: { organizerId: UUID }
Response: { success: boolean, followerCount: number }

DELETE /api/users/{userId}/follow/{organizerId}
Response: { success: boolean, followerCount: number }

GET /api/users/{userId}/following
Response: { organizers: [UUID] }

GET /api/organizers/{organizerId}/followers
Response: { followers: [User], count: number }

POST /api/notifications
Body: { type, title, message, recipientId, ... }
Response: { success: boolean, notificationId: UUID }

GET /api/notifications/{userId}
Query: ?unreadOnly=true&limit=50
Response: { notifications: [NotificationModel] }

PUT /api/notifications/{notificationId}/read
Response: { success: boolean }

DELETE /api/notifications/{notificationId}
Response: { success: boolean }
```

---

## Testing

### Manual Testing

**Follow Manager**:
- [ ] Follow organizer adds to followed set
- [ ] Follower count increments
- [ ] Unfollow removes from followed set
- [ ] Follower count decrements
- [ ] Guest user sees auth prompt
- [ ] Follow persists across app restarts
- [ ] Organizer receives notification
- [ ] Haptic feedback triggers

**In-App Notifications**:
- [ ] Notifications appear in center
- [ ] Unread count accurate
- [ ] Badge displays on tab/bell icon
- [ ] Mark as read works
- [ ] Mark all as read works
- [ ] Delete notification works
- [ ] Clear all works
- [ ] Tap navigates to content
- [ ] Notifications persist
- [ ] Organizer-only filter works

---

## Future Enhancements

**Planned**:
1. **Push Notifications for Follows**
   - Organizer gets push when followed
   - Follower gets push when organizer creates event

2. **Follow Recommendations**
   - "Organizers you might like"
   - Based on event attendance
   - Based on categories

3. **Social Feed**
   - View updates from followed organizers
   - Announcements, new events, etc.
   - Chronological feed

4. **Follower Management**
   - View list of followers (organizers)
   - Block/unblock users
   - Follower insights

5. **Notification Preferences**
   - Customize which notification types to receive
   - Quiet hours
   - Delivery method (in-app vs push)

6. **Rich Notifications**
   - Images in notifications
   - Action buttons (RSVP, Share, etc.)
   - Grouped notifications

---

## Conclusion

The social features in EventPassUG provide a foundation for user engagement and organizer-attendee relationships. The Follow Manager and In-App Notification Manager work together to create a connected experience while maintaining privacy and user control. Both systems are designed to be extensible and ready for backend integration.

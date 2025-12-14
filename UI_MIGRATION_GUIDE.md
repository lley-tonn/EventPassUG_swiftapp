# EventPassUG UI Migration Guide

This guide shows how to migrate existing views to use the new unified design system.

## Quick Reference

### Before & After Examples

---

## 1. Buttons

### ❌ BEFORE (Inconsistent)
```swift
Button(action: signUp) {
    Text("Get Started")
        .font(AppTypography.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoleConfig.getPrimaryColor(for: selectedRole))
        .cornerRadius(AppCornerRadius.medium)
}
```

### ✅ AFTER (Using AppButton)
```swift
AppButton(
    title: "Get Started",
    style: .primary,
    role: selectedRole,
    action: signUp
)
```

### With Loading State
```swift
AppButton(
    title: "Sign Up",
    style: .primary,
    isLoading: isLoading,
    role: selectedRole,
    action: signUp
)
```

### With Icon
```swift
AppButton(
    title: "Continue",
    style: .primary,
    icon: "arrow.right",
    iconPosition: .trailing,
    role: selectedRole,
    action: { }
)
```

### Outline Button
```swift
AppButton(
    title: "Cancel",
    style: .outline,
    role: selectedRole,
    action: { dismiss() }
)
```

---

## 2. Social Auth Buttons

### ❌ BEFORE
```swift
Button(action: onGoogleTap) {
    HStack {
        Image(systemName: "g.circle.fill")
            .font(.title2)
        Text("Continue with Google")
            .font(.headline)
    }
    .foregroundColor(.primary)
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(UIColor.secondarySystemBackground))
    .cornerRadius(12)
}
```

### ✅ AFTER
```swift
SocialAuthButton(provider: .google, isLoading: isLoading) {
    onGoogleTap()
}

SocialAuthButton(provider: .apple, isLoading: isLoading) {
    onAppleTap()
}

SocialAuthButton(provider: .phone, isLoading: isLoading) {
    onPhoneTap()
}
```

---

## 3. Input Fields

### ❌ BEFORE
```swift
VStack(alignment: .leading, spacing: AppSpacing.sm) {
    Text("Email")
        .font(AppTypography.caption)
        .foregroundColor(.secondary)
    TextField("Enter email", text: $email)
        .textFieldStyle(.roundedBorder)
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
}
```

### ✅ AFTER
```swift
AppInputField(
    title: "Email",
    text: $email,
    placeholder: "Enter email",
    icon: "envelope",
    keyboardType: .emailAddress,
    autocapitalization: .never
)
```

### Password Field
```swift
AppInputField(
    title: "Password",
    text: $password,
    placeholder: "Enter password",
    icon: "lock",
    isSecure: true,
    helperText: "Must be at least 6 characters"
)
```

### With Error
```swift
AppInputField(
    title: "Email",
    text: $email,
    placeholder: "Enter email",
    icon: "envelope",
    errorMessage: emailError
)
```

---

## 4. Cards & Containers

### ❌ BEFORE
```swift
VStack(alignment: .leading, spacing: AppSpacing.sm) {
    Text("Card Content")
}
.padding(AppSpacing.md)
.background(Color(UIColor.secondarySystemGroupedBackground))
.cornerRadius(AppCornerRadius.medium)
.shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
```

### ✅ AFTER
```swift
AppCard {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
        Text("Card Content")
    }
}
```

### Without Shadow
```swift
AppCard(hasShadow: false) {
    // Content
}
```

### With Border
```swift
AppCard(hasShadow: false, hasBorder: true) {
    // Content
}
```

---

## 5. Section Headers

### ❌ BEFORE
```swift
HStack {
    Text("Popular Events")
        .font(AppTypography.title3)
        .fontWeight(.semibold)
    Spacer()
    Button("See All") { }
        .font(AppTypography.subheadline)
        .foregroundColor(RoleConfig.attendeePrimary)
}
```

### ✅ AFTER
```swift
AppSectionHeader(
    title: "Popular Events",
    action: { showAllEvents() },
    icon: "flame.fill",
    iconColor: .orange
)
```

### With Subtitle
```swift
AppSectionHeader(
    title: "Your Interests",
    subtitle: "Events you might like",
    action: { showAll() }
)
```

---

## 6. Chips / Tags

### ❌ BEFORE
```swift
HStack(spacing: 4) {
    Image(systemName: "music.note")
        .font(.system(size: 12))
    Text("Music")
        .font(.system(size: 12, weight: .medium))
}
.foregroundColor(.white)
.padding(.horizontal, 10)
.padding(.vertical, 6)
.background(Color.purple)
.cornerRadius(20)
```

### ✅ AFTER
```swift
AppChip(
    title: "Music",
    icon: "music.note",
    isSelected: true,
    color: .purple
)
```

### Removable Chip
```swift
AppChip(
    title: "Music",
    icon: "music.note",
    isSelected: true,
    color: .purple,
    onRemove: { removeCategory("Music") }
)
```

---

## 7. Icon Buttons

### ❌ BEFORE
```swift
Button(action: { dismiss() }) {
    Image(systemName: "xmark")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.primary)
        .frame(width: 32, height: 32)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(Circle())
}
```

### ✅ AFTER
```swift
AppIconButton(icon: "xmark", action: { dismiss() })
```

### With Badge
```swift
AppIconButton(
    icon: "bell.fill",
    badge: unreadCount,
    action: { showNotifications() }
)
```

---

## 8. Empty States

### ❌ BEFORE
```swift
VStack(spacing: AppSpacing.lg) {
    ZStack {
        Circle()
            .fill(Color.pink.opacity(0.1))
            .frame(width: 120, height: 120)
        Image(systemName: "heart.slash")
            .font(.system(size: 50))
            .foregroundColor(.pink.opacity(0.6))
    }
    Text("No Favorites Yet")
        .font(.system(size: 24, weight: .bold))
    Text("Start saving events")
        .foregroundColor(.secondary)
    Button("Browse Events") { }
}
```

### ✅ AFTER
```swift
AppEmptyState(
    icon: "heart.slash",
    title: "No Favorites Yet",
    message: "Start saving events you like",
    iconColor: .pink,
    buttonTitle: "Browse Events",
    buttonAction: { browsEvents() }
)
```

---

## 9. Status Badges

### ❌ BEFORE
```swift
HStack(spacing: 2) {
    Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 10))
    Text("Active")
        .font(.system(size: 10, weight: .medium))
}
.foregroundColor(.green)
.padding(.horizontal, 6)
.padding(.vertical, 2)
.background(Color.green.opacity(0.15))
.cornerRadius(4)
```

### ✅ AFTER
```swift
AppStatusBadge(
    status: "Active",
    color: .green,
    icon: "checkmark.circle.fill"
)
```

---

## 10. Dividers

### ❌ BEFORE
```swift
Divider()
    .padding(.vertical, AppSpacing.sm)
```

### ✅ AFTER
```swift
AppDivider(padding: AppSpacing.sm)
```

---

## Migration Checklist

When refactoring a view:

1. **Import the design system** (already available via `RoleConfig.swift`)

2. **Replace buttons:**
   - [ ] Primary action buttons → `AppButton(style: .primary)`
   - [ ] Secondary buttons → `AppButton(style: .secondary)`
   - [ ] Destructive actions → `AppButton(style: .destructive)`
   - [ ] Outline buttons → `AppButton(style: .outline)`
   - [ ] Social auth buttons → `SocialAuthButton`

3. **Replace input fields:**
   - [ ] TextField → `AppInputField`
   - [ ] SecureField → `AppInputField(isSecure: true)`
   - [ ] Add consistent icons and validation

4. **Replace cards:**
   - [ ] Custom card containers → `AppCard`
   - [ ] Ensure consistent shadows and borders

5. **Replace headers:**
   - [ ] Section titles → `AppSectionHeader`
   - [ ] Add icons where appropriate

6. **Replace chips/tags:**
   - [ ] Category badges → `AppChip`
   - [ ] Filter tags → `AppChip`

7. **Replace empty states:**
   - [ ] Custom empty views → `AppEmptyState`

8. **Standardize spacing:**
   - [ ] Replace hardcoded padding with `AppSpacing.*`
   - [ ] Use `AppSpacing.sectionSpacing` between sections
   - [ ] Use `AppSpacing.itemSpacing` between list items

9. **Standardize typography:**
   - [ ] Replace `.font(.system(size:))` with `AppTypography.*`
   - [ ] Ensure consistent font weights

10. **Standardize corners:**
    - [ ] Replace hardcoded radius with `AppCornerRadius.*`
    - [ ] Use consistent corner radius per component type

---

## Files to Prioritize

High-impact migrations (most visible screens):

1. **OnboardingView.swift** - First impression
2. **ProfileView.swift** - User settings hub
3. **AttendeeHomeView.swift** - Main dashboard
4. **EventDetailsView.swift** - Core feature
5. **TicketPurchaseView.swift** - Revenue flow
6. **CreateEventWizard.swift** - Organizer flow
7. **PaymentMethodsView.swift** - Financial trust
8. **NotificationSettingsView.swift** - User preferences

---

## Testing After Migration

After migrating a view:

1. Test light and dark mode appearance
2. Verify role-based theming (attendee vs organizer colors)
3. Check loading states display correctly
4. Ensure haptic feedback triggers
5. Test disabled states
6. Verify accessibility (VoiceOver support)
7. Check Dynamic Type scaling

# Organizer Onboarding Documentation

## Overview

The Organizer Onboarding Flow is a comprehensive 5-step process that guides new organizers through profile setup, identity verification, contact information, payout configuration, and terms agreement. This ensures all organizers are verified and properly configured before creating events.

---

## Table of Contents

1. [Overview](#overview)
2. [Onboarding Flow](#onboarding-flow)
3. [Step Details](#step-details)
4. [Implementation](#implementation)
5. [Verification Requirements](#verification-requirements)
6. [Exit Handling](#exit-handling)

---

## Onboarding Flow

### Entry Point

**Location**: Profile Tab → "Become an Organizer" button

**Trigger**: User taps "Become an Organizer" when currently in Attendee mode

### Flow Diagram

```
Start
  ↓
Step 1: Profile Completion
  ├─ Organization name
  ├─ Bio/description
  └─ Category selection
  ↓
Step 2: Identity Verification
  ├─ National ID upload
  ├─ Photo capture with frame overlay
  └─ Upload from photo library option
  ↓
Step 3: Contact Information
  ├─ Business email
  ├─ Business phone
  └─ Website (optional)
  ↓
Step 4: Payout Setup
  ├─ Payment method selection
  ├─ Account details
  └─ Verification
  ↓
Step 5: Terms Agreement
  ├─ Review organizer terms
  ├─ Review privacy policy
  └─ Accept checkbox
  ↓
Complete → Auto-switch to Organizer role → Navigate to Organizer Dashboard
```

---

## Step Details

### Step 1: Profile Completion

**File**: `OrganizerProfileCompletionStep.swift`

**Purpose**: Collect organizer business information

**Fields**:
- **Organization Name** (required)
  - Minimum 3 characters
  - Used as display name for events

- **Bio/Description** (required)
  - Minimum 50 characters
  - Maximum 500 characters
  - Multiline text editor
  - Describes organization/event hosting experience

- **Category** (required)
  - Dropdown selection
  - Primary event category
  - Options: Music, Sports, Business, Arts, Technology, etc.
  - Can be changed later in settings

**Validation**:
```swift
var isValid: Bool {
    !organizationName.isEmpty &&
    organizationName.count >= 3 &&
    bio.count >= 50 &&
    bio.count <= 500 &&
    selectedCategory != nil
}
```

**UI Features**:
- Real-time character count for bio
- Category icons displayed
- Progress indicator shows 1/5
- "Continue" button disabled until valid

---

### Step 2: Identity Verification

**File**: `OrganizerIdentityVerificationStep.swift`

**Purpose**: Verify organizer identity for security and trust

**Options**:

1. **Take Photo with ID**
   - Opens camera with guided frame overlay
   - User positions ID within frame
   - Captures photo for review
   - Option to retake if needed

2. **Upload from Library**
   - Opens photo picker
   - Selects existing ID photo
   - Image validation (size, format)
   - Preview before submission

**Accepted Documents**:
- National ID Card
- Passport
- Driver's License

**Requirements**:
- Photo must be clear and readable
- All corners of ID must be visible
- No glare or obstructions
- File size: < 5MB
- Format: JPG, PNG, HEIC

**Implementation**:
```swift
@State private var idImage: UIImage?
@State private var showingCamera = false
@State private var showingPhotoPicker = false
@State private var verificationMethod: VerificationMethod = .camera

enum VerificationMethod {
    case camera
    case photoLibrary
}
```

**Security**:
- Images temporarily stored on device
- Uploaded securely to backend
- Encryption in transit
- Backend processes verification
- Images not accessible to other users

**UI Features**:
- Frame overlay guides ID placement
- Flash toggle for low light
- Zoom capability
- Crop/rotate tools
- Preview before submission
- Progress indicator shows 2/5

---

### Step 3: Contact Information

**File**: `OrganizerContactInfoStep.swift`

**Purpose**: Collect business contact details for communication

**Fields**:
- **Business Email** (required)
  - Email format validation
  - Verification email sent
  - Different from account email allowed
  - Used for official communications

- **Business Phone** (required)
  - Phone number format validation
  - International format support
  - OTP verification optional
  - Used for urgent notifications

- **Website** (optional)
  - URL format validation
  - Displayed on organizer profile
  - Used for marketing/promotion

**Validation**:
```swift
var isValid: Bool {
    Validation.isValidEmail(businessEmail) &&
    Validation.isValidPhone(businessPhone) &&
    (website.isEmpty || Validation.isValidURL(website))
}
```

**UI Features**:
- Email domain suggestions
- Phone country code selector
- Real-time format validation
- Error messages inline
- Progress indicator shows 3/5

---

### Step 4: Payout Setup

**File**: `OrganizerPayoutSetupStep.swift`

**Purpose**: Configure payment receiving method for ticket sales revenue

**Payment Methods**:

1. **Mobile Money** (Recommended for Uganda)
   - MTN Mobile Money
   - Airtel Money
   - Fields: Phone number, Account name

2. **Bank Transfer**
   - Bank name selection
   - Account number
   - Account name
   - Branch (optional)
   - SWIFT code (international only)

3. **Paystack/Flutterwave**
   - Account ID
   - API key (for advanced users)
   - Automatic setup option

**Fields (Mobile Money)**:
- **Provider** (required): MTN MoMo or Airtel Money
- **Phone Number** (required): Registered mobile money number
- **Account Name** (required): Name on account (must match ID)

**Fields (Bank)**:
- **Bank** (required): Dropdown of supported banks
- **Account Number** (required): 10-16 digits
- **Account Name** (required): Name on account
- **Branch** (optional): Bank branch
- **SWIFT Code** (optional): For international transfers

**Validation**:
```swift
var isValid: Bool {
    switch paymentMethod {
    case .mobileMoney:
        return !phoneNumber.isEmpty &&
               phoneNumber.count >= 10 &&
               !accountName.isEmpty
    case .bank:
        return selectedBank != nil &&
               accountNumber.count >= 10 &&
               !accountName.isEmpty
    }
}
```

**Security**:
- Encrypted storage of payout details
- Backend validates account ownership
- Test transfers option available
- Can be updated later in settings

**UI Features**:
- Payment method selection cards
- Provider logos displayed
- Account name auto-fill from profile
- Test payout button (sends UGX 100)
- Progress indicator shows 4/5

---

### Step 5: Terms Agreement

**File**: `OrganizerTermsAgreementStep.swift`

**Purpose**: Review and accept organizer terms and conditions

**Content**:

1. **Organizer Terms** (scrollable)
   - Event creation guidelines
   - Content policy
   - Prohibited events
   - Ticket sales terms
   - Cancellation policy
   - Refund responsibilities
   - Platform fees
   - Payment processing

2. **Privacy Policy** (scrollable)
   - Data collection
   - Data usage
   - Data sharing
   - User rights
   - GDPR compliance

3. **Acceptance**
   - Checkbox: "I have read and agree to the Organizer Terms"
   - Checkbox: "I have read and agree to the Privacy Policy"
   - Both required to continue
   - Timestamp recorded

**Implementation**:
```swift
@State private var acceptedTerms = false
@State private var acceptedPrivacy = false

var canComplete: Bool {
    acceptedTerms && acceptedPrivacy
}
```

**Legal**:
- Terms version tracked
- Acceptance timestamp stored
- IP address logged (optional)
- Can be re-accepted if terms update
- Withdrawal option available

**UI Features**:
- Scrollable terms viewer
- "View Full Document" links
- Checkbox states persistent
- "Complete Setup" button only enabled when both accepted
- Progress indicator shows 5/5

---

## Implementation

### File Structure

```
/Features/Organizer/
  ├── BecomeOrganizerFlow.swift (Main coordinator)
  ├── OrganizerProfileCompletionStep.swift
  ├── OrganizerIdentityVerificationStep.swift
  ├── OrganizerContactInfoStep.swift
  ├── OrganizerPayoutSetupStep.swift
  └── OrganizerTermsAgreementStep.swift
```

### Main Coordinator

**File**: `BecomeOrganizerFlow.swift`

**Responsibilities**:
- Manages 5-step progression
- Tracks completion state
- Handles back/forward navigation
- Saves progress automatically
- Shows exit confirmation
- Completes onboarding and switches role

**State Management**:
```swift
@State private var currentStep = 1
@State private var organizerProfile = OrganizerProfile()
@State private var showingExitConfirmation = false
@State private var isCompleting = false

// Progress calculated
var progress: Double {
    Double(currentStep) / 5.0
}
```

**Navigation**:
```swift
// Next step
if currentStep < 5 {
    currentStep += 1
} else {
    completeOnboarding()
}

// Previous step
if currentStep > 1 {
    currentStep -= 1
}

// Exit confirmation
if showingExitConfirmation {
    // Show alert: "Exit organizer setup?"
    // "Your progress will be saved"
}
```

**Completion**:
```swift
func completeOnboarding() {
    isCompleting = true

    Task {
        // 1. Save organizer profile to backend
        try await authService.updateOrganizerProfile(organizerProfile)

        // 2. Mark verification as complete
        user.organizerVerificationComplete = true

        // 3. Switch to organizer role
        user.isOrganizer = true

        // 4. Navigate to organizer dashboard
        await MainActor.run {
            dismiss()
            // Dashboard automatically shows
        }

        // 5. Show welcome message
        HapticFeedback.success()
    }
}
```

---

## Verification Requirements

### Identity Verification

**Processing**:
1. User submits ID photo
2. Backend receives encrypted image
3. Manual review by admin team (currently)
4. Automated OCR planned for future
5. Verification result sent within 24-48 hours
6. User notified via push notification

**Approval Criteria**:
- ID is valid and not expired
- Photo is clear and readable
- All details visible
- Name matches account name
- No signs of tampering

**Rejection Reasons**:
- Blurry or unreadable image
- Expired document
- Name mismatch
- Tampered document
- Unsupported document type

**Re-submission**:
- User can re-submit if rejected
- Feedback provided on rejection
- No limit on re-submissions
- Each submission reviewed independently

---

## Exit Handling

### Save Progress

**Auto-save**:
- Progress saved after each step completion
- User can exit and resume later
- Profile tab shows "Complete Organizer Setup" badge
- Tapping badge resumes from last completed step

**Manual Exit**:
- Tap "Cancel" button (top-left)
- Confirmation dialog appears:
  - Title: "Exit Organizer Setup?"
  - Message: "Your progress will be saved. You can continue later from Profile settings."
  - Buttons: "Exit" (default), "Continue Setup" (cancel)

**Resume Flow**:
```swift
// Check if onboarding incomplete
if user.isOrganizer == false &&
   user.organizerOnboardingStarted == true &&
   user.organizerVerificationComplete == false {
    // Show "Complete Setup" badge in profile
    showingOnboardingResume = true
}

// Tap badge to resume
Button("Complete Organizer Setup") {
    showingBecomeOrganizer = true
    // Resumes at last completed step
}
```

---

## UI/UX Features

### Progress Indicator

**Display**:
- Linear progress bar at top
- Step counter: "Step X of 5"
- Step titles below progress bar
- Current step highlighted
- Completed steps shown with checkmark

**Implementation**:
```swift
ProgressView(value: Double(currentStep), total: 5.0)
    .tint(RoleConfig.organizerPrimary)

HStack {
    ForEach(1...5, id: \.self) { step in
        StepIndicator(
            number: step,
            isCurrent: step == currentStep,
            isCompleted: step < currentStep
        )
    }
}
```

### Navigation Buttons

**Back Button**:
- Only shown on steps 2-5
- Returns to previous step
- No confirmation required
- Data preserved

**Continue Button**:
- Shown on steps 1-4
- Disabled until step valid
- Animated on tap
- Haptic feedback

**Complete Button**:
- Only shown on step 5
- Requires terms acceptance
- Shows loading state
- Completes onboarding

### Animations

- Step transitions: `.transition(.slide)`
- Progress bar: smooth animation
- Button states: scale animation
- Success: confetti animation (optional)

### Haptic Feedback

- Step completion: `HapticFeedback.success()`
- Validation error: `HapticFeedback.error()`
- Button tap: `HapticFeedback.light()`
- Onboarding complete: `HapticFeedback.success()`

---

## Testing

### Manual Testing Checklist

**Step 1: Profile Completion**
- [ ] Organization name validation works (min 3 chars)
- [ ] Bio character counter accurate
- [ ] Bio min/max length enforced (50-500)
- [ ] Category selection required
- [ ] Continue button disabled until valid
- [ ] Data persists on back navigation

**Step 2: Identity Verification**
- [ ] Camera permission requested
- [ ] Photo library permission requested
- [ ] Frame overlay guides ID placement
- [ ] Flash toggle works
- [ ] Photo preview shows
- [ ] Retake option available
- [ ] Photo library picker works
- [ ] Image validation (size, format)

**Step 3: Contact Information**
- [ ] Email format validation
- [ ] Phone format validation
- [ ] Website URL validation (optional)
- [ ] Error messages display inline
- [ ] Continue disabled until valid

**Step 4: Payout Setup**
- [ ] Payment method selection works
- [ ] Mobile Money fields show for MoMo/Airtel
- [ ] Bank fields show for Bank
- [ ] Account number validation
- [ ] Continue disabled until valid

**Step 5: Terms Agreement**
- [ ] Terms content scrollable
- [ ] Privacy policy scrollable
- [ ] Both checkboxes required
- [ ] Complete button disabled until both checked
- [ ] Terms version tracked

**Flow**:
- [ ] Progress indicator accurate
- [ ] Back navigation works
- [ ] Data preserved across steps
- [ ] Exit confirmation shown
- [ ] Auto-save works
- [ ] Resume from saved state works
- [ ] Completion switches role
- [ ] Navigate to dashboard after completion
- [ ] Welcome message shown

---

## Future Enhancements

**Planned**:
1. **Automated ID Verification**
   - OCR text extraction
   - Face matching
   - Document authenticity check
   - Instant verification (< 5 minutes)

2. **Video Verification**
   - Liveness detection
   - Face matching with ID
   - Fraud prevention

3. **Business Verification**
   - Company registration check
   - Tax ID verification
   - Business license validation

4. **Test Payouts**
   - Send test amount (UGX 100)
   - Verify account ownership
   - Confirm details before approval

5. **Progress Dashboard**
   - Verification status tracking
   - Estimated completion time
   - Required actions highlighted

---

## Troubleshooting

### Common Issues

**Issue**: Camera not opening
**Solution**: Check camera permissions in Settings → EventPassUG → Camera

**Issue**: Photo upload fails
**Solution**: Check file size (< 5MB), check internet connection

**Issue**: Email/phone already registered
**Solution**: Use different business contact or link to existing account

**Issue**: Payout details rejected
**Solution**: Ensure account name matches ID name exactly

**Issue**: Terms won't scroll on small screens
**Solution**: Fixed height container with scroll enabled

**Issue**: Exit and resume doesn't work
**Solution**: Check UserDefaults persistence, verify user ID

---

## Security Considerations

**Data Protection**:
- All sensitive data encrypted at rest
- ID photos encrypted in transit
- Payout details stored securely
- Access logs maintained

**Fraud Prevention**:
- One organizer account per user
- ID verification required
- Manual review currently
- Suspicious activity flagged

**Compliance**:
- GDPR compliant data handling
- User can request data deletion
- Right to withdraw consent
- Terms acceptance tracked with timestamp

---

## Conclusion

The Organizer Onboarding Flow is a production-ready, 5-step verification system that ensures all event organizers are properly vetted and configured before creating events. The flow balances security requirements with user experience, providing clear guidance and auto-save functionality throughout the process.

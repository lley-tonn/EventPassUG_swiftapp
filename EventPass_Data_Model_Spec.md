# EventPass UG - Backend Data Model Specification

**Generated:** 2026-02-20
**Version:** 1.0
**Purpose:** Complete backend-ready variable and schema specification for database design, API contracts, and entity relationships.

---

## Table of Contents

1. [Entity Overview](#entity-overview)
2. [Core Entities](#core-entities)
3. [Financial Entities](#financial-entities)
4. [Analytics Entities](#analytics-entities)
5. [Support Entities](#support-entities)
6. [Enumerations](#enumerations)
7. [Entity Relationships](#entity-relationships)
8. [Naming Conventions](#naming-conventions)
9. [Data Type Standards](#data-type-standards)
10. [Audit Fields](#audit-fields)

---

## Entity Overview

| Entity | Description | Source Files |
|--------|-------------|--------------|
| User | Platform users (attendees and organizers) | User.swift |
| OrganizerProfile | Extended profile for organizer role | OrganizerProfile.swift |
| Event | Events created by organizers | Event.swift |
| Venue | Event location details | Event.swift (embedded) |
| TicketType | Ticket tiers for events | TicketType.swift |
| Ticket | Purchased tickets | Ticket.swift |
| Order | Purchase transactions (inferred) | TicketRepository.swift |
| Payment | Payment transactions | PaymentRepository.swift |
| Refund | Refund requests and transactions | RefundModels.swift |
| RefundPolicy | Event refund policies | RefundModels.swift |
| Attendee | Event attendee records | Attendee.swift |
| CheckIn | Ticket scan/check-in records (inferred) | Ticket.swift |
| Notification | User notifications | NotificationModel.swift |
| NotificationPreferences | User notification settings | NotificationPreferences.swift |
| EventCancellation | Event cancellation records | CancellationModels.swift |
| CompensationPlan | Refund/credit plans for cancellations | CancellationModels.swift |
| OrganizerAnalytics | Event analytics data | OrganizerAnalytics.swift |
| UserInterests | User preference data | UserInterests.swift |
| UserLocation | User location data | UserPreferences.swift |
| SupportTicket | Customer support requests | SupportModels.swift |
| OnboardingProfile | Onboarding state | OnboardingModels.swift |
| ExportRecord | Export audit records (inferred) | EventReportExportService.swift |

---

## Core Entities

### Entity: User

Primary user account entity supporting dual-role (attendee/organizer) functionality.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | User.swift:47 |
| firstName | String | Yes | User's first name | User.swift:48 |
| lastName | String | Yes | User's last name | User.swift:49 |
| email | String | No | Email address | User.swift:50 |
| phoneNumber | String | No | Phone number | User.swift:53 |
| profileImageUrl | String | No | Profile image URL | User.swift:52 |
| role | UserRole | Yes | Primary role (legacy) | User.swift:51 |
| dateJoined | Date | Yes | Account creation timestamp | User.swift:54 |
| dateOfBirth | Date | No | Birth date (privacy-sensitive) | User.swift:85 |
| city | String | No | User's city | User.swift:86 |
| country | String | No | User's country | User.swift:87 |
| isEmailVerified | Bool | Yes | Email verification status | User.swift:59 |
| isPhoneVerified | Bool | Yes | Phone verification status | User.swift:60 |
| authProviders | [String] | Yes | Auth methods used | User.swift:63 |
| isVerified | Bool | Yes | ID verification status | User.swift:66 |
| nationalIdNumber | String | No | National ID (encrypted) | User.swift:67 |
| nationalIdFrontImageUrl | String | No | ID front image URL | User.swift:68 |
| nationalIdBackImageUrl | String | No | ID back image URL | User.swift:69 |
| verificationDate | Date | No | ID verification timestamp | User.swift:70 |
| verificationDocumentType | VerificationDocumentType | No | Document type used | User.swift:71 |
| primaryContactMethod | ContactMethod | No | Preferred contact method | User.swift:74 |
| pendingEmail | String | No | Pending email change | User.swift:77 |
| pendingPhoneNumber | String | No | Pending phone change | User.swift:78 |
| hasCompletedOnboarding | Bool | Yes | Onboarding completion flag | User.swift:82 |
| allowLocationTracking | Bool | Yes | Location opt-in | User.swift:89 |
| isAttendeeRole | Bool | Yes | Can act as attendee | User.swift:103 |
| isOrganizerRole | Bool | Yes | Can act as organizer | User.swift:104 |
| isVerifiedOrganizer | Bool | Yes | ID verified for organizer | User.swift:105 |
| currentActiveRole | UserRole | Yes | Currently active role | User.swift:106 |
| favoriteEventIds | [UUID] | Yes | Favorited events | User.swift:55 |
| followedOrganizerIds | [UUID] | Yes | Followed organizers | User.swift:56 |
| viewedEventIds | [UUID] | Yes | Viewed events | User.swift:92 |
| likedEventIds | [UUID] | Yes | Liked events | User.swift:93 |
| purchasedEventIds | [UUID] | Yes | Purchased events | User.swift:94 |
| favoriteEventTypes | [String] | Yes | Preferred event categories | User.swift:81 |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |
| deletedAt | Date | No | **Backend: Soft delete** | Inferred |

**Computed Properties (not stored):**
- `fullName` - Concatenation of firstName + lastName
- `age` - Calculated from dateOfBirth
- `needsVerificationForOrganizerActions` - isOrganizer && !isVerified
- `availableRoles` - List of roles user can access
- `hasBothRoles` - isAttendeeRole && isOrganizerRole

---

### Entity: OrganizerProfile

Extended profile data for users with organizer role.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| userId | UUID | Yes | **Backend: Foreign key to User** | Inferred |
| publicEmail | String | Yes | Public contact email | OrganizerProfile.swift:13 |
| publicPhone | String | Yes | Public contact phone | OrganizerProfile.swift:14 |
| brandName | String | No | Organization/brand name | OrganizerProfile.swift:15 |
| website | String | No | Website URL | OrganizerProfile.swift:16 |
| instagramHandle | String | No | Instagram username | OrganizerProfile.swift:17 |
| twitterHandle | String | No | Twitter/X username | OrganizerProfile.swift:18 |
| facebookPage | String | No | Facebook page URL | OrganizerProfile.swift:19 |
| followerCount | Int | Yes | Number of followers | OrganizerProfile.swift:23 |
| agreedToTermsDate | Date | No | Terms acceptance date | OrganizerProfile.swift:21 |
| termsVersion | String | No | Terms version accepted | OrganizerProfile.swift:22 |
| completedOnboardingSteps | [OrganizerOnboardingStep] | Yes | Completed steps | OrganizerProfile.swift:20 |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

### Entity: PayoutMethod

Payout configuration for organizers.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| organizerProfileId | UUID | Yes | **Backend: Foreign key** | Inferred |
| type | PayoutMethodType | Yes | Payout method type | OrganizerProfile.swift:35 |
| phoneNumber | String | No | Mobile money number | OrganizerProfile.swift:36 |
| bankName | String | No | Bank name | OrganizerProfile.swift:37 |
| accountNumber | String | No | Bank account number | OrganizerProfile.swift:38 |
| accountName | String | No | Account holder name | OrganizerProfile.swift:39 |
| isVerified | Bool | Yes | Verification status | OrganizerProfile.swift:40 |
| isDefault | Bool | Yes | **Backend: Default method** | Inferred |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

### Entity: Event

Events created and managed by organizers.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | Event.swift:131 |
| title | String | Yes | Event title | Event.swift:132 |
| description | String | Yes | Event description | Event.swift:133 |
| organizerId | UUID | Yes | Foreign key to User | Event.swift:134 |
| organizerName | String | Yes | Denormalized organizer name | Event.swift:135 |
| posterUrl | String | No | Poster image URL | Event.swift:136 |
| category | EventCategory | Yes | Event category | Event.swift:137 |
| startDate | Date | Yes | Event start datetime | Event.swift:138 |
| endDate | Date | Yes | Event end datetime | Event.swift:139 |
| venueId | UUID | Yes | **Backend: Foreign key to Venue** | Inferred |
| status | EventStatus | Yes | Event status | Event.swift:141 |
| rating | Decimal | Yes | Average rating (0.0-5.0) | Event.swift:142 |
| totalRatings | Int | Yes | Number of ratings | Event.swift:143 |
| likeCount | Int | Yes | Number of likes | Event.swift:144 |
| ageRestriction | AgeRestriction | Yes | Age restriction | Event.swift:147 |
| createdAt | Date | Yes | Creation timestamp | Event.swift:145 |
| updatedAt | Date | Yes | Last update timestamp | Event.swift:146 |
| deletedAt | Date | No | **Backend: Soft delete** | Inferred |
| publishedAt | Date | No | **Backend: Publish timestamp** | Inferred |
| cancelledAt | Date | No | **Backend: Cancellation timestamp** | Inferred |

**Computed Properties (not stored):**
- `isHappeningNow` - Event currently in progress
- `isExpired` - Event has ended
- `priceRange` - Formatted price range from ticket types
- `timeCategory` - Today/This Week/This Month

---

### Entity: Venue

Event venue/location details.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| name | String | Yes | Venue name | Event.swift:115 |
| address | String | Yes | Street address | Event.swift:116 |
| city | String | Yes | City | Event.swift:117 |
| latitude | Decimal | Yes | GPS latitude | Event.swift:121 |
| longitude | Decimal | Yes | GPS longitude | Event.swift:122 |
| country | String | No | **Backend: Country** | Inferred |
| postalCode | String | No | **Backend: Postal code** | Inferred |
| capacity | Int | No | **Backend: Venue capacity** | Inferred |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

### Entity: TicketType

Ticket tiers/types available for an event.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | TicketType.swift:12 |
| eventId | UUID | Yes | **Backend: Foreign key to Event** | Inferred |
| name | String | Yes | Ticket type name | TicketType.swift:13 |
| price | Decimal | Yes | Price in UGX | TicketType.swift:14 |
| quantity | Int | Yes | Total available | TicketType.swift:15 |
| sold | Int | Yes | Number sold | TicketType.swift:16 |
| description | String | No | Type description | TicketType.swift:17 |
| perks | [String] | Yes | Benefits/perks list | TicketType.swift:18 |
| saleStartDate | Date | Yes | Sale start datetime | TicketType.swift:19 |
| saleEndDate | Date | Yes | Sale end datetime | TicketType.swift:20 |
| isUnlimitedQuantity | Bool | Yes | Unlimited inventory | TicketType.swift:21 |
| sortOrder | Int | Yes | **Backend: Display order** | Inferred |
| isActive | Bool | Yes | **Backend: Active flag** | Inferred |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

**Computed Properties (not stored):**
- `remaining` - quantity - sold
- `isSoldOut` - sold >= quantity
- `availabilityStatus` - TicketAvailabilityStatus enum
- `isAvailableForPurchase` - Active and in sale window

---

### Entity: Ticket

Individual purchased ticket instances.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | Ticket.swift:17 |
| ticketNumber | String | Yes | Unique ticket number | Ticket.swift:18 |
| orderNumber | String | Yes | Order reference | Ticket.swift:19 |
| eventId | UUID | Yes | Foreign key to Event | Ticket.swift:20 |
| ticketTypeId | UUID | Yes | **Backend: Foreign key to TicketType** | Inferred |
| userId | UUID | Yes | Foreign key to User | Ticket.swift:33 |
| purchaseDate | Date | Yes | Purchase timestamp | Ticket.swift:34 |
| scanStatus | TicketScanStatus | Yes | Current scan status | Ticket.swift:35 |
| scanDate | Date | No | Scan timestamp | Ticket.swift:36 |
| qrCodeData | String | Yes | QR code payload | Ticket.swift:37 |
| seatNumber | String | No | Assigned seat | Ticket.swift:38 |
| userRating | Decimal | No | User's event rating | Ticket.swift:39 |
| expiredAt | Date | No | Expiration timestamp | Ticket.swift:40 |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

**Denormalized Fields (for offline/display):**
| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| eventTitle | String | Yes | Event title | Ticket.swift:21 |
| eventDate | Date | Yes | Event start date | Ticket.swift:22 |
| eventEndDate | Date | Yes | Event end date | Ticket.swift:23 |
| eventVenue | String | Yes | Venue name | Ticket.swift:24 |
| eventVenueAddress | String | Yes | Venue address | Ticket.swift:25 |
| eventVenueCity | String | Yes | Venue city | Ticket.swift:26 |
| venueLatitude | Decimal | Yes | Venue latitude | Ticket.swift:27 |
| venueLongitude | Decimal | Yes | Venue longitude | Ticket.swift:28 |
| eventDescription | String | Yes | Event description | Ticket.swift:29 |
| eventOrganizerName | String | Yes | Organizer name | Ticket.swift:30 |
| eventPosterUrl | String | No | Poster URL | Ticket.swift:31 |

**Note:** Denormalized fields support offline ticket display without event fetch.

---

### Entity: Order

Purchase transaction grouping tickets.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| orderNumber | String | Yes | Order reference number | Ticket.swift:19 |
| userId | UUID | Yes | Foreign key to User | Inferred |
| eventId | UUID | Yes | Foreign key to Event | Inferred |
| totalAmount | Decimal | Yes | Order total in UGX | Inferred |
| currency | String | Yes | Currency code (UGX) | Inferred |
| status | OrderStatus | Yes | Order status | Inferred |
| paymentId | UUID | No | Foreign key to Payment | Inferred |
| ticketCount | Int | Yes | Number of tickets | Inferred |
| createdAt | Date | Yes | Order creation timestamp | Inferred |
| updatedAt | Date | Yes | Last update timestamp | Inferred |

---

### Entity: Attendee

Attendee records for event export/management.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | Attendee.swift:14 |
| eventId | UUID | Yes | Foreign key to Event | Attendee.swift:15 |
| ticketId | UUID | Yes | Foreign key to Ticket | Attendee.swift:16 |
| orderId | String | Yes | Order reference | Attendee.swift:17 |
| fullName | String | Yes | Attendee name | Attendee.swift:18 |
| ticketType | String | Yes | Ticket type name | Attendee.swift:19 |
| purchaseDate | Date | Yes | Purchase timestamp | Attendee.swift:20 |
| checkInStatus | CheckInStatus | Yes | Check-in status | Attendee.swift:21 |
| attendanceStatus | AttendanceStatus | Yes | Attendance status | Attendee.swift:22 |
| isVip | Bool | Yes | VIP ticket holder | Attendee.swift:23 |
| marketingConsent | Bool | Yes | Marketing opt-in | Attendee.swift:24 |

**Privacy Note:** Email and phone are intentionally NOT stored for privacy protection.

---

## Financial Entities

### Entity: Payment

Payment transaction records.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | PaymentRepository.swift:25 |
| amount | Decimal | Yes | Payment amount | PaymentRepository.swift:26 |
| currency | String | Yes | Currency code (UGX) | PaymentRepository.swift:27 |
| method | PaymentMethod | Yes | Payment method used | PaymentRepository.swift:28 |
| status | PaymentStatus | Yes | Payment status | PaymentRepository.swift:29 |
| userId | UUID | Yes | Foreign key to User | PaymentRepository.swift:30 |
| eventId | UUID | Yes | Foreign key to Event | PaymentRepository.swift:31 |
| ticketIds | [UUID] | Yes | Associated ticket IDs | PaymentRepository.swift:32 |
| mobileMoneyNumber | String | No | Mobile money number | PaymentRepository.swift:34 |
| transactionReference | String | No | **Backend: External reference** | Inferred |
| providerResponse | JSON | No | **Backend: Provider response** | Inferred |
| timestamp | Date | Yes | Payment timestamp | PaymentRepository.swift:33 |
| processedAt | Date | No | **Backend: Processing timestamp** | Inferred |
| failedAt | Date | No | **Backend: Failure timestamp** | Inferred |
| failureReason | String | No | **Backend: Failure reason** | Inferred |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

### Entity: RefundPolicy

Event refund policy configuration.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | RefundModels.swift:95 |
| eventId | UUID | Yes | Foreign key to Event | RefundModels.swift:96 |
| ticketTypeId | UUID | No | Optional ticket type | RefundModels.swift:97 |
| isRefundable | Bool | Yes | Refunds allowed | RefundModels.swift:98 |
| refundDeadlineHours | Int | Yes | Hours before event | RefundModels.swift:99 |
| refundPercentage | Decimal | Yes | Refund percentage (0.0-1.0) | RefundModels.swift:100 |
| processingFeePercentage | Decimal | Yes | Fee percentage | RefundModels.swift:101 |
| fullRefundDeadlineHours | Int | No | Full refund cutoff | RefundModels.swift:102 |
| partialRefundDeadlineHours | Int | No | Partial refund cutoff | RefundModels.swift:103 |
| partialRefundPercentage | Decimal | No | Partial percentage | RefundModels.swift:104 |
| allowRescheduledEventRefund | Bool | Yes | Allow on reschedule | RefundModels.swift:105 |
| allowTransfer | Bool | Yes | Allow ticket transfer | RefundModels.swift:106 |
| requiresApproval | Bool | Yes | Manual approval needed | RefundModels.swift:107 |
| maxRefundsPerUser | Int | No | User refund limit | RefundModels.swift:108 |
| policyText | String | Yes | Full policy text | RefundModels.swift:109 |
| createdAt | Date | Yes | Creation timestamp | RefundModels.swift:110 |
| updatedAt | Date | Yes | Update timestamp | RefundModels.swift:111 |

---

### Entity: RefundRequest

Refund request records.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | RefundModels.swift:118 |
| ticketId | UUID | Yes | Foreign key to Ticket | RefundModels.swift:119 |
| ticketNumber | String | Yes | Ticket number | RefundModels.swift:120 |
| eventId | UUID | Yes | Foreign key to Event | RefundModels.swift:121 |
| eventTitle | String | Yes | Event title | RefundModels.swift:122 |
| userId | UUID | Yes | Foreign key to User | RefundModels.swift:123 |
| userName | String | Yes | User name | RefundModels.swift:124 |
| userEmail | String | No | User email | RefundModels.swift:125 |
| userPhone | String | No | User phone | RefundModels.swift:126 |
| reason | RefundReason | Yes | Refund reason | RefundModels.swift:127 |
| userNote | String | No | User's note | RefundModels.swift:128 |
| requestedAmount | Decimal | Yes | Requested amount | RefundModels.swift:129 |
| approvedAmount | Decimal | No | Approved amount | RefundModels.swift:130 |
| currency | String | Yes | Currency code | RefundModels.swift:131 |
| originalPaymentMethod | RefundPaymentMethod | Yes | Original payment | RefundModels.swift:132 |
| originalPaymentReference | String | Yes | Payment reference | RefundModels.swift:133 |
| originalPurchaseDate | Date | Yes | Purchase date | RefundModels.swift:134 |
| status | RefundStatus | Yes | Request status | RefundModels.swift:135 |
| requestedAt | Date | Yes | Request timestamp | RefundModels.swift:136 |
| reviewedAt | Date | No | Review timestamp | RefundModels.swift:137 |
| reviewedBy | UUID | No | Reviewer user ID | RefundModels.swift:138 |
| reviewerNote | String | No | Reviewer's note | RefundModels.swift:139 |
| processedAt | Date | No | Processing timestamp | RefundModels.swift:140 |
| completedAt | Date | No | Completion timestamp | RefundModels.swift:141 |
| failureReason | String | No | Failure reason | RefundModels.swift:142 |

---

### Entity: RefundTransaction

Executed refund transaction records.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | RefundModels.swift:163 |
| refundRequestId | UUID | Yes | Foreign key to RefundRequest | RefundModels.swift:164 |
| ticketId | UUID | Yes | Foreign key to Ticket | RefundModels.swift:165 |
| eventId | UUID | Yes | Foreign key to Event | RefundModels.swift:166 |
| userId | UUID | Yes | Foreign key to User | RefundModels.swift:167 |
| organizerId | UUID | Yes | Foreign key to Organizer | RefundModels.swift:168 |
| originalAmount | Decimal | Yes | Original ticket price | RefundModels.swift:169 |
| refundAmount | Decimal | Yes | Refund amount | RefundModels.swift:170 |
| processingFee | Decimal | Yes | Processing fee | RefundModels.swift:171 |
| netRefund | Decimal | Yes | Net refund amount | RefundModels.swift:172 |
| currency | String | Yes | Currency code | RefundModels.swift:173 |
| paymentMethod | RefundPaymentMethod | Yes | Payment method | RefundModels.swift:174 |
| paymentReference | String | Yes | Payment reference | RefundModels.swift:175 |
| transactionReference | String | Yes | External reference | RefundModels.swift:176 |
| status | RefundStatus | Yes | Transaction status | RefundModels.swift:177 |
| reason | RefundReason | Yes | Refund reason | RefundModels.swift:178 |
| initiatedAt | Date | Yes | Initiation timestamp | RefundModels.swift:179 |
| processedAt | Date | No | Processing timestamp | RefundModels.swift:180 |
| completedAt | Date | No | Completion timestamp | RefundModels.swift:181 |
| failedAt | Date | No | Failure timestamp | RefundModels.swift:182 |
| failureReason | String | No | Failure reason | RefundModels.swift:183 |
| processedBy | UUID | No | Processor user/system ID | RefundModels.swift:184 |
| notes | String | No | Additional notes | RefundModels.swift:185 |

---

### Entity: EventCancellation

Event cancellation records.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | CancellationModels.swift:138 |
| eventId | UUID | Yes | Foreign key to Event | CancellationModels.swift:139 |
| eventTitle | String | Yes | Event title | CancellationModels.swift:140 |
| organizerId | UUID | Yes | Foreign key to Organizer | CancellationModels.swift:141 |
| reason | CancellationReason | Yes | Cancellation reason | CancellationModels.swift:142 |
| reasonNote | String | No | Additional note | CancellationModels.swift:143 |
| status | CancellationStatus | Yes | Cancellation status | CancellationModels.swift:144 |
| createdAt | Date | Yes | Creation timestamp | CancellationModels.swift:147 |
| confirmedAt | Date | No | Confirmation timestamp | CancellationModels.swift:148 |
| processingStartedAt | Date | No | Processing start | CancellationModels.swift:149 |
| completedAt | Date | No | Completion timestamp | CancellationModels.swift:150 |
| initiatedBy | UUID | Yes | Initiator user ID | CancellationModels.swift:151 |
| confirmedBy | UUID | No | Confirmer user ID | CancellationModels.swift:152 |
| confirmationCode | String | No | Confirmation code | CancellationModels.swift:153 |
| refundRequestsCreated | Int | Yes | Refund requests created | CancellationModels.swift:154 |
| refundsProcessed | Int | Yes | Refunds completed | CancellationModels.swift:155 |
| refundsFailed | Int | Yes | Refunds failed | CancellationModels.swift:156 |
| notificationsSent | Int | Yes | Notifications sent | CancellationModels.swift:157 |
| notificationsFailed | Int | Yes | Notifications failed | CancellationModels.swift:158 |

---

### Entity: CancellationImpact

Cancellation financial impact snapshot.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| eventId | UUID | Yes | Foreign key to Event | CancellationModels.swift:31 |
| cancellationId | UUID | Yes | **Backend: Foreign key** | Inferred |
| calculatedAt | Date | Yes | Calculation timestamp | CancellationModels.swift:32 |
| ticketsSold | Int | Yes | Total tickets sold | CancellationModels.swift:35 |
| attendeesCount | Int | Yes | Unique attendees | CancellationModels.swift:36 |
| vipTickets | Int | Yes | VIP ticket count | CancellationModels.swift:37 |
| regularTickets | Int | Yes | Regular ticket count | CancellationModels.swift:38 |
| checkInsCompleted | Int | Yes | Checked-in count | CancellationModels.swift:39 |
| pendingPayments | Int | Yes | Pending payments | CancellationModels.swift:40 |
| transferredTickets | Int | Yes | Transferred tickets | CancellationModels.swift:41 |
| partiallyRefundedTickets | Int | Yes | Partially refunded | CancellationModels.swift:42 |
| grossRevenue | Decimal | Yes | Total revenue | CancellationModels.swift:45 |
| refundTotal | Decimal | Yes | Total refunds | CancellationModels.swift:46 |
| platformFeesRetained | Decimal | Yes | Retained fees | CancellationModels.swift:47 |
| processingFeesEstimate | Decimal | Yes | Processing fees | CancellationModels.swift:48 |
| netRefundAmount | Decimal | Yes | Net refund | CancellationModels.swift:49 |
| organizerPayoutAdjustment | Decimal | Yes | Payout adjustment | CancellationModels.swift:50 |
| currency | String | Yes | Currency code | CancellationModels.swift:51 |

---

### Entity: CompensationPlan

Compensation configuration for cancellations.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | CancellationModels.swift:95 |
| eventId | UUID | Yes | Foreign key to Event | CancellationModels.swift:96 |
| cancellationId | UUID | Yes | **Backend: Foreign key** | Inferred |
| compensationType | CompensationType | Yes | Compensation type | CancellationModels.swift:97 |
| refundPercentage | Decimal | Yes | Refund percentage (0.0-1.0) | CancellationModels.swift:98 |
| creditMultiplier | Decimal | No | Credit bonus (e.g., 1.1) | CancellationModels.swift:99 |
| processingMethod | ProcessingMethod | Yes | Processing method | CancellationModels.swift:100 |
| processingDeadline | Date | Yes | Processing deadline | CancellationModels.swift:101 |
| totalRefundAmount | Decimal | Yes | Total refund amount | CancellationModels.swift:102 |
| platformFeeHandling | PlatformFeeHandling | Yes | Fee handling | CancellationModels.swift:103 |
| estimatedProcessingFees | Decimal | Yes | Estimated fees | CancellationModels.swift:104 |
| organizerNote | String | No | Public organizer note | CancellationModels.swift:105 |
| internalNote | String | No | Internal note | CancellationModels.swift:106 |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

## Analytics Entities

### Entity: OrganizerAnalytics

Event analytics snapshot.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | OrganizerAnalytics.swift:13 |
| eventId | UUID | Yes | Foreign key to Event | OrganizerAnalytics.swift:14 |
| eventTitle | String | Yes | Event title | OrganizerAnalytics.swift:15 |
| lastUpdated | Date | Yes | Last calculation | OrganizerAnalytics.swift:16 |
| revenue | Decimal | Yes | Total revenue | OrganizerAnalytics.swift:19 |
| ticketsSold | Int | Yes | Tickets sold | OrganizerAnalytics.swift:20 |
| totalCapacity | Int | Yes | Total capacity | OrganizerAnalytics.swift:21 |
| attendanceRate | Decimal | Yes | Attendance rate (0.0-1.0) | OrganizerAnalytics.swift:22 |
| capacityUsed | Decimal | Yes | Capacity used (0.0-1.0) | OrganizerAnalytics.swift:23 |
| salesTarget | Decimal | Yes | Sales target | OrganizerAnalytics.swift:24 |
| salesProgress | Decimal | Yes | Progress (0.0-1.0) | OrganizerAnalytics.swift:25 |
| ticketVelocity | Decimal | Yes | Tickets per hour | OrganizerAnalytics.swift:30 |
| dailySalesAverage | Decimal | Yes | Daily average | OrganizerAnalytics.swift:32 |
| peakSalesDay | String | No | Peak sales day | OrganizerAnalytics.swift:33 |
| totalAttendees | Int | Yes | Total attendees | OrganizerAnalytics.swift:36 |
| repeatAttendees | Int | Yes | Repeat attendees | OrganizerAnalytics.swift:37 |
| repeatRate | Decimal | Yes | Repeat rate (0.0-1.0) | OrganizerAnalytics.swift:38 |
| vipShare | Decimal | Yes | VIP percentage (0.0-1.0) | OrganizerAnalytics.swift:39 |
| eventViews | Int | Yes | Total views | OrganizerAnalytics.swift:44 |
| uniqueViews | Int | Yes | Unique views | OrganizerAnalytics.swift:45 |
| conversionRate | Decimal | Yes | Conversion rate (0.0-1.0) | OrganizerAnalytics.swift:46 |
| shareCount | Int | Yes | Share count | OrganizerAnalytics.swift:49 |
| saveCount | Int | Yes | Save/favorite count | OrganizerAnalytics.swift:50 |
| checkinRate | Decimal | Yes | Check-in rate (0.0-1.0) | OrganizerAnalytics.swift:53 |
| peakArrivalTime | String | No | Peak arrival time | OrganizerAnalytics.swift:54 |
| averageArrivalTime | String | No | Average arrival | OrganizerAnalytics.swift:55 |
| queueEstimate | Int | Yes | Queue wait (minutes) | OrganizerAnalytics.swift:56 |
| grossRevenue | Decimal | Yes | Gross revenue | OrganizerAnalytics.swift:60 |
| netRevenue | Decimal | Yes | Net revenue | OrganizerAnalytics.swift:61 |
| platformFees | Decimal | Yes | Platform fees | OrganizerAnalytics.swift:62 |
| processingFees | Decimal | Yes | Processing fees | OrganizerAnalytics.swift:63 |
| refundsTotal | Decimal | Yes | Total refunds | OrganizerAnalytics.swift:64 |
| refundsCount | Int | Yes | Refund count | OrganizerAnalytics.swift:65 |
| revenueForecast | Decimal | No | Revenue forecast | OrganizerAnalytics.swift:69 |
| healthScore | Int | Yes | Health score (0-100) | OrganizerAnalytics.swift:70 |

---

### Entity: SalesDataPoint

Time-series sales data.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | OrganizerAnalytics.swift:122 |
| analyticsId | UUID | Yes | **Backend: Foreign key** | Inferred |
| date | Date | Yes | Data point date | OrganizerAnalytics.swift:123 |
| sales | Int | Yes | Sales count | OrganizerAnalytics.swift:124 |
| revenue | Decimal | Yes | Revenue amount | OrganizerAnalytics.swift:125 |

---

### Entity: TierSalesData

Per-ticket-type sales analytics.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | OrganizerAnalytics.swift:136 |
| analyticsId | UUID | Yes | **Backend: Foreign key** | Inferred |
| tierName | String | Yes | Ticket type name | OrganizerAnalytics.swift:137 |
| sold | Int | Yes | Tickets sold | OrganizerAnalytics.swift:138 |
| capacity | Int | Yes | Tier capacity | OrganizerAnalytics.swift:139 |
| revenue | Decimal | Yes | Tier revenue | OrganizerAnalytics.swift:140 |
| price | Decimal | Yes | Ticket price | OrganizerAnalytics.swift:141 |
| color | String | Yes | Display color (hex) | OrganizerAnalytics.swift:142 |

---

### Entity: PaymentMethodData

Payment method breakdown analytics.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | OrganizerAnalytics.swift:298 |
| analyticsId | UUID | Yes | **Backend: Foreign key** | Inferred |
| method | String | Yes | Payment method name | OrganizerAnalytics.swift:299 |
| amount | Decimal | Yes | Total amount | OrganizerAnalytics.swift:300 |
| count | Int | Yes | Transaction count | OrganizerAnalytics.swift:301 |
| percentage | Decimal | Yes | Percentage (0.0-1.0) | OrganizerAnalytics.swift:302 |
| color | String | Yes | Display color (hex) | OrganizerAnalytics.swift:303 |
| icon | String | Yes | SF Symbol icon | OrganizerAnalytics.swift:304 |

---

### Entity: ExportRecord

Export audit trail.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| eventId | UUID | Yes | Foreign key to Event | EventReportExportService.swift |
| userId | UUID | Yes | **Backend: Exporter user ID** | Inferred |
| exportType | String | Yes | Export type (report/attendee) | EventReportExportService.swift |
| format | String | Yes | File format (pdf/csv) | EventReportExportService.swift |
| filterType | String | No | Filter applied | AttendeeExportService.swift |
| recordCount | Int | No | Records exported | AttendeeExportService.swift |
| fileSize | Int | No | **Backend: File size bytes** | Inferred |
| exportedAt | Date | Yes | Export timestamp | EventReportExportService.swift |

---

## Support Entities

### Entity: Notification

User notification records.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | NotificationModel.swift:11 |
| type | NotificationType | Yes | Notification type | NotificationModel.swift:12 |
| title | String | Yes | Notification title | NotificationModel.swift:13 |
| message | String | Yes | Notification body | NotificationModel.swift:14 |
| timestamp | Date | Yes | Creation timestamp | NotificationModel.swift:15 |
| isRead | Bool | Yes | Read status | NotificationModel.swift:16 |
| relatedEventId | UUID | No | Related event | NotificationModel.swift:17 |
| relatedTicketId | UUID | No | Related ticket | NotificationModel.swift:18 |
| relatedUserId | UUID | No | Related user | NotificationModel.swift:19 |
| recipientUserId | UUID | Yes | **Backend: Recipient** | Inferred |
| deliveredAt | Date | No | **Backend: Delivery timestamp** | Inferred |
| openedAt | Date | No | **Backend: Open timestamp** | Inferred |

---

### Entity: NotificationPreferences

User notification settings.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| userId | UUID | Yes | **Backend: Foreign key to User** | Inferred |
| isEnabled | Bool | Yes | Master toggle | UserPreferences.swift:71 |
| eventReminders24h | Bool | Yes | 24h reminder | UserPreferences.swift:72 |
| eventReminders2h | Bool | Yes | 2h reminder | UserPreferences.swift:73 |
| eventReminders30m | Bool | No | 30m reminder | UserPreferences.swift:74 |
| eventStartingSoon | Bool | Yes | Starting soon alert | UserPreferences.swift:75 |
| ticketPurchaseConfirmation | Bool | Yes | Purchase confirmation | UserPreferences.swift:76 |
| eventUpdates | Bool | Yes | Event updates | UserPreferences.swift:77 |
| recommendations | Bool | Yes | Recommendations | UserPreferences.swift:78 |
| marketing | Bool | Yes | Marketing opt-in | UserPreferences.swift:79 |
| organizerTicketSold | Bool | No | Organizer: ticket sold | UserPreferences.swift:80 |
| organizerLowInventory | Bool | No | Organizer: low stock | UserPreferences.swift:81 |
| organizerCheckIns | Bool | No | Organizer: check-ins | UserPreferences.swift:82 |
| organizerEventReminders | Bool | No | Organizer: reminders | UserPreferences.swift:83 |
| quietHoursEnabled | Bool | Yes | Quiet hours on | UserPreferences.swift:84 |
| quietHoursStartHour | Int | Yes | Start hour (0-23) | UserPreferences.swift:85 |
| quietHoursStartMinute | Int | Yes | Start minute (0-59) | UserPreferences.swift:85 |
| quietHoursEndHour | Int | Yes | End hour (0-23) | UserPreferences.swift:86 |
| quietHoursEndMinute | Int | Yes | End minute (0-59) | UserPreferences.swift:86 |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

### Entity: UserInterests

User preference and behavior data.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| userId | UUID | Yes | **Backend: Foreign key to User** | Inferred |
| preferredCategories | [EventCategory] | Yes | Selected categories | UserInterests.swift:14 |
| inferredCategories | [EventCategory] | Yes | Behavior-inferred | UserInterests.swift:15 |
| preferredCities | [String] | Yes | Preferred cities | UserInterests.swift:16 |
| maxTravelDistance | Decimal | No | Max distance (km) | UserInterests.swift:17 |
| preferredEventTypes | [String] | Yes | Free-form types | UserInterests.swift:18 |
| pricePreference | PricePreference | No | Price range | UserInterests.swift:19 |
| prefersFreeEvents | Bool | Yes | Free events interest | UserInterests.swift:20 |
| preferredDaysOfWeek | [Int] | Yes | Preferred days (0-6) | UserInterests.swift:21 |
| preferredTimeOfDay | [TimeOfDayPreference] | Yes | Preferred times | UserInterests.swift:22 |
| prefersPopularEvents | Bool | Yes | Popular events interest | UserInterests.swift:24 |
| lastUpdated | Date | Yes | Last update timestamp | UserInterests.swift:28 |

---

### Entity: UserLocation

User location data.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| userId | UUID | Yes | **Backend: Foreign key to User** | Inferred |
| city | String | Yes | City name | UserPreferences.swift:17 |
| country | String | Yes | Country name | UserPreferences.swift:18 |
| latitude | Decimal | Yes | GPS latitude | UserPreferences.swift:20 |
| longitude | Decimal | Yes | GPS longitude | UserPreferences.swift:21 |
| lastUpdated | Date | Yes | Last update timestamp | UserPreferences.swift:22 |

---

### Entity: SupportTicket

Customer support request records.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | SupportModels.swift:41 |
| name | String | Yes | User's name | SupportModels.swift:42 |
| contactInfo | String | Yes | Contact information | SupportModels.swift:43 |
| category | SupportCategory | Yes | Support category | SupportModels.swift:44 |
| description | String | Yes | Issue description | SupportModels.swift:45 |
| attachmentUrl | String | No | Attachment URL | SupportModels.swift:46 |
| appVersion | String | Yes | App version | SupportModels.swift:47 |
| deviceModel | String | Yes | Device model | SupportModels.swift:48 |
| iosVersion | String | Yes | iOS version | SupportModels.swift:49 |
| userId | String | Yes | User ID | SupportModels.swift:50 |
| createdAt | Date | Yes | Creation timestamp | SupportModels.swift:51 |
| status | TicketStatus | Yes | **Backend: Ticket status** | Inferred |
| assignedTo | UUID | No | **Backend: Assigned agent** | Inferred |
| resolvedAt | Date | No | **Backend: Resolution timestamp** | Inferred |
| resolution | String | No | **Backend: Resolution notes** | Inferred |

---

### Entity: SavedPaymentMethod

User saved payment methods.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | Primary key | NotificationPreferences.swift:32 |
| userId | UUID | Yes | **Backend: Foreign key to User** | Inferred |
| type | PaymentMethodType | Yes | Payment type | NotificationPreferences.swift:33 |
| isDefault | Bool | Yes | Default method | NotificationPreferences.swift:34 |
| displayName | String | Yes | Display name | NotificationPreferences.swift:35 |
| mobileMoneyNumber | String | No | Mobile money number | NotificationPreferences.swift:36 |
| lastFourDigits | String | No | Card last 4 digits | NotificationPreferences.swift:37 |
| cardBrand | String | No | Card brand | NotificationPreferences.swift:38 |
| expiryMonth | Int | No | Card expiry month | NotificationPreferences.swift:39 |
| expiryYear | Int | No | Card expiry year | NotificationPreferences.swift:40 |
| cardholderName | String | No | Cardholder name | NotificationPreferences.swift:41 |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

### Entity: OnboardingProfile

Onboarding state persistence.

| Field | Type | Required | Description | Source |
|-------|------|----------|-------------|--------|
| id | UUID | Yes | **Backend: Primary key** | Inferred |
| userId | UUID | Yes | **Backend: Foreign key to User** | Inferred |
| role | UserRole | No | Selected role | OnboardingModels.swift |
| fullName | String | Yes | User's full name | OnboardingModels.swift |
| dateOfBirth | Date | No | Birth date | OnboardingModels.swift |
| interests | [InterestCategory] | Yes | Event interests | OnboardingModels.swift |
| eventTypes | [OrganizerEventType] | Yes | Organizer event types | OnboardingModels.swift |
| notificationsEnabled | Bool | Yes | Notification opt-in | OnboardingModels.swift |
| completed | Bool | Yes | Completion flag | OnboardingModels.swift |
| completedAt | Date | No | **Backend: Completion timestamp** | Inferred |
| createdAt | Date | Yes | **Backend: Record creation** | Inferred |
| updatedAt | Date | Yes | **Backend: Last update** | Inferred |

---

## Enumerations

### User & Auth Enums

```
UserRole:
  - attendee
  - organizer

ContactMethod:
  - email
  - phone

VerificationDocumentType:
  - nationalId
  - passport

OrganizerOnboardingStep:
  - profileCompletion
  - identityVerification
  - contactInformation
  - payoutSetup
  - termsAgreement
```

### Event Enums

```
EventCategory:
  - music
  - artsCulture
  - concerts
  - sportsWellness
  - technology
  - fundraising
  - comedy
  - poetry
  - drama
  - exhibitions
  - networking
  - education
  - food
  - nightlife
  - festivals
  - other

EventStatus:
  - draft
  - published
  - ongoing
  - completed
  - cancelled

AgeRestriction:
  - none (0)
  - thirteen (13)
  - sixteen (16)
  - eighteen (18)
  - twentyOne (21)

TimeCategory:
  - today
  - thisWeek
  - thisMonth
```

### Ticket Enums

```
TicketScanStatus:
  - unused
  - scanned
  - expired

TicketAvailabilityStatus:
  - upcoming
  - active
  - expired
  - soldOut

CheckInStatus:
  - notCheckedIn
  - checkedIn
  - noShow

AttendanceStatus:
  - expected
  - attended
  - absent
```

### Payment Enums

```
PaymentMethod:
  - mtnMomo
  - airtelMoney
  - card

PaymentStatus:
  - pending
  - processing
  - completed
  - failed
  - refunded

PaymentMethodType:
  - mtnMomo
  - airtelMoney
  - card
  - cash

PayoutMethodType:
  - mtnMomo
  - airtelMoney
  - bankAccount
```

### Refund Enums

```
RefundStatus:
  - pending
  - approved
  - rejected
  - processing
  - completed
  - failed

RefundReason:
  - eventCancelled
  - eventRescheduled
  - cannotAttend
  - duplicatePurchase
  - organizerDecision
  - fraudulent
  - ticketDowngrade
  - other

RefundPaymentMethod:
  - mtnMobileMoney
  - airtelMoney
  - card
  - bankTransfer
  - wallet

TicketRefundState:
  - none
  - eligible
  - requested
  - approved
  - rejected
  - processing
  - refunded
```

### Cancellation Enums

```
CancellationStatus:
  - draft
  - confirming
  - processing
  - completed
  - failed

CancellationReason:
  - organizerDecision
  - venueIssue
  - forceMajeure
  - regulation
  - lowSales
  - duplicate
  - adminAction

CompensationType:
  - fullRefund
  - partialRefund
  - eventCredit

ProcessingMethod:
  - automatic
  - manual
  - hybrid

PlatformFeeHandling:
  - waive
  - deduct
  - organizerPays
```

### Notification Enums

```
NotificationType:
  - eventReminder
  - ticketPurchased
  - eventUpdate
  - newEvent
  - ticketScanned
  - paymentReceived
  - newFollower

PushNotificationType:
  - eventReminder24h
  - eventReminder2h
  - eventReminder30m
  - eventStartingSoon
  - ticketPurchase
  - eventUpdate
  - recommendation
  - marketing
  - ticketSold
  - lowInventory
  - attendeeCheckIn
  - organizerEventStart
```

### User Preference Enums

```
PricePreference:
  - free
  - budget
  - moderate
  - premium
  - any

TimeOfDayPreference:
  - morning (6-12)
  - afternoon (12-17)
  - evening (17-21)
  - night (21-6)

SupportCategory:
  - payments
  - ticketNotFound
  - qrScanning
  - accountIssues
  - organizerSupport
  - other
```

### Analytics Enums

```
AlertType:
  - lowSales
  - highDemand
  - nearSellOut
  - revenueForecast
  - slowSales
  - pricingOpportunity
  - refundSpike
  - capacityWarning

AlertSeverity:
  - info
  - warning
  - success
  - critical
```

---

## Entity Relationships

### Primary Relationships

```
User 1 ←→ 1 OrganizerProfile (optional)
User 1 ←→ 1 UserInterests
User 1 ←→ 1 UserLocation (optional)
User 1 ←→ 1 NotificationPreferences
User 1 ←→ * SavedPaymentMethod
User 1 ←→ * Ticket (as buyer)
User 1 ←→ * Event (as organizer)
User 1 ←→ * Notification
User 1 ←→ * RefundRequest
User 1 ←→ * Order
User 1 ←→ * Payment

OrganizerProfile 1 ←→ * PayoutMethod

Event 1 ←→ 1 Venue
Event 1 ←→ * TicketType
Event 1 ←→ * Ticket
Event 1 ←→ * Attendee
Event 1 ←→ * RefundPolicy
Event 1 ←→ 1 OrganizerAnalytics
Event 1 ←→ 0..1 EventCancellation

TicketType 1 ←→ * Ticket

Ticket 1 ←→ 1 Order
Ticket 1 ←→ 0..1 RefundRequest
Ticket 1 ←→ 0..1 Attendee
Ticket 1 ←→ 0..1 CheckIn (via scanStatus)

Order 1 ←→ * Ticket
Order 1 ←→ 1 Payment

Payment 1 ←→ 0..1 RefundTransaction

RefundRequest 1 ←→ 0..1 RefundTransaction
RefundRequest 1 ←→ * RefundStatusChange

EventCancellation 1 ←→ 1 CancellationImpact
EventCancellation 1 ←→ 1 CompensationPlan
EventCancellation 1 ←→ * RefundRequest (via eventId)

OrganizerAnalytics 1 ←→ * SalesDataPoint
OrganizerAnalytics 1 ←→ * TierSalesData
OrganizerAnalytics 1 ←→ * PaymentMethodData
```

### Relationship Diagram (Simplified)

```
                          ┌─────────────────┐
                          │      User       │
                          └────────┬────────┘
                                   │
          ┌────────────────┬───────┼───────┬────────────────┐
          │                │       │       │                │
          ▼                ▼       ▼       ▼                ▼
   ┌──────────────┐ ┌──────────┐ ┌────┐ ┌──────────────┐ ┌───────┐
   │OrganizerProf.│ │UserInterests│ │...│ │Notification  │ │Payment│
   └──────┬───────┘ └──────────┘     │  │  Preferences │ └───┬───┘
          │                          │  └──────────────┘     │
          ▼                          ▼                       ▼
   ┌──────────────┐           ┌──────────┐            ┌───────────┐
   │    Event     │◄──────────┤  Ticket  │────────────┤   Order   │
   └──────┬───────┘           └────┬─────┘            └───────────┘
          │                        │
    ┌─────┼─────┐                  │
    │     │     │                  ▼
    ▼     ▼     ▼           ┌────────────┐
┌───────┐│┌──────────┐      │RefundRequest│
│ Venue │││TicketType│      └──────┬─────┘
└───────┘│└──────────┘             │
         │                         ▼
         ▼                  ┌──────────────┐
  ┌──────────────────┐      │RefundTrans.  │
  │OrganizerAnalytics│      └──────────────┘
  └──────────────────┘
```

---

## Naming Conventions

### Entity Naming
- **Singular nouns**: `User`, `Event`, `Ticket` (not Users, Events, Tickets)
- **PascalCase** for entity names
- **Compound names**: `TicketType`, `RefundRequest`, `OrganizerProfile`

### Field Naming
- **camelCase** for all field names
- **ID suffix**: `userId`, `eventId`, `ticketTypeId`
- **Boolean prefix**: `is`, `has`, `allows`, `can` (e.g., `isVerified`, `hasCompletedOnboarding`)
- **Date suffix**: `At` for timestamps (e.g., `createdAt`, `deletedAt`, `processedAt`)
- **URL suffix**: `Url` (e.g., `posterUrl`, `profileImageUrl`)

### Enum Naming
- **PascalCase** for enum type names
- **camelCase** for enum values
- **Raw values**: String for serialization compatibility

---

## Data Type Standards

### Primary Keys
- **Type**: UUID (String format)
- **Format**: Standard UUID v4 (e.g., "550e8400-e29b-41d4-a716-446655440000")

### Dates
- **Type**: Date
- **Format**: ISO 8601 (e.g., "2026-02-20T15:30:00Z")
- **Timezone**: UTC for storage, localized for display

### Money/Currency
- **Type**: Decimal (not Double/Float)
- **Precision**: 2 decimal places
- **Currency**: Stored separately as String (default "UGX")
- **Storage**: Store in smallest unit (cents) as Integer for precision

### Percentages
- **Type**: Decimal
- **Range**: 0.0 to 1.0 (not 0-100)
- **Display**: Multiply by 100 for UI

### Coordinates
- **Type**: Decimal
- **Precision**: 6 decimal places
- **Range**: Latitude (-90 to 90), Longitude (-180 to 180)

### Phone Numbers
- **Type**: String
- **Format**: E.164 (e.g., "+256771234567")

### Email Addresses
- **Type**: String
- **Validation**: RFC 5322 compliant

---

## Audit Fields

All entities should include these standard audit fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| createdAt | Date | Yes | Record creation timestamp |
| updatedAt | Date | Yes | Last modification timestamp |
| deletedAt | Date | No | Soft delete timestamp (null = active) |
| createdBy | UUID | No | Creator user ID |
| updatedBy | UUID | No | Last modifier user ID |

### Soft Delete Strategy
- Use `deletedAt` field for soft deletes
- Query with `WHERE deletedAt IS NULL` for active records
- Cascade soft deletes where appropriate (e.g., Event → TicketTypes)

### Versioning (Optional)
For entities requiring version tracking:

| Field | Type | Description |
|-------|------|-------------|
| version | Int | Optimistic locking version |
| previousVersionId | UUID | Link to previous version |

---

## Index Recommendations

### High-Priority Indexes

```sql
-- User lookups
CREATE INDEX idx_user_email ON User(email);
CREATE INDEX idx_user_phone ON User(phoneNumber);

-- Event queries
CREATE INDEX idx_event_organizer ON Event(organizerId);
CREATE INDEX idx_event_status ON Event(status);
CREATE INDEX idx_event_category ON Event(category);
CREATE INDEX idx_event_dates ON Event(startDate, endDate);
CREATE INDEX idx_event_city ON Event(venueId); -- via Venue.city

-- Ticket queries
CREATE INDEX idx_ticket_event ON Ticket(eventId);
CREATE INDEX idx_ticket_user ON Ticket(userId);
CREATE INDEX idx_ticket_order ON Ticket(orderNumber);
CREATE INDEX idx_ticket_status ON Ticket(scanStatus);

-- Payment queries
CREATE INDEX idx_payment_user ON Payment(userId);
CREATE INDEX idx_payment_event ON Payment(eventId);
CREATE INDEX idx_payment_status ON Payment(status);

-- Refund queries
CREATE INDEX idx_refund_ticket ON RefundRequest(ticketId);
CREATE INDEX idx_refund_event ON RefundRequest(eventId);
CREATE INDEX idx_refund_status ON RefundRequest(status);

-- Notification queries
CREATE INDEX idx_notification_user ON Notification(recipientUserId);
CREATE INDEX idx_notification_read ON Notification(isRead);
CREATE INDEX idx_notification_type ON Notification(type);
```

---

## Validation Rules

### User
- `email`: Valid email format (RFC 5322)
- `phoneNumber`: Valid E.164 format
- `firstName`, `lastName`: 2-50 characters
- `dateOfBirth`: Must be at least 13 years ago

### Event
- `title`: 3-100 characters
- `description`: 10-5000 characters
- `startDate`: Must be in the future (for new events)
- `endDate`: Must be after startDate
- `category`: Must be valid EventCategory

### TicketType
- `name`: 2-50 characters
- `price`: >= 0
- `quantity`: > 0 (unless isUnlimitedQuantity)
- `saleStartDate`: Before saleEndDate
- `saleEndDate`: Before or equal to event.startDate

### Payment
- `amount`: > 0
- `mobileMoneyNumber`: Valid format for selected method

### Refund
- `requestedAmount`: <= original ticket price
- `approvedAmount`: <= requestedAmount

---

## Security Considerations

### Sensitive Fields (Encrypt at Rest)
- `User.nationalIdNumber`
- `PayoutMethod.accountNumber`
- `SavedPaymentMethod.mobileMoneyNumber`
- `SavedPaymentMethod.cardholderName`

### PII Fields (Access Control Required)
- `User.email`
- `User.phoneNumber`
- `User.dateOfBirth`
- `User.nationalIdFrontImageUrl`
- `User.nationalIdBackImageUrl`

### Never Export
- `User.dateOfBirth` (age only if needed)
- `User.email` (without explicit consent)
- `User.phoneNumber` (without explicit consent)
- Any payment credentials

---

## API Considerations

### Pagination
All list endpoints should support:
- `limit`: Number of records (default 20, max 100)
- `offset`: Starting position
- `cursor`: Cursor-based pagination for large datasets

### Filtering
Standard filter parameters:
- `status`: Filter by status enum
- `startDate`, `endDate`: Date range filters
- `category`: Filter by category
- `search`: Full-text search

### Sorting
- `sortBy`: Field name
- `sortOrder`: `asc` or `desc`

### Response Format
```json
{
  "data": [...],
  "meta": {
    "total": 100,
    "limit": 20,
    "offset": 0,
    "hasMore": true
  }
}
```

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-20 | Initial specification |

---

**End of Specification**

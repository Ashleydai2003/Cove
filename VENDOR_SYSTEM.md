# Vendor Account System Implementation

This document describes the vendor account system that has been implemented for Cove. Vendor accounts allow organizations to create events that appear in all users' home feeds.

## Overview

The vendor system consists of two main entities:
1. **Vendor Organization** - The organization (e.g., "Acme Events Inc.")
2. **Vendor Users** - Individual accounts that belong to a vendor organization

## Features Implemented

### Backend (Node.js/TypeScript + Prisma)

#### 1. Database Schema (`Backend/prisma/schema.prisma`)
- **Vendor** model: Stores organization information
  - Organization name, website, email, location
  - Invitation code (rotatable for security)
  - Timestamps for code rotation tracking
  
- **VendorUser** model: Individual vendor account
  - Name, phone, role (MEMBER, ADMIN, SUPERADMIN)
  - Links to Vendor organization
  - Onboarding and verification status
  
- **VendorImage** model: Profile photos for vendor users

- **Updated Event** model: 
  - Now supports both user-hosted and vendor-created events
  - `vendorId` field for vendor events
  - `coveId` and `hostId` are optional for vendor events

#### 2. API Endpoints

**Authentication:**
- `POST /vendor/login` - Vendor user login (similar to user login)

**Onboarding:**
- `POST /vendor/validate-code` - Validate a vendor invitation code
- `POST /vendor/create-organization` - Create new vendor organization
- `POST /vendor/join-organization` - Join existing organization with code
- `POST /vendor/onboard` - Complete vendor user onboarding

**Profile Management:**
- `GET /vendor/profile` - Get vendor user profile
- `PUT /vendor/profile-update` - Update vendor user profile
- `GET /vendor/organization` - Get organization details
- `GET /vendor/members` - Get organization members (ADMIN+ only)
- `POST /vendor/rotate-code` - Rotate organization code (SUPERADMIN only)

**Event Creation:**
- `POST /vendor/create-event` - Create vendor event (appears in all user feeds)

#### 3. Feed Logic Updates
- Updated `feedService.ts` to include vendor events
- Vendor events are fetched separately and appear in all users' feeds
- Events are marked with `isVendorEvent: true` flag

### iOS (Swift/SwiftUI)

#### 1. Models (`CoveApp/Utilities/VendorModels.swift`)
- Swift models for all vendor entities
- Codable responses for API integration
- Role enumeration (MEMBER, ADMIN, SUPERADMIN)

#### 2. Network Layer (`CoveApp/Utilities/VendorNetworkManager.swift`)
- Complete network manager for all vendor API endpoints
- Firebase authentication integration
- Error handling and type-safe responses

#### 3. Onboarding Flow

**VendorController** (`CoveApp/App/VendorController.swift`):
- Manages vendor app state and navigation
- Similar to AppController for regular users
- Tracks onboarding completion

**Views:**
- `VendorCodeEntryView.swift` - Enter vendor code or create organization
- `CreateVendorOrganizationView.swift` - Form to create new vendor org
- `VendorUserDetailsView.swift` - Enter personal information
- `CityPickerView` - Reusable city selection (uses existing CitiesData)

#### 4. Profile Management (`CoveApp/Views/Vendor/Profile/VendorProfileView.swift`)
- View vendor profile and organization info
- Admin features:
  - View/rotate organization code
  - View team members
- Role-based UI (different for MEMBER vs ADMIN vs SUPERADMIN)

## Onboarding Flow

### Vendor Onboarding Process:

1. **Phone Verification** (OTP via Firebase - reuses existing flow)
2. **Vendor Code Entry**:
   - Option A: Enter existing vendor code to join organization
   - Option B: Create new organization
3. **Organization Creation** (if Option B):
   - Enter: Organization name, website (optional), contact email, city
   - System generates unique invitation code
   - Creator becomes SUPERADMIN
4. **Personal Details**:
   - Enter name
   - Optional: Upload profile photo
5. **Complete** - User can now create events

### Vendor Code System

- **Format**: XXXX-XXXX (8 characters, uppercase letters and numbers)
- **Example**: AB3K-7M9P
- **Security**: 
  - Excludes confusing characters (O, I, L, 0, 1)
  - Rotatable by SUPERADMIN
  - Tracks rotation date

## Roles & Permissions

| Role | Permissions |
|------|-------------|
| **SUPERADMIN** | - Create events<br>- Rotate organization code<br>- View all members<br>- (Creator of organization) |
| **ADMIN** | - Create events<br>- View organization code<br>- View all members |
| **MEMBER** | - Create events<br>- View organization details (no code) |

## Event Creation

### Vendor Events vs Cove Events:

| Feature | Cove Events | Vendor Events |
|---------|-------------|---------------|
| Visibility | Cove members only OR public | Always public (all users) |
| Hosted by | Individual user | Vendor organization |
| Requires cove | Yes | No |
| Create permission | Any cove member | Any verified vendor user |

## What Still Needs to be Done

### 1. Database Migration
```bash
cd Backend
npx prisma migrate dev --name add_vendor_system
```
This will create the migration SQL file and apply changes to your database.

### 2. Environment Variables
Add to your backend environment:
```
VENDOR_IMAGE_BUCKET_NAME=your-vendor-image-bucket (or reuse USER_IMAGE_BUCKET_NAME)
```

### 3. iOS Integration

#### A. Update App Entry Point
You need to decide how users access the vendor flow:
- **Option 1**: Separate vendor app (different target/build)
- **Option 2**: Mode selector at login ("Sign in as User" / "Sign in as Vendor")
- **Option 3**: Separate vendor app distributed to organizations

#### B. Create Vendor Onboarding Flow Coordinator
Similar to `OnboardingFlow.swift`, create:
```swift
struct VendorOnboardingFlow: View {
    @StateObject private var vendorController = VendorController.shared
    
    var body: some View {
        NavigationStack(path: $vendorController.vendorPath) {
            LoginView() // Reuse existing login, but call vendor/login
                .navigationDestination(for: VendorOnboardingRoute.self) { route in
                    switch route {
                    case .enterPhoneNumber:
                        UserPhoneNumberView() // Reuse
                    case .otpVerify:
                        OtpVerifyView() // Reuse, but call vendor/login
                    case .vendorCodeEntry:
                        VendorCodeEntryView()
                    case .vendorUserDetails:
                        VendorUserDetailsView()
                    case .pluggingIn:
                        VendorPluggingInView() // Fetch vendor data
                    }
                }
        }
    }
}
```

#### C. Create Vendor Main App View
Create a vendor home view that shows:
- List of vendor events
- Create event button
- Profile access

#### D. Update CreateEventView
Modify `CreateEventView.swift` to work with vendor accounts:
- Remove `coveId` requirement for vendors
- Show vendor organization name instead of cove name
- Call `/vendor/create-event` endpoint

### 4. Firebase Setup
If using separate authentication:
- Configure Firebase to support vendor user accounts
- May need separate Firebase project or custom claims

### 5. Testing Checklist

- [ ] Create vendor organization
- [ ] Generate invitation code
- [ ] Second vendor user joins using code
- [ ] Rotate invitation code
- [ ] Create vendor event
- [ ] Verify event appears in user feeds
- [ ] Test role permissions (MEMBER vs ADMIN vs SUPERADMIN)
- [ ] Test profile management
- [ ] Test team member list

### 6. Additional Considerations

#### Security:
- Consider rate limiting on code validation endpoint
- Add email verification for vendor organization creation
- Consider additional vetting for vendor accounts

#### Features to Add:
- Event analytics for vendors
- Vendor subscription/payment system
- Event approval workflow
- Vendor verification badges
- Event categories/tags

## File Structure

```
Backend/
├── prisma/
│   └── schema.prisma (updated)
├── src/
│   ├── routes/
│   │   ├── vendor-login.ts
│   │   ├── vendor-onboard.ts
│   │   ├── vendor-profile.ts
│   │   └── vendor-event.ts
│   ├── services/
│   │   └── feedService.ts (updated)
│   └── utils/
│       └── vendorCode.ts

CoveApp/
├── App/
│   └── VendorController.swift
├── Utilities/
│   ├── VendorModels.swift
│   └── VendorNetworkManager.swift
└── Views/
    └── Vendor/
        ├── Onboarding/
        │   ├── VendorCodeEntryView.swift
        │   ├── CreateVendorOrganizationView.swift
        │   └── VendorUserDetailsView.swift
        └── Profile/
            └── VendorProfileView.swift
```

## Example Usage

### Creating a Vendor Organization:

1. User signs up with phone number
2. Selects "Create Organization"
3. Enters organization details:
   - Name: "Acme Events"
   - Email: "events@acme.com"
   - City: "New York"
4. System generates code: "AB3K-7M9P"
5. User becomes SUPERADMIN
6. User can now create events

### Joining an Organization:

1. User signs up with phone number
2. Selects "Have a code"
3. Enters code: "AB3K-7M9P"
4. Joins "Acme Events" as MEMBER
5. User can now create events

### Creating an Event:

```swift
VendorNetworkManager.shared.createVendorEvent(
    name: "Summer Music Festival",
    description: "Annual outdoor concert",
    date: Date(),
    location: "Central Park, NYC",
    memberCap: 500,
    ticketPrice: 49.99,
    paymentHandle: "acme-events",
    coverPhoto: base64Image,
    useTieredPricing: false,
    pricingTiers: nil
) { result in
    // Handle result
}
```

## API Base URLs

Update `VendorNetworkManager.swift` with your actual API URLs:

```swift
#if DEBUG
baseURL = "https://your-dev-api.com"
#else
baseURL = "https://your-prod-api.com"
#endif
```

## Notes

- Vendor events are always public (`isPublic: true`)
- Vendor events don't have a `coveId` (they're not associated with any cove)
- The system reuses existing Firebase OTP authentication
- City list from `CitiesData.swift` is reused for vendor location
- Vendor codes are cryptographically secure random strings

## Questions?

For implementation questions or issues, refer to:
- Backend: `/Backend/src/routes/vendor-*.ts` files
- iOS Models: `/CoveApp/Utilities/VendorModels.swift`
- iOS Network: `/CoveApp/Utilities/VendorNetworkManager.swift`
- iOS Views: `/CoveApp/Views/Vendor/` directory


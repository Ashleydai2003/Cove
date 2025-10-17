# Vendor System - Quick Start Guide

## ✅ What's Been Implemented

The complete vendor account system is now ready to use! Here's what you have:

### Backend
- ✅ All vendor API endpoints in `/Backend/src/routes/vendor.ts`
- ✅ Event validation (every event needs cove OR vendor)
- ✅ Feed integration (vendor events appear in all user feeds)
- ✅ 2 roles: ADMIN (creator) and MEMBER

### iOS
- ✅ Vendor onboarding flow (phone/OTP → code entry → org creation → complete)
- ✅ Vendor home view with event creation
- ✅ Vendor profile with org management
- ✅ "log in as vendor instead" link on main login screen

## 🚀 How to Get Started

### Step 1: Run Database Migration (REQUIRED)

```bash
cd Backend
npx prisma migrate dev --name add_vendor_system
```

This will:
- Create Vendor, VendorUser, VendorImage tables
- Update Event table to support vendor events
- Apply all schema changes

### Step 2: Update iOS API URLs

Edit `CoveApp/Utilities/VendorNetworkManager.swift` line 14-18:

```swift
private init() {
    #if DEBUG
    baseURL = "https://your-dev-api-url.com"  // <-- Change this
    #else
    baseURL = "https://your-prod-api-url.com" // <-- Change this
    #endif
}
```

### Step 3: Build and Test!

You're ready to go! Here's how to test:

1. **Launch app** → Tap "log in as vendor instead"
2. **Enter phone** → Get OTP → Verify
3. **Create organization:**
   - Name: "Test Events Co"
   - Email: "test@events.com"  
   - City: "New York"
4. **Note your code** (e.g., `AB3K-7M9P`)
5. **Enter your name** → Complete
6. **Create an event** → It appears in all user feeds!

## 📱 Testing the Flow

### Create First Vendor (ADMIN)
```
1. Tap "log in as vendor instead"
2. Phone: +1234567890 → OTP
3. "don't have a code? create organization"
4. Fill in org details → Get code AB3K-7M9P
5. Enter name → Done!
```

### Join as Team Member (MEMBER)
```
1. New device → "log in as vendor instead"
2. Different phone → OTP
3. Enter code: AB3K-7M9P
4. Enter name → Done!
```

### Create Vendor Event
```
1. Sign in as vendor
2. Events tab → "Create Event"
3. Fill in event details
4. Submit → Event is live!
```

### Verify in User Feed
```
1. Sign in as regular user
2. Check home feed
3. Vendor event appears!
```

## 🔑 Key Features

### Vendor Codes
- Format: `XXXX-XXXX` (e.g., `AB3K-7M9P`)
- Share with team to join
- Rotate anytime (ADMIN only)

### Roles
| Role | Can Do |
|------|--------|
| **ADMIN** | Create events, rotate code, view members |
| **MEMBER** | Create events only |

### Events
- **User events**: Need cove, visible to cove members
- **Vendor events**: No cove, visible to ALL users

## 🐛 Troubleshooting

### "Vendor user not found"
- Make sure you tapped "log in as vendor instead"
- Check you're calling `/vendor/login` not `/login`

### "Invalid vendor code"
- Code format: XXXX-XXXX (uppercase)
- Code may have been rotated
- Check database: `SELECT * FROM Vendor WHERE currentCode = 'YOUR-CODE'`

### Events not showing
- Verify `isPublic: true` for vendor events
- Check `vendorId` is set
- User events need `coveId`, vendor events need `vendorId`

## 📊 Database Check

After migration, verify tables exist:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('Vendor', 'VendorUser', 'VendorImage');
```

## 🎯 What's Next?

Optional enhancements:
- Event analytics dashboard
- Email verification for new vendors
- Vendor verification badges
- Event editing/drafts
- Bulk event creation
- Payment integration

## 📞 Need Help?

1. Check `VENDOR_SYSTEM.md` for full documentation
2. Review API responses in logs
3. Verify database schema matches expected structure

---

That's it! Your vendor system is ready to use. 🎉


# POS Booking Details Enhancement

## Goal
Show rich order/appointment details in the booking details view, fixing the data fetching issue and displaying information similar to the main app's booking details.

## Root Cause of Current Issues
- **POSBookingService** only fetches bookings, not orders or resources
- **orderInfo** is intentionally nil from API (must be populated by fetching orders separately)
- **Fallback strings** show "Guest" and "Booking" when data is missing

## Data to Display

### Booking Info Section
- Date (formatted: "Monday, 05 July 2025")
- Time range (start - end time)
- Duration (calculated or from booking)
- Team member/Resource name

### Status Badges
- **Booking status**: Booked, Cancelled (from attendanceStatusKey)
- **Payment status**: Unpaid, Paid (from statusKey)

### Customer Section
- Full name
- Email
- Phone

### Payment Section
- Service amount (subtotal)
- Tax
- Total
- Pay by Card / Pay by Cash buttons (existing)

## Implementation Tasks

### Task 1: Update POSBookingService to Fetch Orders and Resources
- After fetching bookings, fetch associated orders by orderID
- Fetch resources by resourceID
- Create BookingOrderInfo from booking + order data
- Return enriched bookings

### Task 2: Expand POSBooking Model
Add new fields:
- `endTime: Date` - appointment end time
- `resourceName: String?` - team member/staff name
- `customerEmail: String?`
- `customerPhone: String?`
- `subtotal: String?` - service amount before tax
- `tax: String?`
- `bookingStatus: POSBookingStatus` - booked/cancelled (attendance)
- `paymentStatus: POSPaymentStatus` - unpaid/paid

### Task 3: Update POSBookingListController Mapping
- Map new fields from enriched Booking to POSBooking
- Extract customer info from orderInfo
- Extract payment breakdown from orderInfo

### Task 4: Update POSBookingDetailView
- Add booking details section (date, time range, duration, team member)
- Add status badges row
- Add customer section (name, email, phone)
- Add payment breakdown section
- Keep existing payment action buttons

### Task 5: Update POSBookingRowView (List)
- Show actual customer name and service name (now that data is fetched)
- Optionally show resource name in subtitle

## Files to Modify

**Services:**
- `Modules/Sources/Yosemite/Tools/POS/POSBookingService.swift`

**Models:**
- `Modules/Sources/PointOfSale/Models/POSBooking.swift`

**Controllers:**
- `Modules/Sources/PointOfSale/Controllers/POSBookingListController.swift`

**Views:**
- `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`
- `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingRowView.swift` (optional)

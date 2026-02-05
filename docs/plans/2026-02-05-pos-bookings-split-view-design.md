# POS Bookings Split View Design

## Goal
Reuse the split view pattern from POS order list for bookings to achieve visual consistency.

## Approach
Full parity with the order list implementation.

## Changes

### 1. Split View Structure
- Replace `NavigationSplitView` with `CustomNavigationSplitView`
- iPad/Regular: HStack with 35% sidebar, 65% detail
- iPhone/Compact: NavigationStack with push navigation
- Selection binding connects to controller for auto-selection

### 2. Headers with POSPageHeaderView

**List Header:**
- Title: "Bookings"
- Leading: Close button (X)

**Detail Header:**
- Title: Booking identifier or customer name
- Back button on compact size class
- Bottom content: Date/time, status badge, customer info
- Trailing: Payment action buttons

### 3. Component Changes

**Modified:**
- `POSBookingsContainerView` - Use `CustomNavigationSplitView`, add auto-selection
- `POSBookingListView` - Add `POSPageHeaderView`
- `POSBookingDetailView` - Add `POSPageHeaderView`, move actions to header

**New:**
- `POSBookingDetailsLoadingView` - Shimmer skeleton for loading state
- `POSBookingDetailsEmptyView` - Empty state component (extract from inline)

### 4. Auto-selection Behavior
- On regular size class, auto-select first booking when none selected
- Update selection when current selection removed from list

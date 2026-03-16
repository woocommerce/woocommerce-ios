# Phone POS Design — WooCommerce iOS

**Date:** 2026-03-16
**Last updated:** 2026-03-16 13:40 UTC
**Status:** Complete
**Visual designs:** [phone-pos-designs.html](2026-03-16-phone-pos-designs.html) (open in browser)

## Goal

Adapt the WooCommerce POS from its current iPad-landscape-only layout to work on iPhones in portrait, with full feature parity. All existing features (catalog, cart, payments, orders history, bookings, settings) must be available on phone.

## Context

The current POS is a three-pane iPad landscape layout:
- **Building stage:** ItemList (left) | Cart (center)
- **Finalizing stage:** Cart (center) | Totals (right)

It explicitly rejects compact size class with an "unsupported width" error view (`PointOfSaleUnsupportedWidthView`). Navigation uses a floating control menu in the bottom-left corner for settings, orders, and bookings, presented as full-screen covers.

## Constraints

- **Portrait only** on phone — no landscape support
- **iPad unchanged** — no modifications to the existing iPad layout
- **Feature flagged** — phone POS behind a feature flag for gradual rollout
- **Full parity** — all iPad features available on phone

## Design Decisions

### 1. Tab Bar Navigation

**Decision:** Phone POS uses a bottom tab bar with four tabs: **Sale | Orders | Bookings | Settings**.

**Reasoning:** The iPad's floating control menu doesn't translate to phone — it assumes a landscape screen with free space. A tab bar is the standard iOS phone navigation pattern and gives direct access to all feature areas. "Sale" covers the entire POS flow (browsing, cart, checkout, payment), not just the catalog.

**Key details:**
- Tab bar is visible during the building stage (browsing products) and on all other tabs
- Tab bar is **hidden** during checkout and payment flows (these push full-screen)
- Orders and Bookings tabs use existing `POSNavigationSplitView` compact layouts (stacked navigation) — no changes needed
- Settings tab shows existing `POSSettingsView` content with "Exit Point of Sale" button
- The "Sale" tab name may be refined later

**Architecture:** On phone, a new `POSPhoneRootView` replaces `PointOfSaleDashboardView` as the root. It wraps a `TabView` where the Sale tab contains the product list + cart bar (the core of what `PointOfSaleDashboardView` does in building stage), and the other tabs host the existing views that are currently presented as full-screen covers from the floating menu. The `PointOfSaleAggregateModel` remains the shared state coordinator, injected at the entry point as it is today. `PointOfSaleEntryPointView` selects between `PointOfSaleDashboardView` (iPad/regular) and `POSPhoneRootView` (phone/compact) based on `horizontalSizeClass`.

**iPad split view resilience:** When an iPad user shrinks a split view from regular to compact, SwiftUI will swap the view hierarchy from `PointOfSaleDashboardView` to `POSPhoneRootView`. Business state (cart, order, payment) is preserved because `PointOfSaleAggregateModel` lives above both views. However, view-level state (navigation stack depth, sheet presentation, scroll position) would be lost if the views are torn down and rebuilt.

This is not acceptable — shrinking the screen should not lose the user's place in the app. To solve this, navigation state must be lifted out of the view hierarchy and into the model layer so it survives the view swap. Specifically:

- **Active tab** and **navigation path** per tab should be tracked in an `@Observable` navigation model (or on the aggregate model) rather than in view-local `@State`
- **Sheet/cover presentation state** (e.g., whether checkout is showing, which order is selected) should similarly be model-driven
- **Both view hierarchies read the same navigation state**, so when SwiftUI swaps between them, the new hierarchy picks up where the old one left off — e.g., if the user was mid-checkout on iPad and shrinks to compact, the phone layout opens to the checkout screen

This approach also benefits the phone layout directly, since the cart sheet and checkout push already need model-driven navigation state.

### 2. Core Flow — Sale Tab: Persistent Cart Bar + Pull-up Sheet

**Decision:** The product list is the primary full-screen view. A persistent bottom bar (above the tab bar) shows a preview of the cart contents, item count, and total. Pulling up the bar reveals the full cart.

**Reasoning:** The merchant needs to see what's in the cart while browsing products — both to confirm items were added and to review before checkout. A tab-based approach hides the cart entirely. A vertical split wastes screen space on a phone. The pull-up sheet pattern gives maximum catalog space while keeping the cart visible and one gesture away.

**Key details:**
- The bottom cart area shows approximately 1.5 rows of cart items, so merchants see a visual change as they tap products (new items animate in at the top with a brief highlight)
- The fade-out at the bottom of the visible items hints that the sheet can be expanded
- A drag handle at the top of the cart area reinforces expandability
- The cart summary always shows item count and total
- A Checkout button is visible in the collapsed state
- When expanded, the full cart is shown with item management (remove, quantities)
- The catalog dims behind the expanded sheet
- Swipe down collapses back to the peek state
- Empty state: thinner bar with "Cart empty" and disabled checkout

**Product list format:** Rows (matching the current iPad layout), not a grid. Long product names and variations display more effectively in rows.

**Variation picker:** When tapping a variable product, the variation picker presents over the cart bar (as it does on iPad over the cart). The cart bar reappears when the picker is dismissed.

**Cart bar implementation:** Use a SwiftUI `.sheet` with custom presentation detents — a collapsed detent showing ~1.5 rows plus summary, and an expanded detent for full cart. The sheet cannot be fully dismissed; the collapsed detent is the minimum. When the product list search keyboard is active, the cart bar remains at its collapsed detent.

**Loading/error states:** If the catalog is loading or encounters a sync error, the Sale tab shows these states full-screen with the tab bar still visible (same as iPad shows them in the content area).

```
┌─────────────────────────┐
│ Products        Coupons │
│─────────────────────────│
│ 🔍 Search products...   │
│                         │
│ [img] Espresso    $4.50 │
│ [img] Latte       $5.50 │
│ [img] Muffin      $3.00 │
│ [img] Croissant   $3.50 │
│ [img] Bagel       $2.50 │
│                         │
│═══ cart peek area ══════│
│ ─── (drag handle) ───   │
│ Cart (3)          Clear │
│ [img] Muffin      $3.00 │ ← newest, highlighted
│ [img] Latte       $5.50 │
│ ░░░ fade out ░░░░░░░░░░ │
│ $13.00        [Checkout] │
│─────────────────────────│
│ 💳Sale 📋Orders 📅Book ⚙️Set │
└─────────────────────────┘
```

### 3. Checkout: Pushed Screen with Cart Review

**Decision:** Tapping Checkout pushes a dedicated full-screen checkout view (hiding the tab bar). This screen prioritizes cart contents and the grand total, with two vertically stacked payment buttons at the bottom.

**Reasoning:** The checkout screen serves as the final confirmation before payment. The merchant needs to verify everything in the cart is correct and see the total clearly. No card reader status is shown here — on phone, the primary card payment method is Tap to Pay, which takes over the screen when activated. Keeping this screen simple (cart + total + two buttons) reduces cognitive load at the moment of payment.

**Key details:**
- Back button returns to the catalog (with cart bar and tab bar intact)
- Cart items displayed with generous spacing for easy scanning
- Subtotal and taxes shown in secondary text
- Grand total displayed prominently (large, bold)
- Two vertically stacked buttons:
  - **"Tap to Pay"** (primary, filled) — triggers the iOS Tap to Pay system UI
  - **"Cash Payment"** (secondary, outlined) — opens cash collection flow
- No inline card reader status or connection UI on this screen
- The card reader is not auto-prepared when entering this screen — unlike iPad, the phone checkout screen does not trigger `POSPaymentModel.activate()` on entry. Tapping "Tap to Pay" initiates the entire payment flow (reader preparation + card collection) as a single action via the iOS Tap to Pay system UI
- The existing card payment states (`preparingReader`, `acceptingCard`, `cardInserted`) are handled by the Tap to Pay system UI on phone — the app only needs to handle `processingPayment`, `cardPaymentSuccessful`, and error states after the system UI returns

```
┌─────────────────────────┐
│ ‹ Back     Checkout     │
│─────────────────────────│
│                         │
│ [img] Espresso    $4.50 │
│       Qty: 1            │
│ [img] Latte       $5.50 │
│       Qty: 1            │
│ [img] Muffin      $3.00 │
│       Qty: 1            │
│ [img] Croissant   $7.00 │
│       Qty: 2            │
│                         │
│═════════════════════════│
│ Subtotal         $20.00 │
│ Taxes             $1.80 │
│                         │
│ Total            $21.80 │ ← large, bold
│                         │
│ ┌─────────────────────┐ │
│ │    Tap to Pay       │ │ ← primary (filled)
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │   Cash Payment      │ │ ← secondary (outlined)
│ └─────────────────────┘ │
└─────────────────────────┘
       (no tab bar)
```

### 4. Payment Processing & Result States

**Decision:** Full-screen takeover for processing, success, and error states — same as iPad. These states already work well on any screen size.

**Flow:**
1. **Tap to Pay** → iOS system UI takes over (contactless card reading)
2. **Processing** → full-screen spinner with branded background
3. **Success** → full-screen with checkmark, "New order" and "Send receipt" buttons
4. **Error** → full-screen with error message, "Try again" button
5. **Cash Payment** → full-screen cash collection view (enter amount received, shows change due, "Mark payment as complete")

### 5. Secondary Features

**Decision:** Orders, Bookings, and Settings use their existing compact-mode layouts with no changes.

**Reasoning:** These screens already adapt to compact size class via `POSNavigationSplitView` (stacked navigation on compact) and standard list layouts. No redesign needed.

**Key details:**
- **Orders tab:** `POSNavigationSplitView` in compact mode — order list, tap to see order detail
- **Bookings tab:** Same pattern — bookings list with stacked detail navigation
- **Settings tab:** Existing `POSSettingsView` list (hardware, store info, help). "Exit Point of Sale" button lives here.

### 6. Orientation and Platform Scope

- **Phone: portrait only** — no landscape support
- **iPad: no changes** — existing landscape layout remains as-is
- **Feature flag:** Phone POS is behind a feature flag for gradual rollout

# Screen Identifiers Reference

This document maps every major screen in the WooCommerce iOS app to the accessibility identifiers that AI agents can use with mobile-mcp's `list_elements_on_screen` to detect which screen is displayed and interact with key elements.

## How to Use This Reference

1. **Identify the current screen**: After navigating, call `list_elements_on_screen` and look for the **Primary Identifier** listed for each screen.
2. **Find interactive elements**: Use the **Key Elements** table to locate buttons, fields, and views you need to interact with.
3. **Navigate between screens**: Follow the **Navigation Flows** section to reach any screen from the initial launch.
4. **Handle overlays**: Check **Common Dialogs and Overlays** to dismiss anything blocking interaction.

**Tip**: Always call `list_elements_on_screen` before every interaction. Coordinates shift between screens and after keyboard appearance. Match by `identifier` field, then use the element's coordinates to tap.

---

## Bottom Navigation Tabs

The tab bar is visible on all top-level screens.

| Tab | Identifier | Target Screen |
|-----|-----------|---------------|
| My Store | `tab-bar-my-store-item` | Dashboard |
| Orders | `tab-bar-orders-item` | Orders List |
| Products | `tab-bar-products-item` | Products List |
| Bookings | `tab-bar-bookings-item` | Bookings List (only if Bookings extension active) |
| Point of Sale | `tab-bar-pos-item` | POS (only if POS enabled, requires specific launch args) |
| Menu | `tab-bar-menu-item` | Hub Menu |

---

## Login / Prologue

The app launches to the prologue screen when started with `logout-at-launch`.

- **Primary Identifier**: `prologue-title-label`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Log In button | `Prologue Self Hosted Button` | Navigates to site address entry |
| New Store button | `Prologue Site Creation Guide button` | |

### Site Address Screen

| Element | Identifier | Notes |
|---------|-----------|-------|
| Site address field | `Site address` | Enter the store URL here |
| Continue button | `Site Address Next Button` | |
| Help button | `authenticator-help-button` | |

### 2FA / Authentication Code Screen

The mock server always requires 2FA. Enter any 6-digit code (e.g., `123456`).

| Element | Identifier | Notes |
|---------|-----------|-------|
| Code field | `Authentication code` | Enter any OTP code for mock login |
| Continue button | `Continue Button` | |
| Help button | `authenticator-help-button` | |

### Login Epilogue (Store Picker)

| Element | Identifier | Notes |
|---------|-----------|-------|
| Continue button | `login-epilogue-continue-button` | Proceeds to Dashboard after login |
| Store name | `name-label` | |
| Store URL | `url-label` | |

---

## Top-Level Screens

### Dashboard (My Store)

- **Primary Identifier**: `revenue-value` (always visible on Dashboard)
- **Nav Path**: Tap `tab-bar-my-store-item`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Revenue value | `revenue-value` | Revenue display |
| Time range menu | `performance-time-range-menu` | Date range selector |
| Stats chart | `store-stats-chart` | Statistics chart |
| Time range: Today | `time-range-today` | |
| Time range: This Week | `time-range-this-week` | |
| Time range: This Month | `time-range-this-month` | |
| Time range: This Year | `time-range-this-year` | |

### Orders List

- **Primary Identifier**: `order-search-button` (always visible on Orders screen)
- **Nav Path**: Tap `tab-bar-orders-item`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Search button | `order-search-button` | |
| New order button | `new-order-type-sheet-button` | Creates a new order |
| Filter button | `orders-filter-button` | |
| Scan to create | `create-new-order-by-product-scanning` | |

### Products List

- **Primary Identifier**: `product-search-button` (always visible on Products screen)
- **Nav Path**: Tap `tab-bar-products-item`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Add product button | `product-add-button` | |
| Search button | `product-search-button` | |
| Filter button | `product-filter-button` | |
| Scan button | `product-scan-button` | |
| Product cell | `single-product-cell` | Individual product row |

### Hub Menu

- **Primary Identifier**: `menu-payments` (first menu item, reliably present)
- **Nav Path**: Tap `tab-bar-menu-item`

Menu items (vary by store configuration):

| Menu Item | Identifier | Target Screen |
|-----------|-----------|---------------|
| Settings | `dashboard-settings-button` | Settings screen |
| Payments | `menu-payments` | Payments Hub |
| Blaze | `menu-blaze` | Blaze Campaigns |
| Google Ads | `menu-google-ads` | Google Ads |
| WooCommerce Admin | `menu-woocommerce-admin` | Web admin |
| View Store | `menu-view-store` | Store website |
| Inbox | `menu-inbox` | Inbox |
| Coupons | `menu-coupons` | Coupons List |
| Reviews | `menu-reviews` | Reviews List |
| Customers | `menu-customers` | Customers List |
| Bookings | `menu-bookings` | Bookings List |

---

## Detail Screens

### Order Detail

- **Primary Identifier**: `order-details-table-view`
- **Nav Path**: Orders List → tap any order row

| Element | Identifier | Notes |
|---------|-----------|-------|
| Details table | `order-details-table-view` | Main content |
| Edit button | `order-details-edit-button` | |
| Trash button | `order-details-trash-order-button` | |
| Status list | `order-status-list` | Status selector |
| Summary cell | `summary-table-view-cell` | Order summary |
| Title label | `summary-table-view-cell-title-label` | |
| Created label | `summary-table-view-cell-created-label` | |
| Payment status | `summary-table-view-cell-payment-status-label` | |

### Order Creation

- **Primary Identifier**: `order-form-scroll-view`
- **Nav Path**: Orders List → tap `new-order-type-sheet-button`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Create button | `new-order-create-button` | |
| Cancel button | `new-order-cancel-button` | |
| Add product | `new-order-add-product-button` | |
| Add coupon | `add-coupon-button` | |
| Add shipping | `add-shipping-button` | |
| Add gift card | `add-gift-card-button` | |
| Add custom amount | `new-order-add-custom-amount-button` | |
| Customer details | `add-customer-details-plus-button` | |
| Collect payment | `order-form-collect-payment` | |
| Address form | `order-address-form` | |
| First name field | `order-address-form-first-name-field` | |

### Product Detail

- **Primary Identifier**: `product-form`
- **Nav Path**: Products List → tap any product row

| Element | Identifier | Notes |
|---------|-----------|-------|
| Product form | `product-form` | Main content |
| Title | `product-title` | Product name field |
| Description | `product-description` | |
| Publish button | `publish-product-button` | |
| Save button | `save-product-button` | |
| More options | `edit-product-more-options-button` | |
| Add tags | `add-tags` | |

### Reviews List

- **Primary Identifier**: `reviews-table`
- **Nav Path**: Hub Menu → tap `menu-reviews`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Reviews table | `reviews-table` | |
| Menu button | `reviews-open-menu-button` | |
| Spam button | `single-review-spam-button` | On individual review |
| Trash button | `single-review-trash-button` | On individual review |
| Approve button | `single-review-approval-button` | On individual review |
| Reply button | `single-review-reply-button` | |
| Comment text | `single-review-comment` | |

---

## Point of Sale (POS)

POS requires additional launch arguments: `bypass-pos-eligibility-checks`, `load-mocked-pos-products`, `bypass-pos-order-syncing`.

- **Primary Identifier**: `pos-cart-view`
- **Nav Path**: Tap `tab-bar-pos-item`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Cart view | `pos-cart-view` | Cart container |
| Checkout button | `pos-checkout-button` | |
| Product card | `pos-product-card-{productID}` | Dynamic — includes product ID |
| Variation card | `pos-search-variation-card-{variationID}` | Dynamic — includes variation ID |
| Total field | `pos-total-field` | |
| Cash payment | `pos-cash-payment-button` | |
| Mark complete | `pos-mark-payment-complete-button` | |
| Connect reader | `pos-connect-reader-button` | |
| Reader connected | `pos-reader-connected` | Indicator when connected |
| Card payment msg | `pos-card-payment-message` | Status during card payment |
| Payment success | `pos-payment-success-view` | |
| Menu button | `pos-menu-button` | Floating menu |
| Exit menu item | `pos-exit-menu-item` | |
| Exit close | `pos-exit-modal-close-button` | Close exit confirmation |
| Exit confirm | `pos-exit-confirm-button` | Confirm exit |

---

## Settings

- **Nav Path**: Hub Menu → tap `dashboard-settings-button`

| Element | Identifier | Notes |
|---------|-----------|-------|
| Beta features | `settings-beta-features-button` | |
| Log out | `settings-log-out-button` | |
| Card reader manuals | `card-reader-manuals` | |

---

## Common UI Components

These may appear on any screen.

| Element | Identifier | Notes |
|---------|-----------|-------|
| Top banner dismiss | `top-banner-view-dismiss-button` | Dismiss informational banners |
| Top banner expand | `top-banner-view-expand-collapse-button` | |
| Top banner info | `top-banner-view-info-label` | |
| Feedback close | `feedback-banner-popover-close-button` | |

---

## Navigation Flows

Step-by-step paths for reaching common screens from the Dashboard.

### Login (from prologue)
```
Prologue → tap "Prologue Self Hosted Button"
  → type site URL in "Site address" field → tap "Site Address Next Button"
  → type email → tap continue
  → type password → tap continue
  → type 2FA code (any 6 digits, e.g. "123456") in "Authentication code" → tap "Continue Button"
  → tap "login-epilogue-continue-button"
  → Dashboard
```

### Orders
```
Orders List:       Tap tab "tab-bar-orders-item"
Order Detail:      Orders List → tap any order row → wait for "order-details-table-view"
Order Creation:    Orders List → tap "new-order-type-sheet-button" → wait for "order-form-scroll-view"
```

### Products
```
Products List:     Tap tab "tab-bar-products-item"
Product Detail:    Products List → tap any "single-product-cell" → wait for "product-form"
Product Creation:  Products List → tap "product-add-button"
Product Search:    Products List → tap "product-search-button"
```

### Hub Menu Screens
```
Hub Menu:          Tap tab "tab-bar-menu-item"
Coupons:           Hub Menu → tap "menu-coupons"
Reviews:           Hub Menu → tap "menu-reviews" → wait for "reviews-table"
Customers:         Hub Menu → tap "menu-customers"
Payments:          Hub Menu → tap "menu-payments"
Blaze:             Hub Menu → tap "menu-blaze"
Bookings:          Hub Menu → tap "menu-bookings"
```

### Settings
```
Settings:          Hub Menu → tap "dashboard-settings-button"
Beta Features:     Settings → tap "settings-beta-features-button"
Logout:            Settings → tap "settings-log-out-button"
```

### POS
```
POS:               Tap tab "tab-bar-pos-item" → wait for "pos-cart-view"
POS Checkout:      POS → add products → tap "pos-checkout-button"
POS Cash Payment:  Checkout → tap "pos-cash-payment-button" → tap "pos-mark-payment-complete-button"
POS Exit:          POS → tap "pos-menu-button" → tap "pos-exit-menu-item" → tap "pos-exit-confirm-button"
```

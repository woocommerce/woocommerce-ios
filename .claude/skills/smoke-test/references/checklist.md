# Smoke Test Checklist

Use this checklist after completing the setup, build, and login steps in `../SKILL.md`.

## Section: Login

Run these from the logged-out login flow.

### Wrong credentials

1. Start login with the correct store URL.
2. Enter an incorrect password.
3. List elements and verify an error message is shown.

### Not a WordPress site

1. Start login.
2. Enter `google.com` as the site address.
3. List elements and verify an error indicates the site is not WordPress.

### Not a WooCommerce store

1. Start login.
2. Enter `notawoostore.wordpress.com` as the site address.
3. Continue through login with the provided credentials.
4. List elements and verify the app indicates WooCommerce is not installed.

After finishing login error checks, log back in with the correct credentials before continuing to other sections.

Pass criteria: login errors are surfaced for all negative cases, and the app can still log in successfully afterward.

Audit screenshot checkpoints:
- Logged-out login screen
- Successful post-login dashboard state after re-entering correct credentials

## Section: Dashboard

1. Tap `tab-bar-my-store-item`.
2. List elements and verify `revenue-value` is present with a non-empty value.
3. Tap `performance-time-range-menu`. If needed, use a slight tap offset to trigger the menu.
4. Tap `time-range-this-week`, then list elements and verify the date label updates.
5. Tap the time range picker again, then tap `time-range-this-month` and verify the label updates again.
6. Scroll down and list elements to verify additional dashboard cards appear, such as top performers or store analytics.

Pass criteria: `revenue-value` is populated, the time range selector opens and updates state, and dashboard cards appear.

Audit screenshot checkpoint:
- Dashboard loaded with revenue visible

## Section: Orders

This section mutates store data. Only run it on the agreed smoke-test store.

### Browse orders

1. Tap `tab-bar-orders-item`.
2. List elements and verify `order-search-button` and order rows are present.
3. Scroll down and list elements again to verify more orders load.
4. Tap `order-search-button`. A small downward offset may be needed.
5. Search for a known order number and verify results appear.
6. Cancel search and return to the orders list.

### Create an order and pay via cash

1. Tap `new-order-type-sheet-button`. A small downward offset may be needed.
2. List elements and verify `order-form-scroll-view` or `new-order-add-product-button` is present.
3. Tap `new-order-add-product-button`, select a product, and confirm.
4. List elements and verify the product appears with the expected name and price.
5. Tap `order-form-collect-payment`.
6. Verify `payment-methods-view-cash-row` is present, then tap it.
7. Verify the cash amount is correct, then tap the completion action.
8. Wait for the order to be created and verify the order detail shows a completed state.
9. Record the order number for later verification.
10. Verify the order shows paid with a non-zero amount.

### Verify the created order

1. Return to the orders list.
2. Verify the newly created order appears at the top.
3. Open it and verify the order details screen and payment details.

### Refund the order

1. From the order detail, scroll until the refund action is visible.
2. Select all items, or select individual items as needed.
3. Verify the refund amount, then continue.
4. Verify the refund summary and payment method, then confirm the refund.
5. Confirm the alert dialog.
6. Verify the order detail shows refunded and `Net Payment $0.00`.

Pass criteria: the orders list loads and paginates, order creation succeeds with cash payment, the created order appears correctly, and the refund completes successfully.

Audit screenshot checkpoints:
- Orders list loaded
- Created order detail
- Refunded order detail

## Section: Products

### Browse products

1. Tap `tab-bar-products-item`.
2. List elements and verify `product-search-button` and product rows are present.
3. Scroll and verify more products load.

### Product detail

1. Open any product row.
2. Verify `product-form` and the product title are present.
3. Scroll through the form and verify title, description, price, inventory, categories, and product type sections load.
4. Return to the products list.

### Search products

1. Tap `product-search-button`. A small downward offset may be needed.
2. Enter a product name that exists on the store.
3. Verify search results appear.
4. Cancel search.

Pass criteria: product list pagination works, product detail sections load, and search returns results.

Audit screenshot checkpoints:
- Products list loaded
- Product detail loaded

## Section: Hub Menu

1. Tap `tab-bar-menu-item`.
2. List elements and verify expected menu items are present, including `dashboard-settings-button`, `menu-payments`, and `menu-coupons`.
3. Navigate to each of the following screens, verify it loaded, then return:

| Menu Item | Tap Element | Verify |
|-----------|-------------|--------|
| Settings | `dashboard-settings-button` | `settings-beta-features-button` present; scroll to confirm Log Out exists |
| Coupons | `menu-coupons` | Coupon rows or Add button present |
| Customers | `menu-customers` | Customer rows present |
| Inbox | `menu-inbox` | Inbox content present |
| Payments | `menu-payments` | Funds labels and card reader options present |

Pass criteria: each menu item opens without errors and Settings shows expected options.

Audit screenshot checkpoint:
- Hub Menu root screen loaded

## Section: POS

Requires an iPad simulator. If currently on iPhone, terminate the app, boot an iPad, rebuild, and relaunch.

If not already logged in on the iPad, relaunch with:

```bash
xcrun simctl launch $IPAD_UDID com.automattic.woocommerce disable-animations bypass-pos-eligibility-checks
```

Do not use mocked POS launch arguments such as `load-mocked-pos-products` or `bypass-pos-order-syncing` when running against a real store.

1. Tap `tab-bar-pos-item`.
2. List elements and verify `pos-cart-view` is present.
3. Add one product card to the cart.
4. Add a second product.
5. Verify the cart shows both items and `pos-total-field` has the expected total.
6. Tap `pos-checkout-button`, then tap `pos-cash-payment-button`.
7. Complete the cash payment flow with `pos-mark-payment-complete-button`.
8. Verify `pos-payment-success-view` appears.
9. Dismiss success and verify POS returns to a ready state.

Pass criteria: POS loads products, items can be added to cart, totals update correctly, and cash payment completes.

Audit screenshot checkpoints:
- POS cart ready state
- POS payment success state

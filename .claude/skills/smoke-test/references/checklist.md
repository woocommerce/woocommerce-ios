# Smoke Test Checklist

Use this checklist after completing the setup, build, and login steps in `../SKILL.md`.

## Screenshots

Steps marked with `> SCREENSHOT: <filename> — <label>` are **required** checkpoints. Save each one using `save_screenshot` with the given filename, then compact it immediately. These form the flipbook in the final HTML report.

You may also take **additional** screenshots for failure triage or to capture unexpected states. Use a `FAIL-` prefix for those (e.g. `FAIL-05-unexpected-error.png`).

## Section: Login

Run these from the logged-out login flow.

> SCREENSHOT: 01-prologue.png — Prologue screen

### Successful login

1. Tap `Prologue Self Hosted Button`.
2. Enter the store URL in the `Site address` field.

> SCREENSHOT: 02-site-address-filled.png — Site address entered

3. Tap `Site Address Next Button`. Wait for the email screen.
4. Enter the email address.

> SCREENSHOT: 03-email-filled.png — Email entered

5. Tap `Get Started Email Continue Button`. Wait for the password screen.
6. Enter the password.
7. Tap `Continue Button`. Wait for authentication.
8. If a "Save Password?" prompt appears, dismiss it.
9. If a 2FA screen appears, enter `123456` and tap `Continue Button`.
10. If `login-epilogue-continue-button` appears, tap it.
11. Verify the dashboard loads (`tab-bar-my-store-item` visible, store name shown).

> SCREENSHOT: 04-dashboard-after-login.png — Dashboard loaded (login successful)

Pass criteria: the app navigates from prologue through credentials to the dashboard without errors.

### Wrong credentials (error state)

1. Log out if needed. Start login with the correct store URL.
2. Enter the correct email.
3. Enter an incorrect password.
4. Tap Continue.
5. List elements and verify an error message is shown.

> SCREENSHOT: 05-wrong-password-error.png — Wrong password error

### Not a WordPress site (error state)

1. Start login.
2. Enter `google.com` as the site address.
3. Tap Continue.
4. List elements and verify an error indicates the site is not WordPress.

> SCREENSHOT: 06-not-wordpress-error.png — Not a WordPress site error

After finishing login error checks, log back in with the correct credentials before continuing to other sections.

Pass criteria: login errors are surfaced for all negative cases, and the app can still log in successfully afterward.

## Section: Dashboard

1. Tap `tab-bar-my-store-item`.
2. List elements and verify `revenue-value` is present with a non-empty value.

> SCREENSHOT: 07-dashboard-revenue.png — Dashboard with revenue visible

3. Tap `performance-time-range-menu`. If needed, use a slight tap offset to trigger the menu.
4. Tap `time-range-this-week`, then list elements and verify the date label updates.
5. Tap the time range picker again, then tap `time-range-this-month` and verify the label updates again.

> SCREENSHOT: 08-dashboard-time-range-changed.png — Dashboard after time range change

6. Scroll down and list elements to verify additional dashboard cards appear, such as top performers or store analytics.

Pass criteria: `revenue-value` is populated, the time range selector opens and updates state, and dashboard cards appear.

## Section: Orders

This section mutates store data. Only run it on the agreed smoke-test store.

### Browse orders

1. Tap `tab-bar-orders-item`.
2. List elements and verify `order-search-button` and order rows are present.

> SCREENSHOT: 09-orders-list.png — Orders list loaded

3. Scroll down repeatedly, listing elements after each scroll, until you have seen at least 26 distinct orders (page size is 25, so 26+ confirms pagination loaded a second page). Count unique order rows across all listings.
4. Tap `order-search-button`. A small downward offset may be needed.
5. Search for a known order number and verify results appear.
6. Cancel search and return to the orders list.

### Create an order

1. Tap `new-order-type-sheet-button`. A small downward offset may be needed.
2. List elements and verify `new-order-add-product-button` is present.

> SCREENSHOT: 10-new-order-form.png — Empty order creation form

3. Tap `new-order-add-product-button`, select a product, and confirm.
4. List elements and verify the product appears with the expected name and price.

> SCREENSHOT: 11-order-with-product.png — Order form with product added

### Pay via cash

5. Tap `order-form-collect-payment`.
6. Verify `payment-methods-view-cash-row` is present, then tap it.
7. Verify the cash amount is correct, then tap the completion action (e.g. "Mark Order as Complete").
8. Wait for the order to be created and verify the order detail shows a completed state.
9. Record the order number for later verification.
10. Verify the order shows "Paid" with the correct amount.

> SCREENSHOT: 12-order-created-paid.png — Order detail showing Completed and Paid

### Verify the created order

1. Return to the orders list.
2. Verify the newly created order appears at the top.
3. Open it and verify the order details screen and payment details.

### Refund the order

1. From the order detail, scroll until the "Issue Refund" button is visible and tap it.
2. Tap "Select All" to select all items for refund.
3. Verify the refund amount matches the order total, then tap "Next".
4. Verify the refund summary shows the correct amount and payment method, then tap "Refund".
5. Confirm the alert dialog.
6. Verify the order detail shows "Refunded" status and `Net Payment $0.00`.

> SCREENSHOT: 13-order-refunded.png — Order detail showing Refunded, Net Payment $0.00

Pass criteria: the orders list loads and paginates, order creation succeeds with cash payment, the created order appears correctly, and the refund completes successfully.

## Section: Products

### Browse products

1. Tap `tab-bar-products-item`.
2. List elements and verify `product-search-button` and product rows are present.

> SCREENSHOT: 14-products-list.png — Products list loaded

3. Scroll and verify more products load.

### Product detail

1. Open any product row.
2. Verify `product-form` and the product title are present.

> SCREENSHOT: 15-product-detail.png — Product detail loaded

3. Scroll through the form and verify title, description, price, inventory, categories, and product type sections load.
4. Return to the products list.

### Search products

1. Tap `product-search-button`. A small downward offset may be needed.
2. Enter a product name that exists on the store.
3. Verify search results appear.
4. Cancel search.

Pass criteria: product list pagination works, product detail sections load, and search returns results.

## Section: Hub Menu

1. Tap `tab-bar-menu-item`.
2. List elements and verify expected menu items are present, including `dashboard-settings-button`, `menu-payments`, and `menu-coupons`.

> SCREENSHOT: 16-hub-menu.png — Hub Menu root screen

3. Navigate to each of the following screens, verify it loaded, then return:

| Menu Item | Tap Element | Verify |
|-----------|-------------|--------|
| Settings | `dashboard-settings-button` | `settings-beta-features-button` present; scroll to confirm Log Out exists |
| Coupons | `menu-coupons` | Coupon rows or Add button present |
| Customers | `menu-customers` | Customer rows present |
| Inbox | `menu-inbox` | Inbox content present |
| Payments | `menu-payments` | Funds labels and card reader options present |

Pass criteria: each menu item opens without errors and Settings shows expected options.

## Section: POS

Requires an iPad simulator. If currently on iPhone, terminate the app, boot an iPad, rebuild, and relaunch.

If not already logged in on the iPad, relaunch with:

```bash
xcrun simctl launch $IPAD_UDID com.automattic.woocommerce disable-animations bypass-pos-eligibility-checks
```

Do not use mocked POS launch arguments such as `load-mocked-pos-products` or `bypass-pos-order-syncing` when running against a real store.

1. Tap `tab-bar-pos-item`.
2. List elements and verify `pos-cart-view` is present.

> SCREENSHOT: 17-pos-cart-ready.png — POS cart ready state

3. Add one product card to the cart.
4. Add a second product.
5. Verify the cart shows both items and `pos-total-field` has the expected total.

> SCREENSHOT: 18-pos-cart-with-items.png — POS cart with items added

6. Tap `pos-checkout-button`, then tap `pos-cash-payment-button`.
7. Complete the cash payment flow with `pos-mark-payment-complete-button`.
8. Verify `pos-payment-success-view` appears.

> SCREENSHOT: 19-pos-payment-success.png — POS payment success

9. Dismiss success and verify POS returns to a ready state.

Pass criteria: POS loads products, items can be added to cart, totals update correctly, and cash payment completes.

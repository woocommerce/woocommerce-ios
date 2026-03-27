# Smoke Test Checklist

Use this checklist after completing the setup, build, and login steps in `../SKILL.md`.

## Screenshots

Steps marked with `> SCREENSHOT: <filename> — <label>` are **required** checkpoints. Save each one using `save_screenshot` with the given filename, then compact it immediately. These form the flipbook in the final HTML report.

You may also take **additional** screenshots for failure triage or to capture unexpected states. Use a `FAIL-` prefix for those (e.g. `FAIL-05-unexpected-error.png`).

## Test phases

Tests are organized into two phases:

- **Phase 1 — User-assisted**: Tests that need user interaction (auth sheets, hardware, barcodes). Run these first while the user is present.
- **Phase 2 — Fully automated**: Tests the agent runs independently. The user can walk away after Phase 1.

Within each phase, tests are grouped into sections. Each section has its own pass criteria.

## Interaction types

Steps are marked with one of these labels:

- **(auto)** — Fully automated, no user input needed.
- **(user-assisted)** — The agent drives the UI but pauses for user input via `AskUserQuestion` (e.g. providing a 2FA code, presenting a barcode, completing an auth sheet).
- **(device-only)** — Requires a physical device. Skip on simulator and mark as "not tested (simulator)".
- **(conditional)** — Only run if a prerequisite is met (e.g. store supports the feature). Skip gracefully if not available.

---

# Phase 1: User-Assisted Tests

Run these first while the user is present. After Phase 1 completes, tell the user they can step away.

## Section: Installation (device-only)

These checks verify the upgrade and fresh install paths. Only run on a physical device.

### Upgrade from existing version (device-only)

1. If the device has the current App Store / TestFlight version installed, install the new build over it.
2. Verify the app launches, the user remains logged in, and basic navigation works.

> SCREENSHOT: 01-upgrade-verified.png — App launched after upgrade, session preserved

### Fresh install (device-only)

1. Uninstall the app completely.
2. Install the new build.
3. Verify the app launches to the prologue/login screen.

> SCREENSHOT: 02-fresh-install-prologue.png — Fresh install prologue screen

If running on simulator, skip this section entirely — the build step in SKILL.md handles fresh installation. Mark as "not tested (simulator)".

Pass criteria: upgrade preserves session, fresh install shows prologue.

## Section: User-Assisted Login Flows

These login flows require user interaction for authentication steps the agent cannot complete alone.

### Passwordless login (user-assisted)

1. Log out if needed. Start login.
2. Enter site URL: `https://woomobilepasswordlesslogin.wpcomstaging.com/`
3. Enter email: `woomobile@bakbmdyy.mailosaur.net`
4. Tap continue. The app will send a magic link email.
5. Ask the user via `AskUserQuestion`: "Please check the Mailosaur **passwordless1** inbox (credentials: https://mc.a8c.com/secret-store/?secret_id=11346) and provide the magic link URL."
6. Open the magic link in the simulator/device: `xcrun simctl openurl <UDID> <magic_link_url>`
7. Verify the app completes login and reaches the dashboard.

> SCREENSHOT: 03-passwordless-login-success.png — Dashboard after passwordless login

### Social login — Apple (user-assisted)

1. Log out if needed. Start login.
2. Navigate to the Apple sign-in button and tap it.
3. Ask the user via `AskUserQuestion`: "An Apple sign-in sheet should appear. Please complete the authentication."
4. After the user confirms, verify the app reaches the dashboard.

> SCREENSHOT: 04-social-login-apple.png — Dashboard after Apple sign-in

### Social login — Google (user-assisted)

1. Log out if needed. Start login.
2. Navigate to the Google sign-in button and tap it.
3. Ask the user via `AskUserQuestion`: "A Google sign-in sheet should appear. Please complete the authentication."
4. After the user confirms, verify the app reaches the dashboard.

> SCREENSHOT: 05-social-login-google.png — Dashboard after Google sign-in

### Login with 2FA (user-assisted)

1. Log out if needed. Start login.
2. Enter the store URL and credentials for a 2FA-enabled account.
3. Ask the user via `AskUserQuestion`: "Please provide the current 2FA code from your authenticator app."
4. Enter the 2FA code and tap Continue.
5. Verify the app reaches the dashboard.

> SCREENSHOT: 06-2fa-login-success.png — Dashboard after 2FA login

Pass criteria: all user-assisted login methods reach the dashboard successfully.

## Section: User-Assisted Order Flows

### Barcode scanning — start order creation (user-assisted)

The test store has a "Barcode Product" with this barcode (Code 128):

```
WOOBARCODE123
```

Generate a scannable barcode image and display it to the user. You can use a barcode generator URL or create one inline. Alternatively, the user can generate one at https://barcode.tec-it.com/en/Code128?data=WOOBARCODE123

1. From the orders list, tap the barcode scan button (`create-new-order-by-product-scanning`) to start order creation via barcode.
2. Ask the user via `AskUserQuestion`: "The barcode scanner is open. Please present this barcode to the camera (display it on another screen or print it): https://barcode.tec-it.com/en/Code128?data=WOOBARCODE123 — or use a barcode for another product with a known SKU. Confirm when done."
3. Verify the scanned product is recognized and an order creation form appears with the product added.

> SCREENSHOT: 07-barcode-order-creation.png — Order created from barcode scan

### Barcode scanning — add product to order (user-assisted)

1. During order creation, tap the barcode button to add a product via scan.
2. Ask the user via `AskUserQuestion`: "The barcode scanner is open. Please present the barcode to the camera (same barcode as before, or a different product). Confirm when done."
3. Verify the scanned product is added to the order.

> SCREENSHOT: 08-barcode-product-added.png — Product added via barcode scan

Pass criteria: barcode scanner opens and successfully adds products when a barcode is presented.

## Section: Push Notifications (device-only)

Requires a physical device with push notifications enabled.

### Push notification for new order (device-only)

1. Create an order via the WooCommerce REST API:
   ```bash
   curl -X POST "https://<store_url>/wp-json/wc/v3/orders" \
     -u "<consumer_key>:<consumer_secret>" \
     -H "Content-Type: application/json" \
     -d '{"status": "processing", "line_items": [{"product_id": <known_product_id>, "quantity": 1}]}'
   ```
   Record the order number from the response.
2. Wait up to 30 seconds for the push notification to appear.
3. Verify the push notification appears on the device.

> SCREENSHOT: 09-push-notification-received.png — Push notification for new order

### Tap push notification (device-only)

1. Tap the push notification.
2. Verify the app opens the correct order detail screen matching the order number.

> SCREENSHOT: 10-push-notification-opened.png — Order detail opened from push notification

### Long press push notification (device-only)

1. If another notification is available (create a second order via REST API if needed), long-press the notification.
2. Verify the expanded notification view shows order details.

> SCREENSHOT: 11-push-notification-long-press.png — Expanded push notification

If running on simulator, skip this section. Mark as "not tested (simulator)".

Pass criteria: push notifications arrive, tapping opens the correct order, long press shows expanded view.

## Section: Payments — Card Reader & Tap to Pay (device-only, user-assisted)

Requires a physical device and payment hardware. The agent drives the UI; the user handles the physical card/reader interaction.

### Collect payment via card reader (device-only, user-assisted)

1. Create a new order or use an existing unpaid order.
2. Tap Collect Payment, then select the card reader option.
3. After tapping, watch for permission prompts (Bluetooth, location) and onboarding screens (card reader setup, terms acceptance). Tap through these as they appear — list elements after each to check for the next prompt.
4. Ask the user via `AskUserQuestion`: "Please connect the card reader and present a test card when prompted. Let me know when payment is complete."
5. Verify payment success.
6. Verify the "Print receipt" button appears on the payment success dialog.

> SCREENSHOT: 12-card-reader-payment-success.png — Card reader payment success with print receipt button

### Collect payment via Tap to Pay (device-only, user-assisted)

1. Create a new order or use an existing unpaid order.
2. Tap Collect Payment, then select Tap to Pay.
3. After tapping, watch for permission prompts and onboarding screens (TTP terms acceptance via Apple ID, setup steps). Tap through these as they appear. If an Apple ID prompt requires user interaction, ask via `AskUserQuestion`.
4. Ask the user via `AskUserQuestion`: "Please present a test card for Tap to Pay when prompted. Let me know when payment is complete."
5. Verify payment success.

> SCREENSHOT: 13-ttp-payment-success.png — Tap to Pay payment success

### Refund an IPP order (device-only, user-assisted)

1. From an order paid via card reader or TTP, initiate a refund.
2. Follow the refund flow (select all items, confirm amount, tap Refund).
3. Verify the refund completes and the order shows refunded status.

> SCREENSHOT: 14-ipp-refund-complete.png — IPP order refunded

If running on simulator, skip this section. Mark as "not tested (simulator)".

Pass criteria: card reader and TTP payments complete, receipt button appears, refund succeeds.

## Section: Media Upload — Camera (device-only, user-assisted)

### Upload media via camera (device-only, user-assisted)

1. Open a product detail, navigate to the media/images section.
2. Tap the option to add media via camera.
3. Ask the user via `AskUserQuestion`: "The camera should be open. Please take a photo and confirm."
4. Verify the captured image appears in the product's media section.

> SCREENSHOT: 15-camera-media-uploaded.png — Product media uploaded via camera

If running on simulator, skip this step. The photo library upload path is tested in Phase 2.

Pass criteria: camera capture adds an image to the product.

---

After completing Phase 1, tell the user: **"Phase 1 (user-assisted tests) is complete. You can step away — Phase 2 runs fully automated."**

---

# Phase 2: Fully Automated Tests

No user interaction needed. The agent runs these independently.

## Section: Login

Run these from the logged-out login flow.

> SCREENSHOT: 20-prologue.png — Prologue screen

### Successful login

1. Tap `Prologue Self Hosted Button`.
2. Enter the store URL in the `Site address` field.

> SCREENSHOT: 21-site-address-filled.png — Site address entered

3. Tap `Site Address Next Button`. Wait for the email screen.
4. Enter the email address.

> SCREENSHOT: 22-email-filled.png — Email entered

5. Tap `Get Started Email Continue Button`. Wait for the password screen.
6. Enter the password.
7. Tap `Continue Button`. Wait for authentication.
8. If a "Save Password?" prompt appears, dismiss it.
9. If a 2FA screen appears, enter `123456` and tap `Continue Button`.
10. If `login-epilogue-continue-button` appears, tap it.
11. Verify the dashboard loads (`tab-bar-my-store-item` visible, store name shown).

> SCREENSHOT: 23-dashboard-after-login.png — Dashboard loaded (login successful)

Pass criteria: the app navigates from prologue through credentials to the dashboard without errors.

### Wrong credentials (error state)

1. Log out if needed. Start login with the correct store URL.
2. Enter the correct email.
3. Enter an incorrect password.
4. Tap Continue.
5. List elements and verify an error message is shown.

> SCREENSHOT: 24-wrong-password-error.png — Wrong password error

### Not a WordPress site (error state)

1. Start login.
2. Enter `google.com` as the site address.
3. Tap Continue.
4. List elements and verify an error indicates the site is not WordPress.

> SCREENSHOT: 25-not-wordpress-error.png — Not a WordPress site error

### Not a WooCommerce store (error state)

1. Start login.
2. Enter `notawoostore.wordpress.com` as the site address.
3. Enter credentials — username: `appstestadmin`, from https://mc.a8c.com/secret-store/?secret_id=8326
4. Complete login.
5. Verify the app shows an appropriate error or messaging indicating the site does not have WooCommerce.

> SCREENSHOT: 26-not-woo-store-error.png — Not a WooCommerce store error

### Wrong account for the store (error state)

1. Start login.
2. Enter site URL: `https://site-for-woocommerce12a3fasdf45dfs6789.mystagingwebsite.com/`
3. Enter credentials from https://mc.a8c.com/secret-store/?secret_id=8326
4. Attempt login.
5. Verify the app shows an error indicating the account doesn't have access to the store.

> SCREENSHOT: 27-wrong-account-error.png — Wrong account for store error

### No Jetpack site

1. Create a Jurassic Ninja site with WooCommerce enabled but no Jetpack. Attempt automated creation first; if that fails, ask the user via `AskUserQuestion` for a site URL.
2. Check the WC Smooth Generator options and generate test data (e.g. 100 products and orders).
3. Log in to the app using site credentials.
4. Verify onboarding tasks are shown.
5. Verify the order list loads successfully.
6. Verify the product list loads successfully.

> SCREENSHOT: 28-no-jetpack-site.png — App loaded on no-Jetpack site

### Jetpack not connected

1. Using the same Jurassic Ninja site from the previous test, disconnect Jetpack (via WP Admin or WP CLI).
2. Log in to the site in the app.
3. Verify the app handles the disconnected Jetpack state appropriately.
4. Connect Jetpack from the app after logging in.
5. Verify the app transitions to the connected state successfully.

> SCREENSHOT: 29-jetpack-reconnected.png — App after Jetpack reconnection

After finishing all login checks, log back in with the correct credentials to the primary test store before continuing to other sections.

Pass criteria: all login error states are surfaced correctly, no-Jetpack and Jetpack-not-connected flows work, and the app can log in successfully afterward.

## Section: Dashboard

1. Tap `tab-bar-my-store-item`.
2. List elements and verify `revenue-value` is present with a non-empty value.

> SCREENSHOT: 30-dashboard-revenue.png — Dashboard with revenue visible

3. Tap `performance-time-range-menu`. If needed, use a slight tap offset to trigger the menu.
4. Tap `time-range-this-week`, then list elements and verify the date label updates.
5. Tap the time range picker again, then tap `time-range-this-month` and verify the label updates again.

> SCREENSHOT: 31-dashboard-time-range-changed.png — Dashboard after time range change

6. Scroll down and list elements to verify additional dashboard cards appear, such as top performers or store analytics.

### View All store analytics

7. Tap "View All" or the analytics section to navigate to the full store analytics screen.
8. Verify the analytics detail screen loads with charts/data.

> SCREENSHOT: 32-store-analytics-detail.png — Store analytics detail screen

9. Return to the dashboard.

### Dashboard customization

10. Tap the dashboard customization button (e.g. edit/customize).
11. Verify the customization screen shows toggleable dashboard cards.
12. Toggle one card off, then back on.
13. Verify the dashboard reflects the changes.

> SCREENSHOT: 33-dashboard-customization.png — Dashboard customization screen

Pass criteria: `revenue-value` is populated, time range selector works, analytics detail loads, and dashboard customization functions.

## Section: Orders

This section mutates store data. Only run it on the agreed smoke-test store.

### Browse orders

1. Tap `tab-bar-orders-item`.
2. List elements and verify `order-search-button` and order rows are present.

> SCREENSHOT: 34-orders-list.png — Orders list loaded

3. **Pagination verification (REQUIRED — do not skip or mark as passed early):**
   - The page size is 25. You MUST see **at least 26 distinct order numbers** to confirm a second page loaded.
   - Scroll down, calling `list_elements_on_screen` after each scroll. Extract order numbers from each listing and add them to a running set of unique order numbers seen.
   - Take a screenshot after each scroll that reveals new orders:

   > SCREENSHOT: 34a-orders-page1.png — Orders list first page
   > SCREENSHOT: 34b-orders-page2.png — Orders list after pagination (second page loaded)

   Take additional `34c-`, `34d-`, etc. screenshots if more scrolls are needed.
   - Keep scrolling until you have seen 26+ unique order numbers OR you reach the bottom of the list (no new orders appear after two consecutive scrolls).
   - **In the report**, list all unique order numbers seen and the total count (e.g. "Saw 28 unique orders: #1234, #1233, #1232, ...").
   - **Pass criteria**: 26 or more unique order numbers seen. If fewer than 26 are found, mark pagination as **FAIL** even if scrolling worked — the store may not have enough orders, or the second page did not load.

4. Tap `order-search-button`. A small downward offset may be needed.
5. Search for a known order number and verify results appear.
6. Cancel search and return to the orders list.

### Create an order

1. Tap `new-order-type-sheet-button`. A small downward offset may be needed.
2. List elements and verify `new-order-add-product-button` is present.

> SCREENSHOT: 35-new-order-form.png — Empty order creation form

3. Tap `new-order-add-product-button`, select a **simple product**, and confirm.
4. List elements and verify the product appears with the expected name and price.

5. Tap `new-order-add-product-button` again, select a **variable product**, pick a variation, and confirm.
6. Verify the variable product and its selected variation appear in the order.

> SCREENSHOT: 36-order-with-products.png — Order form with simple and variable products

### Modify order details

7. Increase the quantity of one product using the quantity controls. Verify the quantity and line total update.
8. Decrease the quantity back. Verify it updates.
9. Apply a product discount to one item. Verify the discounted price is reflected.

> SCREENSHOT: 37-order-product-discount.png — Order with product discount applied

10. Tap to add a custom amount. Enter an amount and a note. Verify it appears in the order.
11. Add shipping to the order. Verify the shipping line appears with the expected amount.
12. Add an existing customer to the order. Verify the customer name and details appear.
13. Edit the customer details. Verify the changes are reflected.

> SCREENSHOT: 38-order-with-details.png — Order with custom amount, shipping, and customer

14. Add an order note. Verify the note appears.

### Pay via cash

15. Tap `order-form-collect-payment`.
16. Verify `payment-methods-view-cash-row` is present, then tap it.
17. Verify the cash amount is correct, then tap the completion action (e.g. "Mark Order as Complete").
18. Wait for the order to be created and verify the order detail shows a completed state.
19. Record the order number for later verification.
20. Verify the order shows "Paid" with the correct amount.

> SCREENSHOT: 39-order-created-paid.png — Order detail showing Completed and Paid

### Payment link and QR

21. Create another order (simple product, no need for all the extras).
22. From the Collect Payment screen, verify "Scan to Pay" is available and tap it.
23. Verify a QR code is displayed.

> SCREENSHOT: 40-scan-to-pay-qr.png — Scan to Pay QR code

24. Go back. Verify "Share payment link" is available and tap it.
25. Verify the share sheet appears.

> SCREENSHOT: 41-share-payment-link.png — Share payment link sheet

26. Dismiss the share sheet. Complete this order via cash payment.

### Receipt

27. From the completed order detail, verify the "See receipt" button is present and tap it.
28. Verify the receipt screen loads with order details.

> SCREENSHOT: 42-order-receipt.png — Order receipt screen

29. Return to the order detail.

### Verify the created order

1. Return to the orders list.
2. Verify the first created order appears near the top.
3. Open it and verify the order details screen and payment details.

### Refund the order

1. From the order detail, scroll until the "Issue Refund" button is visible and tap it.
2. Tap "Select All" to select all items for refund.
3. Verify the refund amount matches the order total, then tap "Next".
4. Verify the refund summary shows the correct amount and payment method, then tap "Refund".
5. Confirm the alert dialog.
6. Verify the order detail shows "Refunded" status and `Net Payment $0.00`.

> SCREENSHOT: 43-order-refunded.png — Order detail showing Refunded, Net Payment $0.00

### Add order note

1. From any order detail, scroll to the notes section.
2. Add a note. Verify it appears in the order notes list.

> SCREENSHOT: 44-order-note-added.png — Order note added

### Create a shipping label (conditional)

1. From an order detail that supports shipping labels, tap to create a shipping label.
2. Walk through the shipping label creation flow.
3. Verify the label is created successfully.

> SCREENSHOT: 45-shipping-label-created.png — Shipping label created

If the store does not support shipping labels, skip this step and note it in the report.

### Mark order complete

1. From an order detail (use a Processing order, or create one), tap to mark the order as complete.
2. Verify the order status changes to Completed.

> SCREENSHOT: 46-order-marked-complete.png — Order marked as complete

Pass criteria: the orders list loads and paginates (26+ unique order numbers seen — fewer is a FAIL), order creation succeeds with simple and variable products, quantity/discount/custom amount/shipping/customer/notes all work, cash payment completes, QR code and payment link are shown, receipt loads, refund completes, and shipping label creation works (if available).

## Section: Products

### Browse products

1. Tap `tab-bar-products-item`.
2. List elements and verify `product-search-button` and product rows are present.

> SCREENSHOT: 47-products-list.png — Products list loaded

3. Scroll and verify more products load (pagination).

### Sort products

4. Tap the sort/filter control on the products list.
5. Change the sort order (e.g. by name, by date).
6. Verify the product list order changes.

> SCREENSHOT: 48-products-sorted.png — Products list sorted

### Product detail — all sections

1. Open a **simple product**.
2. Verify `product-form` and the product title are present.

> SCREENSHOT: 49-product-detail.png — Product detail loaded

3. Scroll through the form and verify each section loads:
   - Product description
   - Price settings
   - Inventory settings
   - Categories
   - Tags
   - Product type
   - Shipping settings
   - Linked products
   - Downloadable files (if applicable)

> SCREENSHOT: 50-product-detail-sections.png — Product detail showing all sections

4. Return to the products list.

### Variable product and variations

1. Open a **variable product** from the products list.
2. Verify the variations section is present.
3. Tap into the variations list. Verify variation rows appear with attributes.
4. Open a variation detail. Verify the variation attributes and price are shown.

> SCREENSHOT: 51-product-variations.png — Product variations list

5. Return to the products list.

### Search products

1. Tap `product-search-button`. A small downward offset may be needed.
2. Enter a product name that exists on the store.
3. Verify search results appear.
4. Cancel search.

### Create product

1. Tap the add/create product button.
2. Fill in a product name and a price.
3. Save the product.
4. Verify the product detail screen shows the created product.

> SCREENSHOT: 52-product-created.png — Newly created product

5. Return to the products list.

### Upload media — photo library (simulator)

1. Pre-load a test image into the simulator:
   ```bash
   xcrun simctl addmedia $UDID /path/to/test-image.png
   ```
2. Open a product detail, navigate to the media/images section.
3. Tap to add media from the photo library.
4. Select the test image.
5. Verify the image appears in the product's media section.

> SCREENSHOT: 53-media-uploaded-library.png — Product media uploaded from photo library

Pass criteria: product list loads and paginates, sort works, all product detail sections load, variations display correctly, product creation succeeds, search returns results, and media upload from photo library works.

## Section: Hub Menu

1. Tap `tab-bar-menu-item`.
2. List elements and verify expected menu items are present, including `dashboard-settings-button`, `menu-payments`, and `menu-coupons`.

> SCREENSHOT: 54-hub-menu.png — Hub Menu root screen

### Change store

3. Navigate to the store switcher.
4. Verify multiple stores are listed (the `appstestadmin` account has multiple stores).
5. Select a different store.
6. Verify the app switches to the new store (store name updates, dashboard reloads).

> SCREENSHOT: 55-store-switched.png — App after switching stores

7. Switch back to the primary test store.

### Settings — full walkthrough

8. Tap `dashboard-settings-button`.
9. Walk through each settings item, verifying it opens and loads:

| Setting | Verify |
|---------|--------|
| Beta Features | `settings-beta-features-button` present, toggle list loads |
| Notifications | Notification preferences screen loads |
| Privacy Settings | Privacy screen loads |
| About | About screen shows app version |
| Licenses | Licenses list loads |
| Log Out | Scroll to confirm `settings-log-out-button` exists (do NOT tap it) |

Tap into each setting and verify it loads, then return to Settings.

> SCREENSHOT: 56-settings-walkthrough.png — Settings screen

10. Return to Hub Menu.

### Hub Menu screens

Navigate to each of the following screens, verify it loaded, then return to Hub Menu:

| Menu Item | Tap Element | Verify |
|-----------|-------------|--------|
| Coupons | `menu-coupons` | Coupon rows or Add button present |
| Customers | `menu-customers` | Customer rows present |
| Inbox | `menu-inbox` | Inbox content present |
| Payments | `menu-payments` | Funds labels and card reader options present |

### Coupons — create

1. From the Coupons screen, tap to create a new coupon.
2. Fill in basic coupon details (code, discount amount).
3. Save the coupon.
4. Verify the coupon appears in the list.

> SCREENSHOT: 57-coupon-created.png — Coupon created

### Blaze

1. From Hub Menu, navigate to Blaze.
2. Verify the Blaze campaign creation webview loads.

> SCREENSHOT: 58-blaze-webview.png — Blaze campaign creation webview

3. Return to Hub Menu.

### WC Admin — View Store

1. From Hub Menu, tap "View Store" or the WC Admin option.
2. Verify the WP Admin webview loads.

> SCREENSHOT: 59-wc-admin-webview.png — WC Admin webview

3. Return to Hub Menu.

### Google for Woo

1. From Hub Menu, navigate to Google for Woo.
2. Verify the Google for Woo campaign creation webview loads.

> SCREENSHOT: 60-google-for-woo-webview.png — Google for Woo webview

3. Return to Hub Menu.

Pass criteria: store switching works, all settings screens load, all hub menu items open, coupon creation works, and webviews (Blaze, WC Admin, Google for Woo) load.

## Section: POS

Requires an iPad simulator. If currently on iPhone, terminate the app, boot an iPad, rebuild, and relaunch.

If not already logged in on the iPad, relaunch with:

```bash
xcrun simctl launch $IPAD_UDID com.automattic.woocommerce disable-animations bypass-pos-eligibility-checks
```

Do not use mocked POS launch arguments such as `load-mocked-pos-products` or `bypass-pos-order-syncing` when running against a real store.

### POS product search

1. Tap `tab-bar-pos-item`.
2. List elements and verify `pos-cart-view` is present.

> SCREENSHOT: 61-pos-cart-ready.png — POS cart ready state

3. Use the product search to find a specific product by name.
4. Verify search results appear.

### Add products and coupons

5. Add one product card to the cart.
6. Add a second product.
7. Verify the cart shows both items and `pos-total-field` has the expected total.

> SCREENSHOT: 62-pos-cart-with-items.png — POS cart with items added

8. If coupon support is available in POS, apply a coupon and verify the total updates.

### Pay with cash

9. Tap `pos-checkout-button`, then tap `pos-cash-payment-button`.
10. Complete the cash payment flow with `pos-mark-payment-complete-button`.
11. Verify `pos-payment-success-view` appears.

> SCREENSHOT: 63-pos-payment-success.png — POS payment success

### Email receipt

12. From the payment success screen, verify the option to send an email receipt is available.
13. If possible, enter a test email address and send the receipt.

> SCREENSHOT: 64-pos-email-receipt.png — POS email receipt option

14. Dismiss success and verify POS returns to a ready state.

Pass criteria: POS loads products, search works, items can be added to cart, coupons apply, totals update correctly, cash payment completes, and email receipt option is available.

## Section: Other

### Non-English locale

1. Change the simulator locale to a non-English language (e.g. Arabic for RTL coverage):
   ```bash
   xcrun simctl shutdown $UDID
   xcrun simctl boot $UDID -- -AppleLanguages "(ar)" -AppleLocale "ar_SA"
   ```
2. Launch the app.
3. Navigate through key screens: dashboard, orders list, products list, hub menu.
4. Take screenshots of each. Look for untranslated strings or broken layouts.

> SCREENSHOT: 65-locale-dashboard.png — Dashboard in non-English locale
> SCREENSHOT: 66-locale-orders.png — Orders in non-English locale
> SCREENSHOT: 67-locale-products.png — Products in non-English locale

5. **Revert the locale** back to English:
   ```bash
   xcrun simctl shutdown $UDID
   xcrun simctl boot $UDID -- -AppleLanguages "(en)" -AppleLocale "en_US"
   ```
6. Relaunch the app and verify it's back to English.

Pass criteria: the app is localized in the non-English locale, no obviously untranslated strings, layouts are not broken (especially RTL), and the locale reverts cleanly.

### Home screen widget

1. Go to the device/simulator home screen.
2. Long-press on an empty area to enter edit mode.
3. Add a WooCommerce widget.
4. Verify the widget appears and displays data (e.g. store stats).

> SCREENSHOT: 68-widget-added.png — WooCommerce widget on home screen

5. Remove the widget to clean up.

Pass criteria: widget can be added and displays store data.

### Quick Actions (long press app icon)

1. From the home screen, long-press the WooCommerce app icon.
2. Verify the quick action menu appears with expected items.
3. Tap one of the quick actions.
4. Verify it opens the correct screen in the app.

> SCREENSHOT: 69-quick-actions.png — Quick actions menu

Pass criteria: quick actions menu appears and navigating via a quick action works.

---

## Manual-Only (not tested by agent)

The following items require hardware, external apps, or interactions that cannot be automated. List these in the report as "not tested":

- **Watch app** — requires paired Apple Watch (My Store, Order Lists, Order Detail, push notification opens order detail)

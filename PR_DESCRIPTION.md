Closes WOOMOB-1837

## Description
When a POS order is created and a product's price has changed since the last catalog sync, the API returns the correct totals but the cart UI still shows the old price. This PR fixes the stale price display by:

1. **Updating cart item prices from the order response** — After order creation, compares each cart item's price with the corresponding order line item's price (using decimal comparison to avoid string format mismatches). If the server returned a different price, the cart item is updated with the corrected price and formatted amount.

2. **Triggering an incremental catalog sync when prices differ** — Only when a price mismatch is detected, an incremental catalog sync is kicked off so the local catalog reflects the corrected prices. This ensures consistency if the merchant edits the order or starts a new one.

### Key changes
- `PointOfSaleOrderController.priceUpdates(for:)` — new method that compares cart item prices with the synced order's line items and returns updates for items whose server-side price differs
- `Cart.applyPriceUpdates(_:)` — new mutation that applies price corrections to cart items
- `PointOfSaleAggregateModel.checkOut()` — wired up to apply price updates after order sync, with conditional incremental sync

## Test Steps
1. Set up a WooCommerce store with POS enabled and a product priced at $10
2. Open POS, add the product to the cart, and check out
3. While the POS is open, change the product price to $15 in wp-admin
4. Go back to POS, start a new order, add the same product
5. Check out — verify the cart updates to show $15 after order creation
6. Verify the catalog also reflects the new price for subsequent orders

## Screenshots
N/A — no visual UI changes, behavior-only fix.

---
- [ ] I have considered if this change warrants user-facing release notes and have added them to `RELEASE-NOTES.txt` if necessary.

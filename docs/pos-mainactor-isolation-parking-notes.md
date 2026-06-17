# POS MainActor Isolation Parking Notes

Branch: `codex/pos-mainactor-controller-protocols`

Checkpoint commit: `3c0fac3430` (`Explore POS MainActor isolation`)

## Where This Got To

- Marked POS UI-facing controller protocols as `@MainActor`:
  - `POSOrderListControllerProtocol`
  - `POSSearchingOrderListControllerProtocol`
  - `PointOfSaleItemsControllerProtocol`
  - `PointOfSaleSearchingItemsControllerProtocol`
  - `PointOfSaleCouponsControllerProtocol`
  - `PointOfSaleOrderControllerProtocol`
  - `POSSearchable`
- Updated call sites/tests/previews that construct or use those protocols.
- Updated `POSCartPaymentOrderProvider` to await actor-isolated `orderState`.
- Reworked a few `PointOfSaleOrderControllerTests` assertions away from brittle `withObservationTracking` helpers.
- Marked `POSCartProductObserving` as `@MainActor`, matching the existing `@MainActor` concrete `POSCartProductObserver`.
- That in turn pulled `PointOfSaleAggregateModel`, `PointOfSaleAggregateModelProtocol`, and `POSItemActionHandler`/factory onto the main actor.

## Verification

These passed with Xcode 26.3.0, without specifying `-sdk`:

```bash
xcodebuild -quiet -workspace WooCommerce.xcworkspace -scheme PointOfSale \
  -destination 'platform=iOS Simulator,id=E6B13908-AF9B-401F-9D07-157C0580B352' \
  -derivedDataPath /private/tmp/woocommerce-ios-dd-pos-mainactor build

xcodebuild -quiet -workspace WooCommerce.xcworkspace -scheme PointOfSale \
  -destination 'platform=iOS Simulator,id=E6B13908-AF9B-401F-9D07-157C0580B352' \
  -derivedDataPath /private/tmp/woocommerce-ios-dd-pos-mainactor \
  build-for-testing -only-testing:PointOfSaleTests

xcodebuild -quiet -workspace WooCommerce.xcworkspace -scheme PointOfSale \
  -destination 'platform=iOS Simulator,id=E6B13908-AF9B-401F-9D07-157C0580B352' \
  -derivedDataPath /private/tmp/woocommerce-ios-dd-pos-mainactor \
  test -only-testing:PointOfSaleTests
```

Remaining warnings observed during those runs appeared unrelated to this experiment:

- `NavigationLink(destination:isActive:label:)` deprecations in POS UI.
- Existing PointOfSale test warnings around `.none`, `nowValue`, and unused `sut` values.

## Concerns Before Reviving

- The controller protocol isolation looks reasonable: those protocols expose UI state and are backed by UI-owned observable controllers.
- The `POSCartProductObserving` change is the risky part. It lives in Yosemite and observes GRDB, so marking the protocol `@MainActor` leaks a UI actor contract into a data-ish boundary.
- Because of that protocol annotation, isolation spread into `PointOfSaleAggregateModel`, action handlers, and tests. This compiles, but it may be broader than necessary.
- If keeping `POSCartProductObserver` main-actor isolated, double-check its Combine pipeline. GRDB publisher callbacks may not automatically run on the main actor, so mutations of observer state and `itemsSubject.send` should be deliberately scheduled onto main.
- If avoiding the spread is preferred, revisit whether `POSCartProductObserver` can remain non-main-actor and protect its mutable state with an explicit scheduler/serialization boundary instead.

## Suggested Next Step

Before turning this into a PR, decide the `POSCartProductObserving` boundary:

1. Keep the UI controller protocols as `@MainActor`.
2. Re-evaluate whether `POSCartProductObserving` should be `@MainActor`, or whether only the POS aggregate model should receive its emissions on main.
3. If the observer remains `@MainActor`, audit the Combine callbacks for actual runtime delivery on the main actor, not only compiler isolation.

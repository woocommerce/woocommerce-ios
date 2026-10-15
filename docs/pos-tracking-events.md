# POS tracking events

## Adding an event

1. Add the event name to [`WooAnalyticsStat`](../Modules/Sources/WooFoundationCore/Analytics/WooAnalyticsStat.swift).
2. Add a typed factory to [`WooAnalyticsEvent.PointOfSale`](../Modules/Sources/PointOfSale/Analytics/WooAnalyticsEvent+PointOfSale.swift). Keep property names and values in the factory.
3. Track through the injected `POSAnalyticsProviding` dependency. For payment lifecycle events, use [`POSCollectOrderPaymentAnalyticsTracking`](../Modules/Sources/PointOfSale/Analytics/POSCollectOrderPaymentAnalyticsTracking.swift) and its [app adaptor](../WooCommerce/Classes/POS/Adaptors/POSCollectOrderPaymentAnalyticsAdaptor.swift).
4. Add tests for the event and properties. The [checkout timing tests](../WooCommerce/WooCommerceTests/POS/Analytics/POSCheckoutTimingTests.swift) include the shared cross-platform scenarios and the wrapper contract.

## Checkout timing

The POS payment adaptor adds the available timing fields to these terminal events. The table uses `WooAnalyticsStat` names before prefixes. In POS mode, [TracksProvider](../WooCommerce/Classes/Analytics/TracksProvider.swift) adds `pos_` before the application prefix is applied; use the prefixed names when querying Tracks.

| Event | Outcome |
| --- | --- |
| `card_present_collect_payment_success` | Card payment succeeded, including Interac |
| `card_present_collect_payment_failed` | Card payment failed |
| `card_present_collect_payment_canceled` | Card payment canceled |
| `cash_collect_payment_success` | Cash payment succeeded |

`sync_strategy` identifies the products source selected for the checkout: `local_catalog`, `remote`, or `unknown`. The checkout retains that value if the active source changes later.

| Optional integer milliseconds | Start boundary |
| --- | --- |
| `pos_time_since_checkout_started_ms` | Entry to `PointOfSaleAggregateModel.checkOut()`, before order synchronization |
| `pos_time_since_order_sync_completed_ms` | Successful `.newOrder` synchronization for this checkout |
| `pos_time_since_payment_confirmed_ms` | First processing-completion callback with a confirmed intent in the payment collection, including reuse of an already confirmed intent |

The [aggregate model](../Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift) starts a new context on each `checkOut()` call, including a retry. An unchanged-order result does not set a new synchronization boundary. These fields measure checkout and payment work; they do not measure first display or physical card touch.

The [payment store](../Modules/Sources/Yosemite/Stores/CardPresentPaymentStore.swift) sends processing completion before backend capture. The adaptor records confirmation before checking the payment method. Interac therefore also receives confirmation timing on its generic terminal success. The supplemental `card_interac_collect_payment_success` event is emitted directly at processing completion; it is outside this terminal timing contract. Scan to Pay and Mark as Paid success events are also outside the contract.

Durations use `ContinuousClock`, which includes time during sleep and does not use the wall clock. The adaptor takes a fresh end timestamp when it tracks each terminal event. Zero is valid. An unavailable start, a closed context, or a negative duration causes the field to be omitted. The event wrapper also removes previous values for missing or negative stages. Cash always omits confirmation timing. `pos_time_since_reader_ready_ms` is omitted because the reader callback has no payment-operation identity.

## Context and reset boundaries

The [payment use-case adaptor](<../WooCommerce/Classes/POS/Adaptors/Card Present Payments/CardPresentPaymentCollectOrderPaymentUseCaseAdaptor.swift>) captures a payment scope before it starts its asynchronous task. Late card callbacks retain that scope. Cash captures its own context before asynchronous completion.

A terminal event clears confirmation on its captured context. Failure and cancellation keep the checkout open for retry; success closes only its captured payment context. Preparing another payment creates a new payment context and retains an open checkout, but does not reuse a checkout from a closed context. Internal retries can reuse a payment scope. Duplicate confirmation callbacks preserve the first timestamp until a terminal event clears it.

Starting a new customer interaction replaces the active timing context. Scan to Pay and Mark as Paid success also reset it. Captured callbacks retain their own context when a later checkout starts. Existing event names, legacy wall-clock fields and their types and units, checkout counter rules, and reset behavior remain unchanged.

## Timing coverage

Select Android and iOS cohorts separately with each platform's app-version/build metadata. Use the first released version/build that contains these fields as that platform's lower bound; the release boundaries can differ. No runtime timing-version property is emitted.

Within each cohort, use all eligible terminal events as the coverage denominator. Count events with and without each timing field, and report the missing count or rate. A missing field means its boundary is unavailable or its duration is invalid; it does not mean zero. Keep valid zero durations in distributions. For confirmation coverage, use card terminal events because cash always omits that field. Exclude supplemental Interac events from the terminal-event denominator.

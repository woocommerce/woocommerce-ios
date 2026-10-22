# POS tracking events

## Add an event

1. Add the event name to [`WooAnalyticsStat`](../Modules/Sources/WooFoundationCore/Analytics/WooAnalyticsStat.swift).
2. Add a typed factory to [`WooAnalyticsEvent.PointOfSale`](../Modules/Sources/PointOfSale/Analytics/WooAnalyticsEvent+PointOfSale.swift). Keep property names and values in the factory.
3. Send the event through the injected `POSAnalyticsProviding` dependency. For payment events, use [`POSCollectOrderPaymentAnalyticsTracking`](../Modules/Sources/PointOfSale/Analytics/POSCollectOrderPaymentAnalyticsTracking.swift) and its [app adaptor](../WooCommerce/Classes/POS/Adaptors/POSCollectOrderPaymentAnalyticsAdaptor.swift).
4. Add tests for the event and its properties. The [checkout timing tests](../WooCommerce/WooCommerceTests/POS/Analytics/POSCheckoutTimingTests.swift) cover the shared Android and iOS scenarios and the event wrapper rules.

## Checkout timing

The POS payment adaptor adds timing fields to these payment outcome events when their start times are available.

The table shows the `WooAnalyticsStat` names without prefixes. In POS mode, [TracksProvider](../WooCommerce/Classes/Analytics/TracksProvider.swift) adds `pos_`. The application adds its own prefix. Use the full name in Tracks queries, such as `woocommerceios_pos_card_present_collect_payment_success`.

| Event | Outcome |
| --- | --- |
| `card_present_collect_payment_success` | The card payment succeeded. This includes Interac. |
| `card_present_collect_payment_failed` | The card payment failed. |
| `cash_collect_payment_success` | The cash payment succeeded. |

`sync_strategy` records the product source selected for the POS session. Its value is `local_catalog`, `remote`, or `unknown`. The coordinator selects the source and passes it to the payment analytics adaptor when the session starts. The value stays fixed for that session. A new POS session can select a different source.

| Optional elapsed field | When measurement starts |
| --- | --- |
| `pos_time_since_checkout_started_ms` | The app enters `PointOfSaleAggregateModel.checkOut()`, before order synchronization. |
| `pos_time_since_order_sync_completed_ms` | Order synchronization returns a successful `.newOrder` result for this checkout. |
| `pos_time_since_payment_confirmed_ms` | The collection receives its first processing-completion callback with a confirmed intent. This includes reuse of an already confirmed intent. |

Each field records integer milliseconds from its start time to the outcome event. These periods overlap. They do not measure first display or physical card touch.

The timers use `ContinuousClock`. This clock includes device sleep and does not depend on date or time corrections. The adaptor reads the clock again for each outcome event. Zero is valid. If a start time is unavailable or a duration is negative, the event wrapper omits the field and removes any previous value for it.

Cash events omit confirmation timing. The adaptor also omits `pos_time_since_reader_ready_ms` because the reader callback does not identify the payment operation.

## Payment confirmation

The [payment store](../Modules/Sources/Yosemite/Stores/CardPresentPaymentStore.swift) calls processing completion after it receives a confirmed intent and before backend capture. Android native card and Tap to Pay flows check the receipt URL before capture. iOS does not require this check. The adaptor records the confirmation time before it checks the payment method.

For a canceled collection, the cancellation guard prevents a new confirmation timestamp. It does not suppress the supplemental Interac success event. POS and non-POS flows keep that event.

Interac payments receive confirmation timing on the card payment success event. The separate `card_interac_collect_payment_success` event fires at processing completion. It is outside the outcome timing rules. Scan to Pay and Mark as Paid success events are also outside these rules.

## Timer resets

The payment analytics adaptor stores three shared timestamps. It does not create separate timing objects for each checkout or payment attempt.

The [aggregate model](../Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift) restarts checkout timing on every `checkOut()` call. This includes retries. The adaptor clears the synchronization and confirmation timestamps. The aggregate model ignores synchronization results from an earlier checkout. An unchanged-order result does not set a new synchronization timestamp.

Card success and failure read the timers and then clear confirmation. Cash reads checkout and synchronization timing without clearing card confirmation. Repeated confirmation callbacks keep the first timestamp until a card outcome or collection abandonment clears it.

A new cart or customer interaction clears all three timestamps. Scan to Pay and Mark as Paid success also clear them.

The app receives gateway and reader metadata before collection. The outcome callback runs after payment work and required success metadata checks finish. It creates the event and reads the timers without an asynchronous wait between these operations.

## Cancellation

The POS `card_present_collect_payment_canceled` event omits all `milliseconds_since_*` and `pos_time_since_*` fields. It also omits `sync_strategy`. It keeps the event name, cancellation source, reader, gateway, country and checkout count.

The app clears confirmation when it abandons collection, before asynchronous SDK cancellation completes. A delayed cancellation event does not clear a newer collection's confirmation. A new POS collection also clears confirmation before it starts.

This change removes the four legacy POS cancellation timing fields. All other legacy fields keep their definitions, types and units. Event names, checkout counter rules and payment behavior stay the same.

## Timing coverage

Filter Android and iOS events separately by app version and build. For each platform, start with the first verified released version and build that contains these fields. The release versions can differ. Events have no timing-version property.

Count all eligible outcome events when you calculate timing coverage. For each field, count events with and without the field. Report the missing count or rate.

A missing field means that its start time is unavailable or its duration is invalid. It does not mean zero. Use only events with the field when you calculate duration statistics. Keep measured zero values.

For confirmation coverage, count only card success and failure events. Cash omits this field. Exclude cancellation and supplemental Interac events from timing coverage counts.

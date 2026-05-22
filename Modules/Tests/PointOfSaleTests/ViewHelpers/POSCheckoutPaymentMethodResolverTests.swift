import Testing
@testable import PointOfSale

@Suite("POSCheckoutPaymentMethodResolver")
struct POSCheckoutPaymentMethodResolverTests {
    // MARK: - Cash-button visibility guard

    @Test func returns_empty_when_cash_button_not_visible() {
        // Given — every other input would normally produce a populated list.
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: false,
            isReaderDisconnected: true,
            isTapToPayAvailable: true,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: true
        )

        // Then
        #expect(methods.isEmpty)
    }

    // MARK: - Card-enabled stores

    @Test func card_enabled_with_TTP_and_no_reader_yields_TTP_cardReader_cash() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: true,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: false
        )

        // Then — TTP first (primary), then card-reader, then Cash.
        #expect(methods == [.tapToPay, .cardReader, .cashPayment])
    }

    @Test func card_enabled_with_TTP_and_connected_reader_yields_TTP_cash() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: true,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: false
        )

        // Then — card-reader slot is omitted when a reader is connected.
        #expect(methods == [.tapToPay, .cashPayment])
    }

    @Test func card_enabled_without_TTP_and_no_reader_yields_cardReader_cash() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: false,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: false
        )

        // Then — iPad-style: card-reader is primary, Cash is secondary.
        #expect(methods == [.cardReader, .cashPayment])
    }

    @Test func card_enabled_without_TTP_and_connected_reader_yields_cash_only() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: false,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: false
        )

        // Then
        #expect(methods == [.cashPayment])
    }

    @Test func card_enabled_appends_otherPaymentMethods_when_any_secondary_flag_is_on() {
        // When — Scan to Pay and Mark as Paid don't render inline on card-enabled stores;
        // instead, the resolver appends an `.otherPaymentMethods` slot that opens the
        // existing POSOtherPaymentMethodsSheet (which is what gates Scan/Mark internally).
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: true,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: true
        )

        // Then
        #expect(methods == [.tapToPay, .cardReader, .cashPayment, .otherPaymentMethods])
    }

    @Test func card_enabled_appends_otherPaymentMethods_when_only_scanToPay_is_on() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: false,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: false
        )

        // Then — iPad no-TTP card-supported country with a connected reader still surfaces
        // the Other payment methods entry so Scan-to-Pay is reachable.
        #expect(methods == [.cashPayment, .otherPaymentMethods])
    }

    @Test func card_enabled_appends_otherPaymentMethods_when_only_markOrderAsPaid_is_on() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: false,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: true
        )

        // Then
        #expect(methods == [.cashPayment, .otherPaymentMethods])
    }

    @Test func card_enabled_omits_otherPaymentMethods_when_no_secondary_flag_is_on() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: false,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: false
        )

        // Then — no Other payment methods slot when there's nothing to put inside the sheet.
        #expect(methods == [.cardReader, .cashPayment])
    }

    // MARK: - No-card stores

    @Test func no_card_with_no_secondary_flags_yields_cash_only() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: true,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: false
        )

        // Then — reader/TTP slots are suppressed even when the underlying state would
        // normally include them; Cash stands alone as the primary CTA.
        #expect(methods == [.cashPayment])
    }

    @Test func no_card_with_scanToPay_yields_cash_then_otherPaymentMethods() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: false,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: false
        )

        // Then — Scan-to-Pay is reachable through the `.otherPaymentMethods` sheet entry.
        #expect(methods == [.cashPayment, .otherPaymentMethods])
    }

    @Test func no_card_with_markOrderAsPaid_yields_cash_then_otherPaymentMethods() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: false,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: true
        )

        // Then — Mark-as-Paid is reachable through the `.otherPaymentMethods` sheet entry.
        #expect(methods == [.cashPayment, .otherPaymentMethods])
    }

    @Test func no_card_with_both_secondary_flags_yields_cash_then_otherPaymentMethods() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: false,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: true
        )

        // Then — single `.otherPaymentMethods` entry regardless of how many secondary
        // flags are on; the sheet that opens lists whichever are enabled.
        #expect(methods == [.cashPayment, .otherPaymentMethods])
    }

    @Test func no_card_ignores_reader_and_TTP_state() {
        // When — even with TTP availability and a disconnected reader, no-card stores
        // never expose card UI; only Cash + (optional) Other payment methods appear.
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: true,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: false
        )

        // Then
        #expect(methods == [.cashPayment])
    }
}

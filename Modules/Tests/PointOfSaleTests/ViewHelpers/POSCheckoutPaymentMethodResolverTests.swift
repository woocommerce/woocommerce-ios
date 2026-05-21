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

    @Test func card_enabled_ignores_scanToPay_and_markOrderAsPaid_feature_flags() {
        // When — Scan to Pay and Mark as Paid are surfaced via the "Other payment methods"
        // sheet on card-enabled stores, NOT inline. The resolver only adds them to the
        // promoted no-card layout.
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: true,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: true,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: true
        )

        // Then
        #expect(methods == [.tapToPay, .cardReader, .cashPayment])
    }

    // MARK: - No-card (promoted) layout

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

    @Test func no_card_with_scanToPay_yields_cash_then_scanToPay() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: true,
            isTapToPayAvailable: false,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: false
        )

        // Then
        #expect(methods == [.cashPayment, .scanToPay])
    }

    @Test func no_card_with_markOrderAsPaid_yields_cash_then_markOrderAsPaid() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: false,
            isScanToPayEnabled: false,
            isMarkOrderAsPaidEnabled: true
        )

        // Then
        #expect(methods == [.cashPayment, .markOrderAsPaid])
    }

    @Test func no_card_with_both_secondary_flags_yields_cash_scanToPay_markOrderAsPaid() {
        // When
        let methods = POSCheckoutPaymentMethodResolver.resolve(
            isPOSCardPaymentEnabled: false,
            isCashButtonVisible: true,
            isReaderDisconnected: false,
            isTapToPayAvailable: false,
            isScanToPayEnabled: true,
            isMarkOrderAsPaidEnabled: true
        )

        // Then — Cash is the primary CTA; Scan to Pay and Mark as Paid follow as peers.
        #expect(methods == [.cashPayment, .scanToPay, .markOrderAsPaid])
    }

    @Test func no_card_ignores_reader_and_TTP_state() {
        // When — even with TTP availability and a disconnected reader, no-card stores
        // never expose card UI; only Cash + flagged secondaries appear.
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

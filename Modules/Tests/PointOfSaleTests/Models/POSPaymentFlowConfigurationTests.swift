import Testing
@testable import PointOfSale

struct POSPaymentFlowConfigurationTests {

    // MARK: - Cart Configuration

    @Test("cart config has 'New order' success title")
    func cart_config_has_new_order_success_title() {
        let config = POSPaymentFlowConfiguration.cart(onNewOrder: {}, onEditOrder: {})
        #expect(config.successAction.title == "New order")
    }

    @Test("cart config has 'New order' capture error exit title")
    func cart_config_has_new_order_capture_error_exit_title() {
        let config = POSPaymentFlowConfiguration.cart(onNewOrder: {}, onEditOrder: {})
        #expect(config.captureErrorExitAction.title == "New order")
    }

    @Test("cart config has 'Edit order' intent creation error exit title")
    func cart_config_has_edit_order_intent_creation_error_exit_title() {
        let config = POSPaymentFlowConfiguration.cart(onNewOrder: {}, onEditOrder: {})
        #expect(config.intentCreationErrorExitAction.title == "Edit order")
    }

    @Test("cart config has no close button")
    func cart_config_has_no_close_button() {
        let config = POSPaymentFlowConfiguration.cart(onNewOrder: {}, onEditOrder: {})
        #expect(config.showInitialCloseButton == false)
    }

    @Test("cart config success action calls onNewOrder")
    @MainActor
    func cart_config_success_action_calls_onNewOrder() {
        var called = false
        let config = POSPaymentFlowConfiguration.cart(onNewOrder: { called = true }, onEditOrder: {})
        config.successAction.action()
        #expect(called == true)
    }

    @Test("cart config capture error exit calls onNewOrder")
    @MainActor
    func cart_config_capture_error_exit_calls_onNewOrder() {
        var called = false
        let config = POSPaymentFlowConfiguration.cart(onNewOrder: { called = true }, onEditOrder: {})
        config.captureErrorExitAction.action()
        #expect(called == true)
    }

    @Test("cart config intent creation error exit calls onEditOrder")
    @MainActor
    func cart_config_intent_creation_error_exit_calls_onEditOrder() {
        var called = false
        let config = POSPaymentFlowConfiguration.cart(onNewOrder: {}, onEditOrder: { called = true })
        config.intentCreationErrorExitAction.action()
        #expect(called == true)
    }

    // MARK: - Bookings Configuration

    @Test("bookings config has 'Done' success title")
    func bookings_config_has_done_success_title() {
        let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
        #expect(config.successAction.title == "Done")
    }

    @Test("bookings config has 'Back to Booking' capture error exit title")
    func bookings_config_has_back_to_booking_capture_error_exit_title() {
        let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
        #expect(config.captureErrorExitAction.title == "Back to Booking")
    }

    @Test("bookings config has 'Back to Booking' intent creation error exit title")
    func bookings_config_has_back_to_booking_intent_creation_error_exit_title() {
        let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
        #expect(config.intentCreationErrorExitAction.title == "Back to Booking")
    }

    @Test("bookings config has close button")
    func bookings_config_has_close_button() {
        let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
        #expect(config.showInitialCloseButton == true)
    }

    @Test("bookings config all actions call onDismiss")
    @MainActor
    func bookings_config_all_actions_call_onDismiss() {
        var dismissCount = 0
        let config = POSPaymentFlowConfiguration.bookings(onDismiss: { dismissCount += 1 })

        config.successAction.action()
        config.captureErrorExitAction.action()
        config.intentCreationErrorExitAction.action()

        #expect(dismissCount == 3)
    }
}

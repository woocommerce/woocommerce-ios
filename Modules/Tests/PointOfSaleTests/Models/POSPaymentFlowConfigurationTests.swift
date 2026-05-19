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
}

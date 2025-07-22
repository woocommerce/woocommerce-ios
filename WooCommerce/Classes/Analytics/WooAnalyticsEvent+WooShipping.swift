import Foundation

extension WooAnalyticsEvent {
    enum WooShipping {
        private enum Keys: String {
            case type
            case state
            case unfulfilledShipmentsCount = "unfulfilled_shipments_count"
        }

        enum AddressType: String {
            case origin
            case destination
        }

        enum EditingAddressStep: String {
            case started
            case validationFailed = "validation_failed"
            case validationSuccess = "validation_success"
            case confirmed
            case confirmedWithoutVerification = "confirmed_without_verification"
        }

        enum PackageSelectionStep: String {
            case started
            case loadingSuccess = "loading_success"
            case loadingFailed = "loading_failed"
            case savingSuccess = "saving_success"
            case savingFailed = "saving_failed"
            case removingSuccess = "removing_success"
            case removingFailed = "removing_failed"
            case selected
        }

        enum RateSelectionStep: String {
            case loadingSuccess = "loading_success"
            case loadingFailed = "loading_failed"
            case selected
        }

        enum PaymentStep: String {
            case started
            case addPaymentMethodButtonTapped = "add_payment_method_button_tapped"
            case paymentMethodAdded = "payment_method_added"
            case paymentMethodSelected = "payment_method_selected"
        }

        enum PurchaseStep: String {
            case started
            case purchaseSuccess = "purchase_success"
            case purchaseFailed = "purchase_failed"
        }

        /// When the shipping label creation form is opened.
        static func createShippingLabelFormShown(unfulfilledShipmentsCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooShippingCreateShippingLabelFormShown,
                              properties: [Keys.unfulfilledShipmentsCount.rawValue: unfulfilledShipmentsCount])
        }

        /// When the state of the editing addresses step changes.
        static func editingAddressStep(type: AddressType,
                                       state: EditingAddressStep,
                                       error: Error? = nil) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooShippingEditingAddressStep,
                              properties: [Keys.type.rawValue: type.rawValue,
                                           Keys.state.rawValue: state.rawValue],
                              error: error)
        }

        /// When the state of the package selection step changes.
        static func packageSelectionStep(state: PackageSelectionStep, error: Error? = nil) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooShippingPackageSelectionStep,
                              properties: [Keys.state.rawValue: state.rawValue],
                              error: error)
        }

        /// When the state of the rate selection step changes.
        static func rateSelectionStep(state: RateSelectionStep, error: Error? = nil) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooShippingRateSelectionStep,
                              properties: [Keys.state.rawValue: state.rawValue],
                              error: error)
        }

        /// When the state of the payment step changes.
        static func paymentStep(state: PaymentStep) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooShippingPaymentStep,
                              properties: [Keys.state.rawValue: state.rawValue])
        }

        /// When the state of the purchase step changes.
        static func purchaseStep(state: PurchaseStep, error: Error? = nil) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooShippingPurchaseStep,
                              properties: [Keys.state.rawValue: state.rawValue],
                              error: error)
        }

        /// When a shipping label refund is requested
        static func refundRequested(error: Error? = nil) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooShippingRefundRequested, properties: [:], error: error)
        }
    }
}

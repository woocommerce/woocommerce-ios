import Foundation
import enum WooFoundationCore.WooAnalyticsStat

/// Configures the view-level differences between payment flow callers.
struct POSPaymentFlowConfiguration {
    /// Action shown on the success screen (e.g. "New order" for cart).
    let successAction: PaymentFlowAction

    /// Action to leave the payment flow from a capture error ("New order" for cart).
    let captureErrorExitAction: PaymentFlowAction

    /// Action to leave the payment flow from an intent creation error ("Edit order" for cart).
    let intentCreationErrorExitAction: PaymentFlowAction

    /// Whether to show a close (x) button on the initial payment screen.
    let showInitialCloseButton: Bool

    /// Optional barcode scan handler for the success screen.
    /// When provided, barcode scanning is enabled after a successful payment
    /// (automatically disabled during receipt email entry).
    let onSuccessScreenBarcodeScanned: ((Result<String, HIDBarcodeParserError>) -> Void)?
}

/// A labeled action used by the payment flow configuration.
struct PaymentFlowAction {
    let title: String
    let action: () -> Void
    let analyticsEvent: WooAnalyticsStat?
}

// MARK: - Cart

extension POSPaymentFlowConfiguration {
    static func cart(onNewOrder: @escaping () -> Void,
                     onEditOrder: @escaping () -> Void,
                     onSuccessScreenBarcodeScanned: ((Result<String, HIDBarcodeParserError>) -> Void)? = nil) -> Self {
        POSPaymentFlowConfiguration(
            successAction: PaymentFlowAction(
                title: Localization.Cart.newOrder,
                action: onNewOrder,
                analyticsEvent: .pointOfSaleCreateNewOrderTapped),
            captureErrorExitAction: PaymentFlowAction(
                title: Localization.Cart.newOrder,
                action: onNewOrder,
                analyticsEvent: nil),
            intentCreationErrorExitAction: PaymentFlowAction(
                title: Localization.Cart.editOrder,
                action: onEditOrder,
                analyticsEvent: nil),
            showInitialCloseButton: false,
            onSuccessScreenBarcodeScanned: onSuccessScreenBarcodeScanned
        )
    }
}

// MARK: - Localization

private extension POSPaymentFlowConfiguration {
    enum Localization {
        enum Cart {
            static let newOrder = NSLocalizedString(
                "pointOfSale.paymentFlowConfiguration.cart.newOrder.button.title",
                value: "New order",
                comment: "Button title on the payment success and capture error screens " +
                "in the Point of Sale checkout to start a new order"
            )

            static let editOrder = NSLocalizedString(
                "pointOfSale.paymentFlowConfiguration.cart.editOrder.button.title",
                value: "Edit order",
                comment: "Button title on the payment intent creation error screen " +
                "in the Point of Sale checkout to go back and edit the current order"
            )
        }
    }
}

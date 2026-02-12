import Foundation

/// Configures the view-level differences between payment flow callers.
struct POSPaymentFlowConfiguration {
    /// Action shown on the success screen (e.g. "New order" for cart, "Done" for bookings).
    let successAction: PaymentFlowAction

    /// Action to leave the payment flow from a capture error
    /// ("New order" for cart, "Back to Booking" for bookings).
    let captureErrorExitAction: PaymentFlowAction

    /// Action to leave the payment flow from an intent creation error
    /// ("Edit order" for cart, "Back to Booking" for bookings).
    let intentCreationErrorExitAction: PaymentFlowAction

    /// Whether to show a close (x) button on the initial payment screen.
    let showInitialCloseButton: Bool
}

/// A labeled action used by the payment flow configuration.
struct PaymentFlowAction {
    let title: String
    let action: () -> Void
}

// MARK: - Cart

extension POSPaymentFlowConfiguration {
    static func cart(onNewOrder: @escaping () -> Void,
                     onEditOrder: @escaping () -> Void) -> Self {
        POSPaymentFlowConfiguration(
            successAction: PaymentFlowAction(
                title: Localization.Cart.newOrder,
                action: onNewOrder),
            captureErrorExitAction: PaymentFlowAction(
                title: Localization.Cart.newOrder,
                action: onNewOrder),
            intentCreationErrorExitAction: PaymentFlowAction(
                title: Localization.Cart.editOrder,
                action: onEditOrder),
            showInitialCloseButton: false
        )
    }
}

// MARK: - Bookings

extension POSPaymentFlowConfiguration {
    static func bookings(onDismiss: @escaping () -> Void) -> Self {
        POSPaymentFlowConfiguration(
            successAction: PaymentFlowAction(
                title: Localization.Bookings.done,
                action: onDismiss),
            captureErrorExitAction: PaymentFlowAction(
                title: Localization.Bookings.backToBooking,
                action: onDismiss),
            intentCreationErrorExitAction: PaymentFlowAction(
                title: Localization.Bookings.backToBooking,
                action: onDismiss),
            showInitialCloseButton: true
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

        enum Bookings {
            static let done = NSLocalizedString(
                "pointOfSale.paymentFlowConfiguration.bookings.done.button.title",
                value: "Done",
                comment: "Button title on the payment success screen " +
                "in the Point of Sale bookings payment flow to dismiss and return to booking details"
            )

            static let backToBooking = NSLocalizedString(
                "pointOfSale.paymentFlowConfiguration.bookings.backToBooking.button.title",
                value: "Back to booking",
                comment: "Button title on payment error screens " +
                "in the Point of Sale bookings payment flow to dismiss and return to booking details"
            )
        }
    }
}

import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageViewModel: Equatable {
    let title = Localization.title
    let message: String
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let backToCheckoutButtonViewModel: CardPresentPaymentsModalButtonViewModel?

    init(error: Error,
         tryPaymentAgainButtonAction: @escaping () -> Void,
         backToCheckoutButtonAction: @escaping () -> Void) {
        self.init(error: error,
                  tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel(
                    title: Localization.tryPaymentAgain,
                    actionHandler: tryPaymentAgainButtonAction),
                  backToCheckoutButtonViewModel: CardPresentPaymentsModalButtonViewModel(
                    title: Localization.backToCheckout,
                    actionHandler: backToCheckoutButtonAction))
    }

    init(error: Error,
         tryAnotherPaymentMethodButtonAction: @escaping () -> Void) {
        self.init(error: error,
                  tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel(
                    title: Localization.tryAnotherPaymentMethod,
                    actionHandler: tryAnotherPaymentMethodButtonAction),
                  backToCheckoutButtonViewModel: nil)
    }

    private init(error: Error,
                 tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel,
                 backToCheckoutButtonViewModel: CardPresentPaymentsModalButtonViewModel?) {
        self.message = Self.message(for: error)
        self.tryAgainButtonViewModel = tryAgainButtonViewModel
        self.backToCheckoutButtonViewModel = backToCheckoutButtonViewModel
    }

    private static func message(for error: Error) -> String {
        if let error = error as? CardReaderServiceError {
            return error.errorDescription ?? error.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
}

private extension PointOfSaleCardPresentPaymentErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentError.title",
            value: "Payment failed",
            comment: "Error message. Presented to users after collecting a payment fails on the Point of Sale Checkout"
        )

        static let tryPaymentAgain =  NSLocalizedString(
            "pointOfSale.cardPresent.paymentError.tryPaymentAgain.button.title",
            value: "Try payment again",
            comment: "Button to try to collect a payment again. Presented to users after collecting a " +
            "payment fails on the Point of Sale Checkout"
        )

        static let tryAnotherPaymentMethod =  NSLocalizedString(
            "pointOfSale.cardPresent.paymentError.tryAnotherPaymentMethod.button.title",
            value: "Try another payment method",
            comment: "Button to try to collect a payment again. Presented to users after collecting a " +
            "payment fails on the Point of Sale Checkout, when it's unlikely that the same card will work."
        )

        static let backToCheckout =  NSLocalizedString(
            "pointOfSale.cardPresent.paymentError.backToCheckout.button.title",
            value: "Go back to checkout",
            comment: "Button to leave the order when a card payment fails. Presented to users after " +
            "collecting a payment fails on the Point of Sale Checkout"
        )
    }
}

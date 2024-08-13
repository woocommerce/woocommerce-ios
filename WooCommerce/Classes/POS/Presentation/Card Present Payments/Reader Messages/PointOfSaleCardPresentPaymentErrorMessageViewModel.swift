import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentErrorMessageViewModel {
    let title = Localization.title
    let message: String
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let exitButtonViewModel: CardPresentPaymentsModalButtonViewModel?

    init(error: Error,
         tryPaymentAgainButtonAction: @escaping () -> Void) {
        self.init(error: error,
                  tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel(
            title: Localization.tryPaymentAgain,
            actionHandler: tryPaymentAgainButtonAction))
    }

    init(error: Error,
         tryAnotherPaymentMethodButtonAction: @escaping () -> Void) {
        self.init(error: error,
                  tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel(
                    title: Localization.tryAnotherPaymentMethod,
                    actionHandler: tryAnotherPaymentMethodButtonAction))
    }

    private init(error: Error,
                 tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel) {
        self.message = Self.message(for: error)
        self.tryAgainButtonViewModel = tryAgainButtonViewModel
        self.exitButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.exitOrder,
            actionHandler: { })
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

        static let exitOrder =  NSLocalizedString(
            "pointOfSale.cardPresent.paymentError.exitOrder.button.title",
            value: "Exit order",
            comment: "Button to leave the order when a card payment fails. Presented to users after " +
            "collecting a payment fails on the Point of Sale Checkout"
        )
    }
}

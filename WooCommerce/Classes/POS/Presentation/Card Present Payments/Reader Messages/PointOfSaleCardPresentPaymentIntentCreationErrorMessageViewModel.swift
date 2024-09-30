import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel: Equatable {
    let title = Localization.title
    let message: String
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let editOrderButtonViewModel: CardPresentPaymentsModalButtonViewModel?

    init(error: Error,
         tryPaymentAgainButtonAction: @escaping () -> Void,
         editOrderButtonAction: @escaping () -> Void) {
        self.init(error: error,
                  tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel(
                    title: Localization.tryPaymentAgain,
                    actionHandler: tryPaymentAgainButtonAction),
                  editOrderButtonViewModel: CardPresentPaymentsModalButtonViewModel(
                    title: Localization.backToCheckout,
                    actionHandler: editOrderButtonAction))
    }

    private init(error: Error,
                 tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel,
                 editOrderButtonViewModel: CardPresentPaymentsModalButtonViewModel?) {
        self.message = Self.message(for: error)
        self.tryAgainButtonViewModel = tryAgainButtonViewModel
        self.editOrderButtonViewModel = editOrderButtonViewModel
    }

    private static func message(for error: Error) -> String {
        if let error = error as? CardReaderServiceError {
            return error.errorDescription ?? error.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
}

private extension PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentIntentCreationError.title",
            value: "Payment preparation error",
            comment: "Error message. Presented to users after payment intent creation fails on the Point of Sale Checkout"
        )

        static let tryPaymentAgain =  NSLocalizedString(
            "pointOfSale.cardPresent.paymentIntentCreationError.backToCheckout.button.title",
            value: "Try payment again",
            comment: "Button to try to collect a payment again. Presented to users after collecting a " +
            "payment intention creation fails on the Point of Sale Checkout"
        )

        static let backToCheckout =  NSLocalizedString(
            "pointOfSale.cardPresent.paymentIntentCreationError.backToCheckout.button.title",
            value: "Edit order",
            comment: "Button to come back to order editing when a card payment fails. Presented to users after " +
            "payment intention creation fails on the Point of Sale Checkout"
        )
    }
}

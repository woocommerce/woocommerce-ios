import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel {
    let title = Localization.title
    let message: String
    let nextStep: String = Localization.nextStep
    private(set) var tryAnotherPaymentMethodButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(error: Error, tryAnotherPaymentMethodAction: @escaping () -> Void) {
        self.message = Self.message(for: error)
        self.tryAnotherPaymentMethodButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.tryAnotherPaymentMethod,
            actionHandler: tryAnotherPaymentMethodAction)
    }

    private static func message(for error: Error) -> String {
        if let error = error as? CardReaderServiceError {
            return error.errorDescription ?? error.localizedDescription
        } else {
            return error.localizedDescription
        }
    }

    mutating func updateTryAnotherPaymentMethodAction(_ newAction: @escaping () -> Void) {
        self.tryAnotherPaymentMethodButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.tryAnotherPaymentMethod,
            actionHandler: newAction)
    }
}

private extension PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentErrorNonRetryable.title",
            value: "Payment failed",
            comment: "Error message. Presented to users after collecting a payment fails on the Point of Sale Checkout"
        )

        static let tryAnotherPaymentMethod = NSLocalizedString(
            "pointOfSale.cardPresent.paymentErrorNonRetryable.tryAnotherPaymentMethod.button.title",
            value: "Try another payment method",
            comment: "Title of the button used on a card payment error from the Point of Sale Checkout " +
            "to go back and try another payment method.")

        static let nextStep = NSLocalizedString(
            "pointOfSale.cardPresent.paymentErrorNonRetryable.nextStep.instruction",
            value: "If you’d like to continue processing this transaction, please retry the payment.",
            comment: "Instruction used on a card payment error from the Point of Sale Checkout " +
            "telling the merchant how to continue with the payment.")
    }
}

import Foundation
import enum Networking.DotcomError
import enum Yosemite.CollectOrderPaymentUseCaseNotValidAmountError

struct PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel: Equatable {
    let title: String
    let message: String
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel?

    init(error: Error,
         retryApproach: CardPresentPaymentRetryApproach) {
        self.title = Self.title(for: error)
        self.message = Self.message(for: error)
        if case .tryAgain(let retryAction) = retryApproach {
            self.tryAgainButtonViewModel = CardPresentPaymentsModalButtonViewModel(
                title: Localization.retry,
                actionHandler: retryAction)
        } else {
            self.tryAgainButtonViewModel = nil
        }
    }

    private static func title(for error: Error) -> String {
        switch error {
        case CollectOrderPaymentUseCaseNotValidAmountError.belowMinimumAmount:
            return Localization.belowMinimumAmountTitle
        default:
            return Localization.title
        }
    }

    private static func message(for error: Error) -> String {
        switch error {
        case CollectOrderPaymentUseCaseNotValidAmountError.belowMinimumAmount(let amount):
            return String(format: Localization.belowMinimumAmount, amount)
        case let error as LocalizedError:
            return error.errorDescription ?? error.localizedDescription
        default:
            return error.localizedDescription
        }
    }
}

private extension PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.validatingOrderError.title",
            value: "Error checking order",
            comment: "Title shown on the Point of Sale checkout while the order validation fails."
        )

        static let retry = NSLocalizedString(
            "pointOfSale.cardPresent.validatingOrderError.tryAgain",
            value: "Try again",
            comment: "Button title to retry order validation."
        )

        static let belowMinimumAmountTitle = NSLocalizedString(
            "pointOfSale.cardPresent.validatingOrderError.belowMinimumAmount.title",
            value: "Unable to take card payment",
            comment: "Error title when the order amount is below the minimum amount allowed for a card payment on POS."
        )

        static let belowMinimumAmount = NSLocalizedString(
            "pointOfSale.cardPresent.validatingOrderError.belowMinimumAmount.description",
            value: "The order total is below the minimum amount you can charge a card, which is %1$@. " +
            "You can take a cash payment instead.",
            comment: "Error message when the order amount is below the minimum amount allowed for a card payment on POS."
        )
    }
}

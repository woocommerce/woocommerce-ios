import Foundation
import enum Networking.DotcomError

struct PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel: Equatable {
    let title: String = Localization.title
    let message: String
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel?

    init(error: Error,
         retryApproach: CardPresentPaymentRetryApproach) {
        self.message = Self.message(for: error)
        if case .tryAgain(let retryAction) = retryApproach {
            self.tryAgainButtonViewModel = CardPresentPaymentsModalButtonViewModel(
                title: Localization.retry,
                actionHandler: retryAction)
        } else {
            self.tryAgainButtonViewModel = nil
        }
    }

    private static func message(for error: Error) -> String {
        if let error = error as? LocalizedError {
            return error.errorDescription ?? error.localizedDescription
        } else {
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
            "pointOfSale.cardPresent.validatingOrderError.retry",
            value: "Retry",
            comment: "Button title to retry order validation."
        )
    }
}

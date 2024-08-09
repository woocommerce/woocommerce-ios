import Foundation
import enum Networking.DotcomError

struct PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel {
    let title: String = Localization.title
    let message: String
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(error: Error,
         tryAgainButtonAction: @escaping () -> Void) {
        self.message = Self.message(for: error)
        self.tryAgainButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.retry,
            actionHandler: tryAgainButtonAction)
    }

    private static func message(for error: Error) -> String {
        if let error = error as? DotcomError {
            return error.description
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

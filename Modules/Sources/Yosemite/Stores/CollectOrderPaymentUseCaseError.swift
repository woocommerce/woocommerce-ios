import Foundation

public enum CollectOrderPaymentUseCaseError: LocalizedError {
    case flowCanceledByUser
    case paymentGatewayNotFound
    case orderTotalChanged
    case couldNotRefreshOrder(Error)
    case orderAlreadyPaid

    public var errorDescription: String? {
        switch self {
        case .flowCanceledByUser:
            return Localization.paymentCancelledLocalizedDescription
        case .paymentGatewayNotFound:
            return Localization.paymentGatewayNotFoundLocalizedDescription
        case .orderTotalChanged:
            return Localization.orderTotalChangedLocalizedDescription
        case .couldNotRefreshOrder(let error as LocalizedError):
            return error.errorDescription
        case .couldNotRefreshOrder(let error):
            return String.localizedStringWithFormat(Localization.couldNotRefreshOrderLocalizedDescription, error.localizedDescription)
        case .orderAlreadyPaid:
            return Localization.orderAlreadyPaidLocalizedDescription
        }
    }

    private enum Localization {
        static let couldNotRefreshOrderLocalizedDescription = NSLocalizedString(
            "Unable to process payment. We could not fetch the latest order details. Please check your network " +
            "connection and try again. Underlying error: %1$@",
            comment: "Error message when collecting an In-Person Payment and unable to update the order. %!$@ will " +
            "be replaced with further error details.")

        static let orderTotalChangedLocalizedDescription = NSLocalizedString(
            "collectOrderPaymentUseCase.error.message.orderTotalChanged",
            value: "Order total has changed since the beginning of payment. Please go back and check the order is " +
            "correct, then try the payment again.",
            comment: "Error message when collecting an In-Person Payment and the order total has changed remotely.")

        static let orderAlreadyPaidLocalizedDescription = NSLocalizedString(
            "Unable to process payment. This order is already paid, taking a further payment would result in the " +
            "customer being charged twice for their order.",
            comment: "Error message shown during In-Person Payments when the order is found to be paid after it's refreshed.")

        static let paymentGatewayNotFoundLocalizedDescription = NSLocalizedString(
            "Unable to process payment. We could not connect to the payment system. Please contact support if this " +
            "error continues.",
            comment: "Error message shown during In-Person Payments when the payment gateway is not available.")

        static let paymentCancelledLocalizedDescription = NSLocalizedString(
            "The payment was cancelled.", comment: "Message shown if a payment cancellation is shown as an error.")
    }
}


public enum CollectOrderPaymentUseCaseNotValidAmountError: Error, LocalizedError, Equatable {
    case belowMinimumAmount(amount: String)
    case other

    public var errorDescription: String? {
        switch self {
        case .belowMinimumAmount(let amount):
            return String.localizedStringWithFormat(Localization.belowMinimumAmount, amount)
        case .other:
            return Localization.defaultMessage
        }
    }

    private enum Localization {
        static let defaultMessage = NSLocalizedString(
            "Unable to process payment. Order total amount is not valid.",
            comment: "Error message when the order amount is not valid."
        )

        static let belowMinimumAmount = NSLocalizedString(
            "Unable to process payment. Order total amount is below the minimum amount you can charge, which is %1$@",
            comment: "Error message when the order amount is below the minimum amount allowed."
        )
    }
}

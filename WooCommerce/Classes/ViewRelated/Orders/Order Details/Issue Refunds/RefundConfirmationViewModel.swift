import Foundation
import Yosemite

/// ViewModel for presenting refund confirmation to the user.
///
final class RefundConfirmationViewModel {

    /// Amount to refund, formatted with the order's currency
    ///
    private(set) lazy var refundAmount: String = {
        currencyFormatter.formatAmount(details.amount, with: details.order.currency) ?? ""
    }()

    /// Struct with all refund details needed to create a `Refund` object.
    ///
    private let details: Details

    /// Amount currency formatter
    ///
    private let currencyFormatter: CurrencyFormatter

    /// StoresManager to dispatch the "Create Refund" action.
    ///
    private let actionProcessor: StoresManager

    /// Contains the current value of the Reason for Refund text field.
    ///
    private let reasonForRefundCellViewModel =
        TitleAndEditableValueTableViewCellViewModel(title: Localization.reasonForRefund,
                                                    placeholder: Localization.reasonForRefundingOrder)

    /// The sections and rows to display in the `UITableView`.
    ///
    lazy private(set) var sections: [Section] = [
        Section(
            title: nil,
            rows: [
                makePreviouslyRefundedRow(),
                TwoColumnRow(title: Localization.refundAmount, value: refundAmount, isHeadline: true),
                TitleAndEditableValueRow(cellViewModel: reasonForRefundCellViewModel),
            ]
        ),
        Section(
            title: Localization.refundVia,
            rows: [
                makeRefundViaRow()
            ]
        )
    ]

    private let analytics: Analytics

    init(details: Details,
         actionProcessor: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics) {
        self.details = details
        self.actionProcessor = actionProcessor
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.analytics = analytics
    }

    /// Submit the refund.
    ///
    func submit(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        // Create refund object
        let shippingLine = details.refundsShipping ? details.order.shippingLines.first : nil
        let useCase = RefundCreationUseCase(amount: details.amount,
                                            reason: reasonForRefundCellViewModel.currentValue,
                                            automaticallyRefundsPayment: gatewaySupportsAutomaticRefunds(),
                                            items: details.items,
                                            shippingLine: shippingLine,
                                            currencyFormatter: currencyFormatter)
        let refund = useCase.createRefund()

        // Submit it
        let action = RefundAction.createRefund(siteID: details.order.siteID, orderID: details.order.orderID, refund: refund) { [weak self] _, error  in
            guard let self = self else { return }
            if let error = error {
                DDLogError("Error creating refund: \(refund)\nWith Error: \(error)")
                self.trackCreateRefundRequestFailed(error: error)
                return onCompletion(.failure(error))
            }

            // We don't care if the "update order" fails. We return .success() as the refund creation already succeeded.
            self.updateOrder { _ in
                onCompletion(.success(()))
            }
            self.trackCreateRefundRequestSuccess()
        }

        actionProcessor.dispatch(action)
        trackCreateRefundRequest()
    }

    /// Updates the order associated with the refund to reflect the latest refund status.
    ///
    func updateOrder(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = OrderAction.retrieveOrder(siteID: details.order.siteID, orderID: details.order.orderID) { _, error  in
            if let error = error {
                return onCompletion(.failure(error))
            }
            onCompletion(.success(()))
        }
        actionProcessor.dispatch(action)
    }
}

// MARK: Refund Details
extension RefundConfirmationViewModel {
    struct Details {
        /// Order to refund
        ///
        let order: Order

        /// Total amount to refund
        ///
        let amount: String

        /// Indicates if shipping will be refunded
        ///
        let refundsShipping: Bool

        /// Order items and quantities to refund
        ///
        let items: [RefundableOrderItem]

        /// Payment gateway used with the order
        ///
        let paymentGateway: PaymentGateway?
    }
}

// MARK: - Builders

private extension RefundConfirmationViewModel {
    func makePreviouslyRefundedRow() -> TwoColumnRow {
        let useCase = TotalRefundedCalculationUseCase(order: details.order, currencyFormatter: currencyFormatter)
        let totalRefunded = useCase.totalRefunded().abs()
        let totalRefundedFormatted = currencyFormatter.formatAmount(totalRefunded) ?? ""
        return TwoColumnRow(title: Localization.previouslyRefunded, value: totalRefundedFormatted, isHeadline: false)
    }

    /// Returns a row with special formatting if the payment gateway does not support automatic money refunds.
    ///
    func makeRefundViaRow() -> RefundConfirmationViewModelRow {
        if gatewaySupportsAutomaticRefunds() {
            return SimpleTextRow(text: details.order.paymentMethodTitle)
        } else {
            return TitleAndBodyRow(title: Localization.manualRefund(via: details.order.paymentMethodTitle),
                                   body: Localization.refundWillNotBeIssued(paymentMethod: details.order.paymentMethodTitle))
        }
    }
}

// MARK: Helpers
private extension RefundConfirmationViewModel {
    /// Returns `true` if the payment gateway associated with this order supports automatic money refunds. `False` otherwise.
    /// If no payment gateway is found, `false` will be returned.
    ///
    func gatewaySupportsAutomaticRefunds() -> Bool {
        guard let paymentGateway = details.paymentGateway else {
            return false
        }
        return paymentGateway.features.contains(.refunds)
    }
}

// MARK: Analytics
extension RefundConfirmationViewModel {
    /// Tracks when the user taps the "summary" button
    ///
    func trackSummaryButtonTapped() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.summaryButtonTapped(orderID: details.order.orderID))
    }

    /// Tracks when the create refund request is made.
    ///
    private func trackCreateRefundRequest() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.createRefund(orderID: details.order.orderID,
                                                                          fullyRefunded: details.amount == details.order.total,
                                                                          method: .items,
                                                                          gateway: details.order.paymentMethodID,
                                                                          amount: details.amount))
    }

    /// Tracks when the create refund request succeeds.
    ///
    private func trackCreateRefundRequestSuccess() {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.createRefundSuccess(orderID: details.order.orderID))
    }

    /// Tracks when the create refund request fails.
    ///
    private func trackCreateRefundRequestFailed(error: Error) {
        analytics.track(event: WooAnalyticsEvent.IssueRefund.createRefundFailed(orderID: details.order.orderID, error: error))
    }
}

// MARK: - Section and Row Types

/// A base protocol for the row types used by `RefundConfirmationViewModel`.
protocol RefundConfirmationViewModelRow {

}

extension RefundConfirmationViewModel {
    struct Section {
        let title: String?
        let rows: [RefundConfirmationViewModelRow]
    }

    /// A row that shows a title on the left and a value on the right.
    struct TwoColumnRow: RefundConfirmationViewModelRow {
        let title: String
        let value: String
        /// Indicates the style to use. If true, the view should use an emphasized (bold) style.
        let isHeadline: Bool
    }

    /// A row that shows a title and a text field below it.
    struct TitleAndEditableValueRow: RefundConfirmationViewModelRow {
        let cellViewModel: TitleAndEditableValueTableViewCellViewModel
    }

    /// A row that shows a title and a paragraph (label) below it.
    struct TitleAndBodyRow: RefundConfirmationViewModelRow {
        let title: String
        let body: String?
    }

    /// A row that shows a simple text on it.
    struct SimpleTextRow: RefundConfirmationViewModelRow {
        let text: String
    }
}

// MARK: - Localization

private extension RefundConfirmationViewModel {
    enum Localization {
        static let previouslyRefunded = NSLocalizedString("Previously Refunded",
                                                          comment: "A label representing the amount that was previously refunded for the order.")
        static let refundAmount =
            NSLocalizedString("Refund Amount",
                              comment: "A label representing the amount that will be refunded if the user confirms to proceed with the refund.")
        static let refundVia = NSLocalizedString("Refund Via",
                                                 comment: "The title of the section containing information about how the refund will be processed.")
        static let reasonForRefund =
            NSLocalizedString("Reason for Refund (Optional)",
                              comment: "A label for the text field that the user can edit to indicate why they are issuing a refund.")
        static let reasonForRefundingOrder =
            NSLocalizedString("Reason for refunding order",
                              comment: "A placeholder for the text field that the user can edit to indicate why they are issuing a refund.")

        static func manualRefund(via paymentMethod: String) -> String {
            let format = NSLocalizedString(
                     "Manual Refund via %1$@",
                comment: "In Refund Confirmation, The title shown to the user to inform them that"
                    + " they have to issue the refund manually."
                    + " The %1$@ is the payment method like “Stripe”.")
            return String.localizedStringWithFormat(format, paymentMethod)
        }

        static func refundWillNotBeIssued(paymentMethod: String) -> String {
            let format = NSLocalizedString(
                "A refund will not be issued to the customer."
                    + " You will need to manually issue the refund through %1$@.",
                comment: "In Refund Confirmation, The message shown to the user to inform them that"
                    + " they have to issue the refund manually."
                    + " The %1$@ is the payment method like “Stripe”.")
            return String.localizedStringWithFormat(format, paymentMethod)
        }
    }
}

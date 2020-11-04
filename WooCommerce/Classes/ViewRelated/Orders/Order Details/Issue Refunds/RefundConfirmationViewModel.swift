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

    /// Struct with al refund details needed to create a `Refund` object.
    ///
    private let details: Details

    /// Amount currency formatter
    ///
    private let currencyFormatter: CurrencyFormatter

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
                TitleAndBodyRow(title: Localization.manualRefund(via: "Stripe"),
                                body: Localization.refundWillNotBeIssued(paymentMethod: "Stripe"))
            ]
        )
    ]

    init(details: Details, currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.details = details
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    /// Submit the refund.
    ///
    /// This does not do anything at the moment. XD
    ///
    func submit() {
        print("Submitting refund with reason “\(reasonForRefundCellViewModel.currentValue ?? "")”")
        print("JUST KIDDING! ʕ•ᴥ•ʔ")
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

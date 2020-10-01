import Foundation

final class RefundConfirmationViewModel {

    // This will be computed later :D
    let refundAmount = "$87.50"

    private(set) var sections: [Section]

    init() {
        sections = [
            Section(
                title: nil,
                rows: [
                    TwoColumnRow(title: Localization.previouslyRefunded, value: "$0.01", isHeadline: false),
                    TwoColumnRow(title: Localization.refundAmount, value: refundAmount, isHeadline: true),
                    TitleAndEditableValueRow(title: Localization.reasonForRefund,
                                             placeholder: Localization.reasonForRefundingOrder),
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
    }
}

// MARK: - Sections and Rows

protocol RefundConfirmationViewModelRow {

}

extension RefundConfirmationViewModel {
    struct Section {
        let title: String?
        let rows: [RefundConfirmationViewModelRow]
    }

    struct TwoColumnRow: RefundConfirmationViewModelRow {
        let title: String
        let value: String
        let isHeadline: Bool
    }

    struct TitleAndEditableValueRow: RefundConfirmationViewModelRow {
        let title: String
        let placeholder: String
    }

    struct TitleAndBodyRow: RefundConfirmationViewModelRow {
        let title: String
        let body: String?
    }
}

// MARK: - Localization

private extension RefundConfirmationViewModel {
    enum Localization {
        static let previouslyRefunded = NSLocalizedString("Previously Refunded", comment: "")
        static let refundAmount = NSLocalizedString("Refund Amount", comment: "")
        static let refundVia = NSLocalizedString("Refund Via", comment: "")
        static let reasonForRefund = NSLocalizedString("Reason for Refund (Optional)", comment: "")
        static let reasonForRefundingOrder = NSLocalizedString("Reason for refunding order", comment: "")

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

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
        let fees = details.refundsFees ? details.order.fees : []
        let useCase = RefundCreationUseCase(amount: details.amount,
                                            reason: reasonForRefundCellViewModel.value,
                                            automaticallyRefundsPayment: gatewaySupportsAutomaticRefunds(),
                                            items: details.items,
                                            shippingLine: shippingLine,
                                            fees: fees,
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

        /// Charge of original payment
        ///
        let charge: WCPayCharge?

        /// Total amount to refund
        ///
        let amount: String

        /// Indicates if shipping will be refunded
        ///
        let refundsShipping: Bool

        /// Indicates if fees will be refunded
        ///
        let refundsFees: Bool

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
            guard case .cardPresent(let cardDetails) = details.charge?.paymentMethodDetails else {
                return SimpleTextRow(text: details.order.paymentMethodTitle)
            }
            return PaymentDetailsRow(cardIcon: cardDetails.brand.icon,
                                     cardIconAspectHorizontal: cardDetails.brand.iconAspectHorizontal,
                                     paymentGateway: details.order.paymentMethodTitle,
                                     paymentMethodDescription: cardDetails.brand.cardDescription(last4: cardDetails.last4),
                                     accessibilityDescription: cardDetails.brand.cardAccessibilityDescription(last4: cardDetails.last4))
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

    /// A row that shows an optional payment method image, a gateway name, and an description for the payment below
    struct PaymentDetailsRow: RefundConfirmationViewModelRow {
        let cardIcon: UIImage?
        let cardIconAspectHorizontal: CGFloat
        let paymentGateway: String
        let paymentMethodDescription: String
        let accessibilityDescription: NSAttributedString
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

private extension WCPayCardBrand {
    /// A displayable brand name and last 4 digits for a card. These are deliberately not localized, always in English,
    /// because of various limitations on localization by the card companies. Care should be taken if localizing (some of)
    /// these brand names in future – e.g. Mastercard allows only English, or specific authorized versions in Chinese (translation),
    /// Arabic (transliteration), and Georgian (transliteration).
    ///
    /// Names taken from [Stripe's card branding in the API docs](https://stripe.com/docs/api/cards/object#card_object-brand):
    /// American Express, Diners Club, Discover, JCB, Mastercard, UnionPay, Visa, or Unknown.
    /// N.B. on review, we found that Mastercard should not have an uppercase "c" as it does in Stripe's documentation
    /// https://brand.mastercard.com/brandcenter/branding-requirements/mastercard.html#name
    func cardDescription(last4: String) -> String {
        return String(format: cardDescriptionFormatString(), last4)
    }

    func cardAccessibilityDescription(last4: String) -> NSAttributedString {
        let localizedDescription = String(format: Localization.cardAccessibilityDescriptionFormat, cardBrandName(), last4)
        let attributedLocalizedDescription = NSMutableAttributedString(string: localizedDescription)

        guard let brandNameRange = localizedDescription.range(of: cardBrandName()),
              let last4Range = localizedDescription.range(of: last4)
        else {
            return attributedLocalizedDescription
        }

        let brandNameNSRange = NSRange(brandNameRange, in: localizedDescription)
        let last4NSRange = NSRange(last4Range, in: localizedDescription)
        attributedLocalizedDescription.setAttributes([.accessibilitySpeechLanguage: "en-US"], range: brandNameNSRange)
        attributedLocalizedDescription.setAttributes([.accessibilitySpeechSpellOut: true], range: last4NSRange)

        return attributedLocalizedDescription
    }

    func cardDescriptionFormatString() -> String {
        switch self {
        case .amex:
            return "•••• %1$@ (American Express)"
        case .diners:
            return "•••• %1$@ (Diners Club)"
        case .discover:
            return "•••• %1$@ (Discover)"
        case .interac:
            return "•••• %1$@ (Interac)"
        case .jcb:
            return "•••• %1$@ (JCB)"
        case .mastercard:
            return "•••• %1$@ (Mastercard)"
        case .unionpay:
            return "•••• %1$@ (UnionPay)"
        case .visa:
            return "•••• %1$@ (Visa)"
        case .unknown:
            return "•••• %1$@"
        }
    }

    func cardBrandName() -> String {
        switch self {
        case .amex:
            return "American Express"
        case .diners:
            return "Diners Club"
        case .discover:
            return "Discover"
        case .interac:
            return "interac"
        case .jcb:
            return "JCB"
        case .mastercard:
            return "Mastercard"
        case .unionpay:
            return "UnionPay"
        case .visa:
            return "Visa"
        case .unknown:
            return ""
        }
    }

    enum Localization {
        static let cardAccessibilityDescriptionFormat = NSLocalizedString(
            "%1$@ card ending %2$@",
            comment: "Accessibility description for a card payment method, used by assistive technologies " +
            "such as screen reader. %1$@ is a placeholder for the card brand, %2$@ is a placeholder for the " +
            "last 4 digits of the card number")
    }
}

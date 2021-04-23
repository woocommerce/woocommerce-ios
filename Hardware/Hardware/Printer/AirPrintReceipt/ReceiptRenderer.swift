import UIKit

/// Renders a receipt in an AirPrint enabled printer.
/// To be properly implemented in https://github.com/woocommerce/woocommerce-ios/issues/3978
final class ReceiptRenderer: UIPrintPageRenderer {
    private let lines: [ReceiptLineItem]
    private let parameters: CardPresentReceiptParameters

    private let headerAttributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return [.font: UIFont(name: "HelveticaNeue", size: 24) as Any,
                .paragraphStyle: paragraph]
    }()

    private let bodyAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "HelveticaNeue", size: 12) as Any]

    init(content: ReceiptContent) {
        self.lines = content.lineItems
        self.parameters = content.parameters

        super.init()

        configureHeaderAndFooter()

        configureFormatter()
    }

    override func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        guard let storeName = parameters.storeName else {
            return
        }

        let receiptTitle = String.localizedStringWithFormat(Localization.receiptFromFormat,
                                                            storeName) as NSString

        receiptTitle.draw(in: headerRect, withAttributes: headerAttributes)
    }

    override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect) {
        guard let emv = parameters.cardDetails.receipt else {
            return
        }

        /// According to the documentation, only `Application name` and `AID`
        /// are required in the US.
        /// https://stripe.com/docs/terminal/checkout/receipts#custom
        let mandatoryInfo = """
            \(Localization.applicationName): \(emv.applicationPreferredName)\n
            \(Localization.aid): \(emv.dedicatedFileName)
        """

        let footerString = NSString(string: mandatoryInfo)

        footerString.draw(in: footerRect, withAttributes: bodyAttributes)
    }
}


private extension ReceiptRenderer {
    private func configureHeaderAndFooter() {
        headerHeight = Constants.headerHeight
        footerHeight = Constants.footerHeight
    }

    private func configureFormatter() {
        let formatter = UIMarkupTextPrintFormatter(markupText: htmlContent())
        formatter.perPageContentInsets = .init(top: Constants.headerHeight, left: Constants.marging, bottom: Constants.footerHeight, right: Constants.marging)

        addPrintFormatter(formatter, startingAtPageAt: 0)
    }

    private func htmlContent() -> String {
        return """
            <html>
            <head></head>
                <body>
                    <p>
                        <h3>\(Localization.amountPaidSectionTitle.uppercased())</h3>
                        \(parameters.amount / 100) \(parameters.currency.uppercased())
                    </p>
                    <p>
                        <h3>\(Localization.datePaidSectionTitle.uppercased())</h3>
                        March 23, 2021
                    </p>
                    <p>
                        <h3>\(Localization.paymentMethodSectionTitle.uppercased())</h3>
                        \(parameters.cardDetails.brand) - \(parameters.cardDetails.last4)
                    </p>
                    <p>
                        <h3>\(Localization.summarySectionTitle.uppercased())</h3>
                        \(summaryTable())
                    </p>
                </body>
            </html>
        """
    }

    private func summaryTable() -> String {
        var summaryContent = "<table>"
        for line in lines {
            summaryContent += "<tr><td>\(line.title)</td><td>\(line.amount) \(parameters.currency.uppercased())</td></tr>"
        }
        summaryContent += """
                            <tr>
                                <td>
                                    \(Localization.amountPaidSectionTitle)
                                </td>
                                <td>
                                    \(parameters.amount / 100) \(parameters.currency.uppercased())
                                </td>
                            </tr>
                            """
        summaryContent += "</table>"

        return summaryContent
    }
}


private extension ReceiptRenderer {
    enum Constants {
        static let headerHeight: CGFloat = 80
        static let footerHeight: CGFloat = 80
        static let marging: CGFloat = 20
    }

    enum Localization {
        static let receiptFromFormat = NSLocalizedString(
            "Receipt from %1$@",
            comment: "Title of receipt. Reads like Receipt from WooCommerce, Inc."
        )

        static let amountPaidSectionTitle = NSLocalizedString(
            "Amount paid",
            comment: "Title of 'Amount Paid' section in the receipt"
        )

        static let datePaidSectionTitle = NSLocalizedString(
            "Date paid",
            comment: "Title of 'Date Paid' section in the receipt"
        )

        static let paymentMethodSectionTitle = NSLocalizedString(
            "Payment method",
            comment: "Title of 'Payment method' section in the receipt"
        )

        static let summarySectionTitle = NSLocalizedString(
            "Summary",
            comment: "Title of 'Summary' section in the receipt"
        )

        static let applicationName = NSLocalizedString(
            "Application name",
            comment: "Reads as 'Application name'. Part of the mandatory data in receipts"
        )

        static let aid = NSLocalizedString(
            "AID",
            comment: "Reads as 'AID'. Part of the mandatory data in receipts"
        )

        static let accountType = NSLocalizedString(
            "Account Type",
            comment: "Reads as 'Account Type'. Part of the mandatory data in receipts"
        )
    }
}

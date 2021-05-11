import UIKit

/// Renders a receipt in an AirPrint enabled printer.
/// To be properly implemented in https://github.com/woocommerce/woocommerce-ios/issues/3978
public final class ReceiptRenderer: UIPrintPageRenderer {
    private let lines: [ReceiptLineItem]
    private let parameters: CardPresentReceiptParameters

    private let headerAttributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return [.font: UIFont(name: "HelveticaNeue", size: 24) as Any,
                .paragraphStyle: paragraph]
    }()

    private let footerAttributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        return [.font: UIFont(name: "HelveticaNeue", size: 12) as Any,
                .paragraphStyle: paragraph]
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current

        return formatter
    }()

    public init(content: ReceiptContent) {
        self.lines = content.lineItems
        self.parameters = content.parameters

        super.init()

        configureHeaderAndFooter()

        configureFormatter()
    }

    override public func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        guard let siteName = parameters.storeName else {
            return
        }

        let receiptTitle = String.localizedStringWithFormat(Localization.receiptFromFormat,
                                                            siteName) as NSString

        receiptTitle.draw(in: headerRect, withAttributes: headerAttributes)
    }

    override public func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect) {
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

        footerString.draw(in: footerRect, withAttributes: footerAttributes)
    }
}


public extension ReceiptRenderer {
    /// This is where the layout of the receipt can be customized.
    /// Customization can be done via embedded CSS.
    /// https://github.com/woocommerce/woocommerce-ios/issues/4033
    /// - Returns: A string containing the HTML that will be rendered to the receipt.
    func htmlContent() -> String {
        return """
            <html>
            <head>
                <style type="text/css">
                    h3 { color: #707070; margin:0; }
                    table { background-color:#F5F5F5; width:100%; color: #707070 }
                    table td:last-child { width: 30%; text-align: right; }
                    table tr:last-child { color: #000000; }
                    .card-icon {
                       width: 24px;
                       height: 17px;
                       vertical-align: bottom;
                       background-repeat: no-repeat;
                       background-position-y: center;
                       display: inline-block;
                    }
                    \(cardIconCSS())
                </style>
            </head>
                <body>
                    <p>
                        <h3>\(Localization.amountPaidSectionTitle.uppercased())</h3>
                        \(parameters.amount / 100) \(parameters.currency.uppercased())
                    </p>
                    <p>
                        <h3>\(Localization.datePaidSectionTitle.uppercased())</h3>
                        \(dateFormatter.string(from: parameters.date))
                    </p>
                    <p>
                        <h3>\(Localization.paymentMethodSectionTitle.uppercased())</h3>
                        <span class="card-icon \(parameters.cardDetails.brand.iconName)-icon"></span> - \(parameters.cardDetails.last4)
                    </p>
                    <p>
                        <h3>\(Localization.summarySectionTitle.uppercased())</h3>
                        \(summaryTable())
                    </p>
                    <p>
                        \(requiredItems())
                    </p>
                </body>
            </html>
        """
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

    private func requiredItems() -> String {
        guard let emv = parameters.cardDetails.receipt else {
            return "<br/>"
        }

        /// According to the documentation, only `Application name` and `AID`
        /// are required in the US.
        /// https://stripe.com/docs/terminal/checkout/receipts#custom
        return """
            \(Localization.applicationName): \(emv.applicationPreferredName)<br/>
            \(Localization.aid): \(emv.dedicatedFileName)
        """
    }

    private func cardIconCSS() -> String {
        CardBrand.allCases.map { (cardBrand) in
            ".\(cardBrand.iconName)-icon { background-image: url(\"data:image/svg+xml;base64,\(cardBrand.iconData.base64EncodedString())\") }"
        }.joined(separator: "\n\n")
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

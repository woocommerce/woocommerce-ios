import UIKit

/// Renders a receipt in an AirPrint enabled printer.
///
public final class ReceiptRenderer: UIPrintPageRenderer {
    private let content: ReceiptContent

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current

        return formatter
    }()

    public init(content: ReceiptContent) {
        self.content = content

        super.init()

        configureFormatter()
    }
}


public extension ReceiptRenderer {
    /// This is where the layout of the receipt can be customized.
    /// Customization can be done via embedded CSS.
    /// https://github.com/woocommerce/woocommerce-ios/issues/4033
    /// - Returns: A string containing the HTML that will be rendered to the receipt.
    func htmlContent() -> String {
        let lineHeight = Constants.fontSize * 1.5
        let iconHeight = lineHeight
        let iconWidth = iconHeight * 4/3
        return """
            <html>
            <head>
                <style type="text/css">
                    html { font-family: "Helvetica Neue", sans-serif; font-size: \(Constants.fontSize)pt; }
                    header { margin-top: \(Constants.margin); }
                    h1 { font-size: \(Constants.titleFontSize)pt; font-weight: 500; text-align: center; }
                    h3 { color: #707070; margin:0; }
                    table {
                        background-color:#F5F5F5;
                        width:100%;
                        color: #707070;
                        margin: \(Constants.margin / 2)pt 0;
                        padding: \(Constants.margin / 2)pt;
                    }
                    table td:last-child { width: 30%; text-align: right; }
                    table tr:last-child { color: #000000; font-weight: bold; }
                    footer {
                        font-size: \(Constants.footerFontSize)pt;
                        border-top: 1px solid #707070;
                        margin-top: \(Constants.margin)pt;
                        padding-top: \(Constants.margin)pt;
                    }
                    .card-icon {
                       width: \(iconWidth)pt;
                       height: \(iconHeight)pt;
                       vertical-align: top;
                       background-repeat: no-repeat;
                       background-position-y: center;
                       display: inline-block;
                    }
                    p { line-height: \(lineHeight)pt; margin: 0 0 \(Constants.margin / 2) 0; }
                    \(cardIconCSS())
                </style>
            </head>
                <body>
                    <header>
                        <h1>\(receiptTitle)</h1>
                        <h3>\(Localization.amountPaidSectionTitle.uppercased())</h3>
                        <p>
                            \(content.parameters.formattedAmount) \(content.parameters.currency.uppercased())
                        </p>
                        <h3>\(Localization.datePaidSectionTitle.uppercased())</h3>
                        <p>
                            \(dateFormatter.string(from: content.parameters.date))
                        </p>
                        <h3>\(Localization.paymentMethodSectionTitle.uppercased())</h3>
                        <p>
                            <span class="card-icon \(content.parameters.cardDetails.brand.iconName)-icon"></span> - \(content.parameters.cardDetails.last4)
                        </p>
                    </header>
                    <h3>\(summarySectionTitle.uppercased())</h3>
                    \(summaryTable())
                    \(orderNoteSection())
                    <footer>
                        <p>
                            \(requiredItems())
                        </p>
                    </footer>
                </body>
            </html>
        """
    }
}


private extension ReceiptRenderer {
    private func configureFormatter() {
        let formatter = UIMarkupTextPrintFormatter(markupText: htmlContent())
        formatter.perPageContentInsets = .init(top: 0, left: Constants.margin, bottom: 0, right: Constants.margin)

        addPrintFormatter(formatter, startingAtPageAt: 0)
    }

    private func summaryTable() -> String {
        var summaryContent = "<table>"
        for line in content.lineItems {
            summaryContent += "<tr><td>\(line.title.encodeHtml()) × \(line.quantity)</td><td>\(line.amount) \(content.parameters.currency.uppercased())</td></tr>"
        }
        summaryContent += totalRows()
        summaryContent += "</table>"

        return summaryContent
    }

    private func totalRows() -> String {
        var rows = ""
        for total in content.cartTotals {
            rows += summaryRow(title: total.description, amount: total.amount)
        }
        return rows
    }

    private func summaryRow(title: String, amount: String) -> String {
        """
            <tr>
                <td>
                    \(title)
                </td>
                <td>
                    \(amount) \(content.parameters.currency.uppercased())
                </td>
            </tr>
        """
    }

    private func orderNoteSection() -> String {
        guard let orderNote = content.orderNote else {
            return ""
        }
        return """
        <h3>\(Localization.orderNoteSectionTitle.uppercased())</h3>
        <p>\(orderNote)</p>
        """
    }

    private func requiredItems() -> String {
        guard let emv = content.parameters.cardDetails.receipt else {
            return "<br/>"
        }

        /// According to the documentation, only `Application name` and `AID`
        /// are required in the US.
        /// https://stripe.com/docs/terminal/checkout/receipts#custom
        return """
               \(Localization.applicationName): \(emv.applicationPreferredName.encodeHtml())<br/>
               \(Localization.aid): \(emv.dedicatedFileName.encodeHtml())
               """
    }

    private func cardIconCSS() -> String {
        CardBrand.allCases.map { (cardBrand) in
            ".\(cardBrand.iconName)-icon { background-image: url(\"data:image/svg+xml;base64,\(cardBrand.iconData.base64EncodedString())\") }"
        }.joined(separator: "\n\n")
    }

    private var receiptTitle: String {
        guard let storeName = content.parameters.storeName else {
            return Localization.receiptTitle
        }

        return .localizedStringWithFormat(Localization.receiptFromFormat, storeName)
    }

    private var summarySectionTitle: String {
        guard let orderID = content.parameters.orderID else {
            return Localization.summarySectionTitle
        }
        return String(format: Localization.summarySectionTitleWithOrderFormat, String(orderID))
    }
}


private extension ReceiptRenderer {
    enum Constants {
        static let margin: CGFloat = 16
        static let titleFontSize: CGFloat = 24
        static let fontSize: CGFloat = 12
        static let footerFontSize: CGFloat = 10
    }

    enum Localization {
        static let receiptFromFormat = NSLocalizedString(
            "Receipt from %1$@",
            comment: "Title of receipt. Reads like Receipt from WooCommerce, Inc."
        )

        static let receiptTitle = NSLocalizedString(
            "Receipt",
            comment: "Title of receipt."
        )

        static let amountPaidSectionTitle = NSLocalizedString(
            "Amount Paid",
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
            comment: "Title of 'Summary' section in the receipt when the order number is unknown"
        )

        static let orderNoteSectionTitle = NSLocalizedString(
            "Notes",
            comment: "Title of order note section in the receipt, commonly used for Quick Orders.")

        static let summarySectionTitleWithOrderFormat = NSLocalizedString(
            "Summary: Order #%1$@",
            comment: "Title of 'Summary' section in the receipt. %1$@ is the order number, e.g. 4920"
        )

        static let applicationName = NSLocalizedString(
            "Application Name",
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

private extension String {
    func encodeHtml() -> String {
        let data = Data(utf8)
        do {
            return try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            ).string
        } catch {
            print(error)
            return self
        }
    }
}

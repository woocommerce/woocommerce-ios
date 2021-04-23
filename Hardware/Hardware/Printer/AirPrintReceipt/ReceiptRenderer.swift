import UIKit

/// Renders a receipt in an AirPrint enabled printer.
/// To be properly implemented in https://github.com/woocommerce/woocommerce-ios/issues/3978
final class ReceiptRenderer: UIPrintPageRenderer {
    private let lines: [ReceiptLineItem]
    private let parameters: CardPresentReceiptParameters

    private let headerAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "HelveticaNeue", size: 24) as Any]

    private let bodyTitleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "HelveticaNeue", size: 12) as Any]

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

    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        let printOut = NSString(string: "Total charged: \(parameters.amount / 100) \(parameters.currency.uppercased())")

        printOut.draw(in: contentRect, withAttributes: bodyAttributes)
    }
}


private extension ReceiptRenderer {
    private func configureHeaderAndFooter() {
        headerHeight = Constants.headerHeight
        footerHeight = Constants.footerHeight
    }

    private func configureFormatter() {
        let formatter = UIMarkupTextPrintFormatter(markupText: htmlContent())
//        let formatter = UISimpleTextPrintFormatter(text: "\(parameters.amount / 100) \(parameters.currency.uppercased())")
        formatter.perPageContentInsets = .init(top: Constants.headerHeight, left: Constants.marging, bottom: Constants.footerHeight, right: Constants.marging)

        addPrintFormatter(formatter, startingAtPageAt: 0)
    }

    private func htmlContent() -> String {
        return """
            <p>
                <h3>AMOUNT PAID</h3>
                120 USD<br/>
            </p>
            <p>
                <h3>DATE PAID</h3>
                March 23, 2021<br/>
            </p>
            <p>
                <h3>PAYMENT METHOD</h3>
                - 4242<br/>
            </p>
        """
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
    }
}

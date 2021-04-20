import UIKit

/// Renders a receipt in an AirPrint enabled printer.
/// To be implemented in https://github.com/woocommerce/woocommerce-ios/issues/3978
final class ReceiptRenderer: UIPrintPageRenderer {
    private let lines: [ReceiptLineItem]
    private let paymentIntent: PaymentIntent

    private let attributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "HelveticaNeue", size: 48) as Any]

    init(content: ReceiptContent) {
        self.lines = content.lineItems
        self.paymentIntent = content.paymentIntent
        super.init()

        self.headerHeight = 80
        self.footerHeight = 80

        let formatter = UISimpleTextPrintFormatter(text: "\(paymentIntent.amount / 100) \(paymentIntent.currency.uppercased())")
        formatter.perPageContentInsets = .init(top: 80, left: 20, bottom: 80, right: 20)

        addPrintFormatter(formatter, startingAtPageAt: 0)
    }

    override func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        let pageNumberString = NSString(string: "Order receipt. Page \(pageIndex + 1)")
        pageNumberString.draw(in: headerRect, withAttributes: attributes)
    }

    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        let printOut = NSString(string: "Total charged: \(paymentIntent.amount / 100) \(paymentIntent.currency.uppercased())")

        printOut.draw(in: contentRect, withAttributes: attributes)
    }
}

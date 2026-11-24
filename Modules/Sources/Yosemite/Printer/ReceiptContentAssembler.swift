import Foundation
import Networking
import Hardware
import WooFoundation

/// Builds a `ReceiptContent` (line items, cart totals, order note) from an `Order` and its
/// `CardPresentReceiptParameters`.
///
/// Pure and reusable so receipt layout lives in one place: `ReceiptStore` uses it for the
/// AirPrint / HTML path, and `ReceiptPrinterService` uses it for thermal text printing.
struct ReceiptContentAssembler {
    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())) {
        self.currencyFormatter = currencyFormatter
    }

    func makeContent(order: Order, parameters: CardPresentReceiptParameters, removingHtml: Bool = false) -> ReceiptContent {
        let lineItems = generateLineItems(order: order, currency: parameters.currency)
        let cartTotals = generateCartTotals(order: order, parameters: parameters)
        let note = receiptOrderNote(order: order, removingHtml: removingHtml)

        return ReceiptContent(parameters: parameters,
                              lineItems: lineItems,
                              cartTotals: cartTotals,
                              orderNote: note)
    }
}

private extension ReceiptContentAssembler {
    func receiptOrderNote(order: Order, removingHtml: Bool) -> String? {
        guard let orderNote = order.customerNote else {
            return nil
        }
        if removingHtml {
            return orderNote.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        } else {
            return orderNote
        }
    }

    func generateLineItems(order: Order, currency: String) -> [ReceiptLineItem] {
        order.items.map { item in
            ReceiptLineItem(
                title: item.name,
                quantity: item.quantity.description,
                amount: currencyFormatter.formatAmount(item.subtotal, with: currency) ?? "",
                attributes: item.attributes.map { ReceiptLineAttribute(name: $0.name, value: $0.value) }
            )
        }
    }

    func generateCartTotals(order: Order, parameters: CardPresentReceiptParameters) -> [ReceiptTotalLine] {
        let subtotalLines: [ReceiptTotalLine?] = [
            productTotalLine(order: order, currency: parameters.currency),
            discountLine(order: order)
        ] + feeLines(fees: order.fees, currency: parameters.currency) + [
            lineIfNonZero(description: ReceiptContent.Localization.shippingLineDescription, amount: order.shippingTotal, currency: parameters.currency),
            lineIfNonZero(description: ReceiptContent.Localization.totalTaxLineDescription, amount: order.totalTax, currency: parameters.currency)
        ]
        let totalLine = [ReceiptTotalLine(description: ReceiptContent.Localization.amountPaidLineDescription,
                                         amount: parameters.formattedAmount)]

        return subtotalLines.compactMap { $0 } + totalLine
    }

    func productTotalLine(order: Order, currency: String) -> ReceiptTotalLine {
        let lineItemsTotal = order.items.reduce(into: Decimal(0)) { result, item in
            result += NSDecimalNumber(apiAmount: item.subtotal).decimalValue
        }
        return ReceiptTotalLine(description: ReceiptContent.Localization.productTotalLineDescription,
                                amount: currencyFormatter.formatAmount(lineItemsTotal, with: currency) ?? "")
    }

    func discountLine(order: Order) -> ReceiptTotalLine? {
        let discountValue = NSDecimalNumber(apiAmount: order.discountTotal).decimalValue
        if discountValue == 0 && order.coupons.isEmpty {
            return nil
        }
        return ReceiptTotalLine(description: discountLineDescription(order: order),
                                amount: discountLineAmount(order: order, value: discountValue))
    }

    func discountLineDescription(order: Order) -> String {
        var couponCodes = ""
        if !order.coupons.isEmpty {
            couponCodes = order.coupons.map {
                $0.code
            }
            .joined(separator: ", ")
            couponCodes = "(\(couponCodes))"
        }
        return String.localizedStringWithFormat(ReceiptContent.Localization.discountLineDescription, couponCodes)
    }

    func discountLineAmount(order: Order, value: Decimal) -> String {
        if value > 0 {
            return "-\(order.discountTotal)"
        } else {
            return order.discountTotal
        }
    }

    /// One line per fee so each POS custom amount prints under its own name, in order.
    func feeLines(fees: [OrderFeeLine], currency: String) -> [ReceiptTotalLine?] {
        fees.map { fee in
            let name = (fee.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let description = name.isEmpty ? ReceiptContent.Localization.unnamedFeeLineDescription : name
            return lineIfNonZero(description: description, amount: fee.total, currency: currency)
        }
    }

    func lineIfNonZero(description: String, amount: String, currency: String) -> ReceiptTotalLine? {
        guard NSDecimalNumber(apiAmount: amount).decimalValue != 0,
              let formattedAmount = currencyFormatter.formatAmount(amount, with: currency) else {
            return nil
        }
        return ReceiptTotalLine(description: description, amount: formattedAmount)
    }
}

private extension NSDecimalNumber {
    convenience init(apiAmount: String) {
        self.init(string: apiAmount, locale: Locale(identifier: "en_US"))
    }
}

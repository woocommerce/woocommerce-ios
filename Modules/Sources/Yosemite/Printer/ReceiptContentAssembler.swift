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
        let subtotalLines = [
            productTotalLine(order: order, currency: parameters.currency),
            discountLine(order: order),
            lineIfNonZero(description: ReceiptContent.Localization.feesLineDescription,
                          amount: feesLineAmount(fees: order.fees), currency: parameters.currency),
            lineIfNonZero(description: ReceiptContent.Localization.shippingLineDescription, amount: order.shippingTotal, currency: parameters.currency),
            lineIfNonZero(description: ReceiptContent.Localization.totalTaxLineDescription, amount: order.totalTax, currency: parameters.currency)
        ].compactMap { $0 }
        let totalLine = [ReceiptTotalLine(description: ReceiptContent.Localization.amountPaidLineDescription,
                                         amount: parameters.formattedAmount)]

        return subtotalLines + totalLine
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

    func feesLineAmount(fees: [OrderFeeLine]) -> String {
        let feeTotal = fees.reduce(into: Decimal(0)) { result, fee in
            result += NSDecimalNumber(apiAmount: fee.total).decimalValue
        }
        return currencyFormatter.localize(feeTotal) ?? ""
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

import Foundation
import Yosemite

/// Creates a `Refund` object ready to be used  on `RefundStore.createRefund` action
///
struct RefundCreationUseCase {

    /// Total amount to be refunded.
    ///
    let amount: String

    /// Reason of the refund.
    ///
    let reason: String?

    /// Whether payment refund on the payment gateway should be attempted or not.
    ///
    let automaticallyRefundsPayment: Bool

    /// Line items to be refunded, currently only order items are suported
    ///
    let items: [RefundableOrderItem]

    /// Currency formatted needed for decimal calculations
    ///
    let currencyFormatter: CurrencyFormatter

    /// Creates a `Refund` object ready to be used  on `RefundStore.createRefund` action
    ///
    func createRefundObject() -> Refund {

        let refundItems = items.map { refundableItem -> OrderItemRefund in

            let taxes = refundableItem.item.taxes.map { tax -> OrderItemTaxRefund in
                let taxLineToRefund: Decimal = {
                    let totalTax = currencyFormatter.convertToDecimal(from: tax.total) ?? 0
                    let itemTax = (totalTax as Decimal) / refundableItem.item.quantity
                    return itemTax * Decimal(refundableItem.quantity)
                }()
                return OrderItemTaxRefund(taxID: tax.taxID,
                                          subtotal: "",
                                          total: currencyFormatter.localize(taxLineToRefund) ?? "\(taxLineToRefund)")
            }

            let total = refundableItem.item.price.multiplying(by: NSDecimalNumber(value: refundableItem.quantity))

            // TODO: Calculate item total tax
            let totalTax: Decimal = {
                let totalItemTax = currencyFormatter.convertToDecimal(from: refundableItem.item.totalTax) ?? 0
                let itemTax = (totalItemTax as Decimal) / refundableItem.item.quantity
                return itemTax * Decimal(refundableItem.quantity)
            }()

            return OrderItemRefund(itemID: refundableItem.item.itemID,
                                   name: "",
                                   productID: .min,
                                   variationID: .min,
                                   quantity: Decimal(refundableItem.quantity),
                                   price: .zero,
                                   sku: nil,
                                   subtotal: "",
                                   subtotalTax: "",
                                   taxClass: "",
                                   taxes: taxes,
                                   total: currencyFormatter.localize(total) ?? "\(total)",
                                   totalTax: currencyFormatter.localize(totalTax) ?? "\(totalTax)")
        }

        return Refund(refundID: .min,
                      orderID: .min,
                      siteID: .min,
                      dateCreated: .distantPast,
                      amount: amount,
                      reason: reason ?? "",
                      refundedByUserID: .min,
                      isAutomated: nil,
                      createAutomated: automaticallyRefundsPayment,
                      items: refundItems)
    }

}

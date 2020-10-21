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
    func createRefund() -> Refund {
        return Refund(refundID: .min,
                      orderID: .min,
                      siteID: .min,
                      dateCreated: .distantPast,
                      amount: amount,
                      reason: reason ?? "",
                      refundedByUserID: .min,
                      isAutomated: nil,
                      createAutomated: automaticallyRefundsPayment,
                      items: createRefundItems())
    }

    /// Retuns an array of `OrderItemRefund` based on the provided refundable items
    ///
    private func createRefundItems() -> [OrderItemRefund] {
        items.map { refundable -> OrderItemRefund in
            OrderItemRefund(itemID: refundable.item.itemID,
                            name: "",
                            productID: .min,
                            variationID: .min,
                            quantity: Decimal(refundable.quantity),
                            price: .zero,
                            sku: nil,
                            subtotal: "",
                            subtotalTax: "",
                            taxClass: "",
                            taxes: createTaxes(from: refundable),
                            total: calculateTotal(of: refundable),
                            totalTax: "")
        }
    }

    /// Creates an array of `OrderItemTaxRefund` from the tax lines in the provided `RefundableOrderItem`
    ///
    private func createTaxes(from refundable: RefundableOrderItem) -> [OrderItemTaxRefund] {
        refundable.item.taxes.map { taxLine -> OrderItemTaxRefund in
            OrderItemTaxRefund(taxID: taxLine.taxID,
                               subtotal: "",
                               total: calculateTax(of: taxLine, purchasedQuantity: refundable.item.quantity, refundQuantity: refundable.decimalQuantity))
        }
    }

    /// Calculates the refundable tax from a tax line by diving its total tax value by the purchased quantity and mutiplying it by the refunded quantity.
    ///
    private func calculateTax(of taxLine: OrderItemTax, purchasedQuantity: Decimal, refundQuantity: Decimal) -> String {
        let totalTax = currencyFormatter.convertToDecimal(from: taxLine.total) ?? 0
        let itemTax = (totalTax as Decimal) / purchasedQuantity
        let refundableTax = itemTax * refundQuantity
        return currencyFormatter.localize(refundableTax) ?? "\(refundableTax)"
    }

    /// Calculates the refundable total price from a `RefundableOrderItem` by diving the item price value by the purchased quantity
    /// and mutiplying it by the refunded quantity.
    ///
    private func calculateTotal(of refundable: RefundableOrderItem) -> String {
        let total = (refundable.item.price as Decimal) * refundable.decimalQuantity
        return currencyFormatter.localize(total) ?? "\(total)"
    }
}

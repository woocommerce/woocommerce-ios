import Foundation
import Yosemite
import WooFoundation

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

    /// Shipping line to be refunded, `nil` if shipping will not be refunded.
    ///
    let shippingLine: ShippingLine?

    /// Fees to be refunded, `empty` if fees will not be refunded.
    ///
    let fees: [OrderFeeLine]

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
                      items: createRefundItems(),
                      shippingLines: [])
    }

    /// Returns an array of `OrderItemRefund` based on the provided refundable items, shipping line and order fee lines
    ///
    private func createRefundItems() -> [OrderItemRefund] {
        var refundItems = items.map { refundable -> OrderItemRefund in
            OrderItemRefund(itemID: refundable.item.itemID,
                            name: "",
                            productID: .min,
                            variationID: .min,
                            refundedItemID: nil,
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

        if let shippingLine = shippingLine {
            refundItems.append(createShippingItem(from: shippingLine))
        }

        if fees.isNotEmpty {
            refundItems += createFeeItems(from: fees)
        }

        return refundItems
    }

    /// Returns an `OrderItemRefund` based on the provided `ShippingLine`
    ///
    private func createShippingItem(from shippingLine: ShippingLine) -> OrderItemRefund {
        OrderItemRefund(itemID: shippingLine.shippingID,
                        name: "",
                        productID: .min,
                        variationID: .min,
                        refundedItemID: nil,
                        quantity: .zero,
                        price: .zero,
                        sku: nil,
                        subtotal: "",
                        subtotalTax: "",
                        taxClass: "",
                        taxes: createTaxes(from: shippingLine),
                        total: shippingLine.total,
                        totalTax: "")
    }

    /// Returns an `[OrderItemRefund]` based on the provided `[OrderFeeLine]`
    ///
    private func createFeeItems(from feeLines: [OrderFeeLine]) -> [OrderItemRefund] {
        feeLines.map { feeLine -> OrderItemRefund in
            OrderItemRefund(itemID: feeLine.feeID,
                            name: "",
                            productID: .min,
                            variationID: .min,
                            refundedItemID: nil,
                            quantity: .zero,
                            price: .zero,
                            sku: nil,
                            subtotal: "",
                            subtotalTax: "",
                            taxClass: "",
                            taxes: createTaxes(from: feeLine),
                            total: feeLine.total,
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

    /// Creates an array of `OrderItemTaxRefund` from the tax lines in the provided `ShippingLine`
    ///
    private func createTaxes(from shippingLine: ShippingLine) -> [OrderItemTaxRefund] {
        shippingLine.taxes.map { taxLine -> OrderItemTaxRefund in
            OrderItemTaxRefund(taxID: taxLine.taxID, subtotal: "", total: taxLine.total)
        }
    }

    /// Creates an array of `OrderItemTaxRefund` from the tax lines in the provided `OrderFeeLine`
    ///
    private func createTaxes(from feeLine: OrderFeeLine) -> [OrderItemTaxRefund] {
        feeLine.taxes.map { taxLine -> OrderItemTaxRefund in
            OrderItemTaxRefund(taxID: taxLine.taxID, subtotal: "", total: taxLine.total)
        }
    }

    /// Calculates the refundable tax from a tax line by diving its total tax value by the purchased quantity and mutiplying it by the refunded quantity.
    ///
    private func calculateTax(of taxLine: OrderItemTax, purchasedQuantity: Decimal, refundQuantity: Decimal) -> String {
        let totalTax = currencyFormatter.convertToDecimal(taxLine.total) ?? 0
        let itemTax = (totalTax as Decimal) / purchasedQuantity
        let refundableTax = itemTax * refundQuantity
        return "\(refundableTax)"
    }

    /// Calculates the refundable total price from a `RefundableOrderItem` by diving the item price value by the purchased quantity
    /// and mutiplying it by the refunded quantity.
    ///
    private func calculateTotal(of refundable: RefundableOrderItem) -> String {
        let total = (refundable.item.price as Decimal) * refundable.decimalQuantity
        return "\(total)"
    }
}

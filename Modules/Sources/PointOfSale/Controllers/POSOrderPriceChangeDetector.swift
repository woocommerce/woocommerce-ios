import Foundation
import protocol Yosemite.POSOrderableItem
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

/// Detects whether product prices have changed by comparing cart items against order line items.
///
/// Compares the cart's expected line total (`cartPrice × quantity`) against both the ex-tax
/// and tax-inclusive subtotals from the order. Uses a half-cent tolerance to absorb server-side
/// tax rounding while still detecting real price changes of $0.01 or more.
struct POSOrderPriceChangeDetector {

    /// Returns true if any cart item's price doesn't match the corresponding order line item.
    func detectsPriceChange(cart: Cart, order: Order) -> Bool {
        cart.purchasableItems.contains { cartItem in
            guard let orderableItem = loadedItem(from: cartItem),
                  let orderItem = matchingOrderItem(for: orderableItem, in: order),
                  let rawPrice = rawPrice(of: orderableItem) else {
                return false
            }

            return !priceMatches(rawPrice, orderItem: orderItem)
        }
    }
}

private extension POSOrderPriceChangeDetector {

    func loadedItem(from cartItem: Cart.PurchasableItem) -> POSOrderableItem? {
        guard case .loaded(let item) = cartItem.state else { return nil }
        return item
    }

    func matchingOrderItem(for orderableItem: POSOrderableItem, in order: Order) -> OrderItem? {
        order.items.first { orderableItem.matches(orderItem: $0) }
    }

    func rawPrice(of orderableItem: POSOrderableItem) -> NSDecimalNumber? {
        let priceString: String?
        switch orderableItem {
        case let product as POSSimpleProduct:
            priceString = product.price
        case let variation as POSVariation:
            priceString = variation.price
        default:
            priceString = nil
        }
        guard let priceString else { return nil }
        return NSDecimalNumber(string: priceString)
    }

    func priceMatches(_ cartUnitPrice: NSDecimalNumber, orderItem: OrderItem) -> Bool {
        let expectedLineTotal = cartUnitPrice.multiplying(by: NSDecimalNumber(decimal: orderItem.quantity))
        let exTaxSubtotal = NSDecimalNumber(string: orderItem.subtotal)
        let taxInclusiveSubtotal = exTaxSubtotal.adding(NSDecimalNumber(string: orderItem.subtotalTax))

        return approximatelyEqual(expectedLineTotal, exTaxSubtotal)
            || approximatelyEqual(expectedLineTotal, taxInclusiveSubtotal)
    }

    func approximatelyEqual(_ a: NSDecimalNumber, _ b: NSDecimalNumber) -> Bool {
        let halfCent = NSDecimalNumber(string: "0.005")
        let difference = a.subtracting(b)
        let magnitude = difference.compare(NSDecimalNumber.zero) == .orderedAscending
            ? difference.multiplying(by: NSDecimalNumber(value: -1))
            : difference
        return magnitude.compare(halfCent) != ComparisonResult.orderedDescending
    }
}

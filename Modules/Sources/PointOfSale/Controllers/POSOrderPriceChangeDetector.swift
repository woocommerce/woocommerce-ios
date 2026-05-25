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
        // `Decimal(string:)` returns nil for empty/invalid input. `NSDecimalNumber(string:)`
        // returns `.notANumber`, which raises on subsequent arithmetic — the source of
        // the production overflow crash this helper has hit.
        guard let priceString,
              let decimal = Decimal(string: priceString) else { return nil }
        return NSDecimalNumber(decimal: decimal)
    }

    func priceMatches(_ cartUnitPrice: NSDecimalNumber, orderItem: OrderItem) -> Bool {
        let expectedLineTotal = cartUnitPrice.multiplying(by: NSDecimalNumber(decimal: orderItem.quantity))
        // If the order's subtotal can't be parsed there's nothing to compare against —
        // trust the server and don't flag a price change so we don't block checkout.
        guard let subtotalDecimal = Decimal(string: orderItem.subtotal) else { return true }
        let exTaxSubtotal = NSDecimalNumber(decimal: subtotalDecimal)
        // `subtotalTax` is empty for tax-exempt items, fees, or zero-tax jurisdictions.
        // Treat unparseable / empty as zero rather than letting `.notANumber` propagate
        // and raise on the `.adding(...)` below.
        let taxDecimal = Decimal(string: orderItem.subtotalTax) ?? 0
        let taxInclusiveSubtotal = exTaxSubtotal.adding(NSDecimalNumber(decimal: taxDecimal))

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

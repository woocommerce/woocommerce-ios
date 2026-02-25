import Foundation
import Storage

// MARK: - Storage.BookingOrderLineItem: ReadOnlyConvertible
//
extension Storage.BookingOrderLineItem: ReadOnlyConvertible {
    public func update(with lineItem: Yosemite.BookingOrderLineItem) {
        itemID = lineItem.itemID
        name = lineItem.name
        productID = lineItem.productID
        variationID = lineItem.variationID
        quantity = lineItem.quantity as NSDecimalNumber
        price = lineItem.price
        subtotal = lineItem.subtotal
        total = lineItem.total
        totalTax = lineItem.totalTax
        imageSrc = lineItem.imageSrc
    }

    public func toReadOnly() -> Yosemite.BookingOrderLineItem {
        return .init(itemID: itemID,
                     name: name ?? "",
                     productID: productID,
                     variationID: variationID,
                     quantity: quantity as? Decimal ?? 0,
                     price: price ?? NSDecimalNumber.zero,
                     subtotal: subtotal ?? "",
                     total: total ?? "",
                     totalTax: totalTax ?? "",
                     imageSrc: imageSrc)
    }
}

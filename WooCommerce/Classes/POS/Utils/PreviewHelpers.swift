import Foundation
import class Yosemite.POSProductProvider
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSItem
import struct Yosemite.POSProduct

#if DEBUG
// MARK: - PreviewProvider helpers
//
final class POSItemProviderPreview: POSItemProvider {
    public func providePointOfSaleItems() -> [POSItem] {
        return [
            POSProduct(itemID: UUID(), productID: 1, name: "Product 1", price: "$1.00"),
            POSProduct(itemID: UUID(), productID: 2, name: "Product 2", price: "$2.00"),
            POSProduct(itemID: UUID(), productID: 3, name: "Product 3", price: "$3.00"),
            POSProduct(itemID: UUID(), productID: 4, name: "Product 4", price: "$4.00")
        ]
    }

    public func providePointOfSaleItem() -> POSItem {
        POSProduct(itemID: UUID(),
                   productID: 1,
                   name: "Product 1",
                   price: "$1.00")
    }
}
#endif

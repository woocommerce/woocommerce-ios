import Foundation

/// Temporary fake product factory
///
final class POSProductFactory {
    static func makeProduct() -> POSProduct {
        POSProduct(itemID: UUID(),
                   productID: 1,
                   name: "Product 1",
                   price: "$1.00",
                   stockQuantity: 10)
    }

    static func makeFakeProducts() -> [POSProduct] {
        return [
            POSProduct(itemID: UUID(), productID: 1, name: "Product 1", price: "$1.00", stockQuantity: 10),
            POSProduct(itemID: UUID(), productID: 2, name: "Product 2", price: "$2.00", stockQuantity: 10),
            POSProduct(itemID: UUID(), productID: 3, name: "Product 3", price: "$3.00", stockQuantity: 10),
            POSProduct(itemID: UUID(), productID: 4, name: "Product 4", price: "$4.00", stockQuantity: 0),
            ]
    }
}

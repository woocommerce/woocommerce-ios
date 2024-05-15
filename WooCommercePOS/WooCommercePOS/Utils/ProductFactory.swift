/// Temporary fake product factory
///
final class ProductFactory {
    static func makeFakeProducts() -> [Product] {
        return [
            Product(itemID: UUID(), productID: 1, name: "Product 1", price: "2"),
            Product(itemID: UUID(), productID: 2, name: "Product 2", price: "2"),
            Product(itemID: UUID(), productID: 3, name: "Product 3", price: "2"),
            Product(itemID: UUID(), productID: 4, name: "Product 4", price: "2"),
            ]
    }
}

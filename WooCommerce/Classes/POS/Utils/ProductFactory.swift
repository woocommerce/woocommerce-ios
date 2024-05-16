/// Temporary fake product factory
///
final class ProductFactory {
    static func makeProduct() -> Product {
        Product(itemID: UUID(), productID: 1, name: "Product 1", price: "$1.00")
    }

    static func makeFakeProducts() -> [Product] {
        return [
            Product(itemID: UUID(), productID: 1, name: "Product 1", price: "$1.00"),
            Product(itemID: UUID(), productID: 2, name: "Product 2", price: "$2.00"),
            Product(itemID: UUID(), productID: 3, name: "Product 3", price: "$3.00"),
            Product(itemID: UUID(), productID: 4, name: "Product 4", price: "$4.00"),
            ]
    }
}

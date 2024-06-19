import Foundation
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSItem
import enum Yosemite.ProductType

#if DEBUG
// MARK: - PreviewProvider helpers
//
struct POSProductPreview: POSItem {
    let itemID: UUID
    let productID: Int64
    let name: String
    let price: String
    let itemCategories: [String]
    var productImageSource: String?
    let productType: ProductType
}

final class POSItemProviderPreview: POSItemProvider {
    func providePointOfSaleItems() -> [POSItem] {
        return [
            POSProductPreview(itemID: UUID(), productID: 1, name: "Product 1", price: "$1.00", itemCategories: [], productType: ProductType.simple),
            POSProductPreview(itemID: UUID(), productID: 2, name: "Product 2", price: "$2.00", itemCategories: [], productType: ProductType.simple),
            POSProductPreview(itemID: UUID(), productID: 3, name: "Product 3", price: "$3.00", itemCategories: [], productType: ProductType.simple),
            POSProductPreview(itemID: UUID(), productID: 4, name: "Product 4", price: "$4.00", itemCategories: [], productType: ProductType.simple)
        ]
    }

    func providePointOfSaleItem() -> POSItem {
        POSProductPreview(itemID: UUID(),
                          productID: 1,
                          name: "Product 1",
                          price: "$1.00",
                          itemCategories: [],
                          productType: ProductType.simple)
    }
}
#endif

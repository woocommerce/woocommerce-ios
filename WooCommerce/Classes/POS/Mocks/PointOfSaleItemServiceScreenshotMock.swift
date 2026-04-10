import Foundation
import Yosemite

final class PointOfSaleItemServiceScreenshotMock: Yosemite.PointOfSaleItemServiceProtocol {

    func providePointOfSaleItems(pageNumber: Int,
                                 fetchStrategy: Yosemite.PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<Yosemite.POSItem> {
        let port = UserDefaults.standard.integer(forKey: "mocks-port")
        let mockResourceUrlHost = "http://localhost:\(port)/"

        let mockItems = Self.makeScreenshotMockItems(mockResourceUrlHost: mockResourceUrlHost)

        return PagedItems(items: mockItems, hasMorePages: false, totalItems: mockItems.count)
    }

    func providePointOfSaleVariationItems(for parentProduct: Yosemite.POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: Yosemite.PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<Yosemite.POSItem> {
        // Not needed for screenshot tests, return empty
        return PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    private static func makeScreenshotMockItems(mockResourceUrlHost: String) -> [Yosemite.POSItem] {
        let product1 = Yosemite.POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Rose Gold Shades",
            formattedPrice: "$35.00",
            productImageSource: mockResourceUrlHost + "rose-gold-shades",
            productID: 1,
            price: "35.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        let product2 = Yosemite.POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 2),
            name: "Black Coral Shades",
            formattedPrice: "$45.00",
            productImageSource: mockResourceUrlHost + "black-coral-shades",
            productID: 2,
            price: "45.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        let product3 = Yosemite.POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 3),
            name: "Akoya Pearl Shades",
            formattedPrice: "$50.00",
            productImageSource: mockResourceUrlHost + "akoya-pearl-shades",
            productID: 3,
            price: "50.00",
            manageStock: true,
            stockQuantity: 10,
            stockStatusKey: "instock"
        )

        let product4 = Yosemite.POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 4),
            name: "Malaya Shades",
            formattedPrice: "$40.00",
            productImageSource: mockResourceUrlHost + "malaya-shades",
            productID: 4,
            price: "40.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        return [
            .simpleProduct(product1),
            .simpleProduct(product2),
            .simpleProduct(product3),
            .simpleProduct(product4)
        ]
    }
}

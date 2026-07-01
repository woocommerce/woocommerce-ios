#if DEBUG

import Foundation
import Yosemite

final class PointOfSaleItemServiceUITestMock: Yosemite.PointOfSaleItemServiceProtocol {
    static let simpleProductID: Int64 = 1
    static let variableParentProductID: Int64 = 4
    static let variationID: Int64 = 401

    func providePointOfSaleItems(pageNumber: Int,
                                 fetchStrategy: Yosemite.PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<Yosemite.POSItem> {
        let mockItems = [
            Yosemite.POSItem.simpleProduct(Self.simpleProduct),
            Yosemite.POSItem.variableParentProduct(Self.variableParentProduct)
        ]

        return PagedItems(items: mockItems, hasMorePages: false, totalItems: mockItems.count)
    }

    func providePointOfSaleVariationItems(for parentProduct: Yosemite.POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: Yosemite.PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<Yosemite.POSItem> {
        guard parentProduct.productID == Self.variableParentProductID else {
            return PagedItems(items: [], hasMorePages: false, totalItems: 0)
        }

        return PagedItems(items: [.variation(Self.variation)], hasMorePages: false, totalItems: 1)
    }
}

private extension PointOfSaleItemServiceUITestMock {
    static var simpleProduct: Yosemite.POSSimpleProduct {
        Yosemite.POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: simpleProductID),
            name: "Rose Gold Shades",
            formattedPrice: "$35.00",
            productImageSource: nil,
            productID: simpleProductID,
            price: "35.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
    }

    static var variableParentProduct: Yosemite.POSVariableParentProduct {
        Yosemite.POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: variableParentProductID),
            name: "Malaya Shades",
            productImageSource: nil,
            productID: variableParentProductID
        )
    }

    static var variation: Yosemite.POSVariation {
        Yosemite.POSVariation(
            id: POSItemIdentifier(underlyingType: .variation, itemID: variationID),
            name: "Polarized / Large",
            formattedPrice: "$45.00",
            price: "45.00",
            productID: variableParentProductID,
            variationID: variationID,
            parentProductName: variableParentProduct.name
        )
    }
}

#endif

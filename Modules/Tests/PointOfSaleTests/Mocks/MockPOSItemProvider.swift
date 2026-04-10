import Foundation
@testable import Yosemite
import struct Networking.PagedItems

final class MockPointOfSaleItemService: PointOfSaleItemServiceProtocol {
    /// An array of pages of items, returned when other flags are not set.
    var itemPages: [[POSItem]] = []
    var errorToThrow: Error?
    var shouldReturnZeroItems = false
    var shouldSimulateTwoPages = false
    var shouldSimulateMorePages = false

    var spyLastRequestedPageNumber: Int?
    var spyItemsFetchStrategy: PointOfSalePurchasableItemFetchStrategy?
    func providePointOfSaleItems(pageNumber: Int, fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        spyLastRequestedPageNumber = pageNumber
        spyItemsFetchStrategy = fetchStrategy
        if let errorToThrow {
            throw errorToThrow
        }
        if shouldReturnZeroItems {
            return .init(items: [], hasMorePages: false, totalItems: 0)
        }
        if shouldSimulateTwoPages {
            return pageNumber > 1 ?
                .init(items: MockPointOfSaleItemService.makeSecondPageItems(), hasMorePages: shouldSimulateMorePages, totalItems: 4):
                .init(items: MockPointOfSaleItemService.makeInitialItems(), hasMorePages: shouldSimulateTwoPages, totalItems: 4)
        }
        return .init(items: (itemPages[safe: pageNumber - 1] ?? []), hasMorePages: itemPages.count > pageNumber, totalItems: 2)
    }

    var shouldSimulateTwoPagesOfVariations = false
    var shouldSimulateMorePagesOfVariations = false
    var spyVariationsFetchStrategy: PointOfSalePurchasableItemFetchStrategy?
    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        spyVariationsFetchStrategy = fetchStrategy
        if let errorToThrow {
            throw errorToThrow
        }
        if shouldSimulateTwoPagesOfVariations,
           pageNumber > 1 {
            return .init(items: MockPointOfSaleItemService.makeSecondPageVariationItems(), hasMorePages: shouldSimulateMorePagesOfVariations, totalItems: 4)
        }

        return .init(items: MockPointOfSaleItemService.makeInitialVariationItems(), hasMorePages: shouldSimulateTwoPagesOfVariations, totalItems: 2)
    }
}

extension MockPointOfSaleItemService {
    static func makeInitialItems() -> [POSItem] {
        let product1 = POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                        name: "Choco",
                                        formattedPrice: "$2.00",
                                        productID: 1,
                                        price: "2.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")

        let product2 = POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 2),
                                        name: "Vanilla",
                                        formattedPrice: "$3.00",
                                        productID: 2,
                                        price: "3.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")
        return [.simpleProduct(product1), .simpleProduct(product2)]
    }

    static func makeSecondPageItems() -> [POSItem] {
        let product3 = POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 3),
                                        name: "Strawberry",
                                        formattedPrice: "$2.00",
                                        productID: 3,
                                        price: "2.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")

        let product4 = POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 4),
                                        name: "Pistachio",
                                        formattedPrice: "$3.00",
                                        productID: 4,
                                        price: "3.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")
        return [.simpleProduct(product3), .simpleProduct(product4)]
    }

    static func makeInitialVariationItems() -> [POSItem] {
        let variation1 = POSVariation(id: POSItemIdentifier(underlyingType: .variation, itemID: 1),
                                      name: "Choco",
                                      formattedPrice: "$2.00",
                                      price: "2.00",
                                      productID: 1,
                                      variationID: 1,
                                      parentProductName: "Ice cream")

        let variation2 = POSVariation(id: POSItemIdentifier(underlyingType: .variation, itemID: 2),
                                      name: "Vanilla",
                                      formattedPrice: "$2.00",
                                      price: "2.00",
                                      productID: 1,
                                      variationID: 2,
                                      parentProductName: "Ice cream")
        return [.variation(variation1), .variation(variation2)]
    }

    static func makeSecondPageVariationItems() -> [POSItem] {
        let variation3 = POSVariation(id: POSItemIdentifier(underlyingType: .variation, itemID: 3),
                                      name: "Strawberry",
                                      formattedPrice: "$2.00",
                                      price: "2.00",
                                      productID: 1,
                                      variationID: 3,
                                      parentProductName: "Ice cream")

        let variation4 = POSVariation(id: POSItemIdentifier(underlyingType: .variation, itemID: 4),
                                      name: "Pistachio",
                                      formattedPrice: "$3.00",
                                      price: "3.00",
                                      productID: 1,
                                      variationID: 4,
                                      parentProductName: "Ice cream")
        return [.variation(variation3), .variation(variation4)]
    }
}

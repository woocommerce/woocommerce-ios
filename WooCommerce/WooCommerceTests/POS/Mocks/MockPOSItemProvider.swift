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
        let fakeUUID1 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E84E") ?? UUID()
        let fakeUUID2 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E84A") ?? UUID()

        let product1 = POSSimpleProduct(id: fakeUUID1,
                                        name: "Choco",
                                        formattedPrice: "$2.00",
                                        productID: 1,
                                        price: "2.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")

        let product2 = POSSimpleProduct(id: fakeUUID2,
                                        name: "Vanilla",
                                        formattedPrice: "$3.00",
                                        productID: 1,
                                        price: "2.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")
        return [.simpleProduct(product1), .simpleProduct(product2)]
    }

    static func makeSecondPageItems() -> [POSItem] {
        let fakeUUID3 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E86D") ?? UUID()
        let fakeUUID4 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E86F") ?? UUID()

        let product3 = POSSimpleProduct(id: fakeUUID3,
                                        name: "Strawberry",
                                        formattedPrice: "$2.00",
                                        productID: 1,
                                        price: "2.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")

        let product4 = POSSimpleProduct(id: fakeUUID4,
                                        name: "Pistachio",
                                        formattedPrice: "$3.00",
                                        productID: 1,
                                        price: "2.00",
                                        manageStock: false,
                                        stockQuantity: nil,
                                        stockStatusKey: "")
        return [.simpleProduct(product3), .simpleProduct(product4)]
    }

    static func makeInitialVariationItems() -> [POSItem] {
        let fakeUUID1 = UUID(uuidString: "B04AF636-CF6C-11EF-A45C-FA719FB6C0F0") ?? UUID()
        let fakeUUID2 = UUID(uuidString: "B04AF727-CF6C-11EF-A45C-FA719FB6C0F0") ?? UUID()

        let variation1 = POSVariation(id: fakeUUID1,
                                      name: "Choco",
                                      formattedPrice: "$2.00",
                                      price: "2.00",
                                      productID: 1,
                                      variationID: 1,
                                      parentProductName: "Ice cream")

        let variation2 = POSVariation(id: fakeUUID2,
                                      name: "Vanilla",
                                      formattedPrice: "$2.00",
                                      price: "2.00",
                                      productID: 1,
                                      variationID: 2,
                                      parentProductName: "Ice cream")
        return [.variation(variation1), .variation(variation2)]
    }

    static func makeSecondPageVariationItems() -> [POSItem] {
        let fakeUUID3 = UUID(uuidString: "B04AF758-CF6C-11EF-A45C-FA719FB6C0F0") ?? UUID()
        let fakeUUID4 = UUID(uuidString: "B04AF78A-CF6C-11EF-A45C-FA719FB6C0F0") ?? UUID()

        let variation3 = POSVariation(id: fakeUUID3,
                                      name: "Strawberry",
                                      formattedPrice: "$2.00",
                                      price: "2.00",
                                      productID: 1,
                                      variationID: 3,
                                      parentProductName: "Ice cream")

        let variation4 = POSVariation(id: fakeUUID4,
                                      name: "Pistachio",
                                      formattedPrice: "$3.00",
                                      price: "2.00",
                                      productID: 1,
                                      variationID: 4,
                                      parentProductName: "Ice cream")
        return [.variation(variation3), .variation(variation4)]
    }
}

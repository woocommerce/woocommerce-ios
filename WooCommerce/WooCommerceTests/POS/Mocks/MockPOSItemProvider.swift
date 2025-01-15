import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
@testable import struct Yosemite.POSSimpleProduct
@testable import struct Yosemite.POSVariation
import struct Yosemite.PagedItems
import struct Yosemite.POSVariableParentProduct

final class MockPointOfSaleItemService: PointOfSaleItemServiceProtocol {
    var items: [POSItem] = []
    var shouldThrowError = false
    var shouldReturnZeroItems = false
    var shouldSimulateTwoPages = false
    var shouldSimulateMorePages = false

    var spyLastRequestedPageNumber: Int?
    func providePointOfSaleItems(pageNumber: Int) async throws -> PagedItems<POSItem> {
        spyLastRequestedPageNumber = pageNumber
        if shouldThrowError {
            throw MockError.requestFailed
        }
        if shouldReturnZeroItems {
            return .init(items: [], hasMorePages: false)
        }
        if shouldSimulateTwoPages,
            pageNumber > 1 {
            return .init(items: MockPointOfSaleItemService.makeSecondPageItems(), hasMorePages: shouldSimulateMorePages)
        }
        return .init(items: MockPointOfSaleItemService.makeInitialItems(), hasMorePages: shouldSimulateTwoPages)
    }

    var shouldSimulateTwoPagesOfVariations = false
    var shouldSimulateMorePagesOfVariations = false
    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        if shouldThrowError {
            throw MockError.requestFailed
        }
        if shouldSimulateTwoPagesOfVariations,
           pageNumber > 1 {
            return .init(items: MockPointOfSaleItemService.makeSecondPageVariationItems(), hasMorePages: shouldSimulateMorePagesOfVariations)
        }

        return .init(items: MockPointOfSaleItemService.makeInitialVariationItems(), hasMorePages: shouldSimulateTwoPagesOfVariations)
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
                                        price: "2.00")

        let product2 = POSSimpleProduct(id: fakeUUID2,
                                        name: "Vanilla",
                                        formattedPrice: "$3.00",
                                        productID: 1,
                                        price: "2.00")
        return [.simpleProduct(product1), .simpleProduct(product2)]
    }

    static func makeSecondPageItems() -> [POSItem] {
        let fakeUUID3 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E86D") ?? UUID()
        let fakeUUID4 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E86F") ?? UUID()

        let product3 = POSSimpleProduct(id: fakeUUID3,
                                        name: "Strawberry",
                                        formattedPrice: "$2.00",
                                        productID: 1,
                                        price: "2.00")

        let product4 = POSSimpleProduct(id: fakeUUID4,
                                        name: "Pistachio",
                                        formattedPrice: "$3.00",
                                        productID: 1,
                                        price: "2.00")
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

    enum MockError: Error {
        case requestFailed
    }
}

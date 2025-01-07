import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
@testable import struct Yosemite.POSSimpleProduct
import struct Yosemite.PagedItems
import struct Yosemite.POSParentProduct

final class MockPointOfSaleItemService: PointOfSaleItemServiceProtocol {
    var items: [POSItem] = []
    var shouldThrowError = false
    var shouldReturnZeroItems = false
    var shouldSimulateTwoPages = false

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
            return .init(items: MockPointOfSaleItemService.makeSecondPageItems(), hasMorePages: false)
        }
        return .init(items: MockPointOfSaleItemService.makeInitialItems(), hasMorePages: shouldSimulateTwoPages)
    }

    func providePointOfSaleVariationItems(for parentProduct: POSParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        .init(items: [], hasMorePages: false)
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

    enum MockError: Error {
        case requestFailed
    }
}

import Foundation
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

final class MockPOSItemProvider: POSItemProvider {
    var items: [POSItem] = []
    var shouldThrowError = false
    var shouldReturnZeroItems = false
    var shouldSimulateTwoPages = false
    private var isPageOutOfRange = false

    var spyLastRequestedPageNumber: Int?
    func providePointOfSaleItems(pageNumber: Int) async throws -> [Yosemite.POSItem] {
        if isPageOutOfRange {
            throw MockError.pageOutOfRange
        }
        spyLastRequestedPageNumber = pageNumber
        if shouldThrowError {
            throw MockError.requestFailed
        }
        if shouldReturnZeroItems {
            return []
        }
        if shouldSimulateTwoPages,
            pageNumber > 1 {
            simulateFetchNextPage()
            return items
        }
        return MockPOSItemProvider.makeInitialItems()
    }

    func simulateFetchNextPage() {
        items.append(contentsOf: MockPOSItemProvider.makeSecondPageItems())
    }

    func simulateNextPageIsOutOfRange() {
        isPageOutOfRange = true
    }
}

extension MockPOSItemProvider {
    static func makeInitialItems() -> [POSItem] {
        let fakeUUID1 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E84E") ?? UUID()
        let fakeUUID2 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E84A") ?? UUID()

        let product1 = POSProduct(itemID: fakeUUID1,
                                  productID: 0,
                                  name: "Choco",
                                  price: "2",
                                  formattedPrice: "$2.00",
                                  itemCategories: [],
                                  productImageSource: nil,
                                  productType: .simple)

        let product2 = POSProduct(itemID: fakeUUID2,
                                  productID: 1,
                                  name: "Vanilla",
                                  price: "3",
                                  formattedPrice: "$3.00",
                                  itemCategories: [],
                                  productImageSource: nil,
                                  productType: .simple)
        return [product1, product2]
    }

    static func makeSecondPageItems() -> [POSItem] {
        let fakeUUID3 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E86D") ?? UUID()
        let fakeUUID4 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E86F") ?? UUID()

        let product3 = POSProduct(itemID: fakeUUID3,
                                  productID: 2,
                                  name: "Strawberry",
                                  price: "2",
                                  formattedPrice: "$2.00",
                                  itemCategories: [],
                                  productImageSource: nil,
                                  productType: .simple)

        let product4 = POSProduct(itemID: fakeUUID4,
                                  productID: 4,
                                  name: "Pistachio",
                                  price: "3",
                                  formattedPrice: "$3.00",
                                  itemCategories: [],
                                  productImageSource: nil,
                                  productType: .simple)
        return [product3, product4]
    }

    enum MockError: Error {
        case requestFailed
        case pageOutOfRange
    }
}

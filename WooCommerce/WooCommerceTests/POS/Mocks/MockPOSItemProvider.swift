import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.POSDisplayableItem
@testable import struct Yosemite.POSProduct

final class MockPointOfSaleItemService: PointOfSaleItemServiceProtocol {
    var items: [any POSDisplayableItem] = []
    var shouldThrowError = false
    var shouldReturnZeroItems = false
    var shouldSimulateTwoPages = false
    private var isPageOutOfRange = false

    var spyLastRequestedPageNumber: Int?
    func providePointOfSaleItems(pageNumber: Int) async throws -> [any POSDisplayableItem] {
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
        return MockPointOfSaleItemService.makeInitialItems()
    }

    func simulateFetchNextPage() {
        items.append(contentsOf: MockPointOfSaleItemService.makeSecondPageItems())
    }

    func simulateNextPageIsOutOfRange() {
        isPageOutOfRange = true
    }
}

extension MockPointOfSaleItemService {
    static func makeInitialItems() -> [any POSDisplayableItem] {
        let fakeUUID1 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E84E") ?? UUID()
        let fakeUUID2 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E84A") ?? UUID()

        let product1 = MockPOSItem(name: "Choco",
                                   id: fakeUUID1,
                                   formattedPrice: "$2.00",
                                   productImageSource: nil)

        let product2 = MockPOSItem(name: "Vanilla",
                                   id: fakeUUID2,
                                   formattedPrice: "$3.00",
                                   productImageSource: nil)
        return [product1, product2]
    }

    static func makeSecondPageItems() -> [any POSDisplayableItem] {
        let fakeUUID3 = UUID(uuidString: "DC55E3B9-9D83-4C07-82A7-4C300A50E86D") ?? UUID()
        let fakeUUID4 = UUID(uuidString: "DC55E3B8-9D82-4C06-82A5-4C300A50E86F") ?? UUID()

        let product3 = MockPOSItem(name: "Strawberry",
                                   id: fakeUUID3,
                                   formattedPrice: "$2.00",
                                   productImageSource: nil)

        let product4 = MockPOSItem(name: "Pistachio",
                                   id: fakeUUID4,
                                   formattedPrice: "$3.00",
                                   productImageSource: nil)
        return [product3, product4]
    }

    enum MockError: Error {
        case requestFailed
        case pageOutOfRange
    }
}

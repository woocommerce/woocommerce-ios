import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// ProductStore Unit Tests with different sort orders
///
final class ProductStore_ProductsSortOrderTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 75

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - ProductAction.synchronizeProducts

    func testSynchronizingProductsWithAscendingNameSortOrder() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { [weak self] error in
                                                        guard let self = self else {
                                                            XCTFail()
                                                            return
                                                        }
                                                        self.assertSortOrderParamValues(orderByValue: "title", orderValue: "asc")

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testSynchronizingProductsWithDescendingNameSortOrder() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameDescending) { [weak self] error in
                                                        guard let self = self else {
                                                            XCTFail()
                                                            return
                                                        }
                                                        self.assertSortOrderParamValues(orderByValue: "title", orderValue: "desc")

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testSynchronizingProductsWithAscendingDateSortOrder() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .dateAscending) { [weak self] error in
                                                        guard let self = self else {
                                                            XCTFail()
                                                            return
                                                        }
                                                        self.assertSortOrderParamValues(orderByValue: "date", orderValue: "asc")

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testSynchronizingProductsWithDescendingDateSortOrder() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .dateDescending) { [weak self] error in
                                                        guard let self = self else {
                                                            XCTFail()
                                                            return
                                                        }
                                                        self.assertSortOrderParamValues(orderByValue: "date", orderValue: "desc")

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

private extension ProductStore_ProductsSortOrderTests {
    func assertSortOrderParamValues(orderByValue: String, orderValue: String) {
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let expectedOrderbyParam = "orderby=\(orderByValue)"
        XCTAssertTrue(queryParameters.contains(expectedOrderbyParam), "Expected to have param: \(expectedOrderbyParam)")

        let expectedOrderParam = "order=\(orderValue)"
        XCTAssertTrue(queryParameters.contains(expectedOrderParam), "Expected to have param: \(expectedOrderParam)")
    }
}

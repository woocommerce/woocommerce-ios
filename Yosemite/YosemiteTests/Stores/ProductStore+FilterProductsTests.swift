import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

/// ProductStore Unit Tests with products filtering
///
final class ProductStore_FilterProductsTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

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
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        super.tearDown()
    }

    // MARK: - ProductAction.synchronizeProducts

    func testSynchronizingProductsWithoutFilters() {
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
                                                        self.assertParamValues(stockStatusValue: nil,
                                                                               productStatusValue: nil,
                                                                               productTypeValue: nil)

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testSynchronizingProductsWithOnlyStockStatusFilter() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: .inStock,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { [weak self] error in
                                                        guard let self = self else {
                                                            XCTFail()
                                                            return
                                                        }
                                                        self.assertParamValues(stockStatusValue: ProductStockStatus.inStock.rawValue,
                                                                               productStatusValue: nil,
                                                                               productTypeValue: nil)

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testSynchronizingProductsWithOnlyProductStatusFilter() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: .draft,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { [weak self] error in
                                                        guard let self = self else {
                                                            XCTFail()
                                                            return
                                                        }
                                                        self.assertParamValues(stockStatusValue: nil,
                                                                               productStatusValue: ProductStatus.draft.rawValue,
                                                                               productTypeValue: nil)

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testSynchronizingProductsWithOnlyProductTypeFilter() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: .variable,
                                                       sortOrder: .nameAscending) { [weak self] error in
                                                        guard let self = self else {
                                                            XCTFail()
                                                            return
                                                        }
                                                        self.assertParamValues(stockStatusValue: nil,
                                                                               productStatusValue: nil,
                                                                               productTypeValue: ProductType.variable.rawValue)

                                                        expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

private extension ProductStore_FilterProductsTests {
    func assertParamValues(stockStatusValue: String?, productStatusValue: String?, productTypeValue: String?) {
        guard let pathComponents = network.pathComponents else {
            XCTFail("Cannot parse path from the API request")
            return
        }

        let stockStatusParameter = "stock_status"
        if let stockStatusValue = stockStatusValue {
            let expectedParam = "\(stockStatusParameter)=\(stockStatusValue)"
            XCTAssertTrue(pathComponents.contains(expectedParam), "Expected to have param: \(expectedParam)")
        } else {
            XCTAssertFalse(pathComponents.contains(where: { $0.starts(with: stockStatusParameter) }))
        }

        let productStatusParameter = "status"
        if let productStatusValue = productStatusValue {
            let expectedParam = "\(productStatusParameter)=\(productStatusValue)"
            XCTAssertTrue(pathComponents.contains(expectedParam), "Expected to have param: \(expectedParam)")
        } else {
            XCTAssertFalse(pathComponents.contains(where: { $0.starts(with: productStatusParameter) }))
        }

        let productTypeParameter = "type"
        if let productTypeValue = productTypeValue {
            let expectedParam = "\(productTypeParameter)=\(productTypeValue)"
            XCTAssertTrue(pathComponents.contains(expectedParam), "Expected to have param: \(expectedParam)")
        } else {
            XCTAssertFalse(pathComponents.contains(where: { $0.starts(with: productTypeParameter) }))
        }
    }
}

import XCTest
import TestKit
@testable import Yosemite
@testable import Networking
@testable import Storage

/// ProductStore Unit Tests with products filtering
///
final class ProductStore_FilterProductsTests: XCTestCase {

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

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        super.tearDown()
    }

    // MARK: - ProductAction.synchronizeProducts

    func test_synchronizeProducts_when_filters_are_off_then_it_does_not_send_filter_params() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let _: Bool = waitFor { [weak self] promise in
            guard let self = self else {
                XCTFail()
                return
            }

            let action = ProductAction.synchronizeProducts(siteID: self.sampleSiteID,
                                                           pageNumber: self.defaultPageNumber,
                                                           pageSize: self.defaultPageSize,
                                                           stockStatus: nil,
                                                           productStatus: nil,
                                                           productType: nil,
                                                           productCategory: nil,
                                                           sortOrder: .nameAscending) { _ in
                promise(true)
            }

            productStore.onAction(action)
        }

        self.assertParamValues(stockStatusValue: nil,
                               productStatusValue: nil,
                               productTypeValue: nil,
                               productCategoryValue: nil)
    }

    func test_synchronizeProducts_with_only_stock_status_filter_then_it_sends_stocks_status_filter_param() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let _: Bool = waitFor { [weak self] promise in
            guard let self = self else {
                XCTFail()
                return
            }

            let action = ProductAction.synchronizeProducts(siteID: self.sampleSiteID,
                                                           pageNumber: self.defaultPageNumber,
                                                           pageSize: self.defaultPageSize,
                                                           stockStatus: .inStock,
                                                           productStatus: nil,
                                                           productType: nil,
                                                           productCategory: nil,
                                                           sortOrder: .nameAscending) { _ in
                promise(true)
            }

            productStore.onAction(action)
        }

        self.assertParamValues(stockStatusValue: ProductStockStatus.inStock.rawValue,
                               productStatusValue: nil,
                               productTypeValue: nil,
                               productCategoryValue: nil)
    }

    func test_synchronizeProducts_with_only_product_status_filter_then_it_sends_product_status_filter_param() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let _: Bool = waitFor { [weak self] promise in
            guard let self = self else {
                XCTFail()
                return
            }

            let action = ProductAction.synchronizeProducts(siteID: self.sampleSiteID,
                                                           pageNumber: self.defaultPageNumber,
                                                           pageSize: self.defaultPageSize,
                                                           stockStatus: nil,
                                                           productStatus: .draft,
                                                           productType: nil,
                                                           productCategory: nil,
                                                           sortOrder: .nameAscending) { _ in
                promise(true)
            }

            productStore.onAction(action)
        }

        self.assertParamValues(stockStatusValue: nil,
                               productStatusValue: ProductStatus.draft.rawValue,
                               productTypeValue: nil,
                               productCategoryValue: nil)
    }

    func test_synchronizeProducts_with_only_product_type_filter_then_it_sends_product_type_filter_param() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let _: Bool = waitFor { [weak self] promise in
            guard let self = self else {
                XCTFail()
                return
            }

            let action = ProductAction.synchronizeProducts(siteID: self.sampleSiteID,
                                                           pageNumber: self.defaultPageNumber,
                                                           pageSize: self.defaultPageSize,
                                                           stockStatus: nil,
                                                           productStatus: nil,
                                                           productType: .variable,
                                                           productCategory: nil,
                                                           sortOrder: .nameAscending) { _ in
                                                            promise(true)
            }

            productStore.onAction(action)

        }

        self.assertParamValues(stockStatusValue: nil,
                               productStatusValue: nil,
                               productTypeValue: ProductType.variable.rawValue,
                               productCategoryValue: nil)
    }

    func test_synchronizeProducts_with_only_product_category_filter_then_it_sends_product_category_filter_param() {
        let filterProductCategory = ProductCategory(categoryID: 213, siteID: 0, parentID: 0, name: "", slug: "")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let _: Bool = waitFor { [weak self] promise in
            guard let self = self else {
                XCTFail()
                return
            }

            let action = ProductAction.synchronizeProducts(siteID: self.sampleSiteID,
                                                           pageNumber: self.defaultPageNumber,
                                                           pageSize: self.defaultPageSize,
                                                           stockStatus: nil,
                                                           productStatus: nil,
                                                           productType: nil,
                                                           productCategory: filterProductCategory,
                                                           sortOrder: .nameAscending) { _ in
                                                            promise(true)
            }

            productStore.onAction(action)

        }

        self.assertParamValues(stockStatusValue: nil,
                               productStatusValue: nil,
                               productTypeValue: nil,
                               productCategoryValue: String(filterProductCategory.categoryID))
    }

    func test_synchronizeProducts_with_non_core_product_type_network_error_then_it_returns_success_without_next_page() throws {
        // Given
        let remote = MockProductsRemote()
        remote.whenLoadingAllProducts(siteID: sampleSiteID,
                                      thenReturn: .failure(DotcomError.unknown(code: "rest_invalid_param",
                                                                               message: "Invalid parameter(s): type")))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote,
                                        generativeContentRemote: MockGenerativeContentRemote())
        let nonCoreTypes: [ProductType] = [.subscription, .variableSubscription, .bundle, .composite]

        for nonCoreType in nonCoreTypes {
            // When
            let result = waitFor { promise in
                productStore.onAction(ProductAction.synchronizeProducts(siteID: self.sampleSiteID,
                                                                        pageNumber: self.defaultPageNumber,
                                                                        pageSize: self.defaultPageSize,
                                                                        stockStatus: nil,
                                                                        productStatus: nil,
                                                                        productType: nonCoreType,
                                                                        productCategory: nil,
                                                                        sortOrder: .nameAscending) { result in
                    promise(result)
                })
            }

            // Then
            XCTAssertTrue(result.isSuccess)
            let hasNextPage = try XCTUnwrap(result.get())
            XCTAssertFalse(hasNextPage)
        }
    }

    func test_synchronizeProducts_with_core_product_type_network_error_then_it_returns_failure() throws {
        // Given
        let remote = MockProductsRemote()
        remote.whenLoadingAllProducts(siteID: sampleSiteID,
                                      thenReturn: .failure(DotcomError.unknown(code: "rest_invalid_param",
                                                                               message: "Invalid parameter(s): type")))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote,
                                        generativeContentRemote: MockGenerativeContentRemote())
        let coreTypes: [ProductType?] = [nil, .simple, .variable, .grouped, .affiliate]

        for coreType in coreTypes {
            // When
            let result = waitFor { promise in
                productStore.onAction(ProductAction.synchronizeProducts(siteID: self.sampleSiteID,
                                                                        pageNumber: self.defaultPageNumber,
                                                                        pageSize: self.defaultPageSize,
                                                                        stockStatus: nil,
                                                                        productStatus: nil,
                                                                        productType: coreType,
                                                                        productCategory: nil,
                                                                        sortOrder: .nameAscending) { result in
                    promise(result)
                })
            }

            // Then
            XCTAssertTrue(result.isFailure)
            let error = try XCTUnwrap(result.failure)
            XCTAssertEqual(error as? DotcomError, .unknown(code: "rest_invalid_param",
                                                           message: "Invalid parameter(s): type"))
        }
    }
}

private extension ProductStore_FilterProductsTests {
    func assertParamValues(stockStatusValue: String?, productStatusValue: String?, productTypeValue: String?, productCategoryValue: String?) {
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let stockStatusParameter = "stock_status"
        if let stockStatusValue = stockStatusValue {
            let expectedParam = "\(stockStatusParameter)=\(stockStatusValue)"
            XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
        } else {
            XCTAssertFalse(queryParameters.contains(where: { $0.starts(with: stockStatusParameter) }))
        }

        let productStatusParameter = "status"
        if let productStatusValue = productStatusValue {
            let expectedParam = "\(productStatusParameter)=\(productStatusValue)"
            XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
        } else {
            XCTAssertFalse(queryParameters.contains(where: { $0.starts(with: productStatusParameter) }))
        }

        let productTypeParameter = "type"
        if let productTypeValue = productTypeValue {
            let expectedParam = "\(productTypeParameter)=\(productTypeValue)"
            XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
        } else {
            XCTAssertFalse(queryParameters.contains(where: { $0.starts(with: productTypeParameter) }))
        }

        let productCategoryParameter = "category"
        if let productCategoryValue = productCategoryValue {
            let expectedParam = "\(productCategoryParameter)=\(productCategoryValue)"
            XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
        } else {
            XCTAssertFalse(queryParameters.contains(where: { $0.starts(with: productCategoryParameter) }))
        }
    }
}

import XCTest
@testable import Networking

/// ProductCategoriesRemoteTests
///
final class ProductCategoriesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Load all product categories tests

    /// Verifies that loadAllProductCategories properly parses the `categories-all` sample response.
    ///
    func test_loadAllProductCategories_properly_then_it_returns_parsed_product_categories() {
        // Given
        let remote = ProductCategoriesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")

        // When
        let result: (categories: [ProductCategory]?, error: Error?) = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            remote.loadAllProductCategories(for: self.sampleSiteID) { categories, error in
                promise((categories, error))
            }
        }

        // Then
        XCTAssertNil(result.error)
        XCTAssertNotNil(result.categories)
        XCTAssertEqual(result.categories?.count, 2)
    }

    /// Verifies that loadAllProductCategories properly relays Networking Layer errors.
    ///
    func test_loadAllProductCategories_properly_then_it_relays_networking_errors() {
        // Given
        let remote = ProductCategoriesRemote(network: network)

        // When
        let result: (categories: [ProductCategory]?, error: Error?) = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            remote.loadAllProductCategories(for: self.sampleSiteID) { categories, error in
                promise((categories, error))
            }
        }

        // Then
        XCTAssertNil(result.categories)
        XCTAssertNotNil(result.error)
    }

    // MARK: - Create a product category tests

    /// Verifies that createProductCategory properly parses the `category` sample response.
    ///
    func test_createProductCategory_properly_then_it_returns_parsed_product_category() {
        // Given
        let remote = ProductCategoriesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "category")

        // When
        var result: Result<ProductCategory, Error>?
        waitForExpectation { exp in
            remote.createProductCategory(for: sampleSiteID, name: "Dress", parentID: 0) { aResult in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(result?.failure)
        XCTAssertNotNil(try result?.get())
        XCTAssertEqual(try result?.get().name, "Dress")
    }

    /// Verifies that createProductCategory properly relays Networking Layer errors.
    ///
    func test_createProductCategory_properly_then_it_relays_networking_errors() {
        // Given
        let remote = ProductCategoriesRemote(network: network)

        // When
        let result: Result<ProductCategory, Error>? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            remote.createProductCategory(for: self.sampleSiteID, name: "Dress", parentID: 0) { aResult in
                promise(aResult)
            }
        }

        // Then
        XCTAssertNil(try? result?.get())
        XCTAssertNotNil(result?.failure)
    }

    func test_loadProductCategory_then_returns_parsed_ProductCategory() {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let categoryID: Int64 = 44

        network.simulateResponse(requestUrlSuffix: "products/categories/\(categoryID)", filename: "category")

        // When
        let result: Result<ProductCategory, Error>? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            remote.loadProductCategory(with: categoryID, siteID: self.sampleSiteID) {  aResult in
                promise(aResult)
            }
        }

        // Then
        XCTAssertNil(result?.failure)
        XCTAssertNotNil(try result?.get())
        XCTAssertEqual(try result?.get().name, "Dress")
    }

    func test_loadProductCategory_network_fails_then_returns_error() {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let categoryID: Int64 = 44

        // When
        let result: Result<ProductCategory, Error>? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            remote.loadProductCategory(with: categoryID, siteID: self.sampleSiteID) {  aResult in
                promise(aResult)
            }
        }

        // Then
        XCTAssertNil(try? result?.get())
        XCTAssertNotNil(result?.failure)
    }
}

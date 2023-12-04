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

    // MARK: - Batch creation of categories

    func test_createProductCategories_returns_product_categories_on_success() throws {
        // Given
        let remote = ProductCategoriesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "products/categories/batch", filename: "product-categories-created")

        // When
        let result: Result<[ProductCategory], Error> = waitFor { promise in
            remote.createProductCategories(for: self.sampleSiteID, names: ["Headphone"], parentID: 0) { aResult in
                promise(aResult)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let categories = try XCTUnwrap(result.get())
        XCTAssertEqual(categories.first?.name, "Headphone")
    }

    func test_createProductCategories_properly_relays_errors() throws {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "products/categories/batch", error: error)

        // When
        let result: Result<[ProductCategory], Error> = waitFor {promise in
            remote.createProductCategories(for: self.sampleSiteID, names: ["Headphone"], parentID: 0) { aResult in
                promise(aResult)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
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

    // MARK: - Update product category
    func test_updateProductCategory_success_returns_parsed_ProductCategory() async throws {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let category = ProductCategory.fake().copy(categoryID: 44, siteID: 123)

        network.simulateResponse(requestUrlSuffix: "products/categories/\(category.categoryID)", filename: "category")

        // When
        let updatedCategory = try await remote.updateProductCategory(category)

        // Then
        XCTAssertEqual(updatedCategory.name, "Dress")
    }

    func test_updateProductCategory_failure_relays_networking_error() async throws {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let category = ProductCategory.fake().copy(categoryID: 44)

        network.simulateError(requestUrlSuffix: "products/categories/\(category.categoryID)", error: NetworkError.notFound())

        // When
        do {
            _ = try await remote.updateProductCategory(category)
            XCTFail("Request should fail!")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, .notFound())
        }
    }

    // MARK: - Delete product category
    func test_deleteProductCategory_success_does_not_throw_error() async throws {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let categoryID: Int64 = 44
        let siteID: Int64 = 123

        network.simulateResponse(requestUrlSuffix: "products/categories/\(categoryID)", filename: "generic_success_data")

        // Then the following should not throw error:
        try await remote.deleteProductCategory(for: siteID, categoryID: categoryID)
    }

    func test_deleteProductCategory_failure_relays_networking_error() async throws {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let categoryID: Int64 = 44
        let siteID: Int64 = 123

        network.simulateError(requestUrlSuffix: "products/categories/\(categoryID)", error: NetworkError.notFound())

        // When
        do {
            try await remote.deleteProductCategory(for: siteID, categoryID: categoryID)
            XCTFail("Request should fail!")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, .notFound())
        }
    }
}

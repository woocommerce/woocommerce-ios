import XCTest
@testable import Networking

/// ProductCategoriesRemoteTests
///
final class ProductCategoriesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockupNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockupNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Load all product categories tests

    /// Verifies that loadAllProductCategories properly parses the `categories-all` sample response.
    ///
    func testLoadAllProductCategoriesProperlyReturnsParsedProductCategories() {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Categories")

        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")

        // When
        var result: (categories: [ProductCategory]?, error: Error?)
        remote.loadAllProductCategories(for: sampleSiteID) { categories, error in
            result = (categories, error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertNil(result.error)
        XCTAssertNotNil(result.categories)
        XCTAssertEqual(result.categories?.count, 2)
    }

    /// Verifies that loadAllProductCategories properly relays Networking Layer errors.
    ///
    func testLoadAllProductCategoriesProperlyRelaysNetwokingErrors() {
        // Given
        let remote = ProductCategoriesRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Categories returns error")

        // When
        var result: (categories: [ProductCategory]?, error: Error?)
        remote.loadAllProductCategories(for: sampleSiteID) { categories, error in
            result = (categories, error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertNil(result.categories)
        XCTAssertNotNil(result.error)
    }
}

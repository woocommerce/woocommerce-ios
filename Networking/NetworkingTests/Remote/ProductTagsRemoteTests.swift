import XCTest
@testable import Networking

/// ProductTagsRemoteTests
///
final class ProductTagsRemoteTests: XCTestCase {

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

    // MARK: - Load all product tags tests

    /// Verifies that loadAllProductTags properly parses the `product-tags-all` sample response.
    ///
    func testLoadAllProductTagsProperlyReturnsParsedProductTags() {
        // Given
        let remote = ProductTagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-all")

        // When
        var productTags: [ProductTag]?
        var anError: Error?
        waitForExpectation { exp in
            remote.loadAllProductTags(for: sampleSiteID) { (tags, error) in
                productTags = tags
                anError = error
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(anError)
        XCTAssertNotNil(productTags)
        XCTAssertEqual(productTags?.count, 4)
        XCTAssertEqual(productTags?.first?.tagID, 34)
        XCTAssertEqual(productTags?.first?.name, "Leather Shoes")
        XCTAssertEqual(productTags?.first?.slug, "leather-shoes")
    }

    /// Verifies that loadAllProductTags properly relays Networking Layer errors.
    ///
    func testLoadAllProductTagsProperlyRelaysNetwokingErrors() {
        // Given
        let remote = ProductTagsRemote(network: network)

        // When
        var productTags: [ProductTag]?
        var anError: Error?
        waitForExpectation { exp in
            remote.loadAllProductTags(for: sampleSiteID) { (tags, error) in
                productTags = tags
                anError = error
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(productTags)
        XCTAssertNotNil(anError)
    }

    // MARK: - Create product tags tests

    /// Verifies that createProductTags properly parses the `product tag` sample response.
    ///
    func testCreateProductTagsProperlyReturnsParsedProductTags() {
        // Given
        let remote = ProductTagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "product-tags-created")

        // When
        var result: Result<[ProductTag], Error>?
        waitForExpectation { exp in
            remote.createProductTags(for: sampleSiteID, names: ["Round toe", "Flat"]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(result?.failure)
        XCTAssertNotNil(try result?.get())
        XCTAssertEqual(try result?.get().count, 2)
        XCTAssertEqual(try result?.get().first?.name, "Round toe")
    }

    /// Verifies that createProductTags properly relays Networking Layer errors.
    ///
    func testCreateProductTagsProperlyRelaysNetwokingErrors() {
        // Given
        let remote = ProductTagsRemote(network: network)

        // When
        var result: Result<[ProductTag], Error>?
        waitForExpectation { exp in
            remote.createProductTags(for: sampleSiteID, names: ["Leather Shoes"]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(try? result?.get())
        XCTAssertNotNil(result?.failure)
    }

    // MARK: - Delete product tags tests

    /// Verifies that deleteProductTags properly parses the `product tag` sample response.
    ///
    func testDeleteProductTagsProperlyReturnsParsedProductTags() {
        // Given
        let remote = ProductTagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "product-tags-deleted")

        // When
        var result: Result<[ProductTag], Error>?
        waitForExpectation { exp in
            remote.deleteProductTags(for: sampleSiteID, ids: [35]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(result?.failure)
        XCTAssertNotNil(try result?.get())
        XCTAssertEqual(try result?.get().count, 1)
        XCTAssertEqual(try result?.get().first?.name, "Oxford Shoes")
    }

    /// Verifies that deleteProductTags properly relays Networking Layer errors.
    ///
    func testDeleteProductTagsProperlyRelaysNetwokingErrors() {
        // Given
        let remote = ProductTagsRemote(network: network)

        // When
        var result: Result<[ProductTag], Error>?
        waitForExpectation { exp in
            remote.deleteProductTags(for: sampleSiteID, ids: [35]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(try? result?.get())
        XCTAssertNotNil(result?.failure)
    }

}

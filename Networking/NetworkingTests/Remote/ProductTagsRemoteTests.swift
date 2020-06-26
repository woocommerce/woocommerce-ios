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
        var result: Result<[ProductTag], Error>?
        waitForExpectation { exp in
            remote.loadAllProductTags(for: sampleSiteID) { aResult in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(result?.failure)
        XCTAssertNotNil(try result?.get())
        XCTAssertEqual(try result?.get().count, 4)
        XCTAssertEqual(try result?.get().first?.tagID, 34)
        XCTAssertEqual(try result?.get().first?.name, "Leather Shoes")
        XCTAssertEqual(try result?.get().first?.slug, "leather-shoes")
    }

    /// Verifies that loadAllProductTags properly relays Networking Layer errors.
    ///
    func testLoadAllProductTagsProperlyRelaysNetwokingErrors() {
        // Given
        let remote = ProductTagsRemote(network: network)

        // When
        var result: Result<[ProductTag], Error>?
        waitForExpectation { exp in
            remote.loadAllProductTags(for: sampleSiteID) { aResult in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(try? result?.get())
        XCTAssertNotNil(result?.failure)
    }

    // MARK: - Create a product tag tests

    /// Verifies that createProductTag properly parses the `product tag` sample response.
    ///
    func testCreateProductTagProperlyReturnsParsedProductTag() {
        // Given
        let remote = ProductTagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tag")

        // When
        var result: Result<ProductTag, Error>?
        waitForExpectation { exp in
            remote.createProductTag(for: sampleSiteID, name: "Leather Shoes") { (aResult) in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(result?.failure)
        XCTAssertNotNil(try result?.get())
        XCTAssertEqual(try result?.get().name, "Leather Shoes")
    }

    /// Verifies that createProductTag properly relays Networking Layer errors.
    ///
    func testCreateProductTagProperlyRelaysNetwokingErrors() {
        // Given
        let remote = ProductTagsRemote(network: network)

        // When
        var result: Result<ProductTag, Error>?
        waitForExpectation { exp in
            remote.createProductTag(for: sampleSiteID, name: "Leather Shoes") { (aResult) in
                result = aResult
                exp.fulfill()
            }
        }

        // Then
        XCTAssertNil(try? result?.get())
        XCTAssertNotNil(result?.failure)
    }

}

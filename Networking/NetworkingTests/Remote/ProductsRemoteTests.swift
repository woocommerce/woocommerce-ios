import XCTest
@testable import Networking


/// ProductsRemoteTests:
///
class ProductsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load All Products Tests

    /// Verifies that loadAllProducts properly parses the `products-load-all` sample response.
    ///
    func testLoadAllProductsProperlyReturnsParsedProducts() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load All Products")

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")

        remote.loadAllProducts(for: sampleSiteID) { products, error in
            XCTAssertNil(error)
            XCTAssertNotNil(products)
            XCTAssertEqual(products?.count, 10)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProducts properly relays Networking Layer errors.
    ///
    func testLoadAllProductsProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load all products returns error")

        remote.loadAllProducts(for: sampleSiteID) { products, error in
            XCTAssertNil(products)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

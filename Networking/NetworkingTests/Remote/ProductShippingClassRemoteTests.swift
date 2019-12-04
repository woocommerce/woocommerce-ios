import XCTest

@testable import Networking

final class ProductShippingClassRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load All Product Shipping Classes tests

    /// Verifies that loadAllProductShippingClasses properly parses the `product-shipping-classes-load-all` sample response.
    ///
    func testLoadAllProductShippingClassesProperlyReturnsParsedData() {
        let remote = ProductShippingClassRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Shipping Classes")

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes", filename: "product-shipping-classes-load-all")

        remote.loadAll(for: sampleSiteID) { productShippingClasses, error in
            XCTAssertNil(error)
            XCTAssertNotNil(productShippingClasses)
            XCTAssertEqual(productShippingClasses?.count, 3)

            // Validates on Shipping Class of ID 94.
            let expectedShippingClassID = 94
            guard let expectedShippingClass = productShippingClasses?.first(where: { $0.shippingClassID == expectedShippingClassID }) else {
                XCTFail("Product shipping class with ID \(expectedShippingClassID) should exist")
                return
            }
            XCTAssertEqual(expectedShippingClass.descriptionHTML, "Limited offer!")
            XCTAssertEqual(expectedShippingClass.name, "Free Shipping")
            XCTAssertEqual(expectedShippingClass.slug, "free-shipping")
            XCTAssertEqual(expectedShippingClass.count, 3)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProductShippingClasses properly relays Networking Layer errors.
    ///
    func testLoadAllProductShippingClassesProperlyRelaysNetwokingErrors() {
        let remote = ProductShippingClassRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Shipping Classes returns error")

        remote.loadAll(for: sampleSiteID) { (productShippingClasses, error) in
            XCTAssertNil(productShippingClasses)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}

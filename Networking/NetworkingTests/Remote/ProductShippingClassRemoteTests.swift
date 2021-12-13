import XCTest

@testable import Networking

final class ProductShippingClassRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

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

    /// Verifies that loadAll properly parses the `product-shipping-classes-load-all` sample response.
    ///
    func testLoadAllProductShippingClassesProperlyReturnsParsedData() {
        let remote = ProductShippingClassRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Shipping Classes")

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes", filename: "product-shipping-classes-load-all")

        remote.loadAll(for: sampleSiteID) { result in
            guard case let .success(productShippingClasses) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertEqual(productShippingClasses.count, 3)

            // Validates on Shipping Class of ID 94.
            let expectedShippingClassID: Int64 = 94
            guard let expectedShippingClass = productShippingClasses.first(where: { $0.shippingClassID == expectedShippingClassID }) else {
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

    /// Verifies that loadAll properly relays Networking Layer errors.
    ///
    func testLoadAllProductShippingClassesProperlyRelaysNetwokingErrors() {
        let remote = ProductShippingClassRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Shipping Classes returns error")

        remote.loadAll(for: sampleSiteID) { result in
            XCTAssertTrue(result.isFailure)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - Load One Product Shipping Class tests

    /// Verifies that loadOne properly parses the `product-shipping-classes-load-one` sample response.
    ///
    func testLoadOneProductShippingClassProperlyReturnsParsedData() {
        let remote = ProductShippingClassRemote(network: network)
        let expectation = self.expectation(description: "Load One Product Shipping Class")

        let remoteID = Int64(94)
        network.simulateResponse(requestUrlSuffix: "products/shipping_classes/\(remoteID)", filename: "product-shipping-classes-load-one")

        remote.loadOne(for: sampleSiteID, remoteID: remoteID) { productShippingClass, error in
            XCTAssertNil(error)
            XCTAssertNotNil(productShippingClass)
            XCTAssertEqual(productShippingClass, self.sampleProductShippingClass(remoteID: remoteID))

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOne properly relays Networking Layer errors.
    ///
    func testLoadOneProductShippingClassProperlyRelaysNetwokingErrors() {
        let remote = ProductShippingClassRemote(network: network)
        let expectation = self.expectation(description: "Load One Product Shipping Class returns error")

        let remoteID = Int64(96987515)
        remote.loadOne(for: sampleSiteID, remoteID: remoteID) { (productShippingClass, error) in
            XCTAssertNil(productShippingClass)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}

private extension ProductShippingClassRemoteTests {
    func sampleProductShippingClass(remoteID: Int64) -> ProductShippingClass {
        return ProductShippingClass(count: 3,
                                    descriptionHTML: "Limited offer!",
                                    name: "Free Shipping",
                                    shippingClassID: remoteID,
                                    siteID: sampleSiteID,
                                    slug: "free-shipping")
    }
}

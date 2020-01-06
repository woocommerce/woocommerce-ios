import XCTest

@testable import Networking

final class ProductVariationsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Product ID
    ///
    let sampleProductID: Int64 = 173

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load all product variations tests

    /// Verifies that loadAllProductVariations properly parses the `product-variations-load-all` sample response.
    ///
    func testLoadAllProductVariationsProperlyReturnsParsedData() {
        let remote = ProductVariationsRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Variations")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations", filename: "product-variations-load-all")

        remote.loadAllProductVariations(for: sampleSiteID, productID: sampleProductID) { productVariations, error in
            XCTAssertNil(error)
            XCTAssertNotNil(productVariations)
            XCTAssertEqual(productVariations?.count, 8)

            // Validates on Variation of ID 1275.
            let expectedVariationID: Int64 = 1275
            guard let expectedVariation = productVariations?.first(where: { $0.productVariationID == expectedVariationID }) else {
                XCTFail("Product variation with ID \(expectedVariationID) should exist")
                return
            }
            XCTAssertEqual(expectedVariation.description, "<p>Nutty chocolate marble, 99% and organic.</p>\n")
            XCTAssertEqual(expectedVariation.sku, "99%-nuts-marble")
            XCTAssertEqual(expectedVariation.permalink, "https://chocolate.com/marble")

            XCTAssertEqual(expectedVariation.dateCreated, self.dateFromGMT("2019-11-14T12:40:55"))
            XCTAssertEqual(expectedVariation.dateModified, self.dateFromGMT("2019-11-14T13:06:42"))
            XCTAssertEqual(expectedVariation.dateOnSaleStart, self.dateFromGMT("2019-10-15T21:30:00"))
            XCTAssertEqual(expectedVariation.dateOnSaleEnd, self.dateFromGMT("2019-10-27T21:29:59"))

            let expectedPrice = 12
            XCTAssertEqual(expectedVariation.price, "\(expectedPrice)")
            XCTAssertEqual(expectedVariation.regularPrice, "\(expectedPrice)")
            XCTAssertEqual(expectedVariation.salePrice, "8")

            XCTAssertEqual(expectedVariation.status, .publish)
            XCTAssertEqual(expectedVariation.stockStatus, .inStock)

            let expectedAttributes: [ProductVariationAttribute] = [
                ProductVariationAttribute(id: 0, name: "Darkness", option: "99%"),
                ProductVariationAttribute(id: 0, name: "Flavor", option: "nuts"),
                ProductVariationAttribute(id: 0, name: "Shape", option: "marble")
            ]
            XCTAssertEqual(expectedVariation.attributes, expectedAttributes)

            XCTAssertEqual(expectedVariation.image?.imageID, 1063)

            XCTAssertFalse(expectedVariation.onSale)
            XCTAssertTrue(expectedVariation.purchasable)
            XCTAssertFalse(expectedVariation.virtual)
            XCTAssertTrue(expectedVariation.downloadable)

            XCTAssertTrue(expectedVariation.manageStock)
            XCTAssertEqual(expectedVariation.stockQuantity, 16)
            XCTAssertEqual(expectedVariation.backordersKey, "notify")
            XCTAssertTrue(expectedVariation.backordersAllowed)
            XCTAssertFalse(expectedVariation.backordered)

            XCTAssertEqual(expectedVariation.downloads.count, 0)
            XCTAssertEqual(expectedVariation.downloadLimit, -1)
            XCTAssertEqual(expectedVariation.downloadExpiry, 0)

            XCTAssertEqual(expectedVariation.taxStatusKey, "taxable")
            XCTAssertEqual(expectedVariation.taxClass, "")

            XCTAssertEqual(expectedVariation.weight, "2.5")
            XCTAssertEqual(expectedVariation.dimensions, ProductDimensions(length: "10", width: "2.5", height: ""))

            XCTAssertEqual(expectedVariation.shippingClass, "")
            XCTAssertEqual(expectedVariation.shippingClassID, 0)

            XCTAssertEqual(expectedVariation.menuOrder, 8)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProductVariations properly relays Networking Layer errors.
    ///
    func testLoadAllProductVariationsProperlyRelaysNetwokingErrors() {
        let remote = ProductVariationsRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Variations returns error")

        remote.loadAllProductVariations(for: sampleSiteID, productID: sampleProductID) { (productVariations, error) in
            XCTAssertNil(productVariations)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}

private extension ProductVariationsRemoteTests {
    func dateFromGMT(_ dateStringInGMT: String) -> Date {
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        return dateFormatter.date(from: dateStringInGMT)!
    }
}

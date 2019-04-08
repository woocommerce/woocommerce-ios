import XCTest
@testable import Networking


/// ProductsRemoteTests
///
class ProductsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Dummy Product ID
    ///
    let sampleProductID = 282

    /// Dummy Variation ID
    ///
    let sampleVariationID = 215

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    // MARK: - Load all products tests

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


    // MARK: - Load single product tests

    /// Verifies that loadProduct properly parses the `product` sample response.
    ///
    func testLoadSingleProductProperlyReturnsParsedProduct() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load single product")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product")

        remote.loadProduct(for: sampleSiteID, productID: sampleProductID) { product, error in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product?.productID, self.sampleProductID)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadProduct properly relays any Networking Layer errors.
    ///
    func testLoadSingleProductProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load single product returns error")

        remote.loadProduct(for: sampleSiteID, productID: sampleProductID) { product, error in
            XCTAssertNil(product)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Load all product variation tests

    /// Verifies that loadAllProductVariations properly parses the `products-load-all` sample response.
    ///
    func testLoadAllProductVariationsProperlyReturnsParsedProductVariations() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load All product variations")

        network.simulateResponse(requestUrlSuffix: "variations", filename: "product-variations-load-all")

        remote.loadAllProductVariations(for: sampleSiteID, productID: sampleProductID) { variations, error in
            XCTAssertNil(error)
            XCTAssertNotNil(variations)
            XCTAssertEqual(variations?.count, 4)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProductVariations properly relays Networking Layer errors.
    ///
    func testLoadAllProductVariationsProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load all product variations returns error")

        remote.loadAllProductVariations(for: sampleSiteID, productID: sampleProductID) { variations, error in
            XCTAssertNil(variations)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Load single product variation tests

    /// Verifies that loadAllProductVariation properly parses the `ProductVariation` sample response.
    ///
    func testLoadSingleProductVariationProperlyReturnsParsedProductVariation() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load single product variation")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations/\(sampleVariationID)", filename: "product-variation")
        remote.loadProductVariation(for: sampleSiteID, productID: sampleProductID, variationID: sampleVariationID) { variation, error in
            XCTAssertNil(error)
            XCTAssertNotNil(variation)
            XCTAssertEqual(variation?.variationID, self.sampleVariationID)
            XCTAssertEqual(variation?.productID, self.sampleProductID)
            XCTAssertEqual(variation?.siteID, self.sampleSiteID)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProductVariation properly relays any Networking Layer errors.
    ///
    func testLoadSingleProductVariationProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load single product variation returns error")

        remote.loadProductVariation(for: sampleSiteID, productID: sampleProductID, variationID: sampleVariationID) { variation, error in
            XCTAssertNil(variation)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

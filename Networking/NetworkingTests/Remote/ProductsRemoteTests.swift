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

    // MARK: - Search Products

    /// Verifies that searchProducts properly parses the `products-load-all` sample response.
    ///
    func testSearchProductsProperlyReturnsParsedProducts() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product search results")

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-search-photo")

        remote.searchProducts(for: sampleSiteID,
                              keyword: "photo",
                              pageNumber: 0,
                              pageSize: 100) { (products, error) in
                                XCTAssertNil(error)
                                XCTAssertNotNil(products)
                                XCTAssertEqual(products?.count, 2)
                                expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that searchProducts properly relays Networking Layer errors.
    ///
    func testSearchProductsProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product search results")

        remote.searchProducts(for: sampleSiteID,
                              keyword: String(),
                              pageNumber: 0,
                              pageSize: 100) { (products, error) in
                                XCTAssertNil(products)
                                XCTAssertNotNil(error)
                                expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    
    // MARK: - Update Product name

    /// Verifies that updateProductName name properly parses the `product-update-name` sample response.
    ///
    func testUpdateProductNameProperlyReturnsParsedProduct() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product name update")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-update-name")

        let productName = "This is my new product name!"
        remote.updateProductName(for: sampleSiteID, productID: sampleProductID, name: productName) { (product, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product?.name, productName)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that updateProductName name properly relays Networking Layer errors.
    ///
    func testUpdateProductNameProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product name update")

        remote.updateProductName(for: sampleSiteID, productID: sampleProductID, name: "") { (product, error) in
            XCTAssertNil(product)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
    
    // MARK: - Update Product Description

    /// Verifies that updateProductDescription description properly parses the `product-update-description` sample response.
    ///
    func testUpdateProductDescriptionProperlyReturnsParsedProduct() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product description update")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-update-description")

        let productDescription = "Learn something!"
        remote.updateProductDescription(for: sampleSiteID, productID: sampleProductID, description: productDescription) { (product, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product?.fullDescription, productDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that updateProductDescription description properly relays Networking Layer errors.
    ///
    func testUpdateProductDescriptionProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product description update")

        remote.updateProductDescription(for: sampleSiteID, productID: sampleProductID, description: "") { (product, error) in
            XCTAssertNil(product)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

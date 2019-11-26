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


    // MARK: - Update Product

    /// Verifies that updateProduct properly parses the `product-update` sample response.
    ///
    func testUpdateProductProperlyReturnsParsedProduct() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product update")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-update")

        let productName = "This is my new product name!"
        let productDescription = "Learn something!"
        let product = sampleProduct()
        remote.updateProduct(product: product) { (product, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product?.name, productName)
            XCTAssertEqual(product?.fullDescription, productDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that updateProduct properly relays Networking Layer errors.
    ///
    func testUpdateProductProperlyRelaysNetwokingErrors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Wait for product name update")

        let product = sampleProduct()
        remote.updateProduct(product: product) { (product, error) in
            XCTAssertNil(product)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

// MARK: - Private Helpers
//
private extension ProductsRemoteTests {

    func sampleProduct() -> Product {
        return Product(siteID: sampleSiteID,
                       productID: sampleProductID,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       briefDescription: """
                           [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                           We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                           know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                           for $100.</p>\n
                           """,
                       sku: "",
                       price: "0",
                       regularPrice: "",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: true,
                       downloadable: false,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       externalURL: "http://somewhere.com",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: false,
                       stockQuantity: nil,
                       stockStatusKey: "instock",
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "213",
                       dimensions: sampleDimensions(),
                       shippingRequired: false,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: sampleCategories(),
                       tags: sampleTags(),
                       images: sampleImages(),
                       attributes: sampleAttributes(),
                       defaultAttributes: sampleDefaultAttributes(),
                       variations: [192, 194, 193],
                       groupedProducts: [],
                       menuOrder: 0)
    }

    func sampleDimensions() -> Networking.ProductDimensions {
        return ProductDimensions(length: "12", width: "33", height: "54")
    }

    func sampleCategories() -> [Networking.ProductCategory] {
        let category1 = ProductCategory(categoryID: 36, name: "Events", slug: "events")
        return [category1]
    }

    func sampleTags() -> [Networking.ProductTag] {
        let tag1 = ProductTag(tagID: 37, name: "room", slug: "room")
        let tag2 = ProductTag(tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(tagID: 39, name: "30", slug: "30")
        let tag4 = ProductTag(tagID: 40, name: "20+", slug: "20")
        let tag5 = ProductTag(tagID: 41, name: "meeting room", slug: "meeting-room")
        let tag6 = ProductTag(tagID: 42, name: "meetings", slug: "meetings")
        let tag7 = ProductTag(tagID: 43, name: "parties", slug: "parties")
        let tag8 = ProductTag(tagID: 44, name: "graduation", slug: "graduation")
        let tag9 = ProductTag(tagID: 45, name: "birthday party", slug: "birthday-party")

        return [tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9]
    }

    func sampleImages() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 19,
                                  dateCreated: date(with: "2018-01-26T21:49:45"),
                                  dateModified: date(with: "2018-01-26T21:50:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png",
                                  name: "Vneck Tshirt",
                                  alt: "")
        return [image1]
    }

    func sampleAttributes() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 1,
                                          visible: true,
                                          variation: true,
                                          options: ["Purple", "Yellow", "Hot Pink", "Lime Green", "Teal"])

        let attribute2 = ProductAttribute(attributeID: 0,
                                          name: "Size",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Small", "Medium", "Large"])

        return [attribute1, attribute2]
    }

    func sampleDefaultAttributes() -> [Networking.ProductDefaultAttribute] {
        let defaultAttribute1 = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")
        let defaultAttribute2 = ProductDefaultAttribute(attributeID: 0, name: "Size", option: "Medium")

        return [defaultAttribute1, defaultAttribute2]
    }

    func sampleDownloads() -> [Networking.ProductDownload] {
        let download1 = ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11",
                                        name: "Song #1",
                                        fileURL: "https://woocommerce.files.wordpress.com/2017/06/woo-single-1.ogg")
        let download2 = ProductDownload(downloadID: "ec87d8b5-1361-4562-b4b8-18980b5a2cae",
                                        name: "Artwork",
                                        fileURL: "https://thuy-test.mystagingwebsite.com/wp-content/uploads/2018/01/cd_4_angle.jpg")
        let download3 = ProductDownload(downloadID: "240cd543-5457-498e-95e2-6b51fdaf15cc",
                                        name: "Artwork 2",
                                        fileURL: "https://thuy-test.mystagingwebsite.com/wp-content/uploads/2018/01/cd_4_flat.jpg")
        return [download1, download2, download3]
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}

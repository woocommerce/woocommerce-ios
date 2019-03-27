import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// ProductStore Unit Tests
///
class ProductStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID = 123

    /// Testing ProductID
    ///
    private let sampleProductID = 282

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 75


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    // MARK: - ProductAction.synchronizeProducts

    /// Verifies that ProductAction.synchronizeProducts effectively persists any retrieved products.
    ///
    func testRetrieveProductsEffectivelyPersistsRetrievedProducts() {
        let expectation = self.expectation(description: "Persist product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 10)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.synchronizeProducts` effectively persists all of the product fields
    /// correctly across all of the related Prodcut objects (tags, categories, attributes, etc).
    ///
    func testRetrieveProdcutsEffectivelyPersistsProductFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct()

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            let predicate = NSPredicate(format: "productID = %ld", remoteProduct.productID)
            let storedProduct = self.viewStorage.firstObject(ofType: Storage.Product.self, matching: predicate)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)
            XCTAssertEqual(readOnlyStoredProduct, remoteProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - ProductAction.retrieveProduct

    /// Verifies that OrderAction.retrieveOrder returns the expected Order.
    ///
    func testRetrieveSingleProductReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve single product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct()

        network.simulateResponse(requestUrlSuffix: "products/282", filename: "product")
        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleProductID) { (product, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product, remoteProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}


// MARK: - Private Methods
//
private extension ProductStoreTests {

    func sampleProduct() -> Networking.Product {
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
        let tag1 = ProductTag(tagID: 40, name: "20+", slug: "20")
        let tag2 = ProductTag(tagID: 39, name: "30", slug: "30")
        let tag3 = ProductTag(tagID: 45, name: "birthday party", slug: "birthday-party")
        let tag4 = ProductTag(tagID: 44, name: "graduation", slug: "graduation")
        let tag5 = ProductTag(tagID: 41, name: "meeting room", slug: "meeting-room")
        let tag6 = ProductTag(tagID: 42, name: "meetings", slug: "meetings")
        let tag7 = ProductTag(tagID: 43, name: "parties", slug: "parties")
        let tag8 = ProductTag(tagID: 38, name: "party room", slug: "party-room")
        let tag9 = ProductTag(tagID: 37, name: "room", slug: "room")
        return [tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9].sorted()
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
                                          name: "Size",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Small", "Medium", "Large"])

        let attribute2 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 1,
                                          visible: true,
                                          variation: true,
                                          options: ["Purple", "Yellow", "Hot Pink", "Lime Green", "Teal"])
        return [attribute1, attribute2].sorted()
    }

    func sampleDefaultAttributes() -> [Networking.ProductDefaultAttribute] {
        let defaultAttribute1 = ProductDefaultAttribute(attributeID: 0, name: "Size", option: "Medium")
        let defaultAttribute2 = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")

        return [defaultAttribute1, defaultAttribute2].sorted()
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}

import XCTest
import Storage
import CoreData
import Fakes
@testable import Yosemite

final class ResultsController_StorageProductTests: XCTestCase {
    /// InMemory Storage!
    ///
    private var storageManager: MockStorageManager!

    private let sampleSiteID: Int64 = 134

    private lazy var sampleProductsPredicate = NSPredicate(format: "siteID == %lld", sampleSiteID)

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    // MARK: tests for `init` with a `ProductsSortOrder` param

    func testProductResultsControllerInitWithAscendingNameSortOrder() {
        // Arrange
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Zap")
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "fun house")
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        // Act
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product2, product1])
    }

    func testProductResultsControllerInitWithDescendingNameSortOrder() {
        // Arrange
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "fun house")
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "Zap")
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        // Act
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .nameDescending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product2, product1])
    }

    func testProductResultsControllerInitWithAscendingDateSortOrder() {
        // Arrange
        // Friday, March 27, 2020 9:47:09 AM GMT
        let earlierDate = Date(timeIntervalSince1970: 1585302429)
        // Saturday, June 27, 2020 9:47:09 AM GMT
        let laterDate = Date(timeIntervalSince1970: 1593251229)

        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "fun house", date: laterDate)
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "zap!", date: earlierDate)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        // Act
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .dateAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product2, product1])
    }

    func testProductResultsControllerInitWithDescendingDateSortOrder() {
        // Arrange
        // Friday, March 27, 2020 9:47:09 AM GMT
        let earlierDate = Date(timeIntervalSince1970: 1585302429)
        // Saturday, June 27, 2020 9:47:09 AM GMT
        let laterDate = Date(timeIntervalSince1970: 1593251229)

        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "fun house", dateCreated: earlierDate)
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "zap!", dateCreated: laterDate)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        // Act
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .dateDescending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product2, product1])
    }

    // MARK: tests for `updateSortOrder` with a `ProductsSortOrder` param

    func testProductResultsControllerUpdateWithAscendingNameSortOrder() {
        // Arrange
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "fun house")
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "woo")
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .nameDescending)
        try? resultsController.performFetch()

        // Act
        resultsController.updateSortOrder(.nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product1, product2])
    }

    func testProductResultsControllerUpdateWithDescendingNameSortOrder() {
        // Arrange
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Zap")
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "fun house")
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Act
        resultsController.updateSortOrder(.nameDescending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product1, product2])
    }

    func testProductResultsControllerUpdateWithAscendingDateSortOrder() {
        // Arrange
        // Friday, March 27, 2020 9:47:09 AM GMT
        let earlierDate = Date(timeIntervalSince1970: 1585302429)
        // Saturday, June 27, 2020 9:47:09 AM GMT
        let laterDate = Date(timeIntervalSince1970: 1593251229)

        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "fun house", date: laterDate)
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "woo", date: earlierDate)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .nameDescending)
        try? resultsController.performFetch()

        // Act
        resultsController.updateSortOrder(.dateAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product2, product1])
    }

    func testProductResultsControllerUpdateWithDescendingDateSortOrder() {
        // Arrange
        // Friday, March 27, 2020 9:47:09 AM GMT
        let earlierDate = Date(timeIntervalSince1970: 1585302429)
        // Saturday, June 27, 2020 9:47:09 AM GMT
        let laterDate = Date(timeIntervalSince1970: 1593251229)

        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Zap", dateCreated: earlierDate)
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "fun house", dateCreated: laterDate)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Act
        resultsController.updateSortOrder(.dateDescending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [product2, product1])
    }

    func test_product_ResultsController_sorts_in_descending_date_for_draft_product_of_earlier_date() {
        // Arrange
        // Friday, March 27, 2020 9:47:09 AM GMT
        let earlierDate = Date(timeIntervalSince1970: 1585302429)
        // Saturday, June 27, 2020 9:47:09 AM GMT
        let laterDate = Date(timeIntervalSince1970: 1593251229)

        let draftProduct = Product.fake().copy(siteID: sampleSiteID,
                                               productID: 1,
                                               name: "Zap",
                                               dateCreated: Date(),
                                               dateModified: earlierDate,
                                               statusKey: ProductStatus.draft.rawValue)
        storageManager.insertSampleProduct(readOnlyProduct: draftProduct)

        let publishedProduct = Product.fake().copy(siteID: sampleSiteID,
                                               productID: 2,
                                               name: "fun house",
                                               dateCreated: laterDate,
                                               statusKey: ProductStatus.publish.rawValue)
        storageManager.insertSampleProduct(readOnlyProduct: publishedProduct)

        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: sampleProductsPredicate,
                                                                  sortOrder: .dateDescending)
        try? resultsController.performFetch()

        // Act
        resultsController.updateSortOrder(.dateDescending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)
        XCTAssertEqual(resultsController.fetchedObjects, [publishedProduct, draftProduct])
    }
}

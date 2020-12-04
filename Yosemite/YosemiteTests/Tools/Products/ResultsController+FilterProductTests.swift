import XCTest
import Storage
import CoreData
@testable import Yosemite

final class ResultsController_FilterProductTests: XCTestCase {
    /// InMemory Storage!
    ///
    private var storageManager: MockStorageManager!

    private let sampleSiteID: Int64 = 134

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func testPredicateWithAllNilFilters() {
        // Arrange
        // Creates different combinations of products.
        let expectedProducts = [
            MockProduct().product(siteID: sampleSiteID, productID: 62, name: "A", productStatus: .draft, productType: .affiliate, stockStatus: .onBackOrder),
            MockProduct().product(siteID: sampleSiteID, productID: 2, name: "B", productStatus: .publish, productType: .simple, stockStatus: .inStock),
            MockProduct().product(siteID: sampleSiteID, productID: 25, name: "C", productStatus: .pending, productType: .variable, stockStatus: .outOfStock),
            ]

        expectedProducts.forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID, stockStatus: nil, productStatus: nil, productType: nil)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects, expectedProducts)
    }

    func testPredicateWithNonNilStockStatusFilter() {
        // Arrange
        let otherProduct = MockProduct().product(siteID: sampleSiteID, productID: 1, stockStatus: .inStock)

        let expectedProducts = [
            MockProduct().product(siteID: sampleSiteID, productID: 62, name: "A", stockStatus: .onBackOrder),
            MockProduct().product(siteID: sampleSiteID, productID: 2, name: "B", stockStatus: .onBackOrder)
            ]

        ([otherProduct] + expectedProducts).forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID, stockStatus: .onBackOrder, productStatus: nil, productType: nil)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertFalse(resultsController.fetchedObjects.contains(otherProduct))
        XCTAssertEqual(resultsController.fetchedObjects, expectedProducts)
    }

    func testPredicateWithNonNilProductStatus() {
        // Arrange
        let otherProduct = MockProduct().product(siteID: sampleSiteID, productID: 1, productStatus: .publish)

        let expectedProducts = [
            MockProduct().product(siteID: sampleSiteID, productID: 62, name: "A", productStatus: .draft),
            MockProduct().product(siteID: sampleSiteID, productID: 2, name: "B", productStatus: .draft)
            ]

        ([otherProduct] + expectedProducts).forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID, stockStatus: nil, productStatus: .draft, productType: nil)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertFalse(resultsController.fetchedObjects.contains(otherProduct))
        XCTAssertEqual(resultsController.fetchedObjects, expectedProducts)
    }

    func testPredicateWithNonNilProductType() {
        // Arrange
        let otherProduct = MockProduct().product(siteID: sampleSiteID, productID: 1, productType: .affiliate)

        let expectedProducts = [
            MockProduct().product(siteID: sampleSiteID, productID: 62, name: "A", productType: .variable),
            MockProduct().product(siteID: sampleSiteID, productID: 2, name: "B", productType: .variable)
            ]

        ([otherProduct] + expectedProducts).forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID, stockStatus: nil, productStatus: nil, productType: .variable)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertFalse(resultsController.fetchedObjects.contains(otherProduct))
        XCTAssertEqual(resultsController.fetchedObjects, expectedProducts)
    }
}

import XCTest
import Storage
import CoreData
import Fakes
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
            Product.fake().copy(siteID: sampleSiteID,
                                productID: 62,
                                name: "A",
                                productTypeKey: ProductType.affiliate.rawValue,
                                statusKey: ProductStatus.draft.rawValue,
                                stockStatusKey: ProductStockStatus.onBackOrder.rawValue,
                                categories: [ProductCategory.fake()]),
            Product.fake().copy(siteID: sampleSiteID,
                                productID: 2,
                                name: "B",
                                productTypeKey: ProductType.simple.rawValue,
                                statusKey: ProductStatus.publish.rawValue,
                                stockStatusKey: ProductStockStatus.inStock.rawValue),
            Product.fake().copy(siteID: sampleSiteID,
                                productID: 25,
                                name: "C",
                                productTypeKey: ProductType.variable.rawValue,
                                statusKey: ProductStatus.pending.rawValue,
                                stockStatusKey: ProductStockStatus.outOfStock.rawValue)
        ]

        expectedProducts.forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID, stockStatus: nil, productStatus: nil, productType: nil, productCategory: nil)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects, expectedProducts)
    }

    func testPredicateWithNonNilStockStatusFilter() {
        // Arrange
        let otherProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, stockStatusKey: ProductStockStatus.inStock.rawValue)

        let expectedProducts = [
            Product.fake().copy(siteID: sampleSiteID,
                                productID: 62,
                                name: "A",
                                stockStatusKey: ProductStockStatus.onBackOrder.rawValue,
                                categories: [ProductCategory.fake()]),
            Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "B", stockStatusKey: ProductStockStatus.onBackOrder.rawValue),
        ]

        ([otherProduct] + expectedProducts).forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID,
                                                           stockStatus: .onBackOrder,
                                                           productStatus: nil,
                                                           productType: nil,
                                                           productCategory: nil)
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
        let otherProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, statusKey: ProductStatus.publish.rawValue)

        let expectedProducts = [
            Product.fake().copy(siteID: sampleSiteID, productID: 62, name: "A", statusKey: ProductStatus.draft.rawValue),
            Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "B", statusKey: ProductStatus.draft.rawValue, categories: [ProductCategory.fake()]),
        ]

        ([otherProduct] + expectedProducts).forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID,
                                                           stockStatus: nil,
                                                           productStatus: .draft,
                                                           productType: nil,
                                                           productCategory: nil)
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
        let otherProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, productTypeKey: ProductType.affiliate.rawValue)

        let expectedProducts = [
            Product.fake().copy(siteID: sampleSiteID,
                                productID: 62,
                                name: "A",
                                productTypeKey: ProductType.variable.rawValue,
                                categories: [ProductCategory.fake()]),
            Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "B", productTypeKey: ProductType.variable.rawValue),
        ]

        ([otherProduct] + expectedProducts).forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID,
                                                           stockStatus: nil,
                                                           productStatus: nil,
                                                           productType: .variable,
                                                           productCategory: nil)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertFalse(resultsController.fetchedObjects.contains(otherProduct))
        XCTAssertEqual(resultsController.fetchedObjects, expectedProducts)
    }

    func testPredicateWithNonNilProductCategory() {
        // Arrange
        let filterCategoryID: Int64 = 2
        let otherCategoryID: Int64 = 1
        let otherProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, categories: [ProductCategory.fake().copy(categoryID: otherCategoryID)])

        let expectedProducts = [
            Product.fake().copy(siteID: sampleSiteID,
                                productID: 62,
                                name: "A",
                                productTypeKey: ProductType.variable.rawValue,
                                categories: [ProductCategory.fake().copy(categoryID: otherCategoryID),
                                             ProductCategory.fake().copy(categoryID: filterCategoryID)]),
            Product.fake().copy(siteID: sampleSiteID,
                                productID: filterCategoryID,
                                name: "B",
                                productTypeKey: ProductType.variable.rawValue,
                                categories: [ProductCategory.fake().copy(categoryID: filterCategoryID)]),
        ]

        ([otherProduct] + expectedProducts).forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }

        // Act
        let predicate = NSPredicate.createProductPredicate(siteID: sampleSiteID,
                                                           stockStatus: nil,
                                                           productStatus: nil,
                                                           productType: nil,
                                                           productCategory: ProductCategory.fake().copy(categoryID: 2))
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                  matching: predicate,
                                                                  sortOrder: .nameAscending)
        try? resultsController.performFetch()

        // Assert
        XCTAssertFalse(resultsController.fetchedObjects.contains(otherProduct))
        XCTAssertEqual(resultsController.fetchedObjects, expectedProducts)
    }
}

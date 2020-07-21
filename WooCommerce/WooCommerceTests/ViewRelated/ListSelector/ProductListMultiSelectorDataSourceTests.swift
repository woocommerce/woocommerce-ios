import XCTest

@testable import Storage
@testable import WooCommerce
@testable import Yosemite

final class ProductListMultiSelectorDataSourceTests: XCTestCase {
    private var storageManager: StorageManagerType {
        ServiceLocator.storageManager
    }

    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var cancellable: ObservationToken?

    override func setUp() {
        super.setUp()

        cancellable = nil
    }

    func testDataSourceCreatesResultsControllerExcludingSpecifiedProductIDs() throws {
        // Arrange
        let siteID: Int64 = 1
        let excludedProductIDs: [Int64] = [17, 630]
        excludedProductIDs.forEach { productID in
            insert(Product().copy(siteID: siteID, productID: productID))
        }

        let otherProductIDs: [Int64] = [22, 671, 5]
        otherProductIDs.forEach { productID in
            insert(Product().copy(siteID: siteID, productID: productID))
        }

        let dataSource = ProductListMultiSelectorDataSource(siteID: siteID, excludedProductIDs: excludedProductIDs)

        // Action
        let resultsController = dataSource.createResultsController()
        try resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, otherProductIDs.count)
        XCTAssertFalse(resultsController.fetchedObjects.contains(where: { excludedProductIDs.contains($0.productID) }))
    }

    func testSelectingAndUnselectingAProductChangesSelectedProductIDs() {
        // Arrange
        let siteID: Int64 = 1
        let dataSource = ProductListMultiSelectorDataSource(siteID: siteID, excludedProductIDs: [])
        var productsSequence = [[Int64]]()
        cancellable = dataSource.productIDs.subscribe { productIDs in
            productsSequence.append(productIDs)
        }

        // Action
        let product = Product().copy(productID: 17)
        dataSource.handleSelectedChange(selected: product)
        dataSource.handleSelectedChange(selected: product)

        // Assert
        XCTAssertEqual(productsSequence, [
            [17],
            []
        ])
    }

    func testProductIsSelectedOnlyAfterSelectedChange() {
        // Arrange
        let siteID: Int64 = 1
        let dataSource = ProductListMultiSelectorDataSource(siteID: siteID, excludedProductIDs: [])
        let product = Product().copy(productID: 17)
        XCTAssertFalse(dataSource.isSelected(model: product))

        // Action - step 1: select product
        dataSource.handleSelectedChange(selected: product)

        // Assert - step 1
        XCTAssertTrue(dataSource.isSelected(model: product))

        // Action - step 2: unselect product
        dataSource.handleSelectedChange(selected: product)

        // Assert - step 2
        XCTAssertFalse(dataSource.isSelected(model: product))
    }
}

private extension ProductListMultiSelectorDataSourceTests {
    func insert(_ readOnlyOrderProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyOrderProduct)
    }
}

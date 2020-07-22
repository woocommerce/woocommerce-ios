import XCTest

@testable import Storage
@testable import WooCommerce
@testable import Yosemite

final class ProductListMultiSelectorSearchUICommandTests: XCTestCase {
    private let sampleSiteID: Int64 = 134

    private var storageManager: StorageManagerType {
        ServiceLocator.storageManager
    }

    private var storage: StorageType {
        storageManager.viewStorage
    }

    func testCommandCreatesResultsControllerExcludingSpecifiedProductIDs() throws {
        // Arrange
        let excludedProductIDs: [Int64] = [17, 630]
        excludedProductIDs.forEach { productID in
            insert(Product().copy(siteID: sampleSiteID, productID: productID))
        }

        let otherProductIDs: [Int64] = [22, 671, 5]
        otherProductIDs.forEach { productID in
            insert(Product().copy(siteID: sampleSiteID, productID: productID))
        }

        let command = ProductListMultiSelectorSearchUICommand(siteID: sampleSiteID,
                                                              excludedProductIDs: excludedProductIDs) { _ in }

        // Action
        let resultsController = command.createResultsController()
        try resultsController.performFetch()

        // Assert
        XCTAssertEqual(resultsController.fetchedObjects.count, otherProductIDs.count)
        XCTAssertFalse(resultsController.fetchedObjects.contains(where: { excludedProductIDs.contains($0.productID) }))
    }

    func testSearchActionButtonIsConfiguredToCancelAfterSelectingAndUnselectingTheSameProduct() throws {
        // Arrange
        let command = ProductListMultiSelectorSearchUICommand(siteID: sampleSiteID,
                                                              excludedProductIDs: []) { _ in }

        // Action
        let product = Product().copy(siteID: sampleSiteID, productID: 17)
        command.didSelectSearchResult(model: product, from: UIViewController(), reloadData: {}, updateActionButton: {})
        command.didSelectSearchResult(model: product, from: UIViewController(), reloadData: {}, updateActionButton: {})
        let button = UIButton(type: .custom)
        command.configureActionButton(button, onDismiss: {})

        // Assert
        XCTAssertEqual(button.titleLabel?.text,
                       NSLocalizedString("Cancel", comment: "Action title to cancel selecting products to add to a grouped product from search results"))
    }

    func testSearchActionButtonIsConfiguredToDoneAfterSelectingAProduct() throws {
        // Arrange
        let command = ProductListMultiSelectorSearchUICommand(siteID: sampleSiteID,
                                                              excludedProductIDs: []) { _ in }

        // Action
        let product = Product().copy(siteID: sampleSiteID, productID: 17)
        command.didSelectSearchResult(model: product, from: UIViewController(), reloadData: {}, updateActionButton: {})
        let button = UIButton(type: .custom)
        command.configureActionButton(button, onDismiss: {})

        // Assert
        XCTAssertEqual(button.titleLabel?.text, NSLocalizedString("Done",
                                                                  comment: "Action title to select products to add to a grouped product from search results"))
    }
}

private extension ProductListMultiSelectorSearchUICommandTests {
    func insert(_ readOnlyOrderProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyOrderProduct)
    }
}

import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for public properties/functions in `GroupedProductListSelectorDataSource`.
final class GroupedProductListSelectorDataSourceTests: XCTestCase {
    private var cancellable: ObservationToken?

    override func tearDown() {
        cancellable = nil
        super.tearDown()
    }

    // MARK: `deleteProduct`

    func testDeletingAPreselectedProductRemovesItFromGroupedProducts() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let dataSource = GroupedProductListSelectorDataSource(product: product)
        var updatedProductIDs: [Int64]?
        cancellable = dataSource.productIDs.subscribe { ids in
            updatedProductIDs = ids
        }

        // Action
        let groupedProducts = groupedProductIDs.map { MockProduct().product().copy(productID: $0) }
        dataSource.deleteProduct(groupedProducts[1])

        // Assert
        XCTAssertTrue(dataSource.hasUnsavedChanges())
        let expectedProductIDs = [groupedProductIDs[0]]
        XCTAssertEqual(dataSource.groupedProductIDs, expectedProductIDs)
        XCTAssertEqual(updatedProductIDs, expectedProductIDs)
    }

    func testDeletingANonPreselectedProductResultsInAnError() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let dataSource = GroupedProductListSelectorDataSource(product: product)
        var updatedProductIDs: [Int64]?
        cancellable = dataSource.productIDs.subscribe { ids in
            updatedProductIDs = ids
        }

        // Action
        let newProduct = MockProduct().product().copy(productID: 62)
        dataSource.deleteProduct(newProduct)

        // Assert
        XCTAssertFalse(dataSource.hasUnsavedChanges())
        XCTAssertEqual(dataSource.groupedProductIDs, groupedProductIDs)
        XCTAssertNil(updatedProductIDs)
    }
}

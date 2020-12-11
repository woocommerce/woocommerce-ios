import XCTest
import Observables

@testable import WooCommerce
import Yosemite

/// Unit tests for public properties/functions in `LinkedProductListSelectorDataSource`.
final class LinkedProductListSelectorDataSourceTests: XCTestCase {
    private var cancellable: ObservationToken?

    override func tearDown() {
        cancellable = nil
        super.tearDown()
    }

    // MARK: `addProducts`

    func test_adding_preselected_products_should_result_in_no_changes() {
        // Arrange
        let preselectedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product()
        let dataSource = LinkedProductListSelectorDataSource(product: product,
                                                             linkedProductIDs: preselectedProductIDs,
                                                             deleteButtonTappedEvent: .groupedProductLinkedProductsDeleteButtonTapped)
        var updatedProductIDs: [Int64]?
        cancellable = dataSource.productIDs.subscribe { ids in
            updatedProductIDs = ids
        }

        // Action
        dataSource.addProducts(preselectedProductIDs)

        // Assert
        XCTAssertFalse(dataSource.hasUnsavedChanges())
        XCTAssertEqual(dataSource.linkedProductIDs, preselectedProductIDs)
        XCTAssertNil(updatedProductIDs)
    }

    func test_adding_a_mix_of_preselected_and_new_products_should_append_new_products_to_linked_products() {
        // Arrange
        let preselectedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product()
        let dataSource = LinkedProductListSelectorDataSource(product: product,
                                                             linkedProductIDs: preselectedProductIDs,
                                                             deleteButtonTappedEvent: .groupedProductLinkedProductsDeleteButtonTapped)
        var updatedProductIDs: [Int64]?
        cancellable = dataSource.productIDs.subscribe { ids in
            updatedProductIDs = ids
        }

        // Action
        let newProductIDs: [Int64] = [62, 22]
        dataSource.addProducts(newProductIDs + preselectedProductIDs)

        // Assert
        XCTAssertTrue(dataSource.hasUnsavedChanges())
        let productIDsAfterAddition = preselectedProductIDs + newProductIDs
        XCTAssertEqual(dataSource.linkedProductIDs, productIDsAfterAddition)
        XCTAssertEqual(updatedProductIDs, productIDsAfterAddition)
    }

    // MARK: `deleteProduct`

    func test_deleting_a_preselected_product_removes_it_from_linked_products() {
        // Arrange
        let preselectedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product()
        let dataSource = LinkedProductListSelectorDataSource(product: product,
                                                             linkedProductIDs: preselectedProductIDs,
                                                             deleteButtonTappedEvent: .groupedProductLinkedProductsDeleteButtonTapped)
        var updatedProductIDs: [Int64]?
        cancellable = dataSource.productIDs.subscribe { ids in
            updatedProductIDs = ids
        }

        // Action
        let linkedProducts = preselectedProductIDs.map { MockProduct().product().copy(productID: $0) }
        dataSource.deleteProduct(linkedProducts[1])

        // Assert
        XCTAssertTrue(dataSource.hasUnsavedChanges())
        let expectedProductIDs = [preselectedProductIDs[0]]
        XCTAssertEqual(dataSource.linkedProductIDs, expectedProductIDs)
        XCTAssertEqual(updatedProductIDs, expectedProductIDs)
    }

    func test_deleting_a_non_preselected_product_results_in_an_error() {
        // Arrange
        let preselectedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product()
        let dataSource = LinkedProductListSelectorDataSource(product: product,
                                                             linkedProductIDs: preselectedProductIDs,
                                                             deleteButtonTappedEvent: .groupedProductLinkedProductsDeleteButtonTapped)
        var updatedProductIDs: [Int64]?
        cancellable = dataSource.productIDs.subscribe { ids in
            updatedProductIDs = ids
        }

        // Action
        let newProduct = MockProduct().product().copy(productID: 62)
        dataSource.deleteProduct(newProduct)

        // Assert
        XCTAssertFalse(dataSource.hasUnsavedChanges())
        XCTAssertEqual(dataSource.linkedProductIDs, preselectedProductIDs)
        XCTAssertNil(updatedProductIDs)
    }
}

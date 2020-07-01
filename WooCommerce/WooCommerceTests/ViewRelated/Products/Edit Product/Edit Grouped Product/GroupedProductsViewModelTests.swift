import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for public properties in `GroupedProductsViewModel`.
final class GroupedProductsViewModelTests: XCTestCase {
    private var cancellable: ObservationToken?

    override func tearDown() {
        cancellable = nil
        super.tearDown()
    }

    // MARK: `addProducts`

    func testAddingPreselectedGroupedProductsShouldResultInNoChanges() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let viewModel = GroupedProductsViewModel(product: product)
        var productsResult: Result<[Int64], GroupedProductsViewModel.Error>?
        cancellable = viewModel.productIDs.subscribe { result in
            productsResult = result
        }

        // Action
        viewModel.addProducts(groupedProductIDs)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
        XCTAssertEqual(viewModel.groupedProductIDs, groupedProductIDs)
        XCTAssertEqual(productsResult, .success(groupedProductIDs))
    }

    func testAddingAMixOfPreselectedAndNewProductsShouldAppendNewProductsToGroupedProducts() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let viewModel = GroupedProductsViewModel(product: product)
        var productsResult: Result<[Int64], GroupedProductsViewModel.Error>?
        cancellable = viewModel.productIDs.subscribe { result in
            productsResult = result
        }

        // Action
        let newProductIDs: [Int64] = [62, 22]
        viewModel.addProducts(groupedProductIDs + newProductIDs)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        let productIDsAfterAddition = groupedProductIDs + newProductIDs
        XCTAssertEqual(viewModel.groupedProductIDs, productIDsAfterAddition)
        XCTAssertEqual(productsResult, .success(productIDsAfterAddition))
    }

    // MARK: `deleteProduct`

    func testDeletingAPreselectedProductRemovesItFromGroupedProducts() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let viewModel = GroupedProductsViewModel(product: product)
        var productsResult: Result<[Int64], GroupedProductsViewModel.Error>?
        cancellable = viewModel.productIDs.subscribe { result in
            productsResult = result
        }

        // Action
        let groupedProducts = groupedProductIDs.map { MockProduct().product().copy(productID: $0) }
        viewModel.deleteProduct(groupedProducts[1])

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        let expectedProductIDs = [groupedProductIDs[0]]
        XCTAssertEqual(viewModel.groupedProductIDs, expectedProductIDs)
        XCTAssertEqual(productsResult, .success(expectedProductIDs))
    }

    func testDeletingANonPreselectedProductResultsInAnError() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let viewModel = GroupedProductsViewModel(product: product)
        var productsResult: Result<[Int64], GroupedProductsViewModel.Error>?
        cancellable = viewModel.productIDs.subscribe { result in
            productsResult = result
        }

        // Action
        let newProduct = MockProduct().product().copy(productID: 62)
        viewModel.deleteProduct(newProduct)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
        XCTAssertEqual(viewModel.groupedProductIDs, groupedProductIDs)
        XCTAssertEqual(productsResult, .failure(.productDeletion))
    }
}

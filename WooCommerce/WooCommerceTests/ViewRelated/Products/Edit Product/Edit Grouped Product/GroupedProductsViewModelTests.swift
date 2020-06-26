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
        var productsResult: Result<[Product], GroupedProductsViewModel.Error>?
        cancellable = viewModel.products.subscribe { result in
            productsResult = result
        }

        // Action
        let groupedProducts = groupedProductIDs.map { MockProduct().product().copy(productID: $0) }
        viewModel.onProductsLoaded(products: groupedProducts)
        viewModel.addProducts(groupedProducts)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
        XCTAssertEqual(viewModel.groupedProductIDs, groupedProductIDs)
        XCTAssertEqual(productsResult, .success(groupedProducts))
    }

    func testAddingAMixOfPreselectedAndNewProductsShouldAppendNewProductsToGroupedProducts() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let viewModel = GroupedProductsViewModel(product: product)
        var productsResult: Result<[Product], GroupedProductsViewModel.Error>?
        cancellable = viewModel.products.subscribe { result in
            productsResult = result
        }

        // Action
        let preselectedGroupedProducts = groupedProductIDs.map { MockProduct().product().copy(productID: $0) }
        viewModel.onProductsLoaded(products: preselectedGroupedProducts)
        let newGroupedProducts: [Product] = [
            MockProduct().product().copy(productID: 62),
            MockProduct().product().copy(productID: 22)
        ]
        viewModel.addProducts(newGroupedProducts + preselectedGroupedProducts)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertEqual(viewModel.groupedProductIDs, [17, 671, 62, 22])
        let groupedProductsAfterAddition = preselectedGroupedProducts + newGroupedProducts
        XCTAssertEqual(productsResult, .success(groupedProductsAfterAddition))
    }

    // MARK: `deleteProduct`

    func testDeletingAPreselectedProductRemovesItFromGroupedProducts() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let viewModel = GroupedProductsViewModel(product: product)
        var productsResult: Result<[Product], GroupedProductsViewModel.Error>?
        cancellable = viewModel.products.subscribe { result in
            productsResult = result
        }

        // Action
        let groupedProducts = groupedProductIDs.map { MockProduct().product().copy(productID: $0) }
        viewModel.onProductsLoaded(products: groupedProducts)
        viewModel.deleteProduct(groupedProducts[1])

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertEqual(viewModel.groupedProductIDs, [17])
        XCTAssertEqual(productsResult, .success([groupedProducts[0]]))
    }

    func testDeletingANonPreselectedProductResultsInAnError() {
        // Arrange
        let groupedProductIDs: [Int64] = [17, 671]
        let product = MockProduct().product().copy(groupedProducts: groupedProductIDs)
        let viewModel = GroupedProductsViewModel(product: product)
        var productsResult: Result<[Product], GroupedProductsViewModel.Error>?
        cancellable = viewModel.products.subscribe { result in
            productsResult = result
        }

        // Action
        let groupedProducts = groupedProductIDs.map { MockProduct().product().copy(productID: $0) }
        viewModel.onProductsLoaded(products: groupedProducts)
        let newProduct = MockProduct().product().copy(productID: 62)
        viewModel.deleteProduct(newProduct)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
        XCTAssertEqual(viewModel.groupedProductIDs, groupedProductIDs)
        XCTAssertEqual(productsResult, .failure(.productDeletion))
    }
}

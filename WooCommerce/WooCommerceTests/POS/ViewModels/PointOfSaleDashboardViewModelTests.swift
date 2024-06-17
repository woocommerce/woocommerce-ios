import XCTest
@testable import struct Yosemite.POSProduct
@testable import WooCommerce

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    func test_cart_is_empty_initially() {
        // Given
        let viewModel = PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                      cardPresentPaymentService: CardPresentPaymentPreviewService())

        // Then
        XCTAssertTrue(viewModel.itemsInCart.isEmpty)
    }

    func test_cart_is_collapsed_when_empty_then_not_collapsed_when_has_items() {
        // Given
        let viewModel = PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                      cardPresentPaymentService: CardPresentPaymentPreviewService())

        XCTAssertTrue(viewModel.itemsInCart.isEmpty, "Precondition")
        XCTAssertTrue(viewModel.isCartCollapsed, "Precondition")

        let product = POSProduct(itemID: UUID(),
                                 productID: 0,
                                 name: "Choco",
                                 price: "2.00",
                                 productImageSource: nil)

        // When
        viewModel.addItemToCart(product)

        // Then
        XCTAssertFalse(viewModel.itemsInCart.isEmpty)
        XCTAssertFalse(viewModel.isCartCollapsed)
    }
}

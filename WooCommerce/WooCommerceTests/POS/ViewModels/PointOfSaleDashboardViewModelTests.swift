import XCTest
@testable import WooCommerce

final class PointOfSaleDashboardViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_cart_is_empty_initially() {
        // Given
        let viewModel = PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                      cardPresentPaymentService: CardPresentPaymentPreviewService())

        // Then
        XCTAssertTrue(viewModel.itemsInCart.isEmpty)
    }
}

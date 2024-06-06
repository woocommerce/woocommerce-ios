import XCTest
@testable import WooCommerce

final class PointOfSaleDashboardViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_viewModel_empty_cart() {
        let viewModel = PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                      cardPresentPaymentService: CardPresentPaymentPreviewService())

        XCTAssertTrue(viewModel.itemsInCart.isEmpty)
    }
}

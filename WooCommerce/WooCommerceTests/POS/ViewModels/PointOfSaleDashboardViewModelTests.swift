import XCTest
@testable import WooCommerce
@testable import Yosemite

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    func test_cart_is_empty_initially() {
        // Given
        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        let credentials = Credentials(authToken: "token")
        let orderService = PointOfSaleOrderService(siteID: siteID,
                                                   credentials: credentials)
        let viewModel = PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                      cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                      orderService: orderService)

        // Then
        XCTAssertTrue(viewModel.itemsInCart.isEmpty)
    }
}

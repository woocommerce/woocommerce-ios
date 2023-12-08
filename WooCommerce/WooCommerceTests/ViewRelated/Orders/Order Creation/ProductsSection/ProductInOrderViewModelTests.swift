import XCTest
@testable import WooCommerce
import Yosemite

final class ProductInOrderViewModelTests: XCTestCase {
    var viewModel: ProductInOrderViewModel!
    var analytics: MockAnalyticsProvider!

    override func setUp() {
        super.setUp()

        analytics = MockAnalyticsProvider()
        let product = Product.fake()
        let productRowViewModel = ProductRowViewModel(product: product, quantity: 0)
        viewModel = ProductInOrderViewModel(productRowViewModel: productRowViewModel,
                                            productDiscountConfiguration: nil,
                                            showCouponsAndDiscountsAlert: false,
                                            analytics: WooAnalytics(analyticsProvider: analytics),
                                            onRemoveProduct: {})
    }

    func test_onAddDiscountTapped_then_tracks_event() {
        // When
        viewModel.onAddDiscountTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountAdd.rawValue)
    }

    func test_onEditDiscountTapped_then_tracks_event() {
        // When
        viewModel.onEditDiscountTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountEditButtonTapped.rawValue)
    }
}

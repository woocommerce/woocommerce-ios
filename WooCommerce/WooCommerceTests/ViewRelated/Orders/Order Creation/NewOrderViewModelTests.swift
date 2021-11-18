import XCTest
@testable import WooCommerce
import Yosemite

class NewOrderViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123

    func test_view_model_starts_with_create_button_disabled() {
        // Given
        let viewModel = NewOrderViewModel(siteID: sampleSiteID)

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .create(rendered: false))
    }

    func test_loading_indicator_is_enabled_during_network_request() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let navigationItem: NewOrderViewModel.NavigationItem = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(viewModel.navigationTrailingItem)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createOrder()
        }

        // Then
        XCTAssertEqual(navigationItem, .loading)
    }

    func test_loading_indicator_is_disabled_after_the_network_operation_completes() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createOrder(_, order, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.createOrder()

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .create(rendered: true))
    }
}

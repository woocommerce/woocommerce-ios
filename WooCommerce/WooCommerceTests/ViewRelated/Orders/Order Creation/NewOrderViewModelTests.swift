import XCTest
@testable import WooCommerce
import Yosemite

class NewOrderViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123

    func test_view_model_starts_with_create_button_hidden() {
        // Given
        let viewModel = NewOrderViewModel(siteID: sampleSiteID)

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .none)
    }

    func test_create_button_is_enabled_when_order_detail_changes_from_default_value() {
        // Given
        let viewModel = NewOrderViewModel(siteID: sampleSiteID)

        // When
        viewModel.orderDetails.status = .processing

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .create)
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

    func test_create_button_is_enabled_after_the_network_operation_completes() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.orderDetails.status = .processing
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
        XCTAssertEqual(viewModel.navigationTrailingItem, .create)
    }

    func test_notice_is_enqueued_when_order_creation_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticePresenter = MockNoticePresenter()
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores, noticePresenter: noticePresenter)

        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createOrder(_, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.createOrder()

        // Then
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
    }
}

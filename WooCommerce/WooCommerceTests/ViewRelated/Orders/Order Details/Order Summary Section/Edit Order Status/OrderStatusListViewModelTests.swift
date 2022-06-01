import XCTest
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce

/// Tests for `OrderStatusListViewModel`
///
class OrderStatusListViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345
    private let sampleOrderStatuses: [OrderStatusEnum] = [.pending, .processing, .onHold, .completed]
    private var storageManager: MockOrderStatusesStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockOrderStatusesStoresManager()
        storageManager.insert(sampleOrderStatuses, on: sampleSiteID)
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_view_model_inits_with_expected_values() {
        // Given
        let expectedIndex = 0
        let viewModel = OrderStatusListViewModel(siteID: sampleSiteID, status: sampleOrderStatuses[expectedIndex], storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.initialStatus, IndexPath(row: expectedIndex, section: 0))
        XCTAssertFalse(viewModel.shouldEnableApplyButton)
    }

    func test_statusCount_returns_expected_count() {
        // Given
        let viewModel = OrderStatusListViewModel(siteID: sampleSiteID, status: sampleOrderStatuses[0], storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.statusCount(), sampleOrderStatuses.count)
    }

    func test_apply_button_enabled_when_order_status_is_changed() {
        // Given
        let viewModel = OrderStatusListViewModel(siteID: sampleSiteID, status: sampleOrderStatuses[0], storageManager: storageManager)

        // When
        viewModel.indexOfSelectedStatus = IndexPath(row: 1, section: 0)

        // Then
        XCTAssertTrue(viewModel.shouldEnableApplyButton)
    }

    func test_apply_button_disabled_when_order_status_is_changed_to_initial_status() {
        // Given
        let initialStatusIndex = 0
        let viewModel = OrderStatusListViewModel(siteID: sampleSiteID, status: sampleOrderStatuses[initialStatusIndex], storageManager: storageManager)

        // When
        viewModel.indexOfSelectedStatus = IndexPath(row: 1, section: 0)
        viewModel.indexOfSelectedStatus = IndexPath(row: initialStatusIndex, section: 0)

        // Then
        XCTAssertFalse(viewModel.shouldEnableApplyButton)
    }

    func test_confirmSelectedStatus_sends_selected_status_to_expected_closure() {
        // Given
        let viewModel = OrderStatusListViewModel(siteID: sampleSiteID, status: sampleOrderStatuses[0], storageManager: storageManager)
        let expectedStatusIndex = 1
        var selectedStatus: OrderStatusEnum?
        viewModel.didApplySelection = {
            selectedStatus = $0
        }

        // When
        viewModel.indexOfSelectedStatus = IndexPath(row: expectedStatusIndex, section: 0)
        viewModel.confirmSelectedStatus()

        // Then
        XCTAssertEqual(selectedStatus, sampleOrderStatuses[expectedStatusIndex])
    }

    func test_confirmSelectedStatus_calls_expected_closure_when_no_status_is_selected() {
        // Given
        let viewModel = OrderStatusListViewModel(siteID: sampleSiteID, status: sampleOrderStatuses[0], storageManager: storageManager)
        var didCancel = false
        viewModel.didCancelSelection = {
            didCancel = true
        }

        // When
        viewModel.confirmSelectedStatus()

        // Then
        XCTAssertTrue(didCancel)
    }
}

/// Mock Order Statuses Store Manager
///
private final class MockOrderStatusesStoresManager: MockStorageManager {
    /// Insert an array of order statuses into storage.
    ///
    func insert(_ statuses: [OrderStatusEnum], on siteID: Int64) {
        for status in statuses {
            insert(status, on: siteID)
        }
    }

    /// Inserts an order status into storage.
    ///
    func insert(_ status: OrderStatusEnum, on siteID: Int64) {
        let orderStatus = viewStorage.insertNewObject(ofType: StorageOrderStatus.self)
        orderStatus.name = status.rawValue
        orderStatus.slug = status.rawValue
        orderStatus.siteID = siteID
    }
}

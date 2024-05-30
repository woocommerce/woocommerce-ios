import XCTest
import Yosemite
@testable import WooCommerce
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class LastOrdersDashboardCardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 134
    private var stores: MockStoresManager!
    private let sampleOrders = [Order.fake().copy(siteID: 134, orderID: 1, status: .processing, dateCreated: .now),
                                Order.fake().copy(siteID: 134, orderID: 2, status: .completed, dateCreated: .now.adding(days: -5)),
                                Order.fake().copy(siteID: 134, orderID: 3, status: .refunded, dateCreated: .now.adding(days: -7))]
    private let sampleOrderStatuses = [OrderStatus.fake().copy(siteID: 134, slug: "waiting-pickup"),
                                       OrderStatus.fake().copy(siteID: 134, slug: "pending"),
                                       OrderStatus.fake().copy(siteID: 134, slug: "failed"),
                                       OrderStatus.fake().copy(siteID: 134, slug: "completed")]
    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        storageManager = nil
        super.tearDown()
    }

    @MainActor
    func test_last_3_orders_are_loaded_when_available() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        mockFetchFilteredOrders()
        mockOrderStatuses()

        // When
        await viewModel.reloadData()

        // Then
        let orderIDs = Array(
            sampleOrders
                .map({ $0.orderID })
        )
        XCTAssertEqual(viewModel.rows.map({ $0.id }), orderIDs)
    }

    @MainActor
    func test_syncingData_is_updated_correctly() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        XCTAssertFalse(viewModel.syncingData)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }

        await viewModel.reloadData()

        // Then
        XCTAssertFalse(viewModel.syncingData)
    }

    @MainActor
    func test_syncingError_is_updated_correctly_when_loading_orders_fails() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, completion):
                completion(1, .failure(error))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }


    @MainActor
    func test_order_statuses_are_loaded_from_storage_when_available() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        insertOrderStatuses(sampleOrderStatuses)

        mockFetchFilteredOrders()
        mockOrderStatuses()

        // When
        await viewModel.reloadData()

        let statusSlugs = sampleOrderStatuses
            .map { $0.slug }
            .sorted()

        // Then
        XCTAssertEqual(viewModel.allStatuses.map { $0.id }, (["any"] + statusSlugs))
    }

    @MainActor
    func test_orders_are_fetched_based_on_selected_status() async throws {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        let sampleOrderStatus = LastOrdersDashboardCardViewModel.OrderStatusRow.cancelled
        mockOrderStatuses()

        var requestedOrderStatuses: [String]?

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .fetchFilteredOrders(_, let statuses, _, _, _, _, _, _, _, let completion):
                requestedOrderStatuses = statuses
                XCTAssertTrue(viewModel.syncingData)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }

        // When
        await viewModel.updateOrderStatus(sampleOrderStatus)

        let statuses = try XCTUnwrap(requestedOrderStatuses)
        XCTAssertEqual(statuses, [sampleOrderStatus.status?.rawValue])
    }

    @MainActor
    func test_fetch_orders_request_asks_for_only_3_orders() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .fetchFilteredOrders(_, _, _, _, _, _, _, _, let pageSize, let completion):
                // Then
                XCTAssertEqual(pageSize, 3)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }
        await viewModel.reloadData()
    }

    @MainActor
    func test_fetch_orders_request_asks_to_skip_saving_orders() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .fetchFilteredOrders(_, _, _, _, _, _, _, let writeStrategy, _, let completion):
                // Then
                XCTAssertEqual(writeStrategy, .doNotSave)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }
        await viewModel.reloadData()
    }
}

private extension LastOrdersDashboardCardViewModelTests {
    func insertOrderStatuses(_ readOnlyOrderStatuses: [OrderStatus]) {
        readOnlyOrderStatuses.forEach { orderStatus in
            let newOrderStatus = storage.insertNewObject(ofType: StorageOrderStatus.self)
            newOrderStatus.update(with: orderStatus)
        }
        storage.saveIfNeeded()
    }

    func mockFetchFilteredOrders() {
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, completion):
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }
    }

    func mockOrderStatuses() {
        stores.whenReceivingAction(ofType: OrderStatusAction.self) { action in
            switch action {
            case let .retrieveOrderStatuses(_, completion):
                completion(.success([]))
            default:
                break
            }
        }
    }
}

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
                                Order.fake().copy(siteID: 134, orderID: 3, status: .refunded, dateCreated: .now.adding(days: -7)),
                                Order.fake().copy(siteID: 134, orderID: 4, status: .pending, dateCreated: .now.adding(days: -4)),
                                Order.fake().copy(siteID: 134, orderID: 5, status: .cancelled, dateCreated: .now.adding(days: -3))]
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
    func test_last_3_orders_are_loaded_from_storage_when_available() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        insertOrders(sampleOrders)
        mockSynchronizeOrders()
        mockOrderStatuses()

        // When
        await viewModel.reloadData()

        // Then
        let orderIDs = Array(
            sampleOrders
                .sorted(by: { $0.dateCreated > $1.dateCreated })
                .map({ $0.orderID })
                .prefix(3)
        )
        XCTAssertEqual(viewModel.rows.map({ $0.id }), orderIDs)
    }

    @MainActor
    func test_syncingData_is_updated_correctly_when_orders_not_stored_locally() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        XCTAssertFalse(viewModel.syncingData)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .synchronizeOrders(_, _, _, _, _, _, _, _, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(1, nil)
            default:
                break
            }
        }

        await viewModel.reloadData()

        // Then
        XCTAssertFalse(viewModel.syncingData)
    }

    @MainActor
    func test_syncingData_is_updated_correctly_when_orders_stored_locally() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        insertOrders(sampleOrders)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .synchronizeOrders(_, _, _, _, _, _, _, _, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(1, nil)
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
            case let .synchronizeOrders(_, _, _, _, _, _, _, _, _, completion):
                completion(1, error)
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

        mockSynchronizeOrders()
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
    func test_orders_are_loaded_based_on_selected_status() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        insertOrders(sampleOrders)
        mockSynchronizeOrders()
        mockOrderStatuses()

        // When
        await viewModel.updateOrderStatus(.cancelled)

        // Then
        let orderIDs = Array(
            sampleOrders
                .filter({ $0.status == .cancelled })
                .sorted(by: { $0.dateCreated > $1.dateCreated })
                .map({ $0.orderID })
                .prefix(3)
        )
        XCTAssertEqual(viewModel.rows.map({ $0.id }), orderIDs)
    }
}

extension LastOrdersDashboardCardViewModelTests {
    func insertOrderStatuses(_ readOnlyOrderStatuses: [OrderStatus]) {
        readOnlyOrderStatuses.forEach { orderStatus in
            let newOrderStatus = storage.insertNewObject(ofType: StorageOrderStatus.self)
            newOrderStatus.update(with: orderStatus)
        }
        storage.saveIfNeeded()
    }

    func insertOrders(_ readOnlyOrders: [Order]) {
        readOnlyOrders.forEach { order in
            let newOrder = storage.insertNewObject(ofType: StorageOrder.self)
            newOrder.update(with: order)
        }
        storage.saveIfNeeded()
    }

    func mockSynchronizeOrders() {
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .synchronizeOrders(_, _, _, _, _, _, _, _, _, completion):
                completion(1, nil)
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

import XCTest
import Yosemite
import Networking
import Storage
@testable import WooCommerce

final class PushNotificationBackgroundSynchronizerTests: XCTestCase {

    var stores: MockStoresManager!
    var storage: MockStorageManager!

    @MainActor
    override func setUp() async throws {
        stores = MockStoresManager(sessionManager: .testingInstance)
        storage = MockStorageManager()
    }

    @MainActor
    func test_synchronizer_stores_order_notification_when_exists_in_order_list() async {
        // Given
        mockOrderInOrderListResponses()

        // When
        let synchronizer = PushNotificationBackgroundSynchronizer(userInfo: Self.sampleUserInfo, stores: stores, storage: storage.viewStorage)
        let syncResult = await synchronizer.sync()

        // Then
        let storedOrder = storage.viewStorage.loadOrder(siteID: Self.sampleSiteID, orderID: Self.sampleOrderID)
        XCTAssertNotNil(storedOrder)
        XCTAssertEqual(syncResult, .newData)
    }

    @MainActor
    func test_synchronizer_stores_order_notification_when_does_not_exists_in_order_list() async {
        // Given
        mockOrderNotInOrdersList()

        // When
        let synchronizer = PushNotificationBackgroundSynchronizer(userInfo: Self.sampleUserInfo, stores: stores, storage: storage.viewStorage)
        let syncResult = await synchronizer.sync()

        // Then
        let storedOrder = storage.viewStorage.loadOrder(siteID: Self.sampleSiteID, orderID: Self.sampleOrderID)
        XCTAssertNotNil(storedOrder)
        XCTAssertEqual(syncResult, .newData)
    }
}

// MARK: Helpers
private extension PushNotificationBackgroundSynchronizerTests {
    /// Responses when the order exists in the order list
    ///
    func mockOrderInOrderListResponses() {
        // Mock sync notifications
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                self.storage.insertSampleNote(readOnlyNote: Self.sampleNote)
                onCompletion(nil)
            default:
                break
            }
        }

        // Mock fetch order filters
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadOrdersSettings(_, onCompletion):
                onCompletion(.success(.init(siteID: 123, orderStatusesFilter: nil, dateRangeFilter: nil, productFilter: nil, customerFilter: nil)))
            default:
                break
            }
        }

        // Mock sync order list
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, onCompletion):
                self.storage.insertSampleOrder(readOnlyOrder: Self.sampleOrder)
                onCompletion(0, .success([Self.sampleOrder]))
            default:
                break
            }
        }
    }

    /// Responses when the order does not exists the order list.
    ///
    func mockOrderNotInOrdersList() {
        mockOrderInOrderListResponses()

        // Mock sync order list & single order
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(0, .success([]))
            case let .retrieveOrderRemotely(_, _, onCompletion):
                self.storage.insertSampleOrder(readOnlyOrder: Self.sampleOrder)
                onCompletion(.success(Self.sampleOrder))
            default:
                break
            }
        }
    }
}

// MARK: Sample Objects
private extension PushNotificationBackgroundSynchronizerTests {
    private static let sampleSiteID: Int64 = 123

    private static let sampleNoteID: Int64 = 1234

    private static let sampleOrderType = "store_order"

    private static let sampleOrderID: Int64 = 12345

    static var sampleUserInfo: [String: Any] = [APNSKey.siteID: sampleSiteID,
                                               APNSKey.identifier: sampleNoteID,
                                               APNSKey.aps: [APNSKey.alert: [
                                                APNSKey.alertTitle: ""
                                               ]],
                                               APNSKey.type: sampleOrderType]

    static var sampleNote: Yosemite.Note = {
        let payload: [String: AnyCodable] = [MetaContainer.Containers.ids.rawValue:
                                                [MetaContainer.Keys.site.rawValue: sampleSiteID,
                                                 MetaContainer.Keys.order.rawValue: sampleOrderID]]
        let meta = MetaContainer(payload: payload)
        return Note.fake().copy(noteID: sampleNoteID,
                                kind: .storeOrder,
                                type: sampleOrderType,
                                metaAsData: (try? JSONEncoder().encode(payload)) ?? Data(),
                                meta: meta)
    }()

    static var sampleOrder = Order.fake().copy(siteID: sampleSiteID, orderID: sampleOrderID)
}

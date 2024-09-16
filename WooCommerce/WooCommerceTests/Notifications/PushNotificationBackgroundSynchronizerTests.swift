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
        mockOrderInOrderListResponses(order: Self.sampleOrder)

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
        mockOrderNotInOrdersList(order: Self.sampleOrder)

        // When
        let synchronizer = PushNotificationBackgroundSynchronizer(userInfo: Self.sampleUserInfo, stores: stores, storage: storage.viewStorage)
        let syncResult = await synchronizer.sync()

        // Then
        let storedOrder = storage.viewStorage.loadOrder(siteID: Self.sampleSiteID, orderID: Self.sampleOrderID)
        XCTAssertNotNil(storedOrder)
        XCTAssertEqual(syncResult, .newData)
    }

    @MainActor
    func test_synchronizer_stores_order_notification_when_order_comes_inside_notification() async {
        // Given
        mockOrderNotInOrdersForSampleWithNoteFullData()

        // When
        let synchronizer = PushNotificationBackgroundSynchronizer(userInfo: Self.sampleUserInfoWithNoteFullData, stores: stores, storage: storage.viewStorage)
        let syncResult = await synchronizer.sync()

        // Then
        let storedOrder = storage.viewStorage.loadOrder(siteID: Self.sampleSiteIDFromNotificationWithNoteFullData,
                                                        orderID: Self.sampleOrderIDFromNotificationWithNoteFullData)
        XCTAssertNotNil(storedOrder)
        XCTAssertEqual(syncResult, .newData)
        XCTAssertEqual(storedOrder?.orderID, Self.sampleOrderIDFromNotificationWithNoteFullData)
        XCTAssertEqual(storedOrder?.siteID, Self.sampleSiteIDFromNotificationWithNoteFullData)
    }
}

// MARK: Helpers
private extension PushNotificationBackgroundSynchronizerTests {
    /// Responses when the order exists in the order list
    ///
    func mockOrderInOrderListResponses(order: Networking.Order, synchronizeNotifications: Bool = true) {
        if synchronizeNotifications {
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
        }

        // Mock fetch order filters
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadOrdersSettings(_, onCompletion):
                onCompletion(.success(.init(siteID: order.siteID, orderStatusesFilter: nil, dateRangeFilter: nil, productFilter: nil, customerFilter: nil)))
            default:
                break
            }
        }

        // Mock sync order list
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, onCompletion):
                self.storage.insertSampleOrder(readOnlyOrder: order)
                onCompletion(0, .success([order]))
            default:
                break
            }
        }
    }

    /// Responses when the order does not exists the order list.
    ///
    func mockOrderNotInOrdersList(order: Networking.Order) {
        mockOrderInOrderListResponses(order: order)

        // Mock sync order list & single order
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(0, .success([]))
            case let .retrieveOrderRemotely(_, _, onCompletion):
                self.storage.insertSampleOrder(readOnlyOrder: order)
                onCompletion(.success(order))
            default:
                break
            }
        }
    }

    func mockOrderNotInOrdersForSampleWithNoteFullData() {
        mockOrderInOrderListResponses(order: Self.sampleOrderWithNoteFullDataOrderID, synchronizeNotifications: false)

        // Mock sync order list & single order
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(0, .success([]))
            case let .retrieveOrderRemotely(_, _, onCompletion):
                self.storage.insertSampleOrder(readOnlyOrder: Self.sampleOrderWithNoteFullDataOrderID)
                onCompletion(.success(Self.sampleOrderWithNoteFullDataOrderID))
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

    // Samples with note_full_data
    static var sampleUserInfoWithNoteFullData: [String: Any] = [
        APNSKey.siteID: 205617935,
        APNSKey.identifier: 8300031174,
        APNSKey.aps: [APNSKey.alert: [
            APNSKey.alertTitle: ""
        ]],
        // swiftlint:disable line_length
        APNSKey.noteFullData: "eNqVkc1O6zAQhV/FjNiRH+enTZqHgA0bdI0qN522hsSx4jEFobz7nYRSwZJN7MjnfDpn5hPsQOih+fcJZg9NXUgpiyyrygjowyE04GkYcTuMexwhgmBH1Cy0oesi8NY4h/T92yNpaGaSnw9viAG5XK2zalOsIviCNIVcTxF0xr7+kMGJyPlGpSp1YdeZNtbOJGe2uBG9T9qhVynfSKVvmUpnk1fpFQ5X+h9Bi4tJHAomjuVJU/DXgmH3gi0t8yF85ws8DUGc9BsKLSyexeK/ESrs66Ll76HewBRd1fffEnEYRnGbJ1KKwQo6oVgGC9MzT9r0nEf3jg25zMtYVnG+fswkj6opizspGylh1lGHF+jDZSGmHeyv0j45u6+SZxfzI6Hlqn2IXReOxnLVZeUqNb0+zmdwe00YO/3RszTO3xNnj0xm2QWuwqEsqyVqpz1tPaLdzqH5Lavysi7qzaqYLaHfzTvIpv+sG8QM",
        APNSKey.type: sampleOrderType
    ]
    static let sampleSiteIDFromNotificationWithNoteFullData: Int64 = 205617935
    static let sampleOrderIDFromNotificationWithNoteFullData: Int64 = 306
    static var sampleOrderWithNoteFullDataOrderID = Order.fake().copy(siteID: sampleSiteIDFromNotificationWithNoteFullData,
                                                                      orderID: sampleOrderIDFromNotificationWithNoteFullData)
}

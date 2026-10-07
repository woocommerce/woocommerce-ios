import Testing
import UIKit
import YosemiteTestHelpers
import Yosemite
import Storage
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct OrderListViewControllerTests {
    @Test
    func test_restoreSelectedOrderDetails_when_second_order_is_selected_then_recreates_its_detail() async throws {
        // Given
        let siteID: Int64 = 3932
        let firstOrder = MockOrders().empty().copy(siteID: siteID, orderID: 1, status: .processing, dateCreated: Date())
        let selectedOrder = firstOrder.copy(orderID: 2, dateCreated: Date().addingTimeInterval(-60))
        let sessionID = "orderSelectionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: sessionID))
        defer { defaults.removePersistentDomain(forName: sessionID) }
        let session = SessionManager(defaults: defaults, keychainServiceName: sessionID)
        let stores = MockStoresManager(sessionManager: session)
        let storageManager = MockStorageManager()
        await withCheckedContinuation { continuation in
            storageManager.performAndSave({ storage in
                for order in [firstOrder, selectedOrder] {
                    let stored = storage.insertNewObject(ofType: StorageOrder.self)
                    stored.update(with: order)
                }
            }, completion: { continuation.resume() }, on: .main)
        }
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, storageManager: storageManager, filters: nil)
        var shownOrderIDs: [Int64] = []
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     stores: stores,
                                                     switchDetailsHandler: { viewModels, index, _, completion in
            if let viewModel = viewModels[safe: index] {
                shownOrderIDs.append(viewModel.order.orderID)
                completion?(true)
            } else {
                completion?(false)
            }
        })
        viewController.loadViewIfNeeded()
        try #require(viewController.firstAvailableOrder?.orderID == firstOrder.orderID)
        viewController.showOrderDetails(selectedOrder)
        #expect(shownOrderIDs == [selectedOrder.orderID])
        shownOrderIDs.removeAll()

        // When
        viewController.restoreSelectedOrderDetails()

        // Then
        #expect(shownOrderIDs == [selectedOrder.orderID])
    }

    @Test func empty_state_when_store_previously_qualified_for_test_order_then_uses_first_order_empty_state() throws {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: siteID, statusKey: "publish"))
        storageManager.insertSamplePaymentGateway(readOnlyGateway: PaymentGateway.fake().copy(siteID: siteID, enabled: true))
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     stores: stores,
                                                     switchDetailsHandler: { _, _, _, _ in })

        // When
        viewController.loadViewIfNeeded()

        // Then
        let emptyStateView = try #require(viewController.tableView.tableFooterView as? ListEmptyView)
        let mirror = try mirror(of: emptyStateView)

        #expect(mirror.messageLabel.attributedText == NSAttributedString(string: "Waiting for your first order"))
        #expect(mirror.imageView.image == .boxesImage)
        #expect(mirror.detailsLabel.text == "Explore how you can increase your store sales.")
        #expect(mirror.actionButton.titleLabel?.text == "Learn more")
    }

    @Test
    func test_sync_when_loading_fails_then_reuses_the_same_table_and_refresh_control() async throws {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        let storageManager = MockStorageManager()
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, storageManager: storageManager, filters: nil)
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     stores: stores,
                                                     switchDetailsHandler: { _, _, _, _ in })
        var completeSync: ((TimeInterval, Result<[Yosemite.Order], Error>) -> Void)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, _, onCompletion) = action else { return }
            completeSync = onCompletion
        }
        viewController.loadViewIfNeeded()
        let tableView = try #require(viewController.tableView)
        let refreshControl = try #require(tableView.refreshControl)
        let originalSyncDate = OrderListSyncBackgroundTask.latestSyncDate
        defer { OrderListSyncBackgroundTask.latestSyncDate = originalSyncDate }

        // When: loading an empty list
        viewController.sync(pageNumber: 1, pageSize: 25, retryTimeout: false)

        // Then: placeholders are rows in the same table, with no overlay scroll view
        #expect(tableView.numberOfRows(inSection: 0) == 3)
        #expect(viewController.firstAvailableOrder == nil)
        let firstRow = IndexPath(row: 0, section: 0)
        let loadingCell = try #require(tableView.dataSource?.tableView(tableView, cellForRowAt: firstRow))
        #expect(loadingCell is OrderTableViewCell)
        #expect(loadingCell.accessibilityIdentifier == nil)
        #expect(!loadingCell.isUserInteractionEnabled)
        #expect(viewController.tableView(tableView, willSelectRowAt: IndexPath(row: 0, section: 0)) == nil)
        #expect(viewController.tableView(tableView, canFocusRowAt: IndexPath(row: 0, section: 0)) == false)
        #expect(viewController.children.isEmpty)
        #expect(viewController.tableView === tableView)
        #expect(tableView.refreshControl === refreshControl)
        #expect(viewController.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0)) == nil)

        // When: synchronization fails
        let failSync = try #require(completeSync)
        failSync(0, .failure(URLError(.notConnectedToInternet)))

        // Then: the error and empty content belong to that table
        #expect(tableView.tableHeaderView?.subviews.contains { $0 is TopBannerView } == true)
        #expect(tableView.tableFooterView is ListEmptyView)
        #expect(viewController.children.isEmpty)
        #expect(tableView.refreshControl === refreshControl)

        // When: retry loads an order
        viewController.sync(pageNumber: 1, pageSize: 25, retryTimeout: false)
        let order = MockOrders().empty().copy(siteID: siteID, orderID: 1, status: .processing, dateCreated: Date())
        try await insert([order], into: storageManager)
        let finishRetry = try #require(completeSync)
        finishRetry(0, .success([order]))

        // Then: results replace placeholders without replacing the scroll view or refresh control
        #expect(tableView.numberOfRows(inSection: 0) == 1)
        #expect(viewController.firstAvailableOrder?.orderID == order.orderID)
        let orderCell = try #require(tableView.dataSource?.tableView(tableView, cellForRowAt: firstRow))
        #expect(orderCell.reuseIdentifier != loadingCell.reuseIdentifier)
        #expect(orderCell.isUserInteractionEnabled)
        #expect(tableView.tableFooterView is FooterSpinnerView)
        #expect(viewController.children.isEmpty)
        #expect(viewController.tableView === tableView)
        #expect(tableView.refreshControl === refreshControl)
    }

    @Test func foreground_order_notification_when_orders_are_hidden_then_synchronizes_first_page() async throws {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        let storageManager = MockStorageManager()
        let pushNotificationsManager = MockPushNotificationsManager()
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           pushNotificationsManager: pushNotificationsManager,
                                           pushNotificationSyncInterval: .milliseconds(1),
                                           filters: nil)
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     stores: stores,
                                                     switchDetailsHandler: { _, _, _, _ in })
        var synchronizedSiteID: Int64?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .fetchFilteredOrders(siteID, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            synchronizedSiteID = siteID
            onCompletion(0, .success([]))
        }
        viewController.loadViewIfNeeded()
        let originalSyncDate = OrderListSyncBackgroundTask.latestSyncDate
        defer { OrderListSyncBackgroundTask.latestSyncDate = originalSyncDate }
        OrderListSyncBackgroundTask.latestSyncDate = Date()

        // When
        let notification = WooCommerce.PushNotification(noteID: 1,
                                                        siteID: siteID,
                                                        kind: .storeOrder,
                                                        title: "",
                                                        subtitle: "",
                                                        message: "",
                                                        note: nil,
                                                        meta: nil)
        pushNotificationsManager.sendForegroundNotification(notification)

        // Then
        // The resynchronization is debounced, so give the scheduler a chance to deliver it.
        try await Task.sleep(for: .milliseconds(200))
        #expect(viewController.view.window == nil)
        #expect(synchronizedSiteID == siteID)
    }
}

private extension OrderListViewControllerTests {
    func insert(_ orders: [Yosemite.Order], into storageManager: MockStorageManager) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storageManager.performAndSave({ storage in
                let storedOrders = orders.map { order in
                    let stored = storage.insertNewObject(ofType: StorageOrder.self)
                    stored.update(with: order)
                    return stored
                }
                try storage.obtainPermanentIDs(for: storedOrders)
            }, completion: { continuation.resume(with: $0) }, on: .main)
        }
    }

    struct ListEmptyViewMirror {
        let messageLabel: UILabel
        let imageView: UIImageView
        let detailsLabel: UILabel
        let actionButton: UIButton
    }

    func mirror(of view: ListEmptyView) throws -> ListEmptyViewMirror {
        let mirror = Mirror(reflecting: view)

        return ListEmptyViewMirror(
            messageLabel: try #require(mirror.descendant("messageLabel") as? UILabel),
            imageView: try #require(mirror.descendant("imageView") as? UIImageView),
            detailsLabel: try #require(mirror.descendant("detailsLabel") as? UILabel),
            actionButton: try #require(mirror.descendant("actionButton") as? UIButton)
        )
    }
}

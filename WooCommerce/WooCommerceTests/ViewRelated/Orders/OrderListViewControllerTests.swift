import Testing
import UIKit
import YosemiteTestHelpers
import Yosemite
import Storage
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct OrderListViewControllerTests {
    @Test(arguments: [false, true])
    func test_order_cell_when_design_system_flag_changes_then_uses_expected_cell_type(usesStoreDesignSystem: Bool) async throws {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let storageManager = MockStorageManager()
        let order = MockOrders().empty().copy(siteID: siteID, orderID: 1, number: "1", status: .processing, dateCreated: .now)
        try await insert([order], into: storageManager)
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     usesStoreDesignSystem: usesStoreDesignSystem,
                                                     stores: stores,
                                                     switchDetailsHandler: { _, _, _, _ in })

        // When
        viewController.loadViewIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = try #require(viewController.tableView.dataSource?.tableView(viewController.tableView,
                                                                               cellForRowAt: indexPath))

        // Then
        #expect((cell is StoreOrderListTableViewCell) == usesStoreDesignSystem)
        #expect((cell is OrderTableViewCell) != usesStoreDesignSystem)
        #expect(cell.accessibilityIdentifier == "#1 Guest")
        let header = viewController.tableView(viewController.tableView, viewForHeaderInSection: 0)
        #expect((header is StoreOrderListSectionHeaderView) == usesStoreDesignSystem)
        #expect((header is TwoColumnSectionHeaderView) != usesStoreDesignSystem)
        #expect((viewController.tableView.tableHeaderView is StoreOrderListHeaderView) == false)
        #expect((viewController.storeHeaderView.state != nil) == usesStoreDesignSystem)
    }

    @Test
    func test_store_header_when_filters_timestamp_and_banner_change_then_updates_state() throws {
        // Given
        let originalSyncDate = OrderListSyncBackgroundTask.latestSyncDate
        defer { OrderListSyncBackgroundTask.latestSyncDate = originalSyncDate }
        let syncDate = Date(timeIntervalSinceReferenceDate: 700_000_000)
        OrderListSyncBackgroundTask.latestSyncDate = syncDate
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: MockStorageManager(),
                                           filters: nil)
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     usesStoreDesignSystem: true,
                                                     stores: stores,
                                                     switchDetailsHandler: { _, _, _, _ in })
        viewController.loadViewIfNeeded()
        let header = viewController.storeHeaderView
        let dateFormatter = syncDate.isSameDay(as: Date.now) ? DateFormatter.timeFormatter : DateFormatter.dateAndTimeFormatter
        let expectedLastUpdatedText = OrderListLocalization.lastUpdatedText(time: dateFormatter.string(from: syncDate))
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: nil,
                                                       product: nil,
                                                       customer: nil,
                                                       salesChannel: .pointOfSale,
                                                       numberOfActiveFilters: 2)

        // When: filters change
        viewController.updateFilters(filters)

        // Then: filter and timestamp content are refreshed in the existing hosted header
        #expect(viewModel.filters == filters)
        #expect(header.state?.activeFilterCount == 2)
        #expect(header.state?.title == OrderListLocalization.filteredOrdersHeaderTitle)
        #expect(header.state?.filterButtonTitle == OrderListLocalization.filterButtonTitle(activeFilterCount: 2))
        #expect(header.state?.lastUpdatedText == expectedLastUpdatedText)

        // When: an error banner appears
        viewModel.dataLoadingError = URLError(.notConnectedToInternet)

        // Then: the same header reflects the banner state
        let banner = try #require(header.state?.banner)
        guard case let .error(title, message) = banner else {
            Issue.record("Expected an error notice in the hosted order-list header")
            return
        }
        let expectedError = ErrorTopBannerFactory.ErrorType(error: URLError(.notConnectedToInternet))
        #expect(title == expectedError.title)
        #expect(message == expectedError.info)
    }

    @Test
    func test_store_error_banner_when_toggled_then_collapses_and_expands() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = OrderListViewModel(siteID: 123,
                                           stores: stores,
                                           storageManager: MockStorageManager(),
                                           filters: nil)
        let viewController = OrderListViewController(siteID: 123,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     usesStoreDesignSystem: true,
                                                     stores: stores,
                                                     switchDetailsHandler: { _, _, _, _ in })
        viewController.loadViewIfNeeded()
        viewModel.dataLoadingError = URLError(.notConnectedToInternet)

        // When: the banner is tapped
        viewController.toggleStoreBannerExpansion()

        // Then: the banner is collapsed
        #expect(viewController.storeHeaderView.state?.isBannerExpanded == false)
        #expect(viewController.storeHeaderView.state?.bannerAccessibilityValue == OrderListLocalization.collapsedAccessibilityValue)
        #expect(viewController.storeHeaderView.state?.bannerAccessibilityHint == OrderListLocalization.expandAccessibilityHint)

        // When: the banner is tapped again
        viewController.toggleStoreBannerExpansion()

        // Then: the banner is expanded
        #expect(viewController.storeHeaderView.state?.isBannerExpanded == true)
        #expect(viewController.storeHeaderView.state?.bannerAccessibilityValue == OrderListLocalization.expandedAccessibilityValue)
        #expect(viewController.storeHeaderView.state?.bannerAccessibilityHint == OrderListLocalization.collapseAccessibilityHint)
    }

    @Test
    func test_store_order_cell_when_selected_or_highlighted_then_uses_selected_appearance() {
        // Given
        let order = MockOrders().empty().copy(orderID: 1, status: .processing, dateCreated: .now)
        let viewModel = OrderListCellViewModel(order: order, currencySettings: .init())
        let cell = StoreOrderListTableViewCell(style: .default,
                                               reuseIdentifier: StoreOrderListTableViewCell.reuseIdentifier)
        cell.configure(viewModel: viewModel)

        // When / Then
        cell.setSelected(true, animated: false)
        cell.updateConfiguration(using: cell.configurationState)
        #expect(cell.usesSelectedAppearance)

        cell.setSelected(false, animated: false)
        cell.setHighlighted(true, animated: false)
        cell.updateConfiguration(using: cell.configurationState)
        #expect(cell.usesSelectedAppearance)
    }

    @Test
    func test_store_order_cell_when_used_as_search_result_then_registers_and_configures_the_cell() throws {
        // Given
        let order = MockOrders().empty().copy(orderID: 1, number: "1", status: .processing, dateCreated: .now)
        let viewModel = OrderListCellViewModel(order: order, currencySettings: .init())
        let tableView = UITableView()
        StoreOrderListTableViewCell.register(for: tableView)

        // When
        let cell = try #require(tableView.dequeueReusableCell(withIdentifier: StoreOrderListTableViewCell.reuseIdentifier)
                                as? StoreOrderListTableViewCell)
        cell.configureCell(searchModel: viewModel)

        // Then
        #expect(cell.accessibilityIdentifier == "#1 Guest")
    }

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

    @Test(arguments: [false, true])
    func empty_state_when_store_previously_qualified_for_test_order_then_uses_first_order_empty_state(usesStoreDesignSystem: Bool) throws {
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
                                                     usesStoreDesignSystem: usesStoreDesignSystem,
                                                     stores: stores,
                                                     switchDetailsHandler: { _, _, _, _ in })

        // When
        viewController.loadViewIfNeeded()

        // Then
        if usesStoreDesignSystem {
            #expect(viewController.tableView.tableFooterView is StoreOrderListFooterView)
            return
        }

        let emptyStateView = try #require(viewController.tableView.tableFooterView as? ListEmptyView)
        let mirror = try mirror(of: emptyStateView)

        #expect(mirror.messageLabel.attributedText == NSAttributedString(string: "Waiting for your first order"))
        #expect(mirror.imageView.image == .boxesImage)
        #expect(mirror.detailsLabel.text == "Explore how you can increase your store sales.")
        #expect(mirror.actionButton.titleLabel?.text == "Learn more")
    }

    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func test_sync_when_loading_fails_then_reuses_the_same_table_and_refresh_control(usesStoreDesignSystem: Bool) async throws {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        let storageManager = MockStorageManager()
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, storageManager: storageManager, filters: nil)
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     usesStoreDesignSystem: usesStoreDesignSystem,
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

        let syncResults = AsyncStream<Bool>.makeStream()
        defer { syncResults.continuation.finish() }
        var syncResultIterator = syncResults.stream.makeAsyncIterator()

        // When: loading an empty list
        viewController.sync(pageNumber: 1, pageSize: 25, retryTimeout: false) {
            syncResults.continuation.yield($0)
        }

        // Then: placeholders are rows in the same table, with no overlay scroll view
        #expect(tableView.numberOfRows(inSection: 0) == 3)
        #expect(viewController.firstAvailableOrder == nil)
        let firstRow = IndexPath(row: 0, section: 0)
        let loadingCell = try #require(tableView.dataSource?.tableView(tableView, cellForRowAt: firstRow))
        #expect((loadingCell is StoreOrderListTableViewCell) == usesStoreDesignSystem)
        #expect((loadingCell is OrderTableViewCell) != usesStoreDesignSystem)
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
        let failedSyncSucceeded = await syncResultIterator.next()

        // Then: the error and empty content belong to that table
        #expect(failedSyncSucceeded == false)
        if usesStoreDesignSystem {
            let banner = try #require(viewController.storeHeaderView.state?.banner)
            guard case .error = banner else {
                Issue.record("Expected an error notice in the hosted order-list header")
                return
            }
        } else {
            #expect(tableView.tableHeaderView?.subviews.contains { $0 is TopBannerView } == true)
        }
        #expect((tableView.tableFooterView is StoreOrderListFooterView) == usesStoreDesignSystem)
        #expect((tableView.tableFooterView is ListEmptyView) != usesStoreDesignSystem)
        #expect(viewController.children.isEmpty)
        #expect(tableView.refreshControl === refreshControl)

        // When: retry loads an order
        viewController.sync(pageNumber: 1, pageSize: 25, retryTimeout: false) {
            syncResults.continuation.yield($0)
        }
        let order = MockOrders().empty().copy(siteID: siteID, orderID: 1, status: .processing, dateCreated: Date())
        try await insert([order], into: storageManager)
        let finishRetry = try #require(completeSync)
        finishRetry(0, .success([order]))
        let retrySucceeded = await syncResultIterator.next()

        // Then: results replace placeholders without replacing the scroll view or refresh control
        #expect(retrySucceeded == true)
        #expect(tableView.numberOfRows(inSection: 0) == 1)
        #expect(viewController.firstAvailableOrder?.orderID == order.orderID)
        let orderCell = try #require(tableView.dataSource?.tableView(tableView, cellForRowAt: firstRow))
        #expect((orderCell.reuseIdentifier == loadingCell.reuseIdentifier) == usesStoreDesignSystem)
        #expect(orderCell.isUserInteractionEnabled)
        #expect((tableView.tableFooterView is StoreOrderListFooterView) == usesStoreDesignSystem)
        #expect((tableView.tableFooterView is FooterSpinnerView) != usesStoreDesignSystem)
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

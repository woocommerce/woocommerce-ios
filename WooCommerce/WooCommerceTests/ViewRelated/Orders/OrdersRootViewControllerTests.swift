import Foundation
import Testing
import Storage
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct OrdersRootViewControllerTests {
    @Test
    func test_order_list_when_store_design_system_is_enabled_then_uses_store_order_list() {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.storeDesignSystem] = true

        // When
        let sut = makeSUT(featureFlagService: featureFlagService)

        // Then
        #expect(sut.ordersViewController.viewController is StoreOrderListHostingController)
    }

    @Test
    func test_order_list_when_store_design_system_is_disabled_then_uses_legacy_order_list() {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.storeDesignSystem] = false

        // When
        let sut = makeSUT(featureFlagService: featureFlagService)

        // Then
        #expect(sut.ordersViewController.viewController is OrderListViewController)
    }

    @Test
    func test_store_order_list_when_selected_order_is_restored_then_recreates_its_detail() async throws {
        // Given
        let siteID: Int64 = 3932
        let firstOrder = MockOrders().empty().copy(siteID: siteID, orderID: 1, status: .processing, dateCreated: Date())
        let selectedOrder = firstOrder.copy(orderID: 2, dateCreated: Date().addingTimeInterval(-60))
        let sessionID = "storeOrderSelectionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: sessionID))
        defer { defaults.removePersistentDomain(forName: sessionID) }
        let stores = MockStoresManager(sessionManager: SessionManager(defaults: defaults, keychainServiceName: sessionID))
        let storageManager = MockStorageManager()
        try await insert([firstOrder, selectedOrder], into: storageManager)
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, storageManager: storageManager, filters: nil)
        var shownOrderIDs: [Int64] = []
        let sut = StoreOrderListHostingController(siteID: siteID,
                                                  viewModel: viewModel,
                                                  stores: stores,
                                                  switchDetailsHandler: { viewModels, index, _, completion in
            shownOrderIDs.append(contentsOf: viewModels[safe: index].map { [$0.order.orderID] } ?? [])
            completion?(true)
        })
        sut.loadViewIfNeeded()
        try #require(sut.selectOrderFromListIfPossible(for: selectedOrder.orderID, isTriggeredByUserAction: true))
        #expect(shownOrderIDs == [selectedOrder.orderID])
        shownOrderIDs.removeAll()

        // When
        sut.restoreSelectedOrderDetails()

        // Then
        #expect(shownOrderIDs == [selectedOrder.orderID])
    }
}

private extension OrdersRootViewControllerTests {
    func makeSUT(featureFlagService: MockFeatureFlagService) -> OrdersRootViewController {
        OrdersRootViewController(siteID: 123,
                                 featureFlagService: featureFlagService,
                                 switchDetailsHandler: { _, _, _, _ in })
    }

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
}

import Foundation
import XCTest
import TestKit
import Yosemite
import ViewControllerPresentationSpy

import YosemiteTestHelpers
@testable import WooCommerce

final class OrderDetailsViewControllerTests: XCTestCase {
    @MainActor
    func test_products_cell_is_not_visible_on_order_with_no_items() throws {
        // Given
        let storageManager = MockStorageManager()
        let order = MockOrders().sampleOrder()
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: order)

        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        let viewController = OrderDetailsViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewController.viewWillAppear(false)

        // Then
        let mirror = try Self.mirror(of: viewController)
        let tuple = Self.findCell(type: ProductDetailsTableViewCell.self, on: mirror.tableView)

        XCTAssertNil(tuple)
    }

    @MainActor
    func test_products_cell_is_visible_on_order_with_items() throws {
        // Given
        let storageManager = MockStorageManager()
        let order = MockOrders().sampleOrderWithItems()
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: order)

        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        let viewController = OrderDetailsViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewController.viewWillAppear(false)
        viewModel.reloadSections()

        // Then
        let mirror = try Self.mirror(of: viewController)
        let tuple = Self.findCell(type: ProductDetailsTableViewCell.self, on: mirror.tableView)

        XCTAssertNotNil(tuple?.cell)
    }

    @MainActor
    func test_tapping_products_cell_presents_product_loader() throws {
        // Given
        let presentationVerifier = PresentationVerifier()
        let storageManager = MockStorageManager()
        let order = MockOrders().sampleOrderWithItems()
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: order)

        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        let viewController = OrderDetailsViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewController.viewWillAppear(false)
        viewModel.reloadSections()

        let mirror = try Self.mirror(of: viewController)
        let (_, indexPath) = try XCTUnwrap(Self.findCell(type: ProductDetailsTableViewCell.self, on: mirror.tableView))
        viewController.tableView(mirror.tableView, didSelectRowAt: indexPath)

        // Then
        let presentedNav: UINavigationController? = presentationVerifier.verify(animated: true, presentingViewController: viewController)
        let presentedVC = try XCTUnwrap(presentedNav?.topViewController)
        XCTAssertTrue(presentedVC is ProductLoaderViewController)
    }

    @MainActor
    func test_edit_order_button_is_visible_and_navigates_to_edit_order_screen_when_order_synced() throws {
        // Given
        let presentationVerifier = PresentationVerifier()
        let storageManager = MockStorageManager()
        let order = MockOrders().sampleOrder()
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: order)

        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              syncStateController: OrderDetailsSyncStateController(syncState: .synced))
        let viewController = OrderDetailsViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let editItem = try XCTUnwrap(viewController.navigationItem.rightBarButtonItem)
        Self.performActionOf(item: editItem)

        // Then
        switch presentationVerifier.presentedViewController {
        case is OrderFormHostingController:
            break //Success
        case let navController as UINavigationController:
            XCTAssertTrue(navController.topViewController is OrderFormHostingController)
        default:
            XCTFail("Expected OrderFormHostingController to be presented, got: \(String(describing: presentationVerifier.presentedViewController))")
        }
    }

    @MainActor
    func test_issue_refund_when_order_has_applied_gift_card_then_presents_unsupported_alert() throws {
        // Given
        let presentationVerifier = PresentationVerifier()
        let storageManager = MockStorageManager()
        let giftCard = OrderGiftCard(giftCardID: 1, code: "ABCD-1234", amount: 10)
        let order = MockOrders().sampleOrder().copy(appliedGiftCards: [giftCard])
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: order)
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        let viewController = OrderDetailsViewController(viewModel: viewModel)
        _ = try XCTUnwrap(viewController.view)
        viewController.viewWillAppear(false)
        viewModel.reloadSections()
        let mirror = try Self.mirror(of: viewController)
        let cell = try XCTUnwrap(Self.findCell(type: IssueRefundTableViewCell.self, on: mirror.tableView)?.cell)

        // When
        cell.issueRefundWasPressed()

        // Then
        let alert: UIAlertController? = presentationVerifier.verify(animated: true, presentingViewController: viewController)
        XCTAssertEqual(alert?.title, "Refund from your store admin")
        XCTAssertEqual(alert?.message,
                       "This order was paid with a gift card. Refunding here won’t restore the gift-card balance. " +
                       "To refund correctly, please process it from your store admin on the web.")
        XCTAssertEqual(alert?.actions.map(\.title), ["OK"])
    }

    @MainActor
    func test_issue_refund_when_order_has_no_applied_gift_cards_then_presents_refund_flow() throws {
        // Given
        let presentationVerifier = PresentationVerifier()
        let storageManager = MockStorageManager()
        let order = MockOrders().sampleOrder().copy(appliedGiftCards: [])
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: order)
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        let viewController = OrderDetailsViewController(viewModel: viewModel)
        _ = try XCTUnwrap(viewController.view)
        viewController.viewWillAppear(false)
        viewModel.reloadSections()
        let mirror = try Self.mirror(of: viewController)
        let cell = try XCTUnwrap(Self.findCell(type: IssueRefundTableViewCell.self, on: mirror.tableView)?.cell)

        // When
        cell.issueRefundWasPressed()

        // Then
        let refundFlow: IssueRefundCoordinatingController? = presentationVerifier.verify(animated: true, presentingViewController: viewController)
        XCTAssertNotNil(refundFlow)
    }
    @MainActor
    func test_loading_when_order_appears_again_then_syncs_without_showing_banner() async throws {
        // Given
        let order = Order.fake()
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: order)
        let originalStores = ServiceLocator.stores
        ServiceLocator.setStores(storesManager)
        defer { ServiceLocator.setStores(originalStores) }
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: MockStorageManager(),
                                              receiptEligibilityUseCase: MockReceiptEligibilityUseCase())
        let viewController = OrderDetailsViewController(viewModel: viewModel)
        viewController.loadViewIfNeeded()
        viewController.viewWillAppear(false)
        await until { try Self.mirror(of: viewController).topLoaderView.isHidden }
        var finishSync: ((Order?, Error?) -> Void)?
        storesManager.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .retrieveOrder(_, _, onCompletion) = action {
                finishSync = onCompletion
            }
        }

        // When
        viewController.viewWillAppear(false)

        // Then
        XCTAssertNotNil(finishSync)
        XCTAssertTrue(try Self.mirror(of: viewController).topLoaderView.isHidden)
        try XCTUnwrap(finishSync)(order, nil)
    }

    @MainActor
    func test_loading_when_initial_sync_finishes_first_then_keeps_banner_until_payment_refresh_finishes() async throws {
        try await verifyLoadingDuringOverlappingSyncs(paymentFinishesFirst: false)
    }

    @MainActor
    func test_loading_when_payment_refresh_finishes_first_then_keeps_banner_until_initial_sync_finishes() async throws {
        try await verifyLoadingDuringOverlappingSyncs(paymentFinishesFirst: true)
    }
}

// MARK: - Mirroring

private extension OrderDetailsViewControllerTests {
    struct OrderDetailsViewControllerMirror {
        let tableView: UITableView
        let topLoaderView: TopLoaderView
        let activeTopLoaderRequests: Int
    }

    static func mirror(of viewController: OrderDetailsViewController) throws -> OrderDetailsViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)
        return OrderDetailsViewControllerMirror(
            tableView: try XCTUnwrap(mirror.descendant("tableView") as? UITableView),
            topLoaderView: try XCTUnwrap(mirror.descendant("topLoaderView") as? TopLoaderView),
            activeTopLoaderRequests: try XCTUnwrap(mirror.descendant("activeTopLoaderRequests") as? Int)
        )
    }
}


// MARK: - Helpers

private extension OrderDetailsViewControllerTests {
    @MainActor
    func verifyLoadingDuringOverlappingSyncs(paymentFinishesFirst: Bool) async throws {
        // Given
        let unpaidOrder = Order.fake().copy(status: .pending, datePaid: .some(nil))
        let paidOrder = unpaidOrder.copy(status: .completed, datePaid: .some(Date()))
        let storesManager = OrderDetailStoreManagerFactory.createManager(order: unpaidOrder)
        let originalStores = ServiceLocator.stores
        ServiceLocator.setStores(storesManager)
        defer { ServiceLocator.setStores(originalStores) }
        var finishInitialSync: ((Order?, Error?) -> Void)?
        storesManager.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .retrieveOrder(_, _, onCompletion) = action {
                finishInitialSync = onCompletion
            }
        }
        let viewModel = OrderDetailsViewModel(order: unpaidOrder,
                                              stores: storesManager,
                                              storageManager: MockStorageManager(),
                                              receiptEligibilityUseCase: MockReceiptEligibilityUseCase())
        let viewController = OrderDetailsViewController(viewModel: viewModel)
        viewController.loadViewIfNeeded()
        viewController.viewWillAppear(false)
        let paymentMethods = PaymentMethodsHostingController(viewModel: viewModel.paymentMethodsViewModel)
        viewController.showOrderRefreshing(during: paymentMethods)
        let (orders, continuation) = AsyncStream<Order>.makeStream()
        let paymentRefresh = Task<Order?, Never> {
            for await order in orders { return order }
            return nil
        }
        paymentMethods.rootView.viewModel.onPaymentOrderRefreshStarted?(paymentRefresh)
        XCTAssertEqual(try Self.mirror(of: viewController).activeTopLoaderRequests, 2)

        // When
        if paymentFinishesFirst {
            continuation.yield(paidOrder)
            continuation.finish()
        } else {
            try XCTUnwrap(finishInitialSync)(unpaidOrder, nil)
        }
        await until { try Self.mirror(of: viewController).activeTopLoaderRequests == 1 }

        // Then
        XCTAssertFalse(try Self.mirror(of: viewController).topLoaderView.isHidden)

        // When
        if paymentFinishesFirst {
            try XCTUnwrap(finishInitialSync)(paidOrder, nil)
        } else {
            continuation.yield(paidOrder)
            continuation.finish()
        }
        await until { try Self.mirror(of: viewController).topLoaderView.isHidden }

        // Then
        XCTAssertEqual(try Self.mirror(of: viewController).activeTopLoaderRequests, 0)
        XCTAssertFalse(viewModel.dataSource.isWaitingForPaidOrder)
    }

    static func findCell<T>(type: T.Type, on tableView: UITableView) -> (cell: T, indexPath: IndexPath)? {
        for section in (0..<tableView.numberOfSections) {
            for row in (0..<tableView.numberOfRows(inSection: section)) {

                let ip = IndexPath(row: row, section: section)
                if let cell = tableView.cellForRow(at: ip) as? T {
                    return (cell, ip)
                }
            }
        }
        return nil
    }

    static func performActionOf(item: UIBarButtonItem) {
        guard let target = item.target, let action = item.action else {
            return
        }
        target.performSelector(onMainThread: action, with: nil, waitUntilDone: true)
    }
}

/// Helper that properly provide stubs needed for  `OrderDetailsViewModel`
///
private struct OrderDetailStoreManagerFactory {

    static func createManager(order: Order) -> MockStoresManager {
        let storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())

        storesManager.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .retrieveOrder(_, _, onCompletion):
                onCompletion(order, nil)
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .requestMissingProducts(_, onCompletion):
                onCompletion(nil)
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .requestMissingVariations(_, onCompletion):
                onCompletion(nil)
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: RefundAction.self) { action in
            switch action {
            case let .retrieveRefunds(_, _, _, _, onCompletion):
                onCompletion(nil)
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: SubscriptionAction.self) { action in
            switch action {
            case let .loadSubscriptions(_, onCompletion):
                onCompletion(.success([]))
            }
        }

        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .synchronizeShippingLabels(_, _, onCompletion):
                onCompletion(.success([]))
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: OrderNoteAction.self) { action in
            switch action {
            case let .retrieveOrderNotes(_, _, onCompletion):
                onCompletion([], nil)
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: ShipmentAction.self) { action in
            switch action {
            case let .synchronizeShipmentTrackingData(_, _, onCompletion):
                onCompletion(nil)
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            if case let .fetchSystemPluginWithPath(_, _, onCompletion) = action {
                onCompletion(nil)
            }
        }

        storesManager.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .isRemoteFeatureFlagEnabled(_, defaultValue, _, onCompletion) = action {
                onCompletion(defaultValue)
            }
        }

        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadOrderAddOnsSwitchState(onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        storesManager.whenReceivingAction(ofType: ShippingMethodAction.self) { action in
            switch action {
            case let .synchronizeShippingMethods(_, onCompletion):
                onCompletion(.success(()))
            }
        }

        return storesManager
    }
}

import Testing
import UIKit
import YosemiteTestHelpers
import Yosemite
import Storage
@testable import WooCommerce

@MainActor
struct OrderListViewControllerTests {
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
        let emptyStateViewController = try #require(
            viewController.children.compactMap { $0 as? EmptyStateViewController }.first
        )
        let mirror = try mirror(of: emptyStateViewController)

        #expect(mirror.messageLabel.attributedText == NSAttributedString(string: "Waiting for your first order"))
        #expect(mirror.imageView.image == .boxesImage)
        #expect(mirror.detailsLabel.text == "Explore how you can increase your store sales.")
        #expect(mirror.actionButton.titleLabel?.text == "Learn more")
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
    struct EmptyStateViewControllerMirror {
        let messageLabel: UILabel
        let imageView: UIImageView
        let detailsLabel: UILabel
        let actionButton: UIButton
    }

    func mirror(of viewController: EmptyStateViewController) throws -> EmptyStateViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)

        return EmptyStateViewControllerMirror(
            messageLabel: try #require(mirror.descendant("messageLabel") as? UILabel),
            imageView: try #require(mirror.descendant("imageView") as? UIImageView),
            detailsLabel: try #require(mirror.descendant("detailsLabel") as? UILabel),
            actionButton: try #require(mirror.descendant("actionButton") as? UIButton)
        )
    }
}

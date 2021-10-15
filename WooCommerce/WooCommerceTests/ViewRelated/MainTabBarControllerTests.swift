import TestKit
import XCTest
@testable import WooCommerce
import Yosemite

final class MainTabBarControllerTests: XCTestCase {
    private var stores: StoresManager!
    private var tabBarController: MainTabBarController!

    override func setUp() {
        super.setUp()
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        stores = DefaultStoresManager.testingInstance
        ServiceLocator.setStores(stores)
        tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController
    }

    override func tearDown() {
        SessionManager.testingInstance.reset()
        tabBarController = nil
        stores = nil
        super.tearDown()
    }

    func test_tab_view_controllers_are_not_empty_after_updating_default_site() {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat(tabBarController.tabNavigationController(tab: .myStore)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .orders)?.topViewController,
                   isAnInstanceOf: OrdersRootViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .products)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .reviews)?.topViewController,
                   isAnInstanceOf: ReviewsViewController.self)
    }

    func test_tab_root_viewControllers_are_replaced_after_updating_to_a_different_site() throws {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        let viewControllersBeforeSiteChange = tabBarController.tabRootViewControllers
        stores.updateDefaultStore(storeID: 630)
        let viewControllersAfterSiteChange = tabBarController.tabRootViewControllers

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange.count, viewControllersAfterSiteChange.count)
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.myStore.visibleIndex()], viewControllersAfterSiteChange[WooTab.myStore.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.orders.visibleIndex()], viewControllersAfterSiteChange[WooTab.orders.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.products.visibleIndex()], viewControllersAfterSiteChange[WooTab.products.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.reviews.visibleIndex()], viewControllersAfterSiteChange[WooTab.reviews.visibleIndex()])
    }

    func test_tab_view_controllers_stay_the_same_after_updating_to_the_same_site() throws {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        let viewControllersBeforeSiteChange = try XCTUnwrap(tabBarController.viewControllers)
        stores.updateDefaultStore(storeID: siteID)
        let viewControllersAfterSiteChange = try XCTUnwrap(tabBarController.viewControllers)

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange, viewControllersAfterSiteChange)
    }

    func test_selected_tab_is_dashboard_after_navigating_to_products_tab_then_updating_to_a_different_site() throws {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        tabBarController.navigateTo(.products)
        let selectedTabIndexBeforeSiteChange = tabBarController.selectedIndex
        stores.updateDefaultStore(storeID: 630)
        let selectedTabIndexAfterSiteChange = tabBarController.selectedIndex

        // Assert
        XCTAssertEqual(selectedTabIndexBeforeSiteChange, WooTab.products.visibleIndex())
        XCTAssertEqual(selectedTabIndexAfterSiteChange, WooTab.myStore.visibleIndex())
    }

    func test_when_receiving_a_review_notification_from_a_different_site_navigates_to_reviews_tab_and_presents_review_details() throws {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        ServiceLocator.setPushNotesManager(pushNotificationsManager)

        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        // Reset `receivedActions`
        storesManager.reset()
        ServiceLocator.setStores(storesManager)

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        stores.updateDefaultStore(storeID: 134)

        // Simulate successful state resetting after logging out from push notification store switching
        storesManager.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .resetStoredStats(completion) = action {
                completion()
            }
        }
        storesManager.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .resetStoredOrders(completion) = action {
                completion()
            }
        }
        storesManager.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            if case let .resetStoredProductReviews(completion) = action {
                completion()
            }
        }

        assertThat(tabBarController.tabNavigationController(tab: .reviews)?.topViewController, isAnInstanceOf: ReviewsViewController.self)

        // Action
        // Send push notification in inactive state
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, title: "", subtitle: "", message: "")
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(ProductReviewFromNoteParcelFactory().parcel(metaSiteID: 606)))

        // Assert
        waitUntil {
            self.tabBarController.tabNavigationController(tab: .reviews)?.viewControllers.count == 2
        }

        XCTAssertEqual(tabBarController.selectedIndex, WooTab.reviews.visibleIndex())

        // A ReviewDetailsViewController should be pushed
        assertThat(tabBarController.tabNavigationController(tab: .reviews)?.topViewController, isAnInstanceOf: ReviewDetailsViewController.self)
    }
}

private extension MainTabBarController {
    var tabRootViewControllers: [UIViewController] {
        viewControllers?.compactMap { $0 as? UINavigationController }.compactMap { $0.viewControllers.first } ?? []
    }

    func tabNavigationController(tab: WooTab) -> UINavigationController? {
        guard let navigationController = viewControllers?.compactMap({ $0 as? UINavigationController })[tab.visibleIndex()] else {
            XCTFail("Unexpected access to navigation controller at tab: \(tab)")
            return nil
        }
        return navigationController
    }
}

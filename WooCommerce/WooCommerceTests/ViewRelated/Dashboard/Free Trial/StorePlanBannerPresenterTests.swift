import XCTest
import Yosemite
import Combine
@testable import WooCommerce

final class StorePlanBannerPresenterTests: XCTestCase {

    private let siteID: Int64 = 123
    private var planSynchronizer: MockStorePlanSynchronizer!
    private var inAppPurchaseManager: MockInAppPurchasesForWPComPlansManager!
    private var containerView: UIView!

    override func setUp() {
        planSynchronizer = MockStorePlanSynchronizer()
        inAppPurchaseManager = MockInAppPurchasesForWPComPlansManager(isIAPSupported: true)
        containerView = UIView()
        super.setUp()
    }

    override func tearDown() {
        planSynchronizer = nil
        inAppPurchaseManager = nil
        containerView = nil
        super.tearDown()
    }

    func test_banner_is_displayed_when_site_plan_is_free_trial() {
        // Given
        let defaultSite = Site.fake().copy(siteID: siteID, isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let presenter = StorePlanBannerPresenter(viewController: UIViewController(),
                                                 containerView: containerView,
                                                 siteID: siteID,
                                                 onLayoutUpdated: { _ in },
                                                 stores: stores,
                                                 storePlanSynchronizer: planSynchronizer,
                                                 inAppPurchasesManager: inAppPurchaseManager)

        // When
        let plan = WPComSitePlan(id: "1052", hasDomainCredit: false, expiryDate: Date())
        planSynchronizer.setState(.loaded(plan))

        // Then
        waitUntil {
            self.containerView.subviews.isNotEmpty
        }
    }

    func test_banner_is_displayed_when_site_plan_is_free_and_site_was_ecommerce_trial() {
        // Given
        let defaultSite = Site.fake().copy(siteID: siteID, isWordPressComStore: false, wasEcommerceTrial: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let presenter = StorePlanBannerPresenter(viewController: UIViewController(),
                                                 containerView: containerView,
                                                 siteID: siteID,
                                                 onLayoutUpdated: { _ in },
                                                 stores: stores,
                                                 storePlanSynchronizer: planSynchronizer,
                                                 inAppPurchasesManager: inAppPurchaseManager)

        // When
        let plan = WPComSitePlan(id: "1", hasDomainCredit: false)
        planSynchronizer.setState(.loaded(plan))

        // Then
        waitUntil {
            self.containerView.subviews.isNotEmpty
        }
    }

    func test_banner_is_not_displayed_when_site_plan_is_free_and_site_was_not_ecommerce_trial() {
        // Given
        let defaultSite = Site.fake().copy(siteID: siteID, isWordPressComStore: false, wasEcommerceTrial: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let presenter = StorePlanBannerPresenter(viewController: UIViewController(),
                                                 containerView: containerView,
                                                 siteID: siteID,
                                                 onLayoutUpdated: { _ in },
                                                 stores: stores,
                                                 storePlanSynchronizer: planSynchronizer,
                                                 inAppPurchasesManager: inAppPurchaseManager)

        // When
        let plan = WPComSitePlan(id: "1", hasDomainCredit: false)
        planSynchronizer.setState(.loaded(plan))

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(self.containerView.subviews.isEmpty)
        }
    }

    func test_banner_is_dismissed_when_connection_is_lost() {
        // Given
        let defaultSite = Site.fake().copy(siteID: siteID, isWordPressComStore: false, wasEcommerceTrial: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let connectivityObserver = MockConnectivityObserver()
        let presenter = StorePlanBannerPresenter(viewController: UIViewController(),
                                                 containerView: containerView,
                                                 siteID: siteID,
                                                 onLayoutUpdated: { _ in },
                                                 stores: stores,
                                                 storePlanSynchronizer: planSynchronizer,
                                                 connectivityObserver: connectivityObserver,
                                                 inAppPurchasesManager: inAppPurchaseManager)

        // When
        let plan = WPComSitePlan(id: "1", hasDomainCredit: false)
        planSynchronizer.setState(.loaded(plan))

        // Then
        waitUntil {
            self.containerView.subviews.isNotEmpty
        }

        // When
        connectivityObserver.setStatus(.notReachable)

        // Then
        waitUntil {
            self.containerView.subviews.isEmpty
        }
    }
}

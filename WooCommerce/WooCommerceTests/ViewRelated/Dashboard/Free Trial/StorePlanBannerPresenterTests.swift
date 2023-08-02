import XCTest
import Yosemite
import Combine
@testable import WooCommerce

final class StorePlanBannerPresenterTests: XCTestCase {

    private let siteID: Int64 = 123
    private let inAppPurchaseManager = MockInAppPurchasesForWPComPlansManager(isIAPSupported: true)

    func test_banner_is_displayed_when_site_plan_is_free_trial() {
        // Given
        let planSynchronizer = MockStorePlanSynchronizer()
        let plan = WPComSitePlan(id: "1052", hasDomainCredit: false, expiryDate: Date())
        let defaultSite = Site.fake().copy(siteID: siteID, isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let containerView = UIView()
        let presenter = StorePlanBannerPresenter(viewController: UIViewController(),
                                                 containerView: containerView,
                                                 siteID: siteID,
                                                 onLayoutUpdated: { _ in },
                                                 stores: stores,
                                                 storePlanSynchronizer: planSynchronizer,
                                                 inAppPurchasesManager: inAppPurchaseManager)

        // When
        planSynchronizer.setState(.loaded(plan))

        // Then
        waitUntil {
            containerView.subviews.isNotEmpty
        }
    }
}

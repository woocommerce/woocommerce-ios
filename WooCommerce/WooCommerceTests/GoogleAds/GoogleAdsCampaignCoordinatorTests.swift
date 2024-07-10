import XCTest
@testable import WooCommerce

final class GoogleAdsCampaignCoordinatorTests: XCTestCase {

    private var navigationController: UINavigationController!
    private let siteAdminURL = "https://example.com/wp-admin/"

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
     }

     override func tearDown() {
         super.tearDown()
         navigationController = nil
     }

    func test_web_view_is_presented_if_authentication_is_not_needed() throws {
        // Given
        let coordinator = GoogleAdsCampaignCoordinator(
            siteID: 123,
            siteAdminURL: siteAdminURL,
            source: .myStore,
            shouldStartCampaignCreation: true,
            shouldAuthenticateAdminPage: false,
            navigationController: navigationController,
            onCompletion: { _ in }
        )

        // When
        coordinator.start()

        // Then
        let presentedController = try XCTUnwrap((coordinator.navigationController.presentedViewController as? UINavigationController)?.viewControllers.last)
        XCTAssertTrue(presentedController is WebViewHostingController)
    }

    func test_authenticated_web_view_is_presented_if_authentication_is_needed() throws {
        // Given
        let coordinator = GoogleAdsCampaignCoordinator(
            siteID: 123,
            siteAdminURL: siteAdminURL,
            source: .myStore,
            shouldStartCampaignCreation: true,
            shouldAuthenticateAdminPage: true,
            navigationController: navigationController,
            onCompletion: { _ in }
        )

        // When
        coordinator.start()

        // Then
        let presentedController = try XCTUnwrap((coordinator.navigationController.presentedViewController as? UINavigationController)?.viewControllers.last)
        XCTAssertTrue(presentedController is AuthenticatedWebViewController)
    }
}

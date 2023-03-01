import XCTest
@testable import WooCommerce
@testable import Yosemite
import enum Alamofire.AFError

final class JetpackSetupCoordinatorTests: XCTestCase {

    private var stores: MockStoresManager!
    private var navigationController: UINavigationController!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        super.setUp()
    }

    override func tearDown() {
        stores = nil
        navigationController = nil
        super.tearDown()
    }

    func test_benefit_modal_is_presented_correctly() {
        // Given
        let testSite = Site.fake()
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertTrue(navigationController.presentedViewController is JetpackBenefitsHostingController)
    }

    func test_installation_flow_for_jcp_sites_is_presented_for_jcp_sites() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(JetpackBenefitsViewModel.FetchJetpackUserError.notSupportedForJCPSites))
        waitUntil {
            self.navigationController.presentedViewController is JCPJetpackInstallHostingController
        }
    }

    func test_wpcom_email_screen_is_presented_for_non_jetpack_sites_without_jetpack_if_user_is_admin() throws {
        // Given
        let testSite = Site.fake().copy(siteID: -1)
        let mockSessionManager = MockSessionManager()
        mockSessionManager.defaultRoles = [.administrator]
        let stores = DefaultStoresManager(sessionManager: mockSessionManager)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController, stores: stores)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))))

        // Then
        waitUntil {
            self.navigationController.presentedViewController is UINavigationController
        }
        let navigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is WPComEmailLoginHostingController)
    }

    func test_admin_required_screen_is_presented_for_non_jetpack_sites_without_jetpack_if_user_is_not_admin() throws {
        // Given
        let testSite = Site.fake().copy(siteID: -1)
        let mockSessionManager = MockSessionManager()
        mockSessionManager.defaultRoles = [.shopManager]
        let stores = DefaultStoresManager(sessionManager: mockSessionManager)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController, stores: stores)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))))

        // Then
        waitUntil {
            benefitModal.presentedViewController is UINavigationController
        }
        let navigationController = try XCTUnwrap(benefitModal.presentedViewController as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is AdminRoleRequiredHostingController)
    }

    func test_admin_required_screen_is_presented_for_non_jetpack_sites_when_jetpack_connection_check_returns_403() throws {
        // Given
        let testSite = Site.fake().copy(siteID: -1)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403))))

        // Then
        waitUntil {
            benefitModal.presentedViewController is UINavigationController
        }
        let navigationController = try XCTUnwrap(benefitModal.presentedViewController as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is AdminRoleRequiredHostingController)
    }

}

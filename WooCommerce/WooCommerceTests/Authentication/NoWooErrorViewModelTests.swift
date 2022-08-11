import XCTest
import Yosemite
@testable import WooCommerce

final class NoWooErrorViewModelTests: XCTestCase {

    func test_title_is_correct() {
        // Given
        let site = Site.fake().copy(name: "Test")
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.title, "Test")
    }

    func test_image_is_correct() {
        // Given
        let site = Site.fake()
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.image, UIImage.noStoreImage)
    }

    func test_error_message_is_correct() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.text.string, String(format: Localization.errorMessage, "test.com"))
    }

    func test_auxiliary_button_is_hidden_when_connected_stores_are_not_shown() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.isAuxiliaryButtonHidden)
    }

    func test_auxiliary_button_is_not_hidden_when_connected_stores_are_shown() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: true, onSetupCompletion: { _ in })

        // Then
        XCTAssertFalse(viewModel.isAuxiliaryButtonHidden)
    }

    func test_auxiliary_button_title_is_correct() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        //  Then
        XCTAssertEqual(viewModel.auxiliaryButtonTitle, Localization.seeConnectedStores)
    }

    func test_primary_button_title_is_correct() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        //  Then
        XCTAssertEqual(viewModel.primaryButtonTitle, Localization.primaryButtonTitle)
    }

    func test_primary_button_is_hidden_when_the_site_does_not_have_jetpack_connection() {
        // Given
        let site = Site.fake().copy(url: "https://test.com", isJetpackThePluginInstalled: true, isJetpackConnected: false)
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.isPrimaryButtonHidden)
    }

    func test_primary_button_is_hidden_when_the_site_does_not_have_jetpack_the_plugin() {
        // Given
        let site = Site.fake().copy(url: "https://test.com", isJetpackThePluginInstalled: false, isJetpackConnected: true)
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.isPrimaryButtonHidden)
    }

    func test_primary_button_is_not_hidden_when_the_site_has_both_jetpack_connection_and_the_plugin() {
        // Given
        let site = Site.fake().copy(url: "https://test.com", isJetpackThePluginInstalled: true, isJetpackConnected: true)
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        // Then
        XCTAssertFalse(viewModel.isPrimaryButtonHidden)
    }

    func test_secondary_button_title_is_correct() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let viewModel = NoWooErrorViewModel(site: site, showsConnectedStores: false, onSetupCompletion: { _ in })

        //  Then
        XCTAssertEqual(viewModel.secondaryButtonTitle, Localization.secondaryButtonTitle)
    }

    func test_user_is_logged_out_when_tapping_secondary_button() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let viewModel = NoWooErrorViewModel(site: site,
                                            showsConnectedStores: false,
                                            stores: stores,
                                            onSetupCompletion: { _ in })
        let rootViewController = UIViewController()
        let noWooController = ULErrorViewController(viewModel: viewModel)
        let navigationController = UINavigationController()
        navigationController.viewControllers = [rootViewController, noWooController]

        // When
        viewModel.didTapSecondaryButton(in: noWooController)

        // Then
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertFalse(navigationController.topViewController is ULErrorViewController)
    }

    func test_woocommerce_setup_button_tapped_is_tracked_when_tapping_primary_button() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = NoWooErrorViewModel(site: site,
                                            showsConnectedStores: false,
                                            analytics: analytics,
                                            onSetupCompletion: { _ in })

        // When
        viewModel.didTapPrimaryButton(in: nil)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_woocommerce_setup_button_tapped" }))
    }

    func test_woocommerce_error_screen_is_tracked_when_the_view_is_loaded() {
        // Given
        let site = Site.fake().copy(url: "https://test.com")
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = NoWooErrorViewModel(site: site,
                                            showsConnectedStores: false,
                                            analytics: analytics,
                                            onSetupCompletion: { _ in })

        // When
        viewModel.viewDidLoad()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_woocommerce_error_shown" }))
    }
}

private extension NoWooErrorViewModelTests {
    enum Localization {
        static let errorMessage = NSLocalizedString("It looks like %@ is not a WooCommerce site.",
                                                    comment: "Message explaining that the site entered doesn't have WooCommerce installed or activated. "
                                                        + "Reads like 'It looks like awebsite.com is not a WooCommerce site.")
        static let seeConnectedStores = NSLocalizedString("See Connected Stores",
                                                          comment: "Action button linking to a list of connected stores. "
                                                          + "Presented when logging in with a store address that does not have WooCommerce.")

        static let primaryButtonTitle = NSLocalizedString("Install WooCommerce",
                                                          comment: "Action button for installing WooCommerce."
                                                          + "Presented when logging in with a site address that does not have WooCommerce")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have WooCommerce")
    }
}

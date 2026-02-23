import XCTest
import Yosemite
import enum Networking.NetworkError
import protocol WooFoundation.Analytics
@testable import WooCommerce

@MainActor
final class WPComPushNotificationsBenefitsViewModelTests: XCTestCase {

    // MARK: - Default state

    func test_default_variant_is_connect() {
        // Given
        let viewModel = makeViewModel()

        // Then
        XCTAssertEqual(viewModel.variant, .connect)
    }

    func test_isCheckingPlugin_is_false_initially() {
        // Given
        let viewModel = makeViewModel()

        // Then
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    // MARK: - determineSetupVariant with Jetpack connected

    func test_error_is_nil_initially() {
        // Given / When
        let viewModel = makeViewModel()

        // Then
        XCTAssertNil(viewModel.error)
    }

    func test_error_is_nil_when_jetpack_connected_and_plugin_update_needed() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .success(
            JetpackConnectionData.fake().copy(isRegistered: true)
        )
        let checker = MockPluginVersionChecker()
        checker.result = .success(.incompatible(currentVersion: "10.0.0", requiredVersion: "10.5.3"))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService, pluginVersionChecker: checker)

        // When
        await viewModel.determineSetupVariant()

        // Then
        XCTAssertNil(viewModel.error)
    }

    func test_error_is_nil_when_jetpack_not_connected() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .success(
            JetpackConnectionData.fake().copy(isRegistered: false)
        )
        let viewModel = makeViewModel(jetpackConnectionService: connectionService)

        // When
        await viewModel.determineSetupVariant()

        // Then
        XCTAssertNil(viewModel.error)
    }

    func test_variant_is_pluginUpdate_when_jetpack_connected_and_plugin_incompatible() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .success(
            JetpackConnectionData.fake().copy(isRegistered: true)
        )
        let checker = MockPluginVersionChecker()
        checker.result = .success(.incompatible(currentVersion: "10.0.0", requiredVersion: "10.5.3"))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService, pluginVersionChecker: checker)

        // When
        await viewModel.determineSetupVariant()

        // Then
        XCTAssertEqual(viewModel.variant, .pluginUpdate(currentVersion: "10.0.0"))
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    func test_error_is_noMissingRequirements_when_jetpack_connected_and_plugin_compatible() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .success(
            JetpackConnectionData.fake().copy(isRegistered: true)
        )
        let checker = MockPluginVersionChecker()
        checker.result = .success(.compatible)
        let viewModel = makeViewModel(jetpackConnectionService: connectionService, pluginVersionChecker: checker)

        // When
        await viewModel.determineSetupVariant()

        // Then
        guard case .noMissingRequirements = viewModel.error else {
            return XCTFail("Expected noMissingRequirements error, got \(String(describing: viewModel.error))")
        }
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    func test_error_is_generic_when_jetpack_connected_and_plugin_check_throws() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .success(
            JetpackConnectionData.fake().copy(isRegistered: true)
        )
        let checker = MockPluginVersionChecker()
        checker.result = .failure(NSError(domain: "test", code: 1))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService, pluginVersionChecker: checker)

        // When
        await viewModel.determineSetupVariant()

        // Then
        guard case .generic = viewModel.error else {
            return XCTFail("Expected generic error, got \(String(describing: viewModel.error))")
        }
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    // MARK: - determineSetupVariant with Jetpack not connected

    func test_variant_is_connect_when_jetpack_not_connected() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .success(
            JetpackConnectionData.fake().copy(isRegistered: false)
        )
        let checker = MockPluginVersionChecker()
        checker.result = .success(.incompatible(currentVersion: "10.0.0", requiredVersion: "10.5.3"))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService, pluginVersionChecker: checker)

        // When
        await viewModel.determineSetupVariant()

        // Then
        XCTAssertEqual(viewModel.variant, .connect)
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    // MARK: - Analytics: onAppear

    func test_onAppear_tracks_introduction_view_event() {
        // Given
        let (analyticsProvider, analytics) = makeAnalytics()
        let viewModel = makeViewModel(analytics: analytics)

        // When
        viewModel.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("push_notifications_setup_introduction_view"))
    }

    // MARK: - Analytics: continueTapped

    func test_continueTapped_when_connect_variant_then_tracks_continue_button_label() {
        // Given
        let (analyticsProvider, analytics) = makeAnalytics()
        let viewModel = makeViewModel(analytics: analytics)

        // When
        viewModel.continueTapped()

        // Then
        assertEqual(analyticsProvider, eventName: "push_notifications_setup_introduction_button_tap", property: "button_label", expected: "continue")
    }

    func test_continueTapped_when_pluginUpdate_variant_then_tracks_update_plugin_button_label() async {
        // Given
        let (analyticsProvider, analytics) = makeAnalytics()
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .success(
            JetpackConnectionData.fake().copy(isRegistered: true)
        )
        let checker = MockPluginVersionChecker()
        checker.result = .success(.incompatible(currentVersion: "10.0.0", requiredVersion: "10.5.3"))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService,
                                      pluginVersionChecker: checker,
                                      analytics: analytics)
        await viewModel.determineSetupVariant()

        // When
        viewModel.continueTapped()

        // Then
        assertEqual(analyticsProvider, eventName: "push_notifications_setup_introduction_button_tap", property: "button_label", expected: "update_plugin")
    }

    // MARK: - Analytics: notNowTapped

    func test_notNowTapped_tracks_not_now_button_label() {
        // Given
        let (analyticsProvider, analytics) = makeAnalytics()
        let viewModel = makeViewModel(analytics: analytics)

        // When
        viewModel.notNowTapped()

        // Then
        assertEqual(analyticsProvider, eventName: "push_notifications_setup_introduction_button_tap", property: "button_label", expected: "not_now")
    }

    // MARK: - determineSetupVariant when fetch fails

    func test_error_is_noPermission_when_fetching_connection_data_throws_403() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .failure(NetworkError.unacceptableStatusCode(statusCode: 403, response: nil))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService)

        // When
        await viewModel.determineSetupVariant()

        // Then
        guard case .noPermission = viewModel.error else {
            return XCTFail("Expected noPermission error, got \(String(describing: viewModel.error))")
        }
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    func test_error_is_generic_when_fetching_connection_data_throws_non_403_error() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .failure(NSError(domain: "test", code: 1))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService)

        // When
        await viewModel.determineSetupVariant()

        // Then
        guard case .generic = viewModel.error else {
            return XCTFail("Expected generic error, got \(String(describing: viewModel.error))")
        }
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    // MARK: - Helpers

    private let sampleSiteID: Int64 = 123

    private func makeAnalytics() -> (MockAnalyticsProvider, WooAnalytics) {
        let provider = MockAnalyticsProvider()
        return (provider, WooAnalytics(analyticsProvider: provider))
    }

    private func assertEqual(_ provider: MockAnalyticsProvider, eventName: String, property: String, expected: String) {
        let index = provider.receivedEvents.firstIndex(of: eventName)
        XCTAssertNotNil(index)
        if let index {
            XCTAssertEqual(provider.receivedProperties[index][property] as? String, expected)
        }
    }

    private func makeViewModel(
        jetpackConnectionService: JetpackConnectionServiceProtocol = MockJetpackConnectionService(),
        pluginVersionChecker: PluginVersionCheckerProtocol? = nil,
        analytics: Analytics = ServiceLocator.analytics
    ) -> WPComPushNotificationsBenefitsViewModel {
        WPComPushNotificationsBenefitsViewModel(
            siteID: sampleSiteID,
            siteURL: "https://example.com",
            jetpackConnectionService: jetpackConnectionService,
            pluginVersionChecker: pluginVersionChecker,
            analytics: analytics,
            onDismiss: {}
        )
    }
}

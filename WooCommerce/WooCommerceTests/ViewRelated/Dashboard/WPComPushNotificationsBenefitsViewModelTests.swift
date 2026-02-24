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

    // MARK: - Analytics: introduction button actions

    func test_introduction_button_actions_track_correct_analytics_events() {
        // Given
        let provider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: provider)
        let viewModel = makeViewModel(analytics: analytics)

        // When
        viewModel.onAppear()
        viewModel.continueTapped()
        viewModel.notNowTapped()

        // Then
        XCTAssertTrue(provider.receivedEvents.contains("push_notifications_setup_introduction_view"))
        assertEqual(provider, eventName: "push_notifications_setup_introduction_button_tap", property: "button_label", expected: "continue")
        XCTAssertEqual(provider.receivedEvents.filter { $0 == "push_notifications_setup_introduction_button_tap" }.count, 2)
    }

    func test_continueTapped_when_pluginUpdate_variant_then_tracks_update_plugin_button_label() async {
        // Given
        let provider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: provider)
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
        assertEqual(provider, eventName: "push_notifications_setup_introduction_button_tap", property: "button_label", expected: "update_plugin")
    }

    // MARK: - Analytics: determineSetupVariant errors

    func test_determineSetupVariant_when_connection_errors_then_tracks_correct_introduction_error() async {
        // When 403 error, then tracks no_permission
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let connectionService = MockJetpackConnectionService()
            connectionService.fetchConnectionDataResult = .failure(NetworkError.unacceptableStatusCode(statusCode: 403, response: nil))
            let viewModel = makeViewModel(jetpackConnectionService: connectionService, analytics: analytics)

            await viewModel.determineSetupVariant()

            assertEqual(provider, eventName: "push_notifications_setup_introduction_error", property: "error_type", expected: "no_permission")
        }

        // When generic error, then tracks generic
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let connectionService = MockJetpackConnectionService()
            connectionService.fetchConnectionDataResult = .failure(NSError(domain: "test", code: 1))
            let viewModel = makeViewModel(jetpackConnectionService: connectionService, analytics: analytics)

            await viewModel.determineSetupVariant()

            assertEqual(provider, eventName: "push_notifications_setup_introduction_error", property: "error_type", expected: "generic")
        }
    }

    func test_determineSetupVariant_when_plugin_check_errors_then_tracks_correct_introduction_error() async {
        // When plugin compatible, then tracks no_missing_requirements
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let connectionService = MockJetpackConnectionService()
            connectionService.fetchConnectionDataResult = .success(
                JetpackConnectionData.fake().copy(isRegistered: true)
            )
            let checker = MockPluginVersionChecker()
            checker.result = .success(.compatible)
            let viewModel = makeViewModel(jetpackConnectionService: connectionService, pluginVersionChecker: checker, analytics: analytics)

            await viewModel.determineSetupVariant()

            assertEqual(provider, eventName: "push_notifications_setup_introduction_error", property: "error_type", expected: "no_missing_requirements")
        }

        // When plugin check throws, then tracks generic
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let connectionService = MockJetpackConnectionService()
            connectionService.fetchConnectionDataResult = .success(
                JetpackConnectionData.fake().copy(isRegistered: true)
            )
            let checker = MockPluginVersionChecker()
            checker.result = .failure(NSError(domain: "test", code: 1))
            let viewModel = makeViewModel(jetpackConnectionService: connectionService, pluginVersionChecker: checker, analytics: analytics)

            await viewModel.determineSetupVariant()

            assertEqual(provider, eventName: "push_notifications_setup_introduction_error", property: "error_type", expected: "generic")
        }
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

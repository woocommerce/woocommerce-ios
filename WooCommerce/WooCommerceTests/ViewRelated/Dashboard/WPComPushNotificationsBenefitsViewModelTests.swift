import XCTest
import Yosemite
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

    func test_variant_is_connect_when_jetpack_connected_and_plugin_compatible() async {
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
        XCTAssertEqual(viewModel.variant, .connect)
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    func test_variant_is_connect_when_jetpack_connected_and_plugin_check_throws() async {
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
        XCTAssertEqual(viewModel.variant, .connect)
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

    // MARK: - determineSetupVariant when fetch fails

    func test_variant_is_connect_when_fetching_connection_data_throws() async {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.fetchConnectionDataResult = .failure(NSError(domain: "test", code: 1))
        let viewModel = makeViewModel(jetpackConnectionService: connectionService)

        // When
        await viewModel.determineSetupVariant()

        // Then
        XCTAssertEqual(viewModel.variant, .connect)
        XCTAssertFalse(viewModel.isCheckingPlugin)
    }

    // MARK: - Helpers

    private let sampleSiteID: Int64 = 123

    private func makeViewModel(
        jetpackConnectionService: JetpackConnectionServiceProtocol = MockJetpackConnectionService(),
        pluginVersionChecker: PluginVersionCheckerProtocol? = nil
    ) -> WPComPushNotificationsBenefitsViewModel {
        WPComPushNotificationsBenefitsViewModel(
            siteID: sampleSiteID,
            jetpackConnectionService: jetpackConnectionService,
            pluginVersionChecker: pluginVersionChecker,
            onDismiss: {}
        )
    }
}

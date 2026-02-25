import XCTest
import Yosemite
import enum Networking.NetworkError
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

    private func makeViewModel(
        jetpackConnectionService: JetpackConnectionServiceProtocol = MockJetpackConnectionService(),
        pluginVersionChecker: PluginVersionCheckerProtocol? = nil
    ) -> WPComPushNotificationsBenefitsViewModel {
        WPComPushNotificationsBenefitsViewModel(
            siteID: sampleSiteID,
            siteURL: "https://example.com",
            jetpackConnectionService: jetpackConnectionService,
            pluginVersionChecker: pluginVersionChecker,
            onDismiss: {}
        )
    }
}

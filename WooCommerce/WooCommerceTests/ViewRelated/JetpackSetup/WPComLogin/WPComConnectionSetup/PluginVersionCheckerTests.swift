import XCTest
import Yosemite
@testable import WooCommerce

final class PluginVersionCheckerTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_compatible_when_plugin_meets_minimum_version() async throws {
        // Given
        let plugin = SystemPlugin.fake().copy(
            plugin: "jetpack/jetpack.php",
            version: "14.4"
        )
        mockSystemInfo(with: [plugin])

        let checker = PluginVersionChecker(
            siteID: 123,
            pluginPath: "jetpack/jetpack.php",
            minimumVersion: "14.4",
            stores: stores
        )

        // When
        let result = try await checker.checkCompatibility()

        // Then
        guard case .compatible = result else {
            return XCTFail("Expected .compatible, got \(result)")
        }
    }

    func test_incompatible_when_plugin_below_minimum_version() async throws {
        // Given
        let plugin = SystemPlugin.fake().copy(
            plugin: "jetpack/jetpack.php",
            version: "14.3"
        )
        mockSystemInfo(with: [plugin])

        let checker = PluginVersionChecker(
            siteID: 123,
            pluginPath: "jetpack/jetpack.php",
            minimumVersion: "14.4",
            stores: stores
        )

        // When
        let result = try await checker.checkCompatibility()

        // Then
        guard case let .incompatible(currentVersion, requiredVersion) = result else {
            return XCTFail("Expected .incompatible, got \(result)")
        }
        XCTAssertEqual(currentVersion, "14.3")
        XCTAssertEqual(requiredVersion, "14.4")
    }

    func test_throws_pluginNotFound_when_plugin_missing() async {
        // Given
        mockSystemInfo(with: [])

        let checker = PluginVersionChecker(
            siteID: 123,
            pluginPath: "jetpack/jetpack.php",
            minimumVersion: "14.4",
            stores: stores
        )

        // When / Then
        do {
            _ = try await checker.checkCompatibility()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PluginVersionError)
        }
    }

    func test_throws_when_system_info_sync_fails() async {
        // Given
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .synchronizeSystemInformation(_, onCompletion):
                onCompletion(.failure(NSError(domain: "test", code: 0)))
            default:
                break
            }
        }

        let checker = PluginVersionChecker(
            siteID: 123,
            pluginPath: "jetpack/jetpack.php",
            minimumVersion: "14.4",
            stores: stores
        )

        // When / Then
        do {
            _ = try await checker.checkCompatibility()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
}

private extension PluginVersionCheckerTests {
    func mockSystemInfo(with plugins: [SystemPlugin]) {
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .synchronizeSystemInformation(_, onCompletion):
                let systemInfo = SystemInformation.fake().copy(systemPlugins: plugins)
                onCompletion(.success(systemInfo))
            default:
                break
            }
        }
    }
}

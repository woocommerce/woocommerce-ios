import XCTest
@testable import WooCommerce
@testable import Yosemite

final class JetpackInstallStepsViewModelTests: XCTestCase {

    private let testSiteID: Int64 = 1232

    func test_startInstallation_dispatches_installSitePlugin_action() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID, stores: storesManager)

        // When
        var installedSiteID: Int64?
        var pluginSlug: String?
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .installSitePlugin(let siteID, let slug, _):
                installedSiteID = siteID
                pluginSlug = slug
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        XCTAssertEqual(installedSiteID, testSiteID)
        XCTAssertEqual(pluginSlug, "jetpack")
    }

    func test_activateSitePlugin_is_dispatched_when_installSitePlugin_succeeds() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID, stores: storesManager)

        // When
        var activatedSiteID: Int64?
        var activatedPluginName: String?
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .installSitePlugin(_, _, let onCompletion):
                onCompletion(.success(()))
            case .activateSitePlugin(let siteID, let pluginName, _):
                activatedSiteID = siteID
                activatedPluginName = pluginName
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        XCTAssertEqual(activatedSiteID, testSiteID)
        XCTAssertEqual(activatedPluginName, "jetpack/jetpack")
    }

    func test_currentStep_is_installation_initially() {
        // Given
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID)

        // Then
        XCTAssertEqual(viewModel.currentStep, .installation)
    }

    func test_currentStep_is_activate_when_installation_succeeds() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID, stores: storesManager)

        // When
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .installSitePlugin(_, _, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        XCTAssertEqual(viewModel.currentStep, .activation)
    }

    func test_currentStep_is_connection_when_installation_and_activation_succeeds() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID, stores: storesManager)

        // When
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .installSitePlugin(_, _, let onCompletion):
                onCompletion(.success(()))
            case .activateSitePlugin(_, _, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        XCTAssertEqual(viewModel.currentStep, .connection)
    }
}

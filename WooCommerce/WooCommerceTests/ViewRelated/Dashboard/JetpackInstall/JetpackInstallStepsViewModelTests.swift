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

    func test_loadAndSynchronizeSite_is_dispatched_when_activating_plugin_succeeds() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID, stores: storesManager)

        // When
        var checkedSiteID: Int64?
        var forcedUpdateSite: Bool?
        var supportsJCPSites: Bool?
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
        storesManager.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .loadAndSynchronizeSite(let siteID, let forcedUpdate, let isJetpackConnectionPackageSupported, _):
                checkedSiteID = siteID
                forcedUpdateSite = forcedUpdate
                supportsJCPSites = isJetpackConnectionPackageSupported
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        XCTAssertEqual(checkedSiteID, testSiteID)
        XCTAssertEqual(forcedUpdateSite, true)
        XCTAssertEqual(supportsJCPSites, true)
    }

    func test_currentStep_is_installation_on_startInstallation() {
        // Given
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID)

        // When
        viewModel.startInstallation()

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

    func test_currentStep_is_done_when_site_has_isWooCommerceActive_and_not_isJetpackCPConnected() {
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
        storesManager.whenReceivingAction(ofType: AccountAction.self) { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .loadAndSynchronizeSite(_, _, _, let onCompletion):
                let fetchedSite = Site.fake().copy(siteID: self.testSiteID,
                                                   isJetpackThePluginInstalled: true,
                                                   isJetpackConnected: true,
                                                   isWooCommerceActive: true)
                onCompletion(.success(fetchedSite))
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        XCTAssertEqual(viewModel.currentStep, .done)
    }

    func test_currentStep_is_not_done_when_site_does_not_have_isWooCommerceActive() {
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
        storesManager.whenReceivingAction(ofType: AccountAction.self) { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .loadAndSynchronizeSite(_, _, _, let onCompletion):
                let fetchedSite = Site.fake().copy(siteID: self.testSiteID,
                                                   isJetpackThePluginInstalled: true,
                                                   isJetpackConnected: true,
                                                   isWooCommerceActive: false)
                onCompletion(.success(fetchedSite))
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        // TODO: update this when error handling is implemented
        XCTAssertEqual(viewModel.currentStep, .connection)
    }
}

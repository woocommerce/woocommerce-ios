import XCTest
import Yosemite
@testable import WooCommerce

final class LoginJetpackSetupViewModelTests: XCTestCase {
    private let testURL = "https://test.com"

    func test_title_is_correct_if_jetpack_installation_is_required() {
        // Given
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false)

        // Then
        XCTAssertEqual(viewModel.title, LoginJetpackSetupViewModel.Localization.installingJetpack)
    }

    func test_title_is_correct_if_only_jetpack_connection_is_missing() {
        // Given
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: true)

        // Then
        XCTAssertEqual(viewModel.title, LoginJetpackSetupViewModel.Localization.connectingJetpack)
    }

    func test_description_string_is_correct() {
        // Given
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false)
        let description = String(format: LoginJetpackSetupViewModel.Localization.description, testURL.trimHTTPScheme())

        // Then
        XCTAssertEqual(viewModel.descriptionAttributedString.string, description)
    }

    func test_startSetup_triggers_jetpack_installation_if_retrieving_details_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        var triggeredJetpackInstallation = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = NSError(domain: "Test", code: 1)
                completion(.failure(error))
            case .installJetpackPlugin:
                triggeredJetpackInstallation = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.isSetupStepInProgress(.installation))
        XCTAssertTrue(viewModel.isSetupStepPending(.activation))
        XCTAssertTrue(viewModel.isSetupStepPending(.connection))
        XCTAssertTrue(triggeredJetpackInstallation)
    }

    func test_startSetup_triggers_jetpack_activation_if_retrieving_details_returns_inactive_jetpack() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        var triggeredInstallation = false
        var triggeredActivation = false
        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(plugin))
            case .installJetpackPlugin:
                triggeredInstallation = true
            case .activateJetpackPlugin:
                triggeredActivation = true
            case .fetchJetpackConnectionURL:
                triggeredConnection = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.isSetupStepInProgress(.activation))
        XCTAssertFalse(viewModel.isSetupStepPending(.installation))
        XCTAssertTrue(viewModel.isSetupStepPending(.connection))
        XCTAssertFalse(triggeredInstallation)
        XCTAssertTrue(triggeredActivation)
        XCTAssertFalse(triggeredConnection)
    }

    func test_startSetup_triggers_jetpack_connection_if_retrieving_details_returns_active_jetpack() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .active)

        var triggeredInstallation = false
        var triggeredActivation = false
        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(plugin))
            case .installJetpackPlugin:
                triggeredInstallation = true
            case .activateJetpackPlugin:
                triggeredActivation = true
            case .fetchJetpackConnectionURL:
                triggeredConnection = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.isSetupStepInProgress(.connection))
        XCTAssertFalse(viewModel.isSetupStepPending(.installation))
        XCTAssertFalse(viewModel.isSetupStepPending(.activation))
        XCTAssertTrue(viewModel.isSetupStepPending(.done))
        XCTAssertFalse(triggeredInstallation)
        XCTAssertFalse(triggeredActivation)
        XCTAssertTrue(triggeredConnection)
    }

    func test_installation_triggers_activation_when_completing_successfully() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        var triggeredActivation = false
        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = NSError(domain: "Test", code: 1)
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            case .activateJetpackPlugin:
                triggeredActivation = true
            case .fetchJetpackConnectionURL:
                triggeredConnection = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(triggeredActivation)
        XCTAssertFalse(triggeredConnection)
    }

    func test_activation_triggers_fetching_connection_url_when_completing_successfully() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = NSError(domain: "Test", code: 1)
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            case .activateJetpackPlugin(let completion):
                completion(.success(()))
            case .fetchJetpackConnectionURL:
                triggeredConnection = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(triggeredConnection)
    }

    func test_shouldPresentWebView_is_true_when_fetching_connection_url_completes_successfully() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let testConnectionURL = try XCTUnwrap(URL(string: "https://test-connection.com"))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = NSError(domain: "Test", code: 1)
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            case .activateJetpackPlugin(let completion):
                completion(.success(()))
            case .fetchJetpackConnectionURL(let completion):
                completion(.success(testConnectionURL))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.shouldPresentWebView)
        XCTAssertEqual(viewModel.jetpackConnectionURL, testConnectionURL)
    }

    func test_authorizeJetpackConnection_sets_connection_status_to_in_progress_and_triggers_fetching_jetpack_user() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        XCTAssertEqual(viewModel.currentConnectionStep, .pending)

        var triggeredFetchingJetpackUser = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser:
                triggeredFetchingJetpackUser = true
            default:
                break
            }
        }

        // When
        viewModel.authorizeJetpackConnection()

        // Then
        XCTAssertTrue(triggeredFetchingJetpackUser)
        XCTAssertEqual(viewModel.currentConnectionStep, .inProgress)
    }

    func test_authorizeJetpackConnection_updates_connection_status_and_setup_step_correctly_when_fetching_jetpack_user_successfully() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        XCTAssertEqual(viewModel.currentConnectionStep, .pending)
        
        let user = JetpackUser.fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "test@mail.com"))
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser(let completion):
                completion(.success(user))
            default:
                break
            }
        }

        // When
        viewModel.authorizeJetpackConnection()

        // Then
        XCTAssertEqual(viewModel.currentConnectionStep, .authorized)
        XCTAssertEqual(viewModel.currentSetupStep, .done)
    }

    func test_navigateToStore_triggers_storeNavigationHandler() {
        // Given
        var storeNavigationTriggered = false
        let viewModel = LoginJetpackSetupViewModel(siteURL: testURL, connectionOnly: false, onStoreNavigation: {
            storeNavigationTriggered = true
        })

        // When
        viewModel.navigateToStore()

        // Then
        XCTAssertTrue(storeNavigationTriggered)
    }
}

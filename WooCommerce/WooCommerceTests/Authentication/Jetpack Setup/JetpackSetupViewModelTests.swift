import XCTest
import Yosemite
@testable import WooCommerce
import enum Networking.NetworkError
import WordPressAuthenticator

final class JetpackSetupViewModelTests: XCTestCase {
    private let testURL = "https://example.com"
    private let credentials = Credentials.wpcom(username: "test", authToken: "secret", siteAddress: "https://example.com")

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeAuthenticator()
    }

    // MARK: UI-related

    func test_title_is_correct_if_jetpack_installation_is_required() {
        // Given
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials)

        // Then
        XCTAssertEqual(viewModel.title, JetpackSetupViewModel.Localization.installingJetpack)
    }

    func test_title_is_correct_if_only_jetpack_connection_is_missing() {
        // Given
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials)

        // Then
        XCTAssertEqual(viewModel.title, JetpackSetupViewModel.Localization.connectingJetpack)
    }

    func test_description_string_is_correct() {
        // Given
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials)
        let description = String(format: JetpackSetupViewModel.Localization.description, testURL.trimHTTPScheme())

        // Then
        XCTAssertEqual(viewModel.descriptionAttributedString.string, description)
    }

    func test_isSetupStepFailed_is_correct_when_the_current_step_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(plugin))
            case .activateJetpackPlugin(_, let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertFalse(viewModel.isSetupStepFailed(.installation))
        XCTAssertTrue(viewModel.isSetupStepFailed(.activation))
        XCTAssertFalse(viewModel.isSetupStepFailed(.connection))
    }

    func test_title_is_correct_when_retrieveJetpackPluginDetails_fails_with_permission_error() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 403, response: nil)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertEqual(viewModel.title, JetpackInstallStep.installation.errorTitle)
    }

    func test_title_and_tryAgainButtonTitle_are_correct_when_installation_step_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.notFound(response: nil)))
            case .installJetpackPlugin(_, let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertEqual(viewModel.title, JetpackInstallStep.installation.errorTitle)
        XCTAssertEqual(viewModel.tryAgainButtonTitle, JetpackInstallStep.installation.tryAgainButtonTitle)
    }

    func test_title_and_tryAgainButtonTitle_are_correct_when_activation_step_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(plugin))
            case .activateJetpackPlugin(_, let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertEqual(viewModel.title, JetpackInstallStep.activation.errorTitle)
        XCTAssertEqual(viewModel.tryAgainButtonTitle, JetpackInstallStep.activation.tryAgainButtonTitle)
    }

    func test_title_and_tryAgainButtonTitle_are_correct_when_connection_step_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake()))
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(JetpackConnectionData.fake().copy(isRegistered: nil)))
            case .fetchJetpackConnectionURL(_, let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.setupFailed }

        // Then
        XCTAssertEqual(viewModel.title, JetpackInstallStep.connection.errorTitle)
        XCTAssertEqual(viewModel.tryAgainButtonTitle, JetpackInstallStep.connection.tryAgainButtonTitle)
    }

    func test_shouldShowInitialLoadingIndicator_turns_on_correctly_when_startSetup_then_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.shouldShowInitialLoadingIndicator)
    }

    func test_shouldShowInitialLoadingIndicator_turns_off_correctly_when_retrieveJetpackPluginDetails_is_success_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        // When
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(plugin))
            default:
                break
            }
        }
        viewModel.startSetup()

        // Then
        XCTAssertFalse(viewModel.shouldShowInitialLoadingIndicator)
    }

    func test_shouldShowSetupSteps_when_startSetup_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        // When
        viewModel.startSetup()

        // Then
        XCTAssertFalse(viewModel.shouldShowSetupSteps)
    }

    func test_shouldShowSetupSteps_when_retrieveJetpackPluginDetails_is_success_then_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        // When
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                    completion(.success(plugin))
            default:
                break
            }
        }
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.shouldShowSetupSteps)
    }

    func test_shouldShowGoToStoreButton_is_correct() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        let data = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "test@mail.com"))
        )
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(data))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertFalse(viewModel.shouldShowGoToStoreButton)

        // When
        viewModel.didAuthorizeJetpackConnection()
        waitUntil { viewModel.shouldShowGoToStoreButton }

        // Then
        XCTAssertTrue(viewModel.shouldShowGoToStoreButton)
    }

    // MARK: - API calls
    func test_startSetup_triggers_connection_step_if_connectionOnly_is_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let connectionService = MockJetpackConnectionService()
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials,
                                              stores: stores, connectionService: connectionService)

        var triggeredRetrieveJetpackPluginDetails = false
        var triggeredInstallation = false
        var triggeredActivation = false
        var triggeredConnectionURL = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails:
                triggeredRetrieveJetpackPluginDetails = true
            case .installJetpackPlugin:
                triggeredInstallation = true
            case .activateJetpackPlugin:
                triggeredActivation = true
            case .fetchJetpackConnectionURL:
                triggeredConnectionURL = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { connectionService.evaluateAndConnectCallCount > 0 }

        // Then
        XCTAssertFalse(triggeredRetrieveJetpackPluginDetails)
        XCTAssertFalse(triggeredInstallation)
        XCTAssertFalse(triggeredActivation)
        XCTAssertFalse(triggeredConnectionURL)
        XCTAssertEqual(connectionService.evaluateAndConnectCallCount, 1)
    }

    func test_startSetup_triggers_installation_steps_if_connectionOnly_is_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let connectionService = MockJetpackConnectionService()
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials,
                                              stores: stores, connectionService: connectionService)

        var triggeredRetrieveJetpackPluginDetails = false
        var triggeredInstallation = false
        var triggeredActivation = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                triggeredRetrieveJetpackPluginDetails = true
                completion(.failure(NetworkError.notFound(response: nil)))
            case .installJetpackPlugin(_, let completion):
                triggeredInstallation = true
                completion(.success(()))
            case .activateJetpackPlugin(_, let completion):
                triggeredActivation = true
                completion(.success(()))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { connectionService.evaluateAndConnectCallCount > 0 }

        // Then
        XCTAssertTrue(triggeredRetrieveJetpackPluginDetails)
        XCTAssertTrue(triggeredInstallation)
        XCTAssertTrue(triggeredActivation)
        XCTAssertEqual(connectionService.evaluateAndConnectCallCount, 1)
    }

    func test_startSetup_triggers_jetpack_installation_if_retrieving_details_fails_with_404() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        var triggeredJetpackInstallation = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                let error = NetworkError.notFound(response: nil)
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        var triggeredInstallation = false
        var triggeredActivation = false
        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
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
        let connectionService = MockJetpackConnectionService()
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials,
                                              stores: stores, connectionService: connectionService)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .active)

        var triggeredInstallation = false
        var triggeredActivation = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(plugin))
            case .installJetpackPlugin:
                triggeredInstallation = true
            case .activateJetpackPlugin:
                triggeredActivation = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Step state is set synchronously before the async Task
        XCTAssertTrue(viewModel.isSetupStepInProgress(.connection))
        XCTAssertFalse(viewModel.isSetupStepPending(.installation))
        XCTAssertFalse(viewModel.isSetupStepPending(.activation))
        XCTAssertTrue(viewModel.isSetupStepPending(.done))

        waitUntil { connectionService.evaluateAndConnectCallCount > 0 }

        // Then
        XCTAssertFalse(triggeredInstallation)
        XCTAssertFalse(triggeredActivation)
        XCTAssertEqual(connectionService.evaluateAndConnectCallCount, 1)
    }

    func test_installation_triggers_activation_when_completing_successfully() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              stores: stores)

        var triggeredActivation = false
        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                let error = NetworkError.notFound(response: nil)
                completion(.failure(error))
            case .installJetpackPlugin(_, let completion):
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

    func test_activation_success_triggers_connection_service() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let connectionService = MockJetpackConnectionService()
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials,
                                              stores: stores, connectionService: connectionService)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.notFound(response: nil)))
            case .installJetpackPlugin(_, let completion):
                completion(.success(()))
            case .activateJetpackPlugin(_, let completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { connectionService.evaluateAndConnectCallCount > 0 }

        // Then
        XCTAssertEqual(connectionService.evaluateAndConnectCallCount, 1)
    }

    func test_activation_triggers_fetching_connection_url_when_site_has_outdated_jetpack() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let connectionService = MockJetpackConnectionService()
        connectionService.evaluateAndConnectResult = .success(.webViewRequired)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials,
                                              stores: stores, connectionService: connectionService)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.notFound(response: nil)))
            case .installJetpackPlugin(_, let completion):
                completion(.success(()))
            case .activateJetpackPlugin(_, let completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { connectionService.fetchJetpackConnectionURLCallCount > 0 }

        // Then
        XCTAssertEqual(connectionService.evaluateAndConnectCallCount, 1)
        XCTAssertEqual(connectionService.fetchJetpackConnectionURLCallCount, 1)
    }

    func test_shouldPresentWebView_is_true_when_fetching_connection_url_returns_account_connection_url() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials, stores: stores)
        let testConnectionURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize"))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake()))
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: nil)))
            case .fetchJetpackConnectionURL(_, let completion):
                completion(.success(testConnectionURL))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.shouldPresentWebView }

        // Then
        XCTAssertTrue(viewModel.shouldPresentWebView)
        XCTAssertEqual(viewModel.jetpackConnectionURL, testConnectionURL)
    }

    func test_shouldPresentWebView_is_true_when_fetching_connection_url_returns_site_connection_url() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials, stores: stores)
        let testConnectionURL = try XCTUnwrap(URL(string: "\(testURL)/plugins/jetpack"))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake()))
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: nil)))
            case .fetchJetpackConnectionURL(_, let completion):
                completion(.success(testConnectionURL))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.shouldPresentWebView }

        // Then
        XCTAssertTrue(viewModel.shouldPresentWebView)
        let expectedURL = "\(testURL)/wp-admin/admin.php?page=jetpack"
        XCTAssertEqual(viewModel.jetpackConnectionURL, URL(string: expectedURL))
    }

    func test_authorizeJetpackConnection_sets_connection_status_to_in_progress_and_triggers_fetching_jetpack_connection() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        var triggeredFetchingJetpackConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                triggeredFetchingJetpackConnection = true
                completion(.success(JetpackConnectionData.fake().copy(
                    currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "test@mail.com"))
                )))
            default:
                break
            }
        }

        // When
        viewModel.didAuthorizeJetpackConnection()

        // Connection step is set synchronously before the async Task
        XCTAssertEqual(viewModel.currentConnectionStep, .inProgress)

        waitUntil { triggeredFetchingJetpackConnection }

        // Then
        XCTAssertTrue(triggeredFetchingJetpackConnection)
    }

    func test_authorizeJetpackConnection_updates_connection_status_and_setup_step_correctly_when_fetching_jetpack_connection_successfully() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        let data = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "test@mail.com"))
        )
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(data))
            default:
                break
            }
        }

        // When
        viewModel.didAuthorizeJetpackConnection()
        waitUntil { viewModel.currentConnectionStep == .authorized }

        // Then
        XCTAssertEqual(viewModel.currentConnectionStep, .authorized)
        XCTAssertEqual(viewModel.currentSetupStep, .done)
    }

    func test_navigateToStore_triggers_storeNavigationHandler() {
        // Given
        var storeNavigationTriggered = false
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              onStoreNavigation: { _ in
            storeNavigationTriggered = true
        })

        // When
        viewModel.navigateToStore()

        // Then
        XCTAssertTrue(storeNavigationTriggered)
    }

    // MARK: - Error handling
    func test_setupFailed_is_true_when_retrieveJetpackPluginDetails_encounters_permission_error() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        XCTAssertFalse(viewModel.setupFailed)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 403, response: nil)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.setupFailed)
        XCTAssertTrue(viewModel.hasEncounteredPermissionError)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.permissionErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.permissionErrorSuggestion,
                                                         errorCode: 403))
    }

    func test_retrieveJetpackPluginDetails_triggers_installJetpack_when_encountering_non_permission_error() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        var installJetpackTriggered = false

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.notFound(response: nil)))
            case .installJetpackPlugin:
                installJetpackTriggered = true
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(installJetpackTriggered)
    }

    func test_installJetpack_relays_error_when_failed() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.notFound(response: nil)))
            case .installJetpackPlugin(_, let completion):
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 501, response: nil)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.setupFailed)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.communicationErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: 501))
    }

    func test_activateJetpack_relays_error_when_failed() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(plugin))
            case .activateJetpackPlugin(_, let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.setupFailed)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: -1001))
    }

    func test_register_connection_relays_error_when_failed() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: false)))
            case .registerSite(let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.setupFailed }

        // Then
        XCTAssertTrue(viewModel.setupFailed)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: -1001))
    }

    func test_provision_connection_relays_error_when_failed() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: true, blogID: 123)))
            case .provisionConnection(let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.setupFailed }

        // Then
        XCTAssertTrue(viewModel.setupFailed)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: -1001))
    }

    func test_finalize_connection_relays_error_when_failed() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: true, blogID: 123)))
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 124, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.setupFailed }

        // Then
        XCTAssertTrue(viewModel.setupFailed)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: -1001))
    }

    func test_fetchJetpackConnectionURL_relays_error_when_failed() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: true, wpcomCredentials: credentials, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake()))
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: nil)))
            case .fetchJetpackConnectionURL(_, let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.setupFailed }

        // Then
        XCTAssertTrue(viewModel.setupFailed)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: -1001))
    }

    func test_checkJetpackConnection_hits_fetchJetpackConnection_3_times_when_encountering_error_consistently_and_relays_error() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        var fetchJetpackConnectionTriggerCount = 0

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                fetchJetpackConnectionTriggerCount += 1
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.didAuthorizeJetpackConnection()

        // Then
        waitUntil {
            viewModel.setupFailed
        }
        XCTAssertEqual(fetchJetpackConnectionTriggerCount, 3)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: -1001))
    }

    func test_checkJetpackConnection_hits_fetchJetpackConnectionData_3_times_when_failing_to_fetch_connected_wpcom_user() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, siteID: 0, connectionOnly: false, wpcomCredentials: credentials, stores: stores)
        var fetchJetpackConnectionTriggerCount = 0

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                fetchJetpackConnectionTriggerCount += 1
                completion(.success(JetpackConnectionData.fake().copy(currentUser: .fake().copy(wpcomUser: nil))))
            default:
                break
            }
        }

        // When
        viewModel.didAuthorizeJetpackConnection()

        // Then
        waitUntil {
            viewModel.setupFailed
        }
        XCTAssertEqual(fetchJetpackConnectionTriggerCount, 3)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: 99))
    }

    func test_alreadyConnected_completes_setup_without_tracking_connection_step() {
        // Given
        let connectionService = MockJetpackConnectionService()
        connectionService.evaluateAndConnectResult = .success(.alreadyConnected(email: "user@example.com"))
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: true,
                                              wpcomCredentials: credentials,
                                              connectionService: connectionService)

        // When
        viewModel.startSetup()
        waitUntil { viewModel.currentSetupStep == .done }

        // Then
        XCTAssertEqual(viewModel.currentSetupStep, .done)
        XCTAssertEqual(viewModel.currentConnectionStep, .authorized)
        XCTAssertFalse(viewModel.setupFailed)
        XCTAssertEqual(connectionService.evaluateAndConnectCallCount, 1)
    }

    // MARK: - Analytics
    func test_it_tracks_when_tapping_go_to_store_button() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        // When
        // Tapping "Go to Store" button
        viewModel.navigateToStore()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["tap"] as? String, "go_to_store")
    }

    func test_it_tracks_correct_event_when_jetpack_installation_starts() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)
        let error = NetworkError.notFound(response: nil)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "installation")
        XCTAssertNil(analyticsProvider.receivedProperties[indexOfEvent]["error_code"])
    }

    func test_it_tracks_correct_event_when_jetpack_installation_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NetworkError.notFound(response: nil)))
            case .installJetpackPlugin(_, let completion):
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 403, response: nil)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "installation")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["error_code"] as? String, "403")
    }

    func test_it_tracks_correct_event_when_jetpack_activation_starts() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)
        let error = NetworkError.notFound(response: nil)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(error))
            case .installJetpackPlugin(_, let completion):
                completion(.success(()))
            case .activateJetpackPlugin(_, let completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "activation")
        XCTAssertNil(analyticsProvider.receivedProperties[indexOfEvent]["error_code"])
    }

    func test_it_tracks_correct_event_when_jetpack_activation_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake().copy(status: .inactive)))
            case .activateJetpackPlugin(_, let completion):
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 403, response: nil)))
            default:
                break
            }
        }
        // When
        viewModel.startSetup()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "activation")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["error_code"] as? String, "403")
    }

    func test_it_tracks_correct_event_when_connection_step_starts() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let connectionService = MockJetpackConnectionService()
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: true,
                                              wpcomCredentials: credentials,
                                              analytics: analytics,
                                              connectionService: connectionService)

        // When
        viewModel.startSetup()
        waitUntil { viewModel.currentSetupStep == .done }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.indices.last(where: {
            analyticsProvider.receivedEvents[$0] == "jetpack_setup_flow" &&
            analyticsProvider.receivedProperties[$0]["step"] as? String == "connection"
        }))
        XCTAssertNil(analyticsProvider.receivedProperties[indexOfEvent]["error_code"])
    }

    func test_it_tracks_correct_event_when_connection_step_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: true,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake()))
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: true, blogID: 123)))
            case .provisionConnection(let completion):
                let error = NSError(domain: "Test", code: 1)
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.setupFailed }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "connection")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["error_code"] as? String, "1")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["connection_type"] as? String, "native")
    }

    func test_it_tracks_correct_event_when_fetching_jetpack_connection_url_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: true,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake()))
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: nil)))
            case .fetchJetpackConnectionURL(_, let completion):
                let fetchError = NSError(domain: "Test", code: 1)
                completion(.failure(fetchError))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil { viewModel.setupFailed }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "connection")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["error_code"] as? String, "1")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["connection_type"] as? String, "web")
    }

    func test_it_tracks_correct_event_when_checking_jetpack_connection_is_successful() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: true,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        let data = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "test@mail.com"))
        )
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(data))
            default:
                break
            }
        }

        // When
        viewModel.didAuthorizeJetpackConnection()
        waitUntil { viewModel.currentSetupStep == .done }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "all_done")
    }

    func test_it_tracks_correct_event_when_checking_jetpack_connection_is_successful_but_no_wpCom_user_present() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: true,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                let data = JetpackConnectionData.fake().copy(
                    currentUser: .fake().copy(isConnected: true, wpcomUser: nil),
                    isRegistered: true,
                    blogID: 123
                )
                completion(.success(data))
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 124, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()
        waitUntil {
            viewModel.setupFailed
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "connection")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["error_code"] as? String, "99")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["connection_type"] as? String, "native")
    }

    func test_it_tracks_correct_event_when_retrying_setup() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL,
                                              siteID: 0,
                                              connectionOnly: false,
                                              wpcomCredentials: credentials,
                                              stores: stores,
                                              analytics: analytics)

        // When
        viewModel.retryAllSteps()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "installation")
        XCTAssertNil(analyticsProvider.receivedProperties[indexOfEvent]["error_code"])
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["connection_type"] as? String, "native")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["tap"] as? String, "retry")
    }
}

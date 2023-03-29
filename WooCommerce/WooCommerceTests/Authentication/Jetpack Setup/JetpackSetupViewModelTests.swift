import XCTest
import Yosemite
@testable import WooCommerce
import enum Alamofire.AFError
import WordPressAuthenticator

final class JetpackSetupViewModelTests: XCTestCase {
    private let testURL = "https://example.com"

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeAuthenticator()
    }

    // MARK: UI-related

    func test_title_is_correct_if_jetpack_installation_is_required() {
        // Given
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false)

        // Then
        XCTAssertEqual(viewModel.title, JetpackSetupViewModel.Localization.installingJetpack)
    }

    func test_title_is_correct_if_only_jetpack_connection_is_missing() {
        // Given
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: true)

        // Then
        XCTAssertEqual(viewModel.title, JetpackSetupViewModel.Localization.connectingJetpack)
    }

    func test_description_string_is_correct() {
        // Given
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false)
        let description = String(format: JetpackSetupViewModel.Localization.description, testURL.trimHTTPScheme())

        // Then
        XCTAssertEqual(viewModel.descriptionAttributedString.string, description)
    }

    func test_isSetupStepFailed_is_correct_when_the_current_step_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(plugin))
            case .activateJetpackPlugin(let completion):
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403))))
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))))
            case .installJetpackPlugin(let completion):
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(plugin))
            case .activateJetpackPlugin(let completion):
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .active)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(plugin))
            case .fetchJetpackConnectionURL(let completion):
                completion(.failure(NSError(domain: "Test", code: -1001)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertEqual(viewModel.title, JetpackInstallStep.connection.errorTitle)
        XCTAssertEqual(viewModel.tryAgainButtonTitle, JetpackInstallStep.connection.tryAgainButtonTitle)
    }

    func test_shouldShowInitialLoadingIndicator_turns_on_correctly_when_startSetup_then_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        // When
        viewModel.startSetup()

        // Then
        XCTAssertTrue(viewModel.shouldShowInitialLoadingIndicator)

    }

    func test_shouldShowInitialLoadingIndicator_turns_off_correctly_when_retrieveJetpackPluginDetails_is_success_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        // When
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        // When
        viewModel.startSetup()

        // Then
        XCTAssertFalse(viewModel.shouldShowSetupSteps)

    }

    func test_shouldShowSetupSteps_when_retrieveJetpackPluginDetails_is_success_then_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        // When
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

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
        viewModel.startSetup()

        // Then
        XCTAssertFalse(viewModel.shouldShowGoToStoreButton)

        // When
        viewModel.didAuthorizeJetpackConnection()

        // Then
        XCTAssertTrue(viewModel.shouldShowGoToStoreButton)
    }

    // MARK: - API calls
    func test_startSetup_triggers_jetpack_installation_if_retrieving_details_fails_with_404() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        var triggeredJetpackInstallation = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        var triggeredActivation = false
        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        var triggeredConnection = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
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

    func test_shouldPresentWebView_is_true_when_fetching_connection_url_returns_account_connection_url() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let testConnectionURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize"))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
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

    func test_shouldPresentWebView_is_true_when_fetching_connection_url_returns_site_connection_url() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let testConnectionURL = try XCTUnwrap(URL(string: "\(testURL)/plugins/jetpack"))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
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
        let mobileRedirectURL = "woocommerce://jetpack-connected"
        let expectedURL = "https://wordpress.com/jetpack/connect?url=\(testURL)&mobile_redirect=\(mobileRedirectURL)&from=mobile"
        XCTAssertEqual(viewModel.jetpackConnectionURL, URL(string: expectedURL))
    }

    func test_authorizeJetpackConnection_sets_connection_status_to_in_progress_and_triggers_fetching_jetpack_user() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

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
        viewModel.didAuthorizeJetpackConnection()

        // Then
        XCTAssertTrue(triggeredFetchingJetpackUser)
        XCTAssertEqual(viewModel.currentConnectionStep, .inProgress)
    }

    func test_authorizeJetpackConnection_updates_connection_status_and_setup_step_correctly_when_fetching_jetpack_user_successfully() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

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
        viewModel.didAuthorizeJetpackConnection()

        // Then
        XCTAssertEqual(viewModel.currentConnectionStep, .authorized)
        XCTAssertEqual(viewModel.currentSetupStep, .done)
    }

    func test_navigateToStore_triggers_storeNavigationHandler() {
        // Given
        var storeNavigationTriggered = false
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, onStoreNavigation: { _ in
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        XCTAssertFalse(viewModel.setupFailed)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403))))
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        var installJetpackTriggered = false

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))))
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))))
            case .installJetpackPlugin(let completion):
                completion(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 501))))
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
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .inactive)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(plugin))
            case .activateJetpackPlugin(let completion):
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

    func test_fetchJetpackConnectionURL_relays_error_when_failed() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        let plugin = SitePlugin.fake().copy(plugin: "Jetpack", status: .active)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(plugin))
            case .fetchJetpackConnectionURL(let completion):
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

    func test_checkJetpackConnection_hits_fetchJetpackUser_3_times_when_encountering_error_consistently_and_relays_error() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        var fetchJetpackUserTriggerCount = 0

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser(let completion):
                fetchJetpackUserTriggerCount += 1
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
        XCTAssertEqual(fetchJetpackUserTriggerCount, 3)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: -1001))
    }

    func test_checkJetpackConnection_hits_fetchJetpackUser_3_times_when_failing_to_fetch_connected_wpcom_user() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores)
        var fetchJetpackUserTriggerCount = 0

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser(let completion):
                fetchJetpackUserTriggerCount += 1
                completion(.success(JetpackUser.fake().copy(wpcomUser: nil)))
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
        XCTAssertEqual(fetchJetpackUserTriggerCount, 3)
        XCTAssertEqual(viewModel.setupErrorDetail, .init(setupErrorMessage: JetpackSetupViewModel.Localization.genericErrorMessage,
                                                         setupErrorSuggestion: JetpackSetupViewModel.Localization.communicationErrorSuggestion,
                                                         errorCode: 99))
    }

    // MARK: - Analytics
    func test_it_tracks_login_jetpack_setup_go_to_store_button_tapped_when_tapping_go_to_store_button() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, analytics: analytics)

        // When
        // Tapping "Go to Store" button
        viewModel.navigateToStore()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_go_to_store_button_tapped" }))
    }

    func test_it_tracks_correct_event_when_jetpack_installation_is_successful() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_install_successful" }))
    }

    func test_it_tracks_correct_event_when_jetpack_installation_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_install_failed" }))
    }

    func test_it_tracks_correct_event_when_jetpack_activation_is_successful() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            case .activateJetpackPlugin(let completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_activation_successful" }))
    }

    func test_it_tracks_correct_event_when_jetpack_activation_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            case .activateJetpackPlugin(let completion):
                completion(.failure(error))
            default:
                break
            }
        }
        // When
        viewModel.startSetup()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_activation_failed" }))
    }

    func test_it_tracks_correct_event_when_fetching_jetpack_connection_url_is_successful() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
        let testConnectionURL = try XCTUnwrap(URL(string: "https://test-connection.com"))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            case .activateJetpackPlugin(let completion):
                completion(.success(()))
            case .fetchJetpackConnectionURL(let completion):
                completion(.success((testConnectionURL)))
            default:
                break
            }
        }

        // When
        viewModel.startSetup()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_fetch_jetpack_connection_url_successful" }))
    }

    func test_it_tracks_correct_event_when_fetching_jetpack_connection_url_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(error))
            case .installJetpackPlugin(let completion):
                completion(.success(()))
            case .activateJetpackPlugin(let completion):
                completion(.success(()))
            case .fetchJetpackConnectionURL(let completion):
                let fetchError = NSError(domain: "Test", code: 1)
                completion(.failure(fetchError))
            default:
                break
            }
        }
        // When
        viewModel.startSetup()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_fetch_jetpack_connection_url_failed" }))
    }

    func test_it_tracks_correct_event_when_checking_jetpack_connection_is_successful() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)

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
        viewModel.didAuthorizeJetpackConnection()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_all_steps_marked_done" }))
    }

    func test_it_tracks_correct_event_when_checking_jetpack_connection_is_successful_but_no_wpCom_user_present() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)

        let user = JetpackUser.fake().copy(isConnected: true, wpcomUser: nil)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser(let completion):
                completion(.success(user))
            default:
                break
            }
        }

        // When
        viewModel.didAuthorizeJetpackConnection()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_cannot_find_WPCOM_user" }))
    }

    func test_it_tracks_correct_event_when_checking_jetpack_connection_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, stores: stores, analytics: analytics)

        let error = NSError(domain: "Test", code: 1)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser(let completion):
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.didAuthorizeJetpackConnection()

        waitUntil {
            analyticsProvider.receivedEvents.isNotEmpty
        }

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_error_checking_jetpack_connection" }))
    }

    func test_it_tracks_correct_event_when_retying_setup() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = JetpackSetupViewModel(siteURL: testURL, connectionOnly: false, analytics: analytics)

        // When
        viewModel.retryAllSteps()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_try_again_button_tapped" }))
    }
}

import Testing
import Foundation
import Yosemite
import UserNotifications
import protocol WooFoundation.ConnectivityObserver
@testable import Networking
@testable import WooCommerce

@MainActor
struct SupportDiagnosticsServiceTests {

    private typealias Test = SupportDiagnosticsService.Test
    private typealias Action = SupportDiagnosticsService.Action

    // MARK: - SupportIssueType Tests

    @Test func test_SupportIssueType_loadingOrders_returns_correct_tests() {
        // Given
        let issueType = SupportIssueType.loadingOrders

        // When
        let tests = issueType.testsToRun

        // Then
        let expected: [Test] = [.internetConnection, .site, .siteOrders]
        #expect(tests == expected)
    }

    @Test func test_SupportIssueType_loadingProducts_returns_correct_tests() {
        // Given
        let issueType = SupportIssueType.loadingProducts

        // When
        let tests = issueType.testsToRun

        // Then
        let expected: [Test] = [.internetConnection, .site, .loadingProducts]
        #expect(tests == expected)
    }

    @Test func test_SupportIssueType_loadingAnalytics_returns_correct_tests() {
        // Given
        let issueType = SupportIssueType.loadingAnalytics

        // When
        let tests = issueType.testsToRun

        // Then
        let expected: [Test] = [.internetConnection, .site, .analyticsSetting]
        #expect(tests == expected)
    }

    @Test func test_SupportIssueType_receivingNotifications_returns_correct_tests() {
        // Given
        let issueType = SupportIssueType.receivingNotifications

        // When
        let tests = issueType.testsToRun

        // Then
        let expected: [Test] = [.internetConnection, .site, .notifications]
        #expect(tests == expected)
    }

    @Test func test_SupportIssueType_other_returns_nil_tests() {
        // Given
        let issueType = SupportIssueType.other

        // When
        let tests = issueType.testsToRun

        // Then
        #expect(tests == nil)
    }

    // MARK: - Internet Connection Tests

    @Test func test_testInternetConnection_when_reachable_then_returns_success() async {
        // Given
        let mockConnectivityObserver = MockConnectivityObserver()
        mockConnectivityObserver.setStatus(.reachable(type: .ethernetOrWiFi))
        let sut = makeSUT(connectivityObserver: mockConnectivityObserver)

        // When
        let results = await sut.runTests([Test.internetConnection])

        // Then
        #expect(results.count == 1)
        #expect(results[0].isSuccess == true)
        #expect(results[0].test == Test.internetConnection)
    }

    @Test func test_testInternetConnection_when_unreachable_then_returns_failure() async {
        // Given
        let mockConnectivityObserver = MockConnectivityObserver()
        mockConnectivityObserver.setStatus(.notReachable)
        let sut = makeSUT(connectivityObserver: mockConnectivityObserver)

        // When
        let results = await sut.runTests([Test.internetConnection])

        // Then
        #expect(results.count == 1)
        #expect(results[0].isSuccess == false)
        #expect(results[0].test == Test.internetConnection)
        #expect(results[0].errorMessage?.contains("not connected") == true)
    }

    // MARK: - Analytics Setting Tests

    @Test func test_testAnalyticsSetting_when_enabled_then_returns_success() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        let results = await sut.runTests([Test.analyticsSetting])

        // Then
        #expect(results.count == 1)
        #expect(results[0].isSuccess == true)
        #expect(results[0].test == Test.analyticsSetting)
    }

    @Test func test_testAnalyticsSetting_when_disabled_then_returns_failure_with_enableAnalytics_action() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        let results = await sut.runTests([Test.analyticsSetting])

        // Then
        #expect(results.count == 1)
        #expect(results[0].isSuccess == false)
        #expect(results[0].test == Test.analyticsSetting)
        #expect(results[0].suggestedAction == Action.enableAnalytics)
        #expect(results[0].errorMessage?.contains("not enabled") == true)
    }

    @Test func test_testAnalyticsSetting_when_request_fails_then_returns_failure_with_technical_details() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let testError = NSError(domain: "TestDomain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.failure(testError))
            default:
                break
            }
        }
        let sut = makeSUT(stores: stores)

        // When
        let results = await sut.runTests([Test.analyticsSetting])

        // Then
        #expect(results.count == 1)
        #expect(results[0].isSuccess == false)
        #expect(results[0].technicalDetails != nil)
    }

    // MARK: - Notifications Tests

    @Test func test_testNotifications_when_jetpack_not_active_then_returns_failure_with_setupJetpack_action() async {
        // Given
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let sut = makeSUT(userNotificationCenter: mockUserNotificationCenter)
        // activeSystemPlugins is empty by default, so Jetpack is not active

        // When
        let results = await sut.runTests([Test.notifications])

        // Then
        #expect(results.count == 1)
        #expect(results[0].isSuccess == false)
        #expect(results[0].suggestedAction == Action.setupJetpack)
    }

    @Test func test_testNotifications_when_permission_denied_then_returns_failure_with_openSettings_action() async {
        // Given
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .denied
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(userNotificationCenter: mockUserNotificationCenter, network: network)

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[0].isSuccess == true)
        #expect(results[1].isSuccess == false)
        #expect(results[1].suggestedAction == Action.openNotificationSettings)
    }

    @Test func test_testNotifications_when_registered_for_self_driven_PN_then_returns_success() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(Self.enabledPushNotificationPreferences()))
            }
        }
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [123])
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            stores: stores,
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            network: network,
            siteID: 123
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[0].isSuccess == true)
        #expect(results[1].isSuccess == true)
    }

    @Test func test_testNotifications_when_registered_for_self_driven_PN_and_some_preferences_disabled_then_returns_failure_with_openPreferences_action() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.success(PushNotificationPreferences(storeOrder: .init(enabled: false),
                                                                  storeReview: .init(enabled: true),
                                                                  storeStock: .init(enabled: true))))
            }
        }
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [123])
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            stores: stores,
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            network: network,
            siteID: 123
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[1].isSuccess == false)
        #expect(results[1].suggestedAction == Action.openPushNotificationPreferences)
    }

    @Test func test_testNotifications_when_registered_for_self_driven_PN_and_preferences_fetch_fails_then_returns_success() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            if case let .loadPushNotificationPreferences(_, onCompletion) = action {
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            }
        }
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [123])
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            stores: stores,
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            network: network,
            siteID: 123
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[1].isSuccess == true)
    }

    @Test func test_testNotifications_when_not_eligible_for_self_driven_PN_and_device_not_registered_then_returns_failure_with_registerDevice_action() async {
        // Given
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: nil)
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = false
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            network: network
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[0].isSuccess == true)
        #expect(results[1].isSuccess == false)
        #expect(results[1].suggestedAction == Action.registerDevice)
    }

    @Test func test_testNotifications_when_eligible_for_self_driven_PN_and_site_not_registered_then_returns_failure_with_registerDevice_action() async {
        // Given
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [])
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            network: network
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[0].isSuccess == true)
        #expect(results[1].isSuccess == false)
        #expect(results[1].suggestedAction == Action.registerDevice)
    }

    @Test func test_testNotifications_when_eligible_for_self_driven_PN_site_not_registered_and_WPCom_notifications_enabled_then_returns_success() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            if case let .loadNotificationSettings(_, onCompletion) = action {
                onCompletion(.success(NotificationSettings(deviceID: 123, enabledSites: [123], disabledSites: [])))
            }
        }
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: "123", siteIDsRegisteredForWooPNs: [])
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let pluginVersionChecker = MockPluginVersionChecker()
        var didCheckPluginVersion = false
        pluginVersionChecker.onCheckCompatibility = {
            didCheckPluginVersion = true
        }
        let pluginVersionCheckerFactory = MockPluginVersionCheckerFactory(checker: pluginVersionChecker)
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            stores: stores,
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            pluginVersionCheckerFactory: pluginVersionCheckerFactory,
            network: network
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[0].isSuccess == true)
        #expect(results[1].isSuccess == true)
        #expect(didCheckPluginVersion == false)
    }

    @Test func test_testNotifications_when_eligible_for_self_driven_PN_site_not_registered_and_WPCom_order_notifications_disabled_then_returns_failure_with_enable_action() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let settings = NotificationSettings(deviceID: 123, enabledSites: [], disabledSites: [123])
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            if case let .loadNotificationSettings(_, onCompletion) = action {
                onCompletion(.success(settings))
            }
        }
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: "123", siteIDsRegisteredForWooPNs: [])
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            stores: stores,
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            network: network
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[0].isSuccess == true)
        #expect(results[1].isSuccess == false)
        #expect(results[1].suggestedAction == Action.enableOrderNotifications(settings: settings))
    }

    @Test func test_testNotifications_when_eligible_for_self_driven_PN_and_plugin_is_outdated_then_returns_failure_with_updatePlugin_action() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let mockUserNotificationCenter = MockUserNotificationsCenterAdapter()
        mockUserNotificationCenter.authorizationStatus = .authorized
        let mockPushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [])
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let pluginVersionChecker = MockPluginVersionChecker()
        pluginVersionChecker.result = .success(.incompatible(currentVersion: "10.0.0", requiredVersion: WooPluginRequirements.minimumVersion))
        let pluginVersionCheckerFactory = MockPluginVersionCheckerFactory(checker: pluginVersionChecker)
        let network = makeNetworkWithJetpackActive()
        let sut = makeSUT(
            stores: stores,
            userNotificationCenter: mockUserNotificationCenter,
            pushNotesManager: mockPushNotesManager,
            pushNotificationEligibilityChecker: eligibilityChecker,
            pluginVersionCheckerFactory: pluginVersionCheckerFactory,
            network: network
        )

        // When
        let results = await sut.runTests([Test.site, Test.notifications])

        // Then
        #expect(results.count == 2)
        #expect(results[0].isSuccess == true)
        #expect(results[1].isSuccess == false)
        #expect(results[1].suggestedAction == Action.updateWooCommercePlugin)
        #expect(results[1].errorMessage?.contains(WooPluginRequirements.minimumVersion) == true)
    }

    // MARK: - Sequential Test Execution

    @Test func test_runTests_stops_at_first_failure() async {
        // Given
        let mockConnectivityObserver = MockConnectivityObserver()
        mockConnectivityObserver.setStatus(.notReachable)
        let sut = makeSUT(connectivityObserver: mockConnectivityObserver)

        // When
        let tests: [Test] = [.internetConnection, .wpComServers, .site]
        let results = await sut.runTests(tests)

        // Then
        #expect(results.count == 1)
        #expect(results[0].test == Test.internetConnection)
        #expect(results[0].isSuccess == false)
    }

    // MARK: - Enable Analytics Action

    @Test func test_enableAnalytics_when_succeeds_then_completes_without_error() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .enableAnalyticsSetting(_, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let sut = makeSUT(stores: stores)

        // When / Then
        try await sut.enableAnalytics()
    }

    @Test func test_enableAnalytics_when_fails_twice_then_throws_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let testError = NSError(domain: "TestDomain", code: 500, userInfo: nil)
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .enableAnalyticsSetting(_, onCompletion):
                onCompletion(.failure(testError))
            default:
                break
            }
        }
        let sut = makeSUT(stores: stores)

        // When / Then
        do {
            try await sut.enableAnalytics()
            Issue.record("Expected enableAnalytics to throw an error")
        } catch {
            // Expected
        }
    }

    // MARK: - Register Device Action

    @Test func test_registerDevice_calls_pushNotesManager() async throws {
        // Given
        let mockPushNotesManager = MockPushNotificationsManager()
        mockPushNotesManager.registerDeviceAndWaitForTokenAcceptanceResult = .success(12345)
        let sut = makeSUT(pushNotesManager: mockPushNotesManager)

        // When
        try await sut.registerDevice()

        // Then - no direct spy property, but if no error thrown, registration succeeded
    }

    // MARK: - Troubleshooting Description

    @Test func test_troubleshootingDescription_returns_nil_for_empty_results() {
        // Given
        let results: [SupportDiagnosticsService.Result] = []

        // When
        let description = SupportDiagnosticsService.troubleshootingDescription(from: results)

        // Then
        #expect(description == nil)
    }

    @Test func test_troubleshootingDescription_includes_numbered_sections() {
        // Given
        let results = [
            SupportDiagnosticsService.Result.success(test: Test.internetConnection),
            SupportDiagnosticsService.Result.success(test: Test.wpComServers)
        ]

        // When
        let description = SupportDiagnosticsService.troubleshootingDescription(from: results)

        // Then
        #expect(description != nil)
        #expect(description?.contains("## 1.") == true)
        #expect(description?.contains("## 2.") == true)
    }

    @Test func test_troubleshootingDescription_includes_test_titles() {
        // Given
        let results = [
            SupportDiagnosticsService.Result.success(test: Test.internetConnection)
        ]

        // When
        let description = SupportDiagnosticsService.troubleshootingDescription(from: results)

        // Then
        #expect(description?.contains("Internet Connection") == true)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        stores: StoresManager? = nil,
        connectivityObserver: ConnectivityObserver? = nil,
        userNotificationCenter: UserNotificationsCenterAdapter? = nil,
        pushNotesManager: PushNotesManager? = nil,
        pushNotificationEligibilityChecker: WooPushNotificationEligibilityChecking? = nil,
        pluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol? = nil,
        network: MockNetwork? = nil,
        siteID: Int64 = 123
    ) -> SupportDiagnosticsService {
        let site = Site.fake().copy(siteID: siteID)
        let session = SessionManager.makeForTesting(authenticated: true, defaultSite: site)
        return SupportDiagnosticsService(
            session: session,
            stores: stores ?? MockStoresManager(sessionManager: session),
            connectivityObserver: connectivityObserver ?? MockConnectivityObserver(),
            userNotificationCenter: userNotificationCenter ?? MockUserNotificationsCenterAdapter(),
            pushNotesManager: pushNotesManager ?? MockPushNotificationsManager(),
            pushNotificationEligibilityChecker: pushNotificationEligibilityChecker ?? MockWooPushNotificationEligibilityChecker(),
            pluginVersionCheckerFactory: pluginVersionCheckerFactory ?? MockPluginVersionCheckerFactory(),
            network: network
        )
    }

    private func makeNetworkWithJetpackActive() -> MockNetwork {
        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "system-status-with-jetpack-active")
        return network
    }

    private static func enabledPushNotificationPreferences() -> PushNotificationPreferences {
        PushNotificationPreferences(storeOrder: .init(enabled: true),
                                    storeReview: .init(enabled: true),
                                    storeStock: .init(enabled: true))
    }
}

private final class MockPluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol {
    private let checker: MockPluginVersionChecker

    init(checker: MockPluginVersionChecker = MockPluginVersionChecker()) {
        self.checker = checker
    }

    func makeChecker(siteID: Int64, pluginPath: String, minimumVersion: String) -> PluginVersionCheckerProtocol {
        checker
    }
}

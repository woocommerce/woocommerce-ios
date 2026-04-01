import Testing
import Foundation
import Yosemite
import enum Networking.SitePluginStatusEnum
@testable import WooCommerce

@MainActor
struct ConnectivityToolViewModelTests {

    // MARK: - testAnalyticsSetting

    @Test func test_testAnalyticsSetting_when_analytics_enabled_then_returns_success() async {
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
        let sut = ConnectivityToolViewModel(session: SessionManager.makeForTesting(authenticated: true), stores: stores)

        // When
        let result = await sut.testAnalyticsSetting()

        // Then
        assertState(result, is: .success)
    }

    @Test func test_testAnalyticsSetting_when_analytics_disabled_then_returns_error_with_enable_action() async {
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
        let sut = ConnectivityToolViewModel(session: SessionManager.makeForTesting(authenticated: true), stores: stores)

        // When
        let result = await sut.testAnalyticsSetting()

        // Then
        guard case let .error(message, actions) = result else {
            Issue.record("Expected .error state but got \(result)")
            return
        }
        #expect(message.contains("not enabled"))
        #expect(actions.contains(where: { $0.title == "Enable Analytics" }))
    }

    @Test func test_testAnalyticsSetting_when_request_fails_then_returns_error_with_technical_details() async {
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
        let sut = ConnectivityToolViewModel(session: SessionManager.makeForTesting(authenticated: true), stores: stores)

        // When
        let result = await sut.testAnalyticsSetting()

        // Then
        guard case let .error(_, actions) = result else {
            Issue.record("Expected .error state but got \(result)")
            return
        }
        #expect(actions.contains(where: { $0.title == "View technical details" }))
    }

    // MARK: - enableAnalytics

    @Test func test_enableAnalytics_when_succeeds_then_updates_card_to_relaunch_message() async {
        // Given
        let stores = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(false))
            case let .enableAnalyticsSetting(_, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let sut = ConnectivityToolViewModel(session: SessionManager.makeForTesting(authenticated: true), stores: stores)

        // Run the analytics test to get back the error state with the enable action.
        let testResult = await sut.testAnalyticsSetting()
        guard case let .error(_, actions) = testResult,
              let enableAction = actions.first(where: { $0.title == "Enable Analytics" }) else {
            Issue.record("Expected error card with Enable Analytics action but got \(testResult)")
            return
        }

        // Inject a card for .analyticsSetting so enableAnalytics can find and update it.
        sut.cards.append(ConnectivityTool.Card(
            testCase: .analyticsSetting,
            title: ConnectivityToolViewModel.ConnectivityTest.analyticsSetting.title,
            icon: ConnectivityToolViewModel.ConnectivityTest.analyticsSetting.icon,
            state: testResult
        ))

        // When — trigger enableAnalytics through the action callback (simulates tapping the button).
        enableAction.action()

        // Then — MockStoresManager dispatches synchronously so the card update is immediate.
        let updatedCard = sut.cards.last(where: { $0.testCase == .analyticsSetting })
        guard case let .empty(message) = updatedCard?.state else {
            Issue.record("Expected .empty state after enabling analytics but got \(String(describing: updatedCard?.state))")
            return
        }
        #expect(message.contains("relaunch"))
    }

    @Test func test_enableAnalytics_when_fails_twice_then_restores_error_state() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(false))
            case let .enableAnalyticsSetting(_, onCompletion):
                let error = NSError(domain: "TestDomain", code: 500, userInfo: nil)
                onCompletion(.failure(error))
            default:
                break
            }
        }
        let sut = ConnectivityToolViewModel(session: SessionManager.makeForTesting(authenticated: true), stores: stores)

        // Run the analytics test to get back the error state with the enable action.
        let testResult = await sut.testAnalyticsSetting()
        guard case let .error(_, actions) = testResult,
              let enableAction = actions.first(where: { $0.title == "Enable Analytics" }) else {
            Issue.record("Expected error card with Enable Analytics action but got \(testResult)")
            return
        }

        sut.cards.append(ConnectivityTool.Card(
            testCase: .analyticsSetting,
            title: ConnectivityToolViewModel.ConnectivityTest.analyticsSetting.title,
            icon: ConnectivityToolViewModel.ConnectivityTest.analyticsSetting.icon,
            state: testResult
        ))

        // When — trigger enableAnalytics; it will fail, auto-retry (retries: 1), then restore error state.
        enableAction.action()

        // Then — after two synchronous failures, the card should be restored to the error state.
        let restoredCard = sut.cards.last(where: { $0.testCase == .analyticsSetting })
        guard case let .error(_, restoredActions) = restoredCard?.state else {
            Issue.record("Expected error state to be restored but got \(String(describing: restoredCard?.state))")
            return
        }
        #expect(restoredActions.contains(where: { $0.title == "Enable Analytics" }))
    }

    // MARK: - Analytics tracking

    @Test func test_trackResponseEvent_tracks_analytics_test_event() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        // When
        analytics.track(event: .ConnectivityTool.requestResponse(test: .analytics, success: true, timeTaken: 0.5))

        // Then
        #expect(analyticsProvider.receivedEvents.contains("connectivity_tool_request_response"))
        let properties = analyticsProvider.properties(for: "connectivity_tool_request_response")
        #expect(properties?["test"] as? String == "analytics")
        #expect(properties?["success"] as? Bool == true)
        #expect(properties?["time_taken"] as? Double == 0.5)
    }

    // MARK: - testNotifications

    @Test func test_testNotifications_when_wpcom_site_authorized_and_config_ok_then_returns_success() async {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let session = SessionManager.makeForTesting(authenticated: true, defaultSite: site)
        let stores = MockStoresManager(sessionManager: session)
        let mockNotificationCenter = MockUserNotificationsCenterAdapter()
        mockNotificationCenter.authorizationStatus = .authorized

        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: "123")
        let numericDeviceID = Int64(123)
        let device = NotificationSettings.Device(deviceID: numericDeviceID, newComment: true, storeOrder: true)
        let blog = NotificationSettings.Blog(blogID: site.siteID, devices: [device])
        let settings = NotificationSettings(blogs: [blog])

        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(settings))
            default:
                break
            }
        }

        let sut = ConnectivityToolViewModel(session: session, stores: stores,
                                            userNotificationCenter: mockNotificationCenter,
                                            pushNotesManager: mockPushNotesManager)

        // When
        let result = await sut.testNotifications()

        // Then
        assertState(result, is: .success)
    }

    @Test func test_testNotifications_when_jetpack_not_active_then_returns_error_with_setup_jetpack_action() async {
        // Given — self-hosted site (isWordPressComStore: false)
        let site = Site.fake().copy(isWordPressComStore: false)
        let session = SessionManager.makeForTesting(authenticated: true, defaultSite: site)
        let stores = MockStoresManager(sessionManager: session)
        let mockNotificationCenter = MockUserNotificationsCenterAdapter()
        mockNotificationCenter.authorizationStatus = .authorized

        let inactivePlugin = SitePlugin(siteID: site.siteID,
                                        plugin: "jetpack/jetpack",
                                        status: .inactive,
                                        name: "Jetpack",
                                        pluginUri: "",
                                        author: "",
                                        authorUri: "",
                                        descriptionRaw: "",
                                        descriptionRendered: "",
                                        version: "1.0",
                                        networkOnly: false,
                                        requiresWPVersion: "",
                                        requiresPHPVersion: "",
                                        textDomain: "")

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .retrieveJetpackPluginDetails(_, completion):
                completion(.success(inactivePlugin))
            default:
                break
            }
        }

        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: "123")
        let sut = ConnectivityToolViewModel(session: session, stores: stores,
                                            userNotificationCenter: mockNotificationCenter,
                                            pushNotesManager: mockPushNotesManager)

        // When
        let result = await sut.testNotifications()

        // Then
        guard case let .error(message, actions) = result else {
            Issue.record("Expected .error state but got \(result)")
            return
        }
        #expect(message.contains("Jetpack"))
        #expect(actions.contains(where: { $0.title == "Setup Jetpack" }))
    }

    @Test func test_testNotifications_when_permission_denied_then_returns_error_with_open_settings() async {
        // Given — WPCom site to skip Jetpack check
        let site = Site.fake().copy(isWordPressComStore: true)
        let session = SessionManager.makeForTesting(authenticated: true, defaultSite: site)
        let stores = MockStoresManager(sessionManager: session)
        let mockNotificationCenter = MockUserNotificationsCenterAdapter()
        mockNotificationCenter.authorizationStatus = .denied

        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: "123")
        let sut = ConnectivityToolViewModel(session: session, stores: stores,
                                            userNotificationCenter: mockNotificationCenter,
                                            pushNotesManager: mockPushNotesManager)

        // When
        let result = await sut.testNotifications()

        // Then
        guard case let .error(message, actions) = result else {
            Issue.record("Expected .error state but got \(result)")
            return
        }
        #expect(message.contains("not allowed"))
        #expect(actions.contains(where: { $0.title == "Open Settings" }))
    }

    @Test func test_testNotifications_when_no_device_id_then_returns_device_not_registered_error() async {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let session = SessionManager.makeForTesting(authenticated: true, defaultSite: site)
        let stores = MockStoresManager(sessionManager: session)
        let mockNotificationCenter = MockUserNotificationsCenterAdapter()
        mockNotificationCenter.authorizationStatus = .authorized

        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: nil)
        let sut = ConnectivityToolViewModel(session: session, stores: stores,
                                            userNotificationCenter: mockNotificationCenter,
                                            pushNotesManager: mockPushNotesManager)

        // When
        let result = await sut.testNotifications()

        // Then
        guard case let .error(message, actions) = result else {
            Issue.record("Expected .error state but got \(result)")
            return
        }
        #expect(message.contains("doesn't appear to be registered"))
        #expect(actions.contains(where: { $0.title == "Register Device" }))
        #expect(!actions.contains(where: { $0.title == "Retry" }))
    }

    @Test func test_testNotifications_when_order_notifications_disabled_then_returns_error_with_enable_action() async {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let session = SessionManager.makeForTesting(authenticated: true, defaultSite: site)
        let stores = MockStoresManager(sessionManager: session)
        let mockNotificationCenter = MockUserNotificationsCenterAdapter()
        mockNotificationCenter.authorizationStatus = .authorized

        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: "456")
        let numericDeviceID = Int64(456)
        let device = NotificationSettings.Device(deviceID: numericDeviceID, newComment: true, storeOrder: false)
        let blog = NotificationSettings.Blog(blogID: site.siteID, devices: [device])
        let settings = NotificationSettings(blogs: [blog])

        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(settings))
            default:
                break
            }
        }

        let sut = ConnectivityToolViewModel(session: session, stores: stores,
                                            userNotificationCenter: mockNotificationCenter,
                                            pushNotesManager: mockPushNotesManager)

        // When
        let result = await sut.testNotifications()

        // Then
        guard case let .error(message, actions) = result else {
            Issue.record("Expected .error state but got \(result)")
            return
        }
        #expect(message.contains("Order notifications are not enabled"))
        #expect(actions.contains(where: { $0.title == "Enable Order Notifications" }))
    }

    @Test func test_testNotifications_when_config_request_fails_then_returns_error_with_technical_details() async {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let session = SessionManager.makeForTesting(authenticated: true, defaultSite: site)
        let stores = MockStoresManager(sessionManager: session)
        let mockNotificationCenter = MockUserNotificationsCenterAdapter()
        mockNotificationCenter.authorizationStatus = .authorized

        let testError = NSError(domain: "TestDomain", code: 500, userInfo: nil)
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.failure(testError))
            default:
                break
            }
        }

        let mockPushNotesManager = MockPushNotificationsManager(mockedDeviceID: "789")
        let sut = ConnectivityToolViewModel(session: session, stores: stores,
                                            userNotificationCenter: mockNotificationCenter,
                                            pushNotesManager: mockPushNotesManager)

        // When
        let result = await sut.testNotifications()

        // Then
        guard case let .error(_, actions) = result else {
            Issue.record("Expected .error state but got \(result)")
            return
        }
        #expect(actions.contains(where: { $0.title == "View technical details" }))
    }

}

// MARK: - Helpers

private func assertState(_ actual: ConnectivityToolCard.ConnectivityState,
                          is expected: ConnectivityToolCard.ConnectivityState,
                          sourceLocation: SourceLocation = #_sourceLocation) {
    let matches: Bool = {
        switch (actual, expected) {
        case (.inProgress, .inProgress):
            return true
        case (.success, .success):
            return true
        case (.empty(let lhsMessage), .empty(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.error(let lhsMessage, _), .error(let rhsMessage, _)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }()
    #expect(matches, "Expected \(expected) but got \(actual)", sourceLocation: sourceLocation)
}

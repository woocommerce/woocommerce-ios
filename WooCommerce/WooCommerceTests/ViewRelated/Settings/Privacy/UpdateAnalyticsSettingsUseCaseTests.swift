import XCTest
import TestKit
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider
import os

@testable import WooCommerce
@testable import Yosemite

final class UpdateAnalyticsSettingsUseCaseTests: XCTestCase {

    @MainActor func test_using_a_wpcom_account_opt_in_analytics_updates_analytics_state() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateAccountSettings(_, _, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let analytics = TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: false)

        // Then
        XCTAssertTrue(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    @MainActor func test_using_a_wpcom_account_opt_out_analytics_updates_analytics_state() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateAccountSettings(_, _, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let analytics = TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        XCTAssertFalse(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    @MainActor func test_using_a_non_wpcom_account_opt_in_analytics_updates_analytics_state() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let analytics = TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: false)

        // Then
        XCTAssertTrue(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    @MainActor func test_using_a_non_wpcom_account_opt_out_analytics_updates_analytics_state() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let analytics = TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        XCTAssertFalse(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    @MainActor func test_not_updating_analytic_setting_does_not_fire_a_request() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateAccountSettings(_, _, let onCompletion):
                onCompletion(.success(()))
                XCTFail("Test should not fire a network request")
            default:
                break
            }
        }
        let analytics = TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        analytics.setUserHasOptedOut(true)

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        XCTAssertFalse(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    override class func tearDown() {
        super.tearDown()
        SessionManager.removeTestingDatabase()
    }
}

final class TestAnalytics: Analytics {
    private struct State: Sendable {
        var lastReceivedEventName: String?
        var lastReceivedWaitingTime: TimeInterval?
        var userHasOptedIn = true
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var lastReceivedEventName: String? {
        state.withLock { $0.lastReceivedEventName }
    }

    var lastReceivedWaitingTime: TimeInterval? {
        state.withLock { $0.lastReceivedWaitingTime }
    }

    // MARK: - Protocol conformance

    func initialize() {
    }

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        let waitingTime = properties?["waiting_time"] as? TimeInterval
        state.withLock { state in
            state.lastReceivedEventName = eventName
            state.lastReceivedWaitingTime = waitingTime
        }
    }

    func refreshUserData() {
    }

    func setUserHasOptedOut(_ optedOut: Bool) {
        userHasOptedIn = !optedOut
    }

    var userHasOptedIn: Bool {
        get { state.withLock { $0.userHasOptedIn } }
        set { state.withLock { $0.userHasOptedIn = newValue } }
    }
    let analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()
}

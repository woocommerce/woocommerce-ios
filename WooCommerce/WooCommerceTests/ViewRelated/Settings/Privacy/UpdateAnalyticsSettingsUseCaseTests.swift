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

    @MainActor func test_enqueued_updates_when_first_request_is_pending_then_final_choice_wins() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        let analytics = TestAnalytics()
        analytics.setUserHasOptedOut(true)
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        let firstRequestDispatched = expectation(description: "First account settings request dispatched")
        let secondRequestDispatched = expectation(description: "Second account settings request dispatched")
        var receivedOptOutValues: [Bool] = []
        var requestCompletions: [(Result<Void, Error>) -> Void] = []
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .updateAccountSettings(_, optOut, onCompletion):
                receivedOptOutValues.append(optOut)
                requestCompletions.append(onCompletion)
                if receivedOptOutValues.count == 1 {
                    firstRequestDispatched.fulfill()
                } else {
                    secondRequestDispatched.fulfill()
                }
            default:
                break
            }
        }

        // When
        let optInUpdate = useCase.enqueueUpdate(optOut: false)
        await fulfillment(of: [firstRequestDispatched], timeout: 1)
        let finalOptOutUpdate = useCase.enqueueUpdate(optOut: true)

        // Then
        XCTAssertEqual(receivedOptOutValues, [false])
        requestCompletions.removeFirst()(.success(()))
        try await optInUpdate.value
        await fulfillment(of: [secondRequestDispatched], timeout: 1)
        XCTAssertEqual(receivedOptOutValues, [false, true])
        requestCompletions.removeFirst()(.success(()))
        try await finalOptOutUpdate.value
        XCTAssertFalse(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    @MainActor func test_enqueued_updates_when_first_request_fails_then_final_choice_still_completes() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        let analytics = TestAnalytics()
        analytics.setUserHasOptedOut(true)
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        let firstRequestDispatched = expectation(description: "First account settings request dispatched")
        var receivedOptOutValues: [Bool] = []
        var firstRequestCompletion: ((Result<Void, Error>) -> Void)?
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .updateAccountSettings(_, optOut, onCompletion):
                receivedOptOutValues.append(optOut)
                firstRequestCompletion = onCompletion
                firstRequestDispatched.fulfill()
            default:
                break
            }
        }

        // When
        let optInUpdate = useCase.enqueueUpdate(optOut: false)
        await fulfillment(of: [firstRequestDispatched], timeout: 1)
        let finalOptOutUpdate = useCase.enqueueUpdate(optOut: true)
        let completion = try XCTUnwrap(firstRequestCompletion)
        completion(.failure(TestError.requestFailed))

        // Then
        await assertThrowsError({
            try await optInUpdate.value
        }, errorAssert: { ($0 as? TestError) == .requestFailed })
        try await finalOptOutUpdate.value
        XCTAssertEqual(receivedOptOutValues, [false])
        XCTAssertFalse(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    override class func tearDown() {
        super.tearDown()
        SessionManager.removeTestingDatabase()
    }
}

private enum TestError: Error, Equatable {
    case requestFailed
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

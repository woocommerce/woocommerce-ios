import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

@MainActor final class UpdateAnalyticsSettingsUseCaseTests: XCTestCase {

    func test_using_a_wpcom_account_opt_in_analytics_updates_analytics_state() async throws {
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
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: false)

        // Then
        XCTAssertTrue(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    func test_using_a_wpcom_account_opt_out_analytics_updates_analytics_state() async throws {
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
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        XCTAssertFalse(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    func test_using_a_non_wpcom_account_opt_in_analytics_updates_analytics_state() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: false)

        // Then
        XCTAssertTrue(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }

    func test_using_a_non_wpcom_account_opt_out_analytics_updates_analytics_state() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))

        // When
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        XCTAssertFalse(analytics.userHasOptedIn)
        XCTAssertEqual(userDefaults[.hasSavedPrivacyBannerSettings], true)
    }
}

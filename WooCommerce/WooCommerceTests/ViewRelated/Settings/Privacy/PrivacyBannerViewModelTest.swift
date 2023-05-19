import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

@MainActor final class PrivacyBannerViewModelTest: XCTestCase {

    func test_analytics_state_has_correct_initial_value_when_user_has_opt_out() {
        // Given
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        analytics.userHasOptedIn = false

        // When
        let viewModel = PrivacyBannerViewModel(analytics: analytics, onCompletion: { _ in })

        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }

    func test_analytics_state_has_correct_initial_value_when_user_has_opt_in() {
        // Given
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        analytics.userHasOptedIn = true

        // When
        let viewModel = PrivacyBannerViewModel(analytics: analytics, onCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.analyticsEnabled)
    }

    func test_submit_changes_on_wpcom_account_triggers_network_request_and_updates_loading_state() {
        // Given
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        analytics.userHasOptedIn = true

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Store"))
        let (loading, enabled): (Bool, Bool) = waitFor { promise in

            let viewModel = PrivacyBannerViewModel(analytics: analytics, stores: stores, onCompletion: { _ in })
            stores.whenReceivingAction(ofType: AccountAction.self) { action in
                switch action {
                case .updateAccountSettings(_, _, _):
                    promise((viewModel.isLoading, viewModel.isViewEnabled))
                default:
                    break
                }
            }

            // When
            Task {
                await viewModel.submitChanges(destination: .dismiss)
            }
        }

        // Then
        XCTAssertTrue(loading)
        XCTAssertFalse(enabled)
    }

    func test_submit_changes_using_wpcom_account_calls_completion_block() {
        // Given
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        analytics.userHasOptedIn = true

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Store"))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateAccountSettings(_, _, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        let completionCalled: Bool = waitFor { promise in
            let viewModel = PrivacyBannerViewModel(analytics: analytics, stores: stores, onCompletion: { _ in
                promise(true)
            })

            // When
            Task {
                await viewModel.submitChanges(destination: .dismiss)
            }
        }

        // Then
        XCTAssertTrue(completionCalled)
    }

    func test_submit_changes_using_non_wpcom_account_calls_completion_block() {
        // Given
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        analytics.userHasOptedIn = true

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let completionCalled: Bool = waitFor { promise in
            let viewModel = PrivacyBannerViewModel(analytics: analytics, stores: stores, onCompletion: { _ in
                promise(true)
            })

            // When
            Task {
                await viewModel.submitChanges(destination: .dismiss)
            }
        }

        // Then
        XCTAssertTrue(completionCalled)
    }
}

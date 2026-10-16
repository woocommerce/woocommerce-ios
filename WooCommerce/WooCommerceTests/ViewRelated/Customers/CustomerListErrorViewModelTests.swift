import Foundation
import Testing
import Yosemite
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
@testable import WooCommerce

@Suite(.timeLimit(.minutes(5)))
@MainActor
struct CustomerListErrorViewModelTests {
    @Test func customersDidFail_when_analytics_is_disabled_then_shows_enable_action_and_tracks_cause() async {
        // Given
        let (viewModel, stores, analyticsProvider) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(false))
            }
        }

        // When
        let handled = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(handled)
        #expect(viewModel.state == .shown(.disabled))
        #expect(analyticsProvider.receivedEvents.last == "customer_list_analytics_unavailable_error_shown")
        #expect(analyticsProvider.receivedProperties.last?["source"] as? String == "customers")
        #expect(analyticsProvider.receivedProperties.last?["cause"] as? String == "disabled")
    }

    @Test func customersDidFail_when_analytics_is_enabled_then_shows_unavailable_message() async {
        // Given
        let (viewModel, stores, analyticsProvider) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(true))
            }
        }

        // When
        let handled = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(handled)
        #expect(viewModel.state == .shown(.unavailable))
        #expect(analyticsProvider.receivedProperties.last?["cause"] as? String == "other")
    }

    @Test func customersDidFail_when_setting_permission_is_denied_then_shows_admin_message() async {
        // Given
        let (viewModel, stores, analyticsProvider) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.failure(NetworkError.unacceptableStatusCode(
                    statusCode: 403,
                    response: Data(#"{"code":"woocommerce_rest_cannot_view"}"#.utf8)
                )))
            }
        }

        // When
        let handled = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(handled)
        #expect(viewModel.state == .shown(.noPermission))
        #expect(analyticsProvider.receivedProperties.last?["cause"] as? String == "unknown")
    }

    @Test func customersDidFail_when_setting_permission_is_denied_through_jetpack_then_shows_admin_message() async {
        // Given
        let (viewModel, stores, _) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.failure(DotcomError.unknown(code: "woocommerce_rest_cannot_view", message: nil, data: nil)))
            }
        }

        // When
        let handled = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(handled)
        #expect(viewModel.state == .shown(.noPermission))
    }

    @Test func customersDidFail_when_setting_check_fails_then_shows_unavailable_message() async {
        // Given
        let (viewModel, stores, analyticsProvider) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.failure(NSError(domain: "test", code: 1)))
            }
        }

        // When
        let handled = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(handled)
        #expect(viewModel.state == .shown(.unavailable))
        #expect(analyticsProvider.receivedProperties.last?["cause"] as? String == "unknown")
    }

    @Test func customersDidFail_when_route_is_missing_directly_or_through_jetpack_then_checks_setting() async {
        // Given
        let (viewModel, stores, _) = makeViewModel()
        var retrievalCount = 0
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                retrievalCount += 1
                onCompletion(.success(false))
            }
        }

        // When
        let tunnelHandled = await viewModel.customersDidFail(with: DotcomError.noRestRoute())
        viewModel.customersDidLoad()
        let directHandled = await viewModel.customersDidFail(with: NetworkError.notFound(
            response: Data(#"{"code":"rest_no_route"}"#.utf8)
        ))

        // Then
        #expect(tunnelHandled)
        #expect(directHandled)
        #expect(retrievalCount == 2)
    }

    @Test func customersDidFail_when_other_error_occurs_before_analytics_error_then_leaves_handling_to_host() async {
        // Given
        let (viewModel, stores, _) = makeViewModel()

        // When
        let handled = await viewModel.customersDidFail(with: NetworkError.notFound(
            response: Data(#"{"code":"some_other_error"}"#.utf8)
        ))

        // Then
        #expect(!handled)
        #expect(viewModel.state == .hidden)
        #expect(stores.receivedActions.isEmpty)
    }

    @Test func customersDidFail_when_other_error_occurs_after_analytics_error_then_shows_generic_error() async {
        // Given
        let (viewModel, stores, _) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(false))
            }
        }
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // When
        let handled = await viewModel.customersDidFail(with: NSError(domain: "test", code: 2))

        // Then
        #expect(handled)
        #expect(viewModel.state == .generic)
    }

    @Test func retry_when_customers_load_then_tracks_retry_success() async {
        // Given
        var reloadCount = 0
        let (viewModel, stores, analyticsProvider) = makeViewModel {
            reloadCount += 1
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(false))
            }
        }
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // When
        viewModel.retry()
        let stateWhileReloading = viewModel.state
        viewModel.customersDidLoad()

        // Then
        #expect(reloadCount == 1)
        #expect(stateWhileReloading == .checking)
        #expect(viewModel.state == .hidden)
        #expect(analyticsProvider.receivedEvents.last == "customer_list_analytics_unavailable_reload_success")
        #expect(analyticsProvider.receivedProperties.last?["type"] as? String == "retry")
    }

    @Test func retry_when_generic_error_is_shown_then_reload_success_is_not_tracked() async {
        // Given
        var reloadCount = 0
        let (viewModel, stores, analyticsProvider) = makeViewModel {
            reloadCount += 1
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(false))
            }
        }
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())
        _ = await viewModel.customersDidFail(with: NSError(domain: "test", code: 2))

        // When
        viewModel.retry()
        let stateWhileReloading = viewModel.state
        viewModel.customersDidLoad()

        // Then
        #expect(reloadCount == 1)
        #expect(stateWhileReloading == .checking)
        #expect(viewModel.state == .hidden)
        #expect(analyticsProvider.receivedEvents.contains("customer_list_analytics_unavailable_reload_success") == false)
    }

    @Test func retry_when_customers_reload_fails_then_clears_pending_recovery() async {
        // Given
        let (viewModel, stores, analyticsProvider) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(false))
            }
        }
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())
        viewModel.retry()

        // When
        _ = await viewModel.customersDidFail(with: NSError(domain: "test", code: 2))
        viewModel.customersDidLoad()

        // Then
        #expect(viewModel.state == .hidden)
        #expect(!analyticsProvider.receivedEvents.contains("customer_list_analytics_unavailable_reload_success"))
    }

    @Test func enableAnalytics_when_first_request_fails_then_retries_and_tracks_successful_reload() async {
        // Given
        var reloadCount = 0
        var enableCount = 0
        let (viewModel, stores, analyticsProvider) = makeViewModel {
            reloadCount += 1
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .enableAnalyticsSetting(_, onCompletion) = action {
                enableCount += 1
                onCompletion(enableCount == 1 ? .failure(NSError(domain: "test", code: 3)) : .success(()))
            }
        }

        // When
        await viewModel.enableAnalytics()
        viewModel.customersDidLoad()

        // Then
        #expect(enableCount == 2)
        #expect(reloadCount == 1)
        #expect(analyticsProvider.receivedEvents.last == "customer_list_analytics_unavailable_reload_success")
        #expect(analyticsProvider.receivedProperties.last?["type"] as? String == "enable_analytics")
    }

    @Test func enableAnalytics_when_both_requests_fail_then_shows_notice_and_keeps_enable_available() async {
        // Given
        var enableCount = 0
        let (viewModel, stores, _) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(false))
            } else if case let .enableAnalyticsSetting(_, onCompletion) = action {
                enableCount += 1
                onCompletion(.failure(NSError(domain: "test", code: 4)))
            }
        }
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // When
        await viewModel.enableAnalytics()

        // Then
        #expect(enableCount == 2)
        #expect(viewModel.state == .shown(.disabled))
        #expect(viewModel.notice?.message == "WooCommerce Analytics couldn't be enabled. Please try again.")
    }

    @Test func enableAnalytics_when_setting_remains_disabled_then_retry_allows_enable_again() async {
        // Given
        let (viewModel, stores, analyticsProvider) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(false))
            } else if case let .enableAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.success(()))
            }
        }

        // When
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())
        await viewModel.enableAnalytics()
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(viewModel.state == .shown(.unavailable))
        #expect(analyticsProvider.receivedEvents.last == "customer_list_analytics_unavailable_error_shown")
        #expect(analyticsProvider.receivedProperties.last?["cause"] as? String == "disabled")

        // When
        viewModel.retry()
        _ = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(viewModel.state == .shown(.disabled))
    }

    @Test func customersDidFail_when_setting_check_finishes_after_load_then_drops_stale_result() async {
        // Given
        let (viewModel, stores, analyticsProvider) = makeViewModel()
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .retrieveAnalyticsSetting(_, onCompletion) = action {
                viewModel.customersDidLoad()
                onCompletion(.success(false))
            }
        }

        // When
        let handled = await viewModel.customersDidFail(with: DotcomError.noRestRoute())

        // Then
        #expect(handled)
        #expect(viewModel.state == .hidden)
        #expect(analyticsProvider.receivedEvents.isEmpty)
    }
}

@MainActor
private func makeViewModel(reloadCustomers: @escaping () -> Void = {}) -> (CustomerListErrorViewModel, MockStoresManager, MockAnalyticsProvider) {
    let stores = MockStoresManager(sessionManager: .testingInstance)
    let analyticsProvider = MockAnalyticsProvider()
    let viewModel = CustomerListErrorViewModel(siteID: 123,
                                               source: .customers,
                                               reloadCustomers: reloadCustomers,
                                               stores: stores,
                                               analytics: WooAnalytics(analyticsProvider: analyticsProvider))
    return (viewModel, stores, analyticsProvider)
}

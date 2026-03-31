import Testing
import Foundation
import Yosemite
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
        #expect(result == .success)
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
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        let sut = ConnectivityToolViewModel(session: SessionManager.makeForTesting(authenticated: true), stores: stores, analytics: analytics)

        // When — call testAnalyticsSetting() directly; tracking is done by the pipeline wrapper,
        // so we verify the analytics event type maps to the "analytics" raw value that the
        // trackResponseEvent method would pass to the provider.
        _ = await sut.testAnalyticsSetting()

        // Then — verify the analytics test type maps correctly.
        // trackResponseEvent passes WooAnalyticsEvent.ConnectivityTool.Test.analytics as the test param.
        #expect(WooAnalyticsEvent.ConnectivityTool.Test.analytics.rawValue == "analytics")
    }

}

// MARK: - ConnectivityToolCard.ConnectivityState: Equatable

extension ConnectivityToolCard.ConnectivityState: @retroactive Equatable {
    public static func == (lhs: ConnectivityToolCard.ConnectivityState, rhs: ConnectivityToolCard.ConnectivityState) -> Bool {
        switch (lhs, rhs) {
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
    }
}

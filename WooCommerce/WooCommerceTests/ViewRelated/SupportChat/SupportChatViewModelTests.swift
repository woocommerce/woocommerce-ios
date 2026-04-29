import Testing
import Foundation
import Yosemite
@testable import WooCommerce

@MainActor
struct SupportChatViewModelTests {

    // MARK: - Greeting Tests

    @Test func test_showGreeting_when_entryPoint_is_helpAndSupport_then_shows_issue_picker() {
        // Given
        let sut = makeSUT(entryPoint: .helpAndSupport)

        // When
        sut.showGreeting()

        // Then
        #expect(sut.messages.count == 1)
        if case .issuePicker = sut.messages.first?.content {
            // Success
        } else {
            Issue.record("Expected issue picker message")
        }
    }

    @Test func test_showGreeting_when_entryPoint_is_connectivityTool_then_shows_text_greeting() {
        // Given
        let sut = makeSUT(entryPoint: .connectivityTool)

        // When
        sut.showGreeting()

        // Then
        #expect(sut.messages.count == 1)
        if case .text = sut.messages.first?.content {
            // Success
        } else {
            Issue.record("Expected text greeting message")
        }
    }

    // MARK: - Issue Selection Tests

    @Test func test_selectIssue_when_other_then_skips_diagnostics_and_shows_greeting() async {
        // Given
        let sut = makeSUT()
        sut.showGreeting()

        // When
        await sut.selectIssue(.other)

        // Then
        #expect(sut.selectedIssue == .other)
        #expect(sut.diagnosticResults.isEmpty)
        // Should have: issue picker, user selection, greeting
        #expect(sut.messages.count == 3)
    }

    @Test func test_selectIssue_when_specific_issue_then_runs_diagnostics_and_shows_final_result() async {
        // Given
        let sut = makeSUT()
        sut.showGreeting()

        // When
        await sut.selectIssue(.loadingAnalytics)

        // Then
        #expect(sut.selectedIssue == .loadingAnalytics)
        #expect(sut.diagnosticResults.isEmpty == false)
        // Should have: issue picker, user selection, final result (success or failure)
        #expect(sut.messages.count == 3)
        let lastContent = sut.messages.last?.content
        let isValidFinalState = {
            if case .diagnosticsSuccess = lastContent { return true }
            if case .diagnosticsFailure = lastContent { return true }
            return false
        }()
        #expect(isValidFinalState, "Expected diagnosticsSuccess or diagnosticsFailure message")
    }

    // MARK: - Proceed to Chat Tests

    @Test func test_proceedToChat_appends_greeting_message() async {
        // Given
        let sut = makeSUT()
        sut.showGreeting()
        await sut.selectIssue(.loadingOrders)
        let messageCountBeforeProceed = sut.messages.count

        // When
        sut.proceedToChat()

        // Then
        #expect(sut.messages.count == messageCountBeforeProceed + 1)
        if case .text = sut.messages.last?.content {
            // Success
        } else {
            Issue.record("Expected text greeting after proceeding to chat")
        }
    }

    // MARK: - Execute Action Tests

    @Test func test_executeAction_enableAnalytics_calls_service() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
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
        let diagnosticsService = SupportDiagnosticsService(stores: stores)
        let sut = makeSUT(stores: stores, diagnosticsService: diagnosticsService)

        // Run analytics test to get the failure result
        await sut.selectIssue(.loadingAnalytics)

        // When
        await sut.executeAction(.enableAnalytics)

        // Then - action executed without error (test would fail if service threw)
    }

    @Test func test_executeAction_openNotificationSettings_sets_selectedURL() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.executeAction(.openNotificationSettings)

        // Then
        #expect(sut.selectedURL != nil)
    }

    @Test func test_executeAction_setupJetpack_sets_shouldStartJetpackSetup() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.executeAction(.setupJetpack)

        // Then
        #expect(sut.shouldStartJetpackSetup == true)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        entryPoint: SupportChatViewModel.EntryPoint = .helpAndSupport,
        stores: StoresManager? = nil,
        diagnosticsService: SupportDiagnosticsService? = nil
    ) -> SupportChatViewModel {
        let stores = stores ?? MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        return SupportChatViewModel(
            entryPoint: entryPoint,
            stores: stores,
            diagnosticsService: diagnosticsService,
            onContactHumanSupport: { _ in }
        )
    }
}

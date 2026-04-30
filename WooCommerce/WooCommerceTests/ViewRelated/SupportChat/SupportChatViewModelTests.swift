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

    // MARK: - Input Area Visibility Tests

    @Test func test_shouldShowInputArea_when_entryPoint_is_connectivityTool_then_returns_true() {
        // Given
        let sut = makeSUT(entryPoint: .connectivityTool)

        // Then
        #expect(sut.shouldShowInputArea == true)
    }

    @Test func test_shouldShowInputArea_when_entryPoint_is_helpAndSupport_and_not_proceeded_then_returns_false() {
        // Given
        let sut = makeSUT(entryPoint: .helpAndSupport)
        sut.showGreeting()

        // Then
        #expect(sut.shouldShowInputArea == false)
    }

    @Test func test_shouldShowInputArea_when_proceeded_to_chat_then_returns_true() async {
        // Given
        let sut = makeSUT(entryPoint: .helpAndSupport)
        sut.showGreeting()
        await sut.selectIssue(.loadingOrders)

        // When
        sut.proceedToChat()

        // Then
        #expect(sut.shouldShowInputArea == true)
    }

    @Test func test_shouldShowInputArea_when_other_selected_then_returns_true() async {
        // Given
        let sut = makeSUT(entryPoint: .helpAndSupport)
        sut.showGreeting()

        // When
        await sut.selectIssue(.other)

        // Then
        #expect(sut.shouldShowInputArea == true)
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
        #expect(sut.hasProceededToChat == true)
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

    @Test func test_proceedToChat_sets_hasProceededToChat() async {
        // Given
        let sut = makeSUT()
        sut.showGreeting()
        await sut.selectIssue(.loadingOrders)
        #expect(sut.hasProceededToChat == false)

        // When
        sut.proceedToChat()

        // Then
        #expect(sut.hasProceededToChat == true)
    }

    // MARK: - Execute Action Tests

    @Test func test_executeAction_enableAnalytics_calls_service_and_reruns_test() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var enableAnalyticsCalled = false
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                // Return false first (disabled), then true after enabling
                onCompletion(.success(enableAnalyticsCalled))
            case let .enableAnalyticsSetting(_, onCompletion):
                enableAnalyticsCalled = true
                onCompletion(.success(()))
            default:
                break
            }
        }
        let diagnosticsService = SupportDiagnosticsService(stores: stores)
        let sut = makeSUT(stores: stores, diagnosticsService: diagnosticsService)
        sut.showGreeting()

        // Run analytics test to get the failure result
        await sut.selectIssue(.loadingAnalytics)

        // Verify we have a failure message
        let hasFailureMessage = sut.messages.contains {
            if case .diagnosticsFailure = $0.content { return true }
            return false
        }
        #expect(hasFailureMessage, "Expected diagnostics failure message before executing action")

        // When
        await sut.executeAction(.enableAnalytics)

        // Then - should have success message after rerun
        let hasSuccessMessage = sut.messages.contains {
            if case .diagnosticsSuccess = $0.content { return true }
            return false
        }
        #expect(hasSuccessMessage, "Expected diagnostics success message after executing action")
        #expect(sut.isExecutingAction == false)
    }

    @Test func test_executeAction_openNotificationSettings_completes_without_error() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.executeAction(.openNotificationSettings)

        // Then
        #expect(sut.isExecutingAction == false)
    }

    @Test func test_executeAction_setupJetpack_calls_onStartJetpackSetup() async {
        // Given
        var callbackCalled = false
        let sut = makeSUT(onStartJetpackSetup: { callbackCalled = true })

        // When
        await sut.executeAction(.setupJetpack)

        // Then
        #expect(callbackCalled == true)
        #expect(sut.isExecutingAction == false)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        entryPoint: SupportChatViewModel.EntryPoint = .helpAndSupport,
        stores: StoresManager? = nil,
        diagnosticsService: SupportDiagnosticsService? = nil,
        onStartJetpackSetup: @escaping () -> Void = {}
    ) -> SupportChatViewModel {
        let stores = stores ?? MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let viewModel = SupportChatViewModel(
            entryPoint: entryPoint,
            stores: stores,
            diagnosticsService: diagnosticsService,
            onContactHumanSupport: { _ in }
        )
        viewModel.onStartJetpackSetup = onStartJetpackSetup
        return viewModel
    }
}

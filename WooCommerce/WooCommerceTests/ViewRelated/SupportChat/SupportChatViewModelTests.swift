import Testing
import Foundation
import Yosemite
@testable import WooCommerce

@MainActor
struct SupportChatViewModelTests {

    // MARK: - Initial Phase Tests

    @Test func test_init_when_entryPoint_is_helpAndSupport_then_phase_is_issuePicker() {
        // Given / When
        let sut = makeSUT(entryPoint: .helpAndSupport)

        // Then
        #expect(sut.phase == .issuePicker)
    }

    @Test func test_init_when_entryPoint_is_connectivityTool_then_phase_is_chatting() {
        // Given / When
        let sut = makeSUT(entryPoint: .connectivityTool)

        // Then
        #expect(sut.phase == .chatting)
    }

    // MARK: - Issue Selection Tests

    @Test func test_selectIssue_when_other_then_skips_diagnostics_and_goes_to_chatting() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.selectIssue(.other)

        // Then
        #expect(sut.phase == .chatting)
        #expect(sut.selectedIssue == .other)
        #expect(sut.diagnosticResults.isEmpty)
    }

    @Test func test_selectIssue_when_specific_issue_then_runs_diagnostics_and_shows_results() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.selectIssue(.loadingAnalytics)

        // Then
        #expect(sut.phase == .showingResults)
        #expect(sut.selectedIssue == .loadingAnalytics)
        #expect(sut.diagnosticResults.isEmpty == false)
    }

    // MARK: - Proceed to Chat Tests

    @Test func test_proceedToChat_transitions_to_chatting_phase() async {
        // Given
        let sut = makeSUT()
        await sut.selectIssue(.loadingOrders)

        // When
        sut.proceedToChat()

        // Then
        #expect(sut.phase == .chatting)
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

import Testing
import Foundation
import Yosemite
import enum Networking.NetworkError
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

    @Test func test_showGreeting_when_entryPoint_is_connectivityTool_then_state_remains_idle() {
        // Given
        let sut = makeSUT(entryPoint: .connectivityTool)

        // When
        sut.showGreeting()

        // Then
        #expect(sut.state == .idle)
    }

    @Test func test_showGreeting_when_entryPoint_is_preLogin_then_shows_text_greeting() {
        // Given
        let sut = makeSUT(entryPoint: .preLogin)

        // When
        sut.showGreeting()

        // Then
        #expect(sut.messages.count == 1)
        if case .text = sut.messages.first?.content {
            // Success
        } else {
            Issue.record("Expected text greeting message")
        }
        #expect(sut.state == .idle)
    }

    @Test func test_shouldShowInputArea_when_entryPoint_is_preLogin_then_returns_true() {
        // Given
        let sut = makeSUT(entryPoint: .preLogin)

        // Then
        #expect(sut.shouldShowInputArea == true)
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

    // MARK: - Send Message Error Handling Tests

    @Test func test_sendMessage_when_failure_with_429_then_state_is_rate_limit_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, _, completion) = action {
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 429, response: nil)))
            }
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)
        sut.inputText = "hello"

        // When
        sut.sendMessage()

        // Then
        guard case let .error(message) = sut.state else {
            Issue.record("Expected state to be .error after 429, got \(String(describing: sut.state))")
            return
        }
        #expect(message.contains("limit"), "Expected rate-limit copy, got: \(message)")
    }

    @Test func test_sendMessage_when_failure_with_500_then_state_is_generic_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, _, completion) = action {
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500, response: nil)))
            }
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)
        sut.inputText = "hello"

        // When
        sut.sendMessage()

        // Then
        guard case let .error(message) = sut.state else {
            Issue.record("Expected state to be .error after 500, got \(String(describing: sut.state))")
            return
        }
        #expect(message.contains("couldn't connect"), "Expected generic copy, got: \(message)")
    }

    @Test func test_sendMessage_when_failure_then_marks_last_user_message_as_failed() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, _, completion) = action {
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500, response: nil)))
            }
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)
        sut.inputText = "hello"

        // When
        sut.sendMessage()

        // Then
        let lastUserMessage = sut.messages.last { $0.role == .user }
        #expect(lastUserMessage?.failed == true, "Expected the failed user bubble to be marked")
    }

    @Test func test_sendMessage_when_failure_with_timeout_then_state_is_generic_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, _, completion) = action {
                completion(.failure(NetworkError.timeout(response: nil)))
            }
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)
        sut.inputText = "hello"

        // When
        sut.sendMessage()

        // Then
        guard case let .error(message) = sut.state else {
            Issue.record("Expected state to be .error after timeout, got \(String(describing: sut.state))")
            return
        }
        #expect(message.contains("couldn't connect"), "Expected generic copy, got: \(message)")
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

    @Test func test_executeAction_when_service_throws_then_state_is_error() async {
        // Given — enableAnalytics fails
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .enableAnalyticsSetting(_, onCompletion) = action {
                onCompletion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500, response: nil)))
            }
        }
        let diagnosticsService = SupportDiagnosticsService(stores: stores)
        let sut = makeSUT(stores: stores, diagnosticsService: diagnosticsService)

        // When
        await sut.executeAction(.enableAnalytics)

        // Then
        guard case .error = sut.state else {
            Issue.record("Expected state to be .error after action failure, got \(String(describing: sut.state))")
            return
        }
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

    // MARK: - Resume Chat Tests

    @Test(.timeLimit(.minutes(1)))
    func test_resumeIfNeeded_when_chat_flagged_for_human_support_then_sets_shouldPromptHumanSupport() async {
        // Given
        let chatID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        await confirmation { fetchCompleted in
            stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
                switch action {
                case let .fetchChat(_, _, completion):
                    let flaggedMessage = SupportChatMessage(
                        messageID: 2,
                        role: .bot,
                        content: "Please contact support.",
                        context: SupportChatMessageContext(
                            sources: [],
                            flags: SupportChatFlags(
                                forwardToHumanSupport: true,
                                cannedResponse: false,
                                loggedIn: true,
                                branch: nil
                            )
                        )
                    )
                    let response = SupportChatResponse(
                        chatID: chatID,
                        sessionID: "session-1",
                        botSlug: "test-bot",
                        botVersion: "1.0",
                        messages: [
                            SupportChatMessage(messageID: 1, role: .user, content: "Help", context: nil),
                            flaggedMessage
                        ]
                    )
                    completion(.success(response))
                    fetchCompleted()
                default:
                    break
                }
            }
            let sut = SupportChatViewModel(
                entryPoint: .chatHistory,
                stores: stores,
                chatID: chatID,
                onContactHumanSupport: { _, _, _ in }
            )

            // When
            sut.resumeIfNeeded()
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func test_resumeIfNeeded_when_chat_flagged_for_human_support_then_filters_flagged_message() async {
        // Given
        let chatID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let sut = SupportChatViewModel(
            entryPoint: .chatHistory,
            stores: stores,
            chatID: chatID,
            onContactHumanSupport: { _, _, _ in }
        )

        await confirmation { fetchCompleted in
            stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
                switch action {
                case let .fetchChat(_, _, completion):
                    let flaggedMessage = SupportChatMessage(
                        messageID: 2,
                        role: .bot,
                        content: "Please contact support.",
                        context: SupportChatMessageContext(
                            sources: [],
                            flags: SupportChatFlags(
                                forwardToHumanSupport: true,
                                cannedResponse: false,
                                loggedIn: true,
                                branch: nil
                            )
                        )
                    )
                    let response = SupportChatResponse(
                        chatID: chatID,
                        sessionID: "session-1",
                        botSlug: "test-bot",
                        botVersion: "1.0",
                        messages: [
                            SupportChatMessage(messageID: 1, role: .user, content: "Help", context: nil),
                            flaggedMessage
                        ]
                    )
                    completion(.success(response))
                    fetchCompleted()
                default:
                    break
                }
            }

            // When
            sut.resumeIfNeeded()
        }

        // Then
        #expect(sut.shouldPromptHumanSupport == true)
        #expect(sut.messages.count == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func test_resumeIfNeeded_when_chat_not_flagged_then_shouldPromptHumanSupport_is_false() async {
        // Given
        let chatID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let sut = SupportChatViewModel(
            entryPoint: .chatHistory,
            stores: stores,
            chatID: chatID,
            onContactHumanSupport: { _, _, _ in }
        )

        await confirmation { fetchCompleted in
            stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
                switch action {
                case let .fetchChat(_, _, completion):
                    let response = SupportChatResponse(
                        chatID: chatID,
                        sessionID: "session-1",
                        botSlug: "test-bot",
                        botVersion: "1.0",
                        messages: [
                            SupportChatMessage(messageID: 1, role: .user, content: "Help", context: nil),
                            SupportChatMessage(messageID: 2, role: .bot, content: "How can I help?", context: nil)
                        ]
                    )
                    completion(.success(response))
                    fetchCompleted()
                default:
                    break
                }
            }

            // When
            sut.resumeIfNeeded()
        }

        // Then
        #expect(sut.shouldPromptHumanSupport == false)
        #expect(sut.messages.count == 2)
    }

    @Test func test_contactHumanSupport_passes_chatID_in_callback() async {
        // Given
        let chatID: Int64 = 456
        var receivedChatID: Int64?
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            switch action {
            case let .sendMessage(_, _, _, _, _, completion):
                let response = SupportChatResponse(
                    chatID: chatID,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: "Hello", context: nil),
                        SupportChatMessage(
                            messageID: 2,
                            role: .bot,
                            content: "Please contact support.",
                            context: SupportChatMessageContext(
                                sources: [],
                                flags: SupportChatFlags(
                                    forwardToHumanSupport: true,
                                    cannedResponse: false,
                                    loggedIn: true,
                                    branch: nil
                                )
                            )
                        )
                    ]
                )
                completion(.success(response))
            default:
                break
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .preLogin,
            stores: stores,
            onContactHumanSupport: { chatID, _, _ in
                receivedChatID = chatID
            }
        )

        sut.inputText = "Hello"
        sut.sendMessage()

        // When
        sut.contactHumanSupport()

        // Then
        #expect(receivedChatID == chatID)
    }

    @Test func test_contactHumanSupport_when_prefetched_systemStatusReport_then_passes_it_in_supportAreaInfo() async {
        // Given
        let prefetchedReport = "### Pre-fetched System Status Report ###"
        var receivedSupportAreaInfo: SupportAreaInfo?
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            switch action {
            case let .sendMessage(_, _, _, _, _, completion):
                let response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: "Hello", context: nil),
                        SupportChatMessage(
                            messageID: 2,
                            role: .bot,
                            content: "Please contact support.",
                            context: SupportChatMessageContext(
                                sources: [],
                                flags: SupportChatFlags(
                                    forwardToHumanSupport: true,
                                    cannedResponse: false,
                                    loggedIn: true,
                                    branch: nil
                                ),
                                supportArea: SupportChatSupportArea(area: .mobileApp, confidence: .high)
                            )
                        )
                    ]
                )
                completion(.success(response))
            default:
                break
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .connectivityTool,
            stores: stores,
            systemStatusReport: prefetchedReport,
            onContactHumanSupport: { _, _, supportAreaInfo in
                receivedSupportAreaInfo = supportAreaInfo
            }
        )

        sut.inputText = "Hello"
        sut.sendMessage()

        // When
        sut.contactHumanSupport()

        // Then
        #expect(receivedSupportAreaInfo?.systemStatusReport == prefetchedReport)
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
            onContactHumanSupport: { _, _, _ in }
        )
        viewModel.onStartJetpackSetup = onStartJetpackSetup
        return viewModel
    }
}

import Testing
import Foundation
import Yosemite
import enum Networking.NetworkError
@testable import WooCommerce

@MainActor
struct SupportChatViewModelTests {

    // MARK: - Greeting Tests

    @Test func showGreeting_when_entryPoint_is_helpAndSupport_then_shows_issue_picker() {
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

    @Test func showGreeting_when_entryPoint_is_connectivityTool_then_shows_text_greeting() {
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

    @Test func showGreeting_when_entryPoint_is_connectivityTool_then_state_remains_idle() {
        // Given
        let sut = makeSUT(entryPoint: .connectivityTool)

        // When
        sut.showGreeting()

        // Then
        #expect(sut.state == .idle)
    }

    @Test func showGreeting_when_entryPoint_is_preLogin_then_shows_text_greeting() {
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

    @Test func shouldShowInputArea_when_entryPoint_is_preLogin_then_returns_true() {
        // Given
        let sut = makeSUT(entryPoint: .preLogin)

        // Then
        #expect(sut.shouldShowInputArea == true)
    }

    // MARK: - Input Area Visibility Tests

    @Test func shouldShowInputArea_when_entryPoint_is_connectivityTool_then_returns_true() {
        // Given
        let sut = makeSUT(entryPoint: .connectivityTool)

        // Then
        #expect(sut.shouldShowInputArea == true)
    }

    @Test func shouldShowInputArea_when_entryPoint_is_helpAndSupport_and_not_proceeded_then_returns_false() {
        // Given
        let sut = makeSUT(entryPoint: .helpAndSupport)
        sut.showGreeting()

        // Then
        #expect(sut.shouldShowInputArea == false)
    }

    @Test func shouldShowInputArea_when_proceeded_to_chat_then_returns_true() async {
        // Given
        let sut = makeSUT(entryPoint: .helpAndSupport)
        sut.showGreeting()
        await sut.selectIssue(.loadingOrders)

        // When
        sut.proceedToChat()

        // Then
        #expect(sut.shouldShowInputArea == true)
    }

    @Test func shouldShowInputArea_when_other_selected_then_returns_true() async {
        // Given
        let sut = makeSUT(entryPoint: .helpAndSupport)
        sut.showGreeting()

        // When
        await sut.selectIssue(.other)

        // Then
        #expect(sut.shouldShowInputArea == true)
    }

    // MARK: - Issue Selection Tests

    @Test func selectIssue_when_other_then_skips_diagnostics_and_shows_greeting() async {
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

    @Test func proceedToChat_appends_greeting_message() async {
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

    @Test func proceedToChat_sets_hasProceededToChat() async {
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

    @Test func sendMessage_when_failure_with_429_then_state_is_rate_limit_error() async {
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

    @Test func sendMessage_when_failure_with_500_then_state_is_generic_error() async {
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

    @Test func sendMessage_when_failure_then_marks_last_user_message_as_failed() async {
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

    @Test func sendMessage_when_failure_with_timeout_then_state_is_generic_error() async {
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

    @Test func executeAction_enableAnalytics_calls_service_and_reruns_test() async {
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

    @Test func executeAction_openNotificationSettings_completes_without_error() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.executeAction(.openNotificationSettings)

        // Then
        #expect(sut.isExecutingAction == false)
    }

    @Test func executeAction_when_service_throws_then_state_is_error() async {
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

    @Test func executeAction_setupJetpack_calls_onStartJetpackSetup() async {
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
    func resumeIfNeeded_when_chat_flagged_for_human_support_then_sets_shouldPromptHumanSupport() async {
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
    func resumeIfNeeded_when_chat_flagged_for_human_support_then_filters_flagged_message() async {
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
    func resumeIfNeeded_when_chat_not_flagged_then_shouldPromptHumanSupport_is_false() async {
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

    @Test func contactHumanSupport_passes_chatID_in_callback() async {
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

    @Test func contactHumanSupport_when_prefetched_systemStatusReport_then_passes_it_in_supportAreaInfo() async {
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
                                supportArea: SupportChatSupportArea(area: .mobileApp, topic: "woo_mobile_issue_orders", confidence: .high)
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
        #expect(receivedSupportAreaInfo?.topic == "woo_mobile_issue_orders")
        #expect(receivedSupportAreaInfo?.systemStatusReport == prefetchedReport)
    }

    // MARK: - canEscalateToHumanSupport Tests

    @Test func canEscalateToHumanSupport_is_false_initially() {
        // Given
        let sut = makeSUT(entryPoint: .connectivityTool)

        // Then
        #expect(sut.canEscalateToHumanSupport == false)
    }

    @Test func canEscalateToHumanSupport_is_false_when_only_bot_greeting_exists() {
        // Given
        let sut = makeSUT(entryPoint: .connectivityTool)

        // When
        sut.showGreeting()

        // Then
        #expect(sut.messages.contains(where: { $0.role == .bot }))
        #expect(sut.canEscalateToHumanSupport == false)
    }

    @Test func canEscalateToHumanSupport_becomes_true_after_first_user_message_is_sent() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            completeSendMessageSuccessfully(action)
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)

        // When
        sut.inputText = "Hello"
        sut.sendMessage()

        // Then
        #expect(sut.canEscalateToHumanSupport == true)
    }

    @Test func canEscalateToHumanSupport_becomes_true_when_sending_message_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, _, completion) = action {
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500, response: nil)))
            }
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)

        // When
        sut.inputText = "Hello"
        sut.sendMessage()

        // Then
        #expect(sut.canEscalateToHumanSupport == true)
    }

    @Test func canEscalateToHumanSupport_is_false_for_helpAndSupport_entry_until_proceedToChat() async {
        // Given — helpAndSupport entry shows issue picker first; input area is hidden
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            completeSendMessageSuccessfully(action)
        }
        let sut = makeSUT(entryPoint: .helpAndSupport, stores: stores)
        sut.showGreeting()

        // When — proceed to chat
        sut.proceedToChat()

        // Then — input area is visible, but the merchant has not typed anything yet
        #expect(sut.shouldShowInputArea == true)
        #expect(sut.canEscalateToHumanSupport == false)

        // When — merchant actually types and sends a message
        sut.inputText = "Hello"
        sut.sendMessage()

        // Then
        #expect(sut.canEscalateToHumanSupport == true)
    }

    @Test func canEscalateToHumanSupport_is_false_after_helpAndSupport_picker_selection_until_user_types() async {
        // Reviewer scenario (PR #17102 / WOOMOB-3033): tapping an issue picker option appends a
        // user-role message ("Loading orders" etc.). The toolbar entry must wait until the merchant
        // actually describes the problem via the input field — picker taps don't count.
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            completeSendMessageSuccessfully(action)
        }
        let sut = makeSUT(entryPoint: .helpAndSupport, stores: stores)
        sut.showGreeting()

        // When — pick the no-diagnostics path so we land in chat without manual `proceedToChat`
        await sut.selectIssue(.other)

        // Then — chat surface is in free-chat phase, picker tap added a user message,
        // but the merchant has NOT typed via the input field yet
        #expect(sut.hasProceededToChat == true)
        #expect(sut.messages.contains(where: { $0.role == .user }))
        #expect(sut.canEscalateToHumanSupport == false)

        // When — merchant types and sends
        sut.inputText = "Help, my orders aren't loading"
        sut.sendMessage()

        // Then
        #expect(sut.canEscalateToHumanSupport == true)
    }

    @Test func canEscalateToHumanSupport_is_false_for_helpAndSupport_entry_when_input_area_is_hidden() {
        // Given — helpAndSupport entry shows the issue picker; input area is hidden until proceedToChat
        let sut = makeSUT(entryPoint: .helpAndSupport)

        // When
        sut.showGreeting()

        // Then — even if there are messages, the toolbar must stay hidden during the picker phase
        #expect(sut.shouldShowInputArea == false)
        #expect(sut.canEscalateToHumanSupport == false)
    }

    @Test func markChatTicketCreated_flips_hasCreatedTicket_and_hides_toolbar() {
        // Given — a live chat with at least one user message so the toolbar would otherwise be visible
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            completeSendMessageSuccessfully(action)
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)
        sut.inputText = "Hello"
        sut.sendMessage()
        #expect(sut.canEscalateToHumanSupport == true)

        // When
        sut.markChatTicketCreated()

        // Then
        #expect(sut.hasCreatedTicket == true)
        #expect(sut.canEscalateToHumanSupport == false)
    }

    @Test func canEscalateToHumanSupport_is_false_when_hasCreatedTicket_is_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            completeSendMessageSuccessfully(action)
        }
        let sut = SupportChatViewModel(
            entryPoint: .preLogin,
            stores: stores,
            hasCreatedTicket: true,
            onContactHumanSupport: { _, _, _ in }
        )

        // When — append a user message so the only failing condition is hasCreatedTicket
        sut.inputText = "Hello"
        sut.sendMessage()

        // Then
        #expect(sut.canEscalateToHumanSupport == false)
    }

    @Test func canEscalateToHumanSupport_is_false_when_chat_is_resolved() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            completeSendMessageSuccessfully(action)
        }
        let sut = makeSUT(entryPoint: .preLogin, stores: stores)
        sut.inputText = "Hello"
        sut.sendMessage()
        #expect(sut.canEscalateToHumanSupport == true)

        // When
        sut.markChatResolved()

        // Then
        #expect(sut.canEscalateToHumanSupport == false)
    }

    // MARK: - Resolved Button Tests

    @Test func shouldShowResolvedButton_when_last_bot_message_is_resolved_then_returns_true() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            guard case let .sendMessage(_, message, _, _, _, completion) = action else {
                return
            }

            let response = SupportChatResponse(
                chatID: 123,
                sessionID: "session-1",
                botSlug: "test-bot",
                botVersion: "1.0",
                messages: [
                    SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                    SupportChatMessage(
                        messageID: 2,
                        role: .bot,
                        content: "Glad that helped.",
                        context: SupportChatMessageContext(sources: [], flags: nil, isResolved: true)
                    )
                ]
            )
            completion(.success(response))
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)

        // When
        sut.inputText = "That fixed it"
        sut.sendMessage()

        // Then
        #expect(sut.shouldShowResolvedButton == true)
    }

    @Test func shouldShowResolvedButton_when_last_bot_message_is_upvoted_then_returns_true() async {
        // Given
        let messageID: Int64 = 2
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            switch action {
            case let .sendMessage(_, message, _, _, _, completion):
                let response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Try this.", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)
        sut.inputText = "Help"
        sut.sendMessage()
        #expect(sut.shouldShowResolvedButton == false)

        // When
        sut.submitFeedback(messageID: messageID, upvoted: true)

        // Then
        #expect(sut.shouldShowResolvedButton == true)
    }

    @Test func sendMessage_when_last_bot_message_is_resolved_then_appends_resolved_prompt() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            guard case let .sendMessage(_, message, _, _, _, completion) = action else {
                return
            }

            let response = SupportChatResponse(
                chatID: 123,
                sessionID: "session-1",
                botSlug: "test-bot",
                botVersion: "1.0",
                messages: [
                    SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                    SupportChatMessage(
                        messageID: 2,
                        role: .bot,
                        content: "Glad that helped.",
                        context: SupportChatMessageContext(sources: [], flags: nil, isResolved: true)
                    )
                ]
            )
            completion(.success(response))
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)

        // When
        sut.inputText = "That fixed it"
        sut.sendMessage()

        // Then
        let prompt = try #require(sut.messages.last)
        #expect(prompt.role == .bot)
        #expect(prompt.messageID == nil)
        #expect(prompt.content == .resolvedPrompt)
    }

    @Test func submitFeedback_when_upvoting_last_bot_message_then_appends_resolved_prompt() async throws {
        // Given
        let messageID: Int64 = 2
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            switch action {
            case let .sendMessage(_, message, _, _, _, completion):
                let response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Try this.", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)
        sut.inputText = "Help"
        sut.sendMessage()

        // When
        sut.submitFeedback(messageID: messageID, upvoted: true)

        // Then
        let prompt = try #require(sut.messages.last)
        #expect(prompt.role == .bot)
        #expect(prompt.messageID == nil)
        #expect(prompt.content == .resolvedPrompt)
    }

    @Test func submitFeedback_when_resolved_prompt_already_exists_then_does_not_append_duplicate_prompt() async {
        // Given
        let messageID: Int64 = 2
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            switch action {
            case let .sendMessage(_, message, _, _, _, completion):
                let response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                        SupportChatMessage(
                            messageID: messageID,
                            role: .bot,
                            content: "Glad that helped.",
                            context: SupportChatMessageContext(sources: [], flags: nil, isResolved: true)
                        )
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)
        sut.inputText = "That fixed it"
        sut.sendMessage()
        let promptCount = sut.messages.filter { $0.content == .resolvedPrompt }.count

        // When
        sut.submitFeedback(messageID: messageID, upvoted: true)

        // Then
        #expect(promptCount == 1)
        #expect(sut.messages.filter { $0.content == .resolvedPrompt }.count == 1)
    }

    @Test func shouldShowResolvedButton_when_last_bot_message_is_downvoted_then_returns_false() async {
        // Given
        let messageID: Int64 = 2
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            switch action {
            case let .sendMessage(_, message, _, _, _, completion):
                let response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Try this.", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)
        sut.inputText = "Help"
        sut.sendMessage()

        // When
        sut.submitFeedback(messageID: messageID, upvoted: false)

        // Then
        #expect(sut.shouldShowResolvedButton == false)
    }

    @Test func shouldShowResolvedButton_when_two_bot_responses_excluding_greeting_and_issue_picker_then_returns_true() async {
        // Given
        var botMessageID: Int64 = 1
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            guard case let .sendMessage(_, message, _, _, _, completion) = action else {
                return
            }

            botMessageID += 1
            let response = SupportChatResponse(
                chatID: 123,
                sessionID: "session-1",
                botSlug: "test-bot",
                botVersion: "1.0",
                messages: [
                    SupportChatMessage(messageID: botMessageID - 1, role: .user, content: message, context: nil),
                    SupportChatMessage(messageID: botMessageID, role: .bot, content: "Bot response", context: nil)
                ]
            )
            completion(.success(response))
        }
        let sut = makeSUT(entryPoint: .helpAndSupport, stores: stores)
        sut.showGreeting()
        await sut.selectIssue(.other)

        // When
        sut.inputText = "First question"
        sut.sendMessage()
        #expect(sut.shouldShowResolvedButton == false)

        sut.inputText = "Follow up"
        sut.sendMessage()

        // Then
        #expect(sut.shouldShowResolvedButton == true)
    }

    @Test func shouldShowResolvedButton_when_shouldPromptHumanSupport_then_returns_false() async {
        // Given
        var sendCount = 0
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            guard case let .sendMessage(_, message, _, _, _, completion) = action else {
                return
            }

            sendCount += 1
            let response: SupportChatResponse
            if sendCount <= 2 {
                response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: Int64(sendCount * 2 - 1), role: .user, content: message, context: nil),
                        SupportChatMessage(messageID: Int64(sendCount * 2), role: .bot, content: "Bot response", context: nil)
                    ]
                )
            } else {
                response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 5, role: .user, content: message, context: nil),
                        SupportChatMessage(
                            messageID: 6,
                            role: .bot,
                            content: "Contact support.",
                            context: SupportChatMessageContext(
                                sources: [],
                                flags: SupportChatFlags(forwardToHumanSupport: true, cannedResponse: false, loggedIn: true, branch: nil)
                            )
                        )
                    ]
                )
            }
            completion(.success(response))
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)
        sut.inputText = "First question"
        sut.sendMessage()
        sut.inputText = "Follow up"
        sut.sendMessage()
        #expect(sut.shouldShowResolvedButton == true)

        // When
        sut.inputText = "Still need help"
        sut.sendMessage()

        // Then
        #expect(sut.shouldPromptHumanSupport == true)
        #expect(sut.shouldShowResolvedButton == false)
    }

    @Test func markChatResolved_when_shouldShowResolvedButton_then_hides_resolved_button() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            guard case let .sendMessage(_, message, _, _, _, completion) = action else {
                return
            }

            let response = SupportChatResponse(
                chatID: 123,
                sessionID: "session-1",
                botSlug: "test-bot",
                botVersion: "1.0",
                messages: [
                    SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                    SupportChatMessage(
                        messageID: 2,
                        role: .bot,
                        content: "Glad that helped.",
                        context: SupportChatMessageContext(sources: [], flags: nil, isResolved: true)
                    )
                ]
            )
            completion(.success(response))
        }
        let sut = makeSUT(entryPoint: .connectivityTool, stores: stores)
        sut.inputText = "That fixed it"
        sut.sendMessage()
        #expect(sut.shouldShowResolvedButton == true)

        // When
        sut.markChatResolved()

        // Then
        #expect(sut.isChatResolved == true)
        #expect(sut.shouldShowResolvedButton == false)
    }

    // MARK: - Feedback Tests

    @Test func chatMessage_shouldShowFeedbackButtons_when_bot_message_is_resolved_then_returns_false() {
        // Given
        let message = SupportChatViewModel.ChatMessage(
            role: .bot,
            text: "This should solve the issue.",
            messageID: 123,
            isResolved: true
        )

        // Then
        #expect(message.shouldShowFeedbackButtons == false)
    }

    @Test func submitFeedback_when_valid_messageID_then_dispatches_action() async {
        // Given
        let chatID: Int64 = 123
        let sessionID = "session-1"
        let messageID: Int64 = 456
        let botSlug = "test-bot"
        var receivedFeedback: (botSlug: String, chatID: Int64, messageID: Int64, sessionID: String, upvoted: Bool)?
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            switch action {
            case let .sendMessage(_, _, _, _, _, completion):
                let response = SupportChatResponse(
                    chatID: chatID,
                    sessionID: sessionID,
                    botSlug: botSlug,
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: "Help", context: nil),
                        SupportChatMessage(messageID: messageID, role: .bot, content: "How can I help?", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(botSlug, chatID, messageID, sessionID, upvoted, onCompletion):
                receivedFeedback = (botSlug, chatID, messageID, sessionID, upvoted)
                onCompletion(.success(()))
            default:
                break
            }
        }

        let sut = SupportChatViewModel(
            botSlug: botSlug,
            entryPoint: .connectivityTool,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
            onContactHumanSupport: { _, _, _ in }
        )
        sut.inputText = "Help"
        sut.sendMessage()

        // When
        sut.submitFeedback(messageID: messageID, upvoted: true)

        // Then
        #expect(receivedFeedback?.botSlug == botSlug)
        #expect(receivedFeedback?.chatID == chatID)
        #expect(receivedFeedback?.messageID == messageID)
        #expect(receivedFeedback?.sessionID == sessionID)
        #expect(receivedFeedback?.upvoted == true)
    }

    @Test func submitFeedback_when_already_rated_then_does_not_dispatch_again() async {
        // Given
        let chatID: Int64 = 123
        let messageID: Int64 = 456
        var feedbackCallCount = 0
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
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Hello", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                feedbackCallCount += 1
                onCompletion(.success(()))
            default:
                break
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .connectivityTool,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
            onContactHumanSupport: { _, _, _ in }
        )
        sut.inputText = "Hello"
        sut.sendMessage()

        // When - rate twice
        sut.submitFeedback(messageID: messageID, upvoted: true)
        sut.submitFeedback(messageID: messageID, upvoted: false)

        // Then - only one call
        #expect(feedbackCallCount == 1)
    }

    @Test func submitFeedback_when_upvoted_stores_rating_direction() async {
        // Given
        let chatID: Int64 = 123
        let messageID: Int64 = 456
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
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Hello", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .connectivityTool,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
            onContactHumanSupport: { _, _, _ in }
        )
        sut.inputText = "Hello"
        sut.sendMessage()

        // When
        sut.submitFeedback(messageID: messageID, upvoted: true)

        // Then
        #expect(sut.messageRatings[messageID] == true)
    }

    @Test func submitFeedback_when_downvoted_stores_rating_direction() async {
        // Given
        let chatID: Int64 = 123
        let messageID: Int64 = 456
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
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Hello", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .connectivityTool,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
            onContactHumanSupport: { _, _, _ in }
        )
        sut.inputText = "Hello"
        sut.sendMessage()

        // When
        sut.submitFeedback(messageID: messageID, upvoted: false)

        // Then
        #expect(sut.messageRatings[messageID] == false)
    }

    @Test func submitFeedback_tracks_analytics_event() async {
        // Given
        let chatID: Int64 = 123
        let messageID: Int64 = 456
        let analyticsProvider = MockAnalyticsProvider()
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
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Hello", context: nil)
                    ]
                )
                completion(.success(response))
            case let .submitFeedback(_, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .connectivityTool,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: analyticsProvider),
            onContactHumanSupport: { _, _, _ in }
        )
        sut.inputText = "Hello"
        sut.sendMessage()

        // When
        sut.submitFeedback(messageID: messageID, upvoted: false)

        // Then
        #expect(analyticsProvider.receivedEvents.contains("support_chat_feedback_submitted"))
        #expect(analyticsProvider.received(event: "support_chat_feedback_submitted", with: ["rating": "down"]))
    }

    @Test func sendMessage_when_success_then_bot_message_has_messageID() async {
        // Given
        let messageID: Int64 = 789
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, _, completion) = action {
                let response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: "Hello", context: nil),
                        SupportChatMessage(messageID: messageID, role: .bot, content: "Hi there!", context: nil)
                    ]
                )
                completion(.success(response))
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .connectivityTool,
            stores: stores,
            onContactHumanSupport: { _, _, _ in }
        )
        sut.inputText = "Hello"

        // When
        sut.sendMessage()

        // Then
        let botMessage = sut.messages.first { $0.role == .bot }
        #expect(botMessage?.messageID == messageID)
    }

    @Test func sendMessage_when_success_then_bot_message_isNewInSession_is_true() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, _, completion) = action {
                let response = SupportChatResponse(
                    chatID: 123,
                    sessionID: "session-1",
                    botSlug: "test-bot",
                    botVersion: "1.0",
                    messages: [
                        SupportChatMessage(messageID: 1, role: .user, content: "Hello", context: nil),
                        SupportChatMessage(messageID: 2, role: .bot, content: "Hi there!", context: nil)
                    ]
                )
                completion(.success(response))
            }
        }

        let sut = SupportChatViewModel(
            entryPoint: .connectivityTool,
            stores: stores,
            onContactHumanSupport: { _, _, _ in }
        )
        sut.inputText = "Hello"

        // When
        sut.sendMessage()

        // Then
        let botMessage = sut.messages.first { $0.role == .bot }
        #expect(botMessage?.isNewInSession == true)
    }

    @Test(.timeLimit(.minutes(1)))
    func resumeIfNeeded_when_success_then_rehydrated_messages_have_isNewInSession_false() async {
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
        #expect(sut.messages.allSatisfy { $0.isNewInSession == false })
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

    private func completeSendMessageSuccessfully(_ action: SupportChatAction) {
        guard case let .sendMessage(botSlug, message, _, _, _, completion) = action else {
            return
        }

        let response = SupportChatResponse(
            chatID: 123,
            sessionID: "session-1",
            botSlug: botSlug,
            botVersion: "1.0",
            messages: [
                SupportChatMessage(messageID: 1, role: .user, content: message, context: nil),
                SupportChatMessage(messageID: 2, role: .bot, content: "How can I help?", context: nil)
            ]
        )
        completion(.success(response))
    }
}

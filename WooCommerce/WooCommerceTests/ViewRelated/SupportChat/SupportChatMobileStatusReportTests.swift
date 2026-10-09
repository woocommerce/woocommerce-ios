import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct SupportChatMobileStatusReportTests {
    @Test(arguments: [SupportChatViewModel.EntryPoint.preLogin, .helpAndSupport, .connectivityTool])
    func test_first_message_when_chat_is_new_then_merges_mobile_report_and_preserves_other_context(entryPoint: SupportChatViewModel.EntryPoint) async {
        // Given
        let provider = MockMobileStatusReportProvider()
        provider.report = "# Mobile Status Report\nOS: iOS 27\n# No store selected"
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        var sentContext: RequestParameterDictionary?
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, context, _) = action { sentContext = context }
        }
        let context: RequestParameterDictionary = ["troubleshootingResults": .string("Connectivity failed"),
                                                   "site_url": .string("https://context.example.com"), "selectedSiteId": .int64(123)]
        let sut = SupportChatViewModel(mobileStatusReportProvider: provider, entryPoint: entryPoint, stores: stores,
                                      initialContext: context, supportSiteAddress: "https://failed.example.com",
                                      onContactHumanSupport: { _, _, _, _, _ in })
        sut.inputText = "Help with my store"

        // When
        await sut.sendMessage()

        // Then
        #expect(provider.generateReportSiteAddresses == ["https://failed.example.com"])
        #expect(sentContext?["troubleshootingResults"] == .string("Connectivity failed\n\n## Mobile Status Report\n" + provider.report))
        #expect(sentContext?["site_url"] == context["site_url"])
        #expect(sentContext?["selectedSiteId"] == context["selectedSiteId"])
        #expect(sut.messages.first?.content.text == "Help with my store")
        #expect(!sut.messages.contains { $0.content.text?.contains("Mobile Status Report") == true })
    }

    @Test func test_initial_message_when_report_is_preparing_then_shows_sending_state_and_rejects_duplicate_submission() async {
        // Given
        let provider = MockMobileStatusReportProvider()
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        var sendCount = 0
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case .sendMessage = action { sendCount += 1 }
        }
        let sut = SupportChatViewModel(mobileStatusReportProvider: provider, entryPoint: .preLogin, stores: stores,
                                      initialMessage: "Login failed", onContactHumanSupport: { _, _, _, _, _ in })
        provider.onGenerateReport = {
            #expect(sut.state == .sending)
            #expect(sut.messages.map(\.role) == [.user])
            #expect(sendCount == 0)
            sut.inputText = "Duplicate"
            await sut.sendMessage()
            await sut.startIfNeeded()
        }

        // When
        await sut.startIfNeeded()

        // Then
        #expect(sendCount == 1)
        #expect(provider.generateReportSiteAddresses.count == 1)
        #expect(sut.messages.count == 1)
    }

    @Test func test_first_request_when_failed_then_reuses_report_but_follow_up_has_no_context() async {
        // Given
        let provider = MockMobileStatusReportProvider()
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        var contexts = [RequestParameterDictionary?]()
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            guard case let .sendMessage(botSlug, _, _, _, context, completion) = action else { return }
            contexts.append(context)
            if contexts.count == 1 {
                completion(.failure(NSError(domain: "Test", code: 500)))
            } else {
                completion(.success(SupportChatResponse(chatID: 123, sessionID: "session", botSlug: botSlug, botVersion: "1",
                                                       messages: [SupportChatMessage(messageID: 1, role: .bot, content: "Try this", context: nil)])))
            }
        }
        let sut = SupportChatViewModel(mobileStatusReportProvider: provider, entryPoint: .preLogin, stores: stores,
                                      initialContext: ["site_url": .string("https://context.example.com")],
                                      initialMessage: "Login failed", onContactHumanSupport: { _, _, _, _, _ in })

        // When
        await sut.startIfNeeded()
        sut.dismissError()
        provider.report = "Changed report must not replace the startup snapshot"
        sut.inputText = "Please try again"
        await sut.sendMessage()
        sut.inputText = "A follow-up"
        await sut.sendMessage()

        // Then
        #expect(provider.generateReportSiteAddresses == ["https://context.example.com"])
        #expect(contexts.count == 3)
        #expect(contexts[0] == contexts[1])
        #expect(contexts[2] == nil)
    }

    @Test func test_resume_when_history_is_opened_then_does_not_generate_or_send_mobile_report() async {
        // Given
        let provider = MockMobileStatusReportProvider()
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        var sendCount = 0
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case .sendMessage = action { sendCount += 1 }
        }
        let sut = SupportChatViewModel(mobileStatusReportProvider: provider, entryPoint: .chatHistory, stores: stores,
                                      initialMessage: "Do not resend", chatID: 123, sessionID: "session",
                                      onContactHumanSupport: { _, _, _, _, _ in })

        // When
        await sut.startIfNeeded()

        // Then
        #expect(provider.generateReportSiteAddresses.isEmpty)
        #expect(sendCount == 0)
    }

    @Test func test_send_when_preparation_is_cancelled_then_does_not_dispatch_and_restores_input_availability() async {
        // Given
        let provider = MockMobileStatusReportProvider()
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        var sendCount = 0
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case .sendMessage = action { sendCount += 1 }
        }
        let sut = SupportChatViewModel(mobileStatusReportProvider: provider, entryPoint: .preLogin, stores: stores,
                                      initialMessage: "Login failed", onContactHumanSupport: { _, _, _, _, _ in })

        // When
        let task = Task { await sut.startIfNeeded() }
        task.cancel()
        await task.value

        // Then
        #expect(sendCount == 0)
        #expect(sut.state == .idle)
        #expect(sut.messages.first?.failed == true)
        #expect(sut.isContactHumanSupportButtonEnabled)
    }

    @Test func test_send_when_report_is_empty_then_preserves_available_diagnostics() async {
        // Given
        let provider = MockMobileStatusReportProvider()
        provider.report = ""
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let context: RequestParameterDictionary = ["troubleshootingResults": .string("Login failed")]
        var sentContext: RequestParameterDictionary?
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .sendMessage(_, _, _, _, context, _) = action { sentContext = context }
        }
        let sut = SupportChatViewModel(mobileStatusReportProvider: provider, entryPoint: .preLogin, stores: stores,
                                      initialContext: context, initialMessage: "Login failed",
                                      onContactHumanSupport: { _, _, _, _, _ in })

        // When
        await sut.startIfNeeded()

        // Then
        #expect(sentContext == context)
        #expect(sut.state == .sending)
    }
}

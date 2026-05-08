import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

struct SupportChatRemoteTests {
    private let network = MockNetwork()
    private let botSlug = "woo-chat-allusers"

    // MARK: - Request shape

    @Test func sendMessage_when_no_chatID_then_posts_to_new_chat_path() async throws {
        // Given
        let remote = SupportChatRemote(network: network)

        // When
        _ = try? await remote.sendMessage(botSlug: botSlug,
                                          message: "hi",
                                          chatID: nil,
                                          sessionID: nil,
                                          context: nil)

        // Then
        let request = try #require(network.requestsForResponseData.first as? DotcomRequest)
        #expect(request.path == "odie/chat/\(botSlug)")
    }

    @Test func sendMessage_when_chatID_provided_then_posts_to_follow_up_path() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let chatID: Int64 = 4242

        // When
        _ = try? await remote.sendMessage(botSlug: botSlug,
                                          message: "hi",
                                          chatID: chatID,
                                          sessionID: nil,
                                          context: nil)

        // Then
        let request = try #require(network.requestsForResponseData.first as? DotcomRequest)
        #expect(request.path == "odie/chat/\(botSlug)/\(chatID)")
    }

    @Test func sendMessage_sends_message_in_request_parameters() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let message = "How do I set up shipping zones?"

        // When
        _ = try? await remote.sendMessage(botSlug: botSlug,
                                          message: message,
                                          chatID: nil,
                                          sessionID: nil,
                                          context: nil)

        // Then
        let parameters = try #require(network.queryParametersDictionary)
        #expect(parameters["message"] as? String == message)
    }

    @Test func sendMessage_when_context_provided_then_context_is_in_request_parameters() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let context: [String: Any] = [
            "selectedSiteId": 220224716,
            "pathname": "/home/example.com"
        ]

        // When
        _ = try? await remote.sendMessage(botSlug: botSlug,
                                          message: "hi",
                                          chatID: nil,
                                          sessionID: nil,
                                          context: context)

        // Then
        let parameters = try #require(network.queryParametersDictionary)
        let sentContext = try #require(parameters["context"] as? [String: Any])
        #expect(sentContext["selectedSiteId"] as? Int == 220224716)
        #expect(sentContext["pathname"] as? String == "/home/example.com")
    }

    @Test func sendMessage_when_context_nil_then_context_is_absent_from_parameters() async throws {
        // Given
        let remote = SupportChatRemote(network: network)

        // When
        _ = try? await remote.sendMessage(botSlug: botSlug,
                                          message: "hi",
                                          chatID: nil,
                                          sessionID: nil,
                                          context: nil)

        // Then
        let parameters = try #require(network.queryParametersDictionary)
        #expect(parameters["context"] == nil)
    }

    // MARK: - Response decoding

    @Test func sendMessage_when_response_is_valid_then_returns_parsed_chat() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)",
                                 filename: "support-chat-send-message")

        // When
        let response = try await remote.sendMessage(botSlug: botSlug,
                                                    message: "hi",
                                                    chatID: nil,
                                                    sessionID: nil,
                                                    context: nil)

        // Then
        #expect(response.chatID == 1001)
        #expect(response.sessionID == "8c1e24b8-7d67-4f1f-92b2-f45d53136fd4")
        #expect(response.botSlug == botSlug)
        #expect(response.botVersion == "1.4.3")
        #expect(response.messages.count == 1)

        let firstMessage = try #require(response.messages.first)
        #expect(firstMessage.messageID == 3003)
        #expect(firstMessage.role == .bot)
        #expect(firstMessage.content.contains("Placeholder Markdown answer"))
    }

    @Test func sendMessage_when_response_has_sources_then_sources_are_decoded() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)",
                                 filename: "support-chat-send-message")

        // When
        let response = try await remote.sendMessage(botSlug: botSlug,
                                                    message: "hi",
                                                    chatID: nil,
                                                    sessionID: nil,
                                                    context: nil)

        // Then
        let context = try #require(response.messages.first?.context)
        #expect(context.sources.count == 2)

        let firstSource = try #require(context.sources.first)
        #expect(firstSource.title == "Placeholder Source Title")
        #expect(firstSource.url == "https://example.com/docs/source-a")
        #expect(firstSource.heading == "Excerpted heading")
    }

    @Test func sendMessage_when_response_has_flags_then_flags_are_decoded() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)",
                                 filename: "support-chat-send-message")

        // When
        let response = try await remote.sendMessage(botSlug: botSlug,
                                                    message: "hi",
                                                    chatID: nil,
                                                    sessionID: nil,
                                                    context: nil)

        // Then
        let flags = try #require(response.messages.first?.context?.flags)
        #expect(flags.forwardToHumanSupport == false)
        #expect(flags.cannedResponse == false)
        #expect(flags.loggedIn == false)
        #expect(flags.branch == "default")
    }

    @Test func sendMessage_when_response_role_is_unknown_then_decodes_as_unknown_case() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)",
                                 filename: "support-chat-unknown-role")

        // When
        let response = try await remote.sendMessage(botSlug: botSlug,
                                                    message: "hi",
                                                    chatID: nil,
                                                    sessionID: nil,
                                                    context: nil)

        // Then — unrecognized roles must not crash decoding; they fall back to .unknown.
        let firstMessage = try #require(response.messages.first)
        #expect(firstMessage.role == .unknown)
    }

    @Test func sendMessage_when_response_signals_forward_to_human_then_flag_is_true() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)",
                                 filename: "support-chat-forward-to-human")

        // When
        let response = try await remote.sendMessage(botSlug: botSlug,
                                                    message: "I need a human",
                                                    chatID: nil,
                                                    sessionID: nil,
                                                    context: nil)

        // Then
        let flags = try #require(response.messages.first?.context?.flags)
        #expect(flags.forwardToHumanSupport == true)
        #expect(flags.branch == "escalation")
    }

    @Test func sendMessage_when_response_has_support_area_then_area_is_decoded() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)",
                                 filename: "support-chat-with-support-area")

        // When
        let response = try await remote.sendMessage(botSlug: botSlug,
                                                    message: "My card reader won't connect",
                                                    chatID: nil,
                                                    sessionID: nil,
                                                    context: nil)

        // Then
        let supportArea = try #require(response.messages.first?.context?.supportArea)
        #expect(supportArea.area == .cardReader)
        #expect(supportArea.confidence == .high)
        #expect(supportArea.isHighConfidence == true)
    }

    @Test func sendMessage_when_response_lacks_support_area_then_support_area_is_nil() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)",
                                 filename: "support-chat-forward-to-human")

        // When
        let response = try await remote.sendMessage(botSlug: botSlug,
                                                    message: "hi",
                                                    chatID: nil,
                                                    sessionID: nil,
                                                    context: nil)

        // Then
        let context = try #require(response.messages.first?.context)
        #expect(context.supportArea == nil)
    }

    // MARK: - Error paths

    @Test func sendMessage_when_no_response_stubbed_then_throws_notFound() async throws {
        // Given
        let remote = SupportChatRemote(network: network)

        // When / Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.sendMessage(botSlug: botSlug,
                                         message: "hi",
                                         chatID: nil,
                                         sessionID: nil,
                                         context: nil)
        }
    }

    @Test func sendMessage_when_network_errors_then_propagates_error() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        network.simulateError(requestUrlSuffix: "odie/chat/\(botSlug)",
                              error: NetworkError.timeout())

        // When / Then
        await #expect(throws: NetworkError.timeout()) {
            try await remote.sendMessage(botSlug: botSlug,
                                         message: "hi",
                                         chatID: nil,
                                         sessionID: nil,
                                         context: nil)
        }
    }

    // MARK: - fetchChat

    @Test func fetchChat_issues_get_request_to_chat_path() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let chatID: Int64 = 4522824

        // When
        _ = try? await remote.fetchChat(botSlug: botSlug, chatID: chatID)

        // Then
        let request = try #require(network.requestsForResponseData.first as? DotcomRequest)
        #expect(request.path == "odie/chat/\(botSlug)/\(chatID)")
        #expect(request.method == .get)
    }

    @Test func fetchChat_when_response_is_valid_then_returns_every_turn_in_order() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let chatID: Int64 = 4522824
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)",
                                 filename: "support-chat-fetch-chat")

        // When
        let response = try await remote.fetchChat(botSlug: botSlug, chatID: chatID)

        // Then
        #expect(response.chatID == chatID)
        #expect(response.messages.count == 4)
        #expect(response.messages.map(\.role) == [.user, .bot, .user, .bot])
    }

    @Test func fetchChat_when_response_contains_user_role_then_decodes_as_user_case() async throws {
        // Given — GET surfaces user turns (POST only returns bot), so `.user` must decode cleanly.
        let remote = SupportChatRemote(network: network)
        let chatID: Int64 = 4522824
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)",
                                 filename: "support-chat-fetch-chat")

        // When
        let response = try await remote.fetchChat(botSlug: botSlug, chatID: chatID)

        // Then
        let firstMessage = try #require(response.messages.first)
        #expect(firstMessage.role == .user)
        #expect(firstMessage.content == "Smoke test for GET endpoint — ignore.")
    }

    @Test func fetchChat_when_user_message_context_lacks_flags_and_sources_then_decodes_failsafe() async throws {
        // Given — user messages carry a different `context` shape than bot messages (no flags/sources).
        let remote = SupportChatRemote(network: network)
        let chatID: Int64 = 4522824
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)",
                                 filename: "support-chat-fetch-chat")

        // When
        let response = try await remote.fetchChat(botSlug: botSlug, chatID: chatID)

        // Then — the failsafe decoder produces empty sources + nil flags rather than throwing.
        let userMessageContext = try #require(response.messages.first?.context)
        #expect(userMessageContext.sources.isEmpty)
        #expect(userMessageContext.flags == nil)
    }

    @Test func fetchChat_when_no_response_stubbed_then_throws_notFound() async throws {
        // Given
        let remote = SupportChatRemote(network: network)

        // When / Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.fetchChat(botSlug: botSlug, chatID: 4522824)
        }
    }

    @Test func fetchChat_when_network_errors_then_propagates_error() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let chatID: Int64 = 4522824
        network.simulateError(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)",
                              error: NetworkError.timeout())

        // When / Then
        await #expect(throws: NetworkError.timeout()) {
            try await remote.fetchChat(botSlug: botSlug, chatID: chatID)
        }
    }

    // MARK: - submitFeedback

    @Test func submitFeedback_posts_to_correct_path() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let botSlug = "woo-chat"
        let chatID: Int64 = 999
        let messageID: Int64 = 123
        let sessionID = "session-abc-123"
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)/\(messageID)/feedback",
                                 filename: "generic_success")

        // When
        try await remote.submitFeedback(botSlug: botSlug, chatID: chatID, messageID: messageID, sessionID: sessionID, upvoted: true)

        // Then
        let request = try #require(network.requestsForResponseData.first as? DotcomRequest)
        #expect(request.path == "odie/chat/\(botSlug)/\(chatID)/\(messageID)/feedback")
        #expect(request.method == .post)
    }

    @Test func submitFeedback_sends_sessionID_and_positive_ratingValue_in_parameters() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let botSlug = "woo-chat"
        let chatID: Int64 = 999
        let messageID: Int64 = 123
        let sessionID = "session-abc-123"
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)/\(messageID)/feedback",
                                 filename: "generic_success")

        // When
        try await remote.submitFeedback(botSlug: botSlug, chatID: chatID, messageID: messageID, sessionID: sessionID, upvoted: true)

        // Then
        let parameters = try #require(network.queryParametersDictionary)
        #expect(parameters["session_id"] as? String == sessionID)
        #expect(parameters["rating_value"] as? Int == 1)
    }

    @Test func submitFeedback_sends_negative_ratingValue_in_parameters_when_downvoted() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let botSlug = "woo-chat"
        let chatID: Int64 = 888
        let messageID: Int64 = 456
        let sessionID = "session-xyz"
        network.simulateResponse(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)/\(messageID)/feedback",
                                 filename: "generic_success")

        // When
        try await remote.submitFeedback(botSlug: botSlug, chatID: chatID, messageID: messageID, sessionID: sessionID, upvoted: false)

        // Then
        let parameters = try #require(network.queryParametersDictionary)
        #expect(parameters["rating_value"] as? Int == -1)
    }

    @Test func submitFeedback_when_network_errors_then_propagates_error() async throws {
        // Given
        let remote = SupportChatRemote(network: network)
        let botSlug = "woo-chat"
        let chatID: Int64 = 999
        let messageID: Int64 = 123
        let sessionID = "session-abc"
        network.simulateError(requestUrlSuffix: "odie/chat/\(botSlug)/\(chatID)/\(messageID)/feedback",
                              error: NetworkError.timeout())

        // When / Then
        await #expect(throws: NetworkError.timeout()) {
            try await remote.submitFeedback(botSlug: botSlug, chatID: chatID, messageID: messageID, sessionID: sessionID, upvoted: true)
        }
    }
}

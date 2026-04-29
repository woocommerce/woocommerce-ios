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
                                                    context: nil)

        // Then
        let flags = try #require(response.messages.first?.context?.flags)
        #expect(flags.forwardToHumanSupport == true)
        #expect(flags.branch == "escalation")
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
                                         context: nil)
        }
    }
}

import Foundation
import Testing
@testable import WooAIAssistant

struct WooAssistantHeadlessTests {

    @Test
    func test_send_when_text_only_response_then_assistantText_populated_and_no_cards() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("Hi"), .completed(.stop)]
        ])
        let restClient = MockWCRESTClient(response: StubResponses.ok("[]"))
        let harness = WooAssistantHeadless(
            credentials: makeTestCredentials(),
            configuration: .init(),
            chatService: chat,
            restClient: restClient
        )

        // When
        let result = try await harness.send("hi there")

        // Then
        #expect(result.assistantText == "Hi")
        #expect(result.toolCalls.isEmpty)
        #expect(result.cards.isEmpty)
        #expect(result.confirmations.isEmpty)
        #expect(result.failureMessage == nil)
    }

    @Test
    func test_send_when_tool_call_then_toolCalls_includes_resultJSON() async throws {
        // Given
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_orders_1",
            function: .init(name: "orders_list", arguments: #"{"per_page":2}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("done"), .completed(.stop)]
        ])
        let cannedOrders = #"[{"id":3551,"number":"3551","status":"processing","total":"42.00","currency":"USD"}]"#
        let restClient = MockWCRESTClient(response: StubResponses.ok(cannedOrders))
        let harness = WooAssistantHeadless(
            credentials: makeTestCredentials(),
            configuration: .init(),
            chatService: chat,
            restClient: restClient
        )

        // When
        let result = try await harness.send("show recent orders")

        // Then
        #expect(result.toolCalls.count == 1)
        let firstCall = try #require(result.toolCalls.first)
        #expect(firstCall.name == "orders_list")
        let resultJSON = try #require(firstCall.resultJSON)
        #expect(resultJSON.contains("3551"))
        #expect(result.assistantText == "done")
    }

    @Test
    func test_send_when_orders_list_emitted_then_cards_array_includes_kind_and_payload() async throws {
        // Given
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_orders_card",
            function: .init(name: "orders_list", arguments: #"{"per_page":1}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("here you go"), .completed(.stop)]
        ])
        let cannedOrders = #"[{"id":4001,"number":"4001","status":"completed","total":"99.00","currency":"USD"}]"#
        let restClient = MockWCRESTClient(response: StubResponses.ok(cannedOrders))
        let harness = WooAssistantHeadless(
            credentials: makeTestCredentials(),
            configuration: .init(),
            chatService: chat,
            restClient: restClient
        )

        // When
        let result = try await harness.send("show me one order")

        // Then
        #expect(result.cards.count == 1)
        let card = try #require(result.cards.first)
        #expect(card.kind == "orders_list")
        #expect(card.toolName == "orders_list")
        #expect(card.payloadJSON.isEmpty == false)
        #expect(card.payloadJSON.contains("4001"))
    }

    @Test
    func test_send_when_destructive_tool_and_default_decline_then_confirmation_recorded_as_declined() async throws {
        // Given
        let chat = MockAIChatService()
        let destructiveCall = OpenAIChat.ToolCall(
            id: "call_orders_update_1",
            function: .init(name: "orders_update", arguments: #"{"id":42,"status":"completed"}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(destructiveCall), .completed(.toolCalls)],
            [.textDelta("ok, I won't change that."), .completed(.stop)]
        ])
        let restClient = MockWCRESTClient(response: StubResponses.ok("{}"))
        let harness = WooAssistantHeadless(
            credentials: makeTestCredentials(),
            configuration: .init(defaultConfirmationPolicy: .alwaysDecline),
            chatService: chat,
            restClient: restClient
        )

        // When
        let result = try await harness.send("mark order 42 as completed")

        // Then
        #expect(result.confirmations.count == 1)
        let confirmation = try #require(result.confirmations.first)
        #expect(confirmation.toolName == "orders_update")
        #expect(confirmation.decision == "auto-declined")
        let restCalls = await restClient.calls
        let destructiveCallCount = restCalls.filter { $0.path.contains("orders/42") }.count
        #expect(destructiveCallCount == 0, "destructive REST call must be suppressed when declined")
    }

    @Test
    func test_jwt_cache_when_concurrent_callers_same_credentials_then_single_mint() async throws {
        // Given a valid-shape stub JWT so the cache's CachedJWT validation passes.
        await URLSessionJetpackAIJWTClient.providerCache.reset()
        let mintCounter = HeadlessMintCounter()
        let stubToken = Self.makeStubJWT(blogID: 12345, expiresIn: 3600)
        let mint: URLSessionJetpackAIJWTClient.Mint = { _, _, _ in
            await mintCounter.increment()
            return stubToken
        }
        let siteURL = URL(string: "https://store.example.com").unsafelyUnwrapped
        let providerA = URLSessionJetpackAIJWTClient(siteURL: siteURL,
                                                     blogID: 12345,
                                                     username: "merchant",
                                                     appPassword: "abcd efgh ijkl mnop",
                                                     mint: mint)
        let providerB = URLSessionJetpackAIJWTClient(siteURL: siteURL,
                                                     blogID: 12345,
                                                     username: "merchant",
                                                     appPassword: "abcd efgh ijkl mnop",
                                                     mint: mint)

        // When
        async let tokenA = providerA.currentJWT()
        async let tokenB = providerB.currentJWT()
        let resolvedA = try await tokenA
        let resolvedB = try await tokenB

        // Then
        #expect(resolvedA == stubToken)
        #expect(resolvedB == stubToken)
        let calls = await mintCounter.value
        #expect(calls == 1, "concurrent callers with identical credentials must share one mint")
    }

    private static func makeStubJWT(blogID: Int64, expiresIn seconds: Int) -> String {
        let header = #"{"alg":"HS256","typ":"JWT"}"#
        let exp = Int(Date().timeIntervalSince1970) + seconds
        let payload = "{\"blog_id\":\(blogID),\"exp\":\(exp)}"
        return [header, payload].map { Self.base64URLEncode(Data($0.utf8)) }.joined(separator: ".") + ".sig"
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func makeTestCredentials() -> WooAssistantHeadless.Credentials {
        WooAssistantHeadless.Credentials(
            siteURL: "https://store.example.com",
            siteID: 12345,
            username: "merchant",
            appPassword: "abcd efgh ijkl mnop"
        )
    }
}

actor HeadlessMintCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}


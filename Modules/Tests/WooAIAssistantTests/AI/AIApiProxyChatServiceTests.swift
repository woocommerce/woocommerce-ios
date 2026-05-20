import Foundation
import Testing
import NetworkingCore
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AIApiProxyChatServiceTests {

    // MARK: - Request shape

    @Test
    func test_sendChat_when_streaming_enabled_then_sets_text_event_stream_accept_header() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
    }

    @Test
    func test_sendChat_sets_authorization_bearer_header_from_token_provider() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport, token: "test-bearer-token")

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-bearer-token")
    }

    @Test
    func test_sendChat_does_not_set_X_WPCOM_AI_Feature_header() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        #expect(request.value(forHTTPHeaderField: "X-WPCOM-AI-Feature") == nil)
    }

    @Test
    func test_sendChat_sets_content_type_application_json() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func test_sendChat_uses_endpoint_override_when_provided() async throws {
        // Given
        let override = URL(string: "https://test.example/wpcom/v2/woo-mobile-ai/chat/completions")!
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = AIApiProxyChatService(tokenProvider: ConstantWPCOMTokenProvider(value: "tok"),
                                            endpoint: override,
                                            streamingTransport: transport.handler,
                                            sleep: noOpSleep)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        #expect(request.url == override)
    }

    @Test
    func test_sendChat_uses_production_endpoint_when_override_nil() async throws {
        // Given
        let expectedBase = try #require(URL(string: Settings.wordpressApiBaseURL))
        let expected = try #require(
            URL(string: "wpcom/v2/woo-mobile-ai/chat/completions", relativeTo: expectedBase)?.absoluteURL
        )
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = AIApiProxyChatService(tokenProvider: ConstantWPCOMTokenProvider(value: "tok"),
                                            endpoint: nil,
                                            streamingTransport: transport.handler,
                                            sleep: noOpSleep)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        #expect(request.url == expected)
    }

    // MARK: - Body shape

    @Test
    func test_sendChat_body_omits_feature_field() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["feature"] == nil)
    }

    @Test
    func test_sendChat_body_sets_stream_to_true() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["stream"] as? Bool == true)
    }

    @Test
    func test_sendChat_body_requests_usage_via_stream_options() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let streamOptions = try #require(json["stream_options"] as? [String: Any])
        #expect(streamOptions["include_usage"] as? Bool == true)
    }

    @Test
    func test_sendChat_body_defaults_model_to_configured_model() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == AssistantConfiguration.chatModel)
    }

    @Test
    func test_sendChat_body_includes_messages_in_order() async throws {
        // Given
        let messages: [OpenAIChat.Message] = [
            .init(role: .system, content: "You are helpful."),
            .init(role: .user, content: "Hello"),
            .init(role: .assistant, content: "Hi there")
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: messages, tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let wireMessages = try #require(json["messages"] as? [[String: Any]])
        #expect(wireMessages.count == 3)
        #expect(wireMessages[0]["role"] as? String == "system")
        #expect(wireMessages[1]["role"] as? String == "user")
        #expect(wireMessages[2]["role"] as? String == "assistant")
    }

    @Test
    func test_sendChat_body_includes_tools_when_provided() async throws {
        // Given
        let tool = OpenAIChat.ToolDefinition(function: .init(
            name: "orders_list",
            description: "List orders",
            parameters: .object(["type": .string("object"), "properties": .object([:])])
        ))
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: [tool], toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let tools = try #require(json["tools"] as? [[String: Any]])
        #expect(tools.count == 1)
        let fn = try #require(tools.first?["function"] as? [String: Any])
        #expect(fn["name"] as? String == "orders_list")
    }

    @Test
    func test_sendChat_body_omits_tools_when_nil() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["tools"] == nil)
    }

    @Test
    func test_sendChat_body_includes_tool_choice_when_provided() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([singleTextChunk()])])
        let service = makeService(transport: transport)

        // When
        _ = try await collect(
            service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: .auto)
        )

        // Then
        let captured = await transport.lastRequest
        let request = try #require(captured)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["tool_choice"] as? String == "auto")
    }

    // MARK: - Token provider failures

    @Test
    func test_sendChat_when_token_provider_throws_then_finishes_stream_with_assistant_error() async throws {
        // Given
        struct ThrowingTokenProvider: WPCOMTokenProviding {
            func token() async throws -> String {
                throw AssistantError(kind: .auth, message: "credentials unavailable")
            }
        }
        let transport = ScriptedProxyTransport(scenarios: [])
        let service = AIApiProxyChatService(tokenProvider: ThrowingTokenProvider(),
                                            endpoint: testEndpoint,
                                            streamingTransport: transport.handler,
                                            sleep: noOpSleep)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected token provider error to surface.")
        } catch let error as AssistantError {
            #expect(error.kind == .auth)
        }
    }

    // MARK: - Streaming success

    @Test
    func test_sendChat_streaming_when_chunks_arrive_then_yields_textDelta_events_in_order() async throws {
        // Given
        let frames = [
            sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Hello\"}}]}"),
            sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\", world\"},\"finish_reason\":\"stop\"}]}"),
            "data: [DONE]\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        #expect(textDeltas(in: events).joined() == "Hello, world")
    }

    @Test
    func test_sendChat_streaming_when_DONE_sentinel_arrives_then_terminates_cleanly() async throws {
        // Given
        let frames = [
            sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"done\"},\"finish_reason\":\"stop\"}]}"),
            "data: [DONE]\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        if case .completed(let reason) = events.last {
            #expect(reason == .stop)
        } else {
            Issue.record("Expected last event to be .completed.")
        }
    }

    @Test
    func test_sendChat_streaming_when_tool_call_deltas_arrive_in_pieces_then_yields_complete_toolCall_after_all_deltas()
    async throws {
        // Given
        let frames = [
            toolCallSkeletonFrame(index: 0, id: "call_99", name: "products_list"),
            toolCallArgsFrame(index: 0, args: "{\"page\":"),
            toolCallArgsFrame(index: 0, args: "1}"),
            finishFrame(reason: "tool_calls"),
            "data: [DONE]\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let calls = toolCalls(in: events)
        #expect(calls.count == 1)
        #expect(calls.first?.id == "call_99")
        #expect(calls.first?.function.name == "products_list")
        #expect(calls.first?.function.arguments == "{\"page\":1}")
    }

    @Test
    func test_sendChat_streaming_when_utf8_multibyte_char_straddles_chunk_boundary_then_text_decoded_correctly()
    async throws {
        // Given
        let prefix = "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"caf"
        let suffix = "\"},\"finish_reason\":\"stop\"}]}\n\ndata: [DONE]\n\n"
        let eBytes: [UInt8] = [0xC3, 0xA9]
        var firstChunk = Data(prefix.utf8)
        firstChunk.append(eBytes[0])
        var secondChunk = Data()
        secondChunk.append(eBytes[1])
        secondChunk.append(Data(suffix.utf8))
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([firstChunk, secondChunk])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        #expect(textDeltas(in: events).joined() == "café")
    }

    @Test
    func test_sendChat_when_stream_completes_with_no_events_on_200_then_throws_upstream_error() async throws {
        // Given
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data("data: [DONE]\n\n".utf8)])])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected empty 200 stream to surface as upstream error.")
        } catch let error as AssistantError {
            #expect(error.kind == .upstreamFailure)
            #expect(error.code == "200")
        }
    }

    // MARK: - Single-chunk success paths

    @Test
    func test_sendChat_single_chunk_when_200_with_assistant_text_then_yields_textDelta_then_completed() async throws {
        // Given
        let frames = [
            sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Hello\"},\"finish_reason\":\"stop\"}]}"),
            "data: [DONE]\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let deltas = textDeltas(in: events)
        #expect(deltas == ["Hello"])
        if case .completed(let reason) = events.last {
            #expect(reason == .stop)
        } else {
            Issue.record("Expected last event to be .completed.")
        }
    }

    @Test
    func test_sendChat_single_chunk_when_200_with_tool_calls_then_yields_toolCall_then_completed() async throws {
        // Given
        let frames = [
            toolCallSkeletonFrame(index: 0, id: "call_1", name: "orders_get"),
            toolCallArgsFrame(index: 0, args: "{\"id\":7}"),
            finishFrame(reason: "tool_calls"),
            "data: [DONE]\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let calls = toolCalls(in: events)
        #expect(calls.count == 1)
        #expect(calls.first?.function.name == "orders_get")
        if case .completed(let reason) = events.last {
            #expect(reason == .toolCalls)
        } else {
            Issue.record("Expected last event to be .completed.")
        }
    }

    @Test
    func test_sendChat_single_chunk_when_choice_has_finish_reason_then_completed_event_carries_it() async throws {
        // Given
        let frame = sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"ok\"},\"finish_reason\":\"length\"}]}")
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data((frame + "data: [DONE]\n\n").utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        if case .completed(let reason) = events.last {
            #expect(reason == .length)
        } else {
            Issue.record("Expected last event to be .completed with .length.")
        }
    }

    // MARK: - Error envelope decoder

    @Test
    func test_sendChat_when_response_is_401_with_rest_unauthorized_then_throws_typed_auth_error() async throws {
        // Given
        let body = proxyEnvelopeBody(code: "rest_unauthorized", message: "Unauthorized", status: 401)
        let transport = ScriptedProxyTransport(scenarios: [.errorBody(status: 401, body: body)])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected typed auth error to surface.")
        } catch let error as AssistantError {
            #expect(error.kind == .auth)
            #expect(error.code == "401")
        }
    }

    @Test
    func test_sendChat_when_response_is_401_with_oauth2_invalid_token_then_throws_typed_auth_error() async throws {
        // Given
        let body = proxyEnvelopeBody(code: "oauth2_invalid_token", message: "The OAuth2 token is invalid.", status: 401)
        let transport = ScriptedProxyTransport(scenarios: [.errorBody(status: 401, body: body)])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected typed auth error to surface.")
        } catch let error as AssistantError {
            #expect(error.kind == .auth)
            #expect(error.code == "401")
        }
    }

    @Test
    func test_sendChat_when_response_is_403_with_rest_forbidden_then_throws_typed_auth_error_with_server_message()
    async throws {
        // Given
        let serverMessage = "Sorry, this OAuth client is not allowed to use this endpoint."
        let body = proxyEnvelopeBody(code: "rest_forbidden", message: serverMessage, status: 403)
        let transport = ScriptedProxyTransport(scenarios: [.errorBody(status: 403, body: body)])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected typed auth error to surface.")
        } catch let error as AssistantError {
            #expect(error.kind == .auth)
            #expect(error.code == "403")
            #expect(error.message == serverMessage)
        }
    }

    @Test
    func test_sendChat_when_response_is_429_with_woo_mobile_ai_user_rate_limit_then_throws_rate_limit_error_after_retries()
    async throws {
        // Given
        let serverMessage = "Too many AI requests. Please slow down and try again in a minute."
        let body = proxyEnvelopeBody(code: "woo_mobile_ai_user_rate_limit", message: serverMessage, status: 429)
        let scenarios: [ProxyTransportScenario] = (0..<3).map { _ in .errorBody(status: 429, body: body) }
        let transport = ScriptedProxyTransport(scenarios: scenarios)
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected typed rate limit error to surface.")
        } catch let error as AssistantError {
            #expect(error.kind == .rateLimit)
            #expect(error.code == "429")
            #expect(error.message == serverMessage)
        }
        #expect(await transport.callCount == 3)
    }

    @Test
    func test_sendChat_when_response_is_429_with_unknown_code_then_falls_through_to_generic_error_after_retries()
    async throws {
        // Given
        let body = proxyEnvelopeBody(code: "some_other_error", message: "Unknown limit", status: 429)
        let scenarios: [ProxyTransportScenario] = (0..<3).map { _ in .errorBody(status: 429, body: body) }
        let transport = ScriptedProxyTransport(scenarios: scenarios)
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected error to surface.")
        } catch let error as AssistantError {
            #expect(error.code == "429")
            #expect(error.message.contains("some_other_error"))
        }
        #expect(await transport.callCount == 3)
    }

    @Test
    func test_sendChat_when_response_is_400_with_generic_envelope_then_surfaces_envelope_message() async throws {
        // Given
        let body = proxyEnvelopeBody(code: "validation_error", message: "Invalid input provided", status: 400)
        let transport = ScriptedProxyTransport(scenarios: [.errorBody(status: 400, body: body)])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected 400 error to surface.")
        } catch let error as AssistantError {
            #expect(error.code == "400")
            #expect(error.message.contains("validation_error"))
        }
    }

    @Test
    func test_sendChat_when_response_is_500_with_no_envelope_then_throws_generic_http_error() async throws {
        // Given
        let body = Data("Internal server error".utf8)
        let transport = ScriptedProxyTransport(scenarios: [.errorBody(status: 500, body: body)])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected 500 to surface.")
        } catch let error as AssistantError {
            #expect(error.kind == .upstreamFailure)
            #expect(error.code == "500")
        }
    }

    // MARK: - Retry behavior

    @Test
    func test_sendChat_when_429_then_retries_up_to_3_times_with_backoff_then_throws() async throws {
        // Given
        let body = proxyEnvelopeBody(code: "woo_mobile_ai_user_rate_limit", message: "Rate limited", status: 429)
        let scenarios: [ProxyTransportScenario] = (0..<3).map { _ in .errorBody(status: 429, body: body) }
        let transport = ScriptedProxyTransport(scenarios: scenarios)
        let recorder = SleepDelayRecorder()
        let service = AIApiProxyChatService(tokenProvider: ConstantWPCOMTokenProvider(value: "tok"),
                                            endpoint: testEndpoint,
                                            streamingTransport: transport.handler,
                                            sleep: recorder.handler)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected 429 to surface after retries.")
        } catch let error as AssistantError {
            #expect(error.kind == .rateLimit)
            #expect(error.code == "429")
        }
        #expect(await transport.callCount == 3)
        let delays = await recorder.delays
        #expect(delays.count == 2)
        #expect(delays[0] == 2_000_000_000)
        #expect(delays[1] == 4_000_000_000)
        #expect(delays[1] > delays[0])
    }

    @Test
    func test_sendChat_when_429_then_200_on_retry_then_yields_success_events() async throws {
        // Given
        let rateLimitBody = proxyEnvelopeBody(code: "woo_mobile_ai_user_rate_limit", message: "Rate limited", status: 429)
        let successChunk = singleTextChunk(text: "retry worked")
        let scenarios: [ProxyTransportScenario] = [
            .errorBody(status: 429, body: rateLimitBody),
            .successChunks([successChunk])
        ]
        let transport = ScriptedProxyTransport(scenarios: scenarios)
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        #expect(await transport.callCount == 2)
        #expect(textDeltas(in: events).joined() == "retry worked")
    }

    @Test
    func test_sendChat_streaming_when_429_arrives_after_partial_events_then_does_not_retry() async throws {
        // Given
        let partialFrame = sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"partial\"}}]}")
        let midStreamError = AssistantError(kind: .rateLimit, code: "429", message: "Rate limited mid-stream")
        let transport = ScriptedProxyTransport(scenarios: [
            .partialChunksThenError(chunks: [Data(partialFrame.utf8)], error: midStreamError)
        ])
        let service = makeService(transport: transport)

        // When
        var observed: [ChatStreamEvent] = []
        var caught: AssistantError?
        do {
            for try await event in service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil) {
                observed.append(event)
            }
            Issue.record("Expected mid-stream 429 to surface after partial events.")
        } catch let error as AssistantError {
            caught = error
        }

        // Then
        #expect(textDeltas(in: observed) == ["partial"])
        #expect(caught?.kind == .rateLimit)
        #expect(caught?.code == "429")
        #expect(await transport.callCount == 1)
    }

    @Test
    func test_sendChat_when_non_429_error_then_does_not_retry() async throws {
        // Given
        let body = Data("server error".utf8)
        let transport = ScriptedProxyTransport(scenarios: [.errorBody(status: 500, body: body)])
        let recorder = SleepDelayRecorder()
        let service = AIApiProxyChatService(tokenProvider: ConstantWPCOMTokenProvider(value: "tok"),
                                            endpoint: testEndpoint,
                                            streamingTransport: transport.handler,
                                            sleep: recorder.handler)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected 500 to surface.")
        } catch let error as AssistantError {
            #expect(error.kind == .upstreamFailure)
            #expect(error.code == "500")
        }
        #expect(await transport.callCount == 1)
        #expect(await recorder.delays.isEmpty)
    }

    // MARK: - Stream-level wrapped errors

    @Test
    func test_sendChat_streaming_when_first_chunk_is_wrapped_error_envelope_then_throws_typed_error() async throws {
        // Given
        let envelope = """
        {"code":"rest_unauthorized","message":"Unauthorized","data":{"status":401}}
        """
        let frame = "data: \(envelope)\n\n"
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frame.utf8)])])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected wrapped envelope inside SSE stream to surface as typed error.")
        } catch let error as AssistantError {
            #expect(error.kind == .auth)
            #expect(error.code == "401")
        }
    }

    @Test
    func test_sendChat_streaming_when_chunk_payload_is_unparseable_then_throws_invalid_stream_error() async throws {
        // Given
        let frame = "data: {\"completely\":\"invalid\"}\n\n"
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frame.utf8)])])
        let service = makeService(transport: transport)

        // When / Then
        do {
            _ = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected malformed SSE chunk to surface as invalid stream error.")
        } catch let error as AssistantError {
            #expect(error.kind == .invalidStream)
        }
    }

    @Test
    func test_sendChat_when_200_stream_envelope_is_user_rate_limit_then_retries() async throws {
        // Given
        let envelope = """
        {"code":"woo_mobile_ai_user_rate_limit","message":"Rate limited","data":{"status":429}}
        """
        let firstAttempt = Data("data: \(envelope)\n\n".utf8)
        let secondAttempt = singleTextChunk(text: "retry worked")
        let transport = ScriptedProxyTransport(scenarios: [
            .successChunks([firstAttempt]),
            .successChunks([secondAttempt])
        ])
        let recorder = SleepDelayRecorder()
        let service = AIApiProxyChatService(tokenProvider: ConstantWPCOMTokenProvider(value: "tok"),
                                            endpoint: testEndpoint,
                                            streamingTransport: transport.handler,
                                            sleep: recorder.handler)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        #expect(await transport.callCount == 2)
        #expect(await recorder.delays.count == 1)
        #expect(textDeltas(in: events).joined() == "retry worked")
    }

    // MARK: - Coverage

    @Test
    func test_sendChat_when_two_tool_calls_in_one_stream_then_both_yielded_in_index_order() async throws {
        // Given
        let frames = [
            toolCallSkeletonFrame(index: 0, id: "call_a", name: "orders_list"),
            toolCallSkeletonFrame(index: 1, id: "call_b", name: "products_list"),
            toolCallArgsFrame(index: 0, args: "{\"page\":"),
            toolCallArgsFrame(index: 1, args: "{\"q\":"),
            toolCallArgsFrame(index: 0, args: "1}"),
            toolCallArgsFrame(index: 1, args: "\"hat\"}"),
            finishFrame(reason: "tool_calls"),
            "data: [DONE]\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let calls = toolCalls(in: events)
        #expect(calls.count == 2)
        #expect(calls.first?.id == "call_a")
        #expect(calls.first?.function.name == "orders_list")
        #expect(calls.first?.function.arguments == "{\"page\":1}")
        #expect(calls.last?.id == "call_b")
        #expect(calls.last?.function.name == "products_list")
        #expect(calls.last?.function.arguments == "{\"q\":\"hat\"}")
    }

    @Test
    func test_sendChat_when_stream_cancelled_then_no_completion_event_emitted() async throws {
        // Given
        let textFrame = sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"partial\"}}]}")
        let transport = ScriptedProxyTransport(scenarios: [.chunksThenHangUntilCancelled([Data(textFrame.utf8)])])
        let service = makeService(transport: transport)

        // When
        let consumer = Task { () -> [ChatStreamEvent] in
            var seen: [ChatStreamEvent] = []
            for try await event in service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil) {
                seen.append(event)
                break
            }
            return seen
        }
        let observed = try await consumer.value

        // Then
        #expect(observed.count == 1)
        #expect(textDeltas(in: observed) == ["partial"])
        #expect(!observed.contains { if case .completed = $0 { return true } else { return false } })
    }

    @Test
    func test_sendChat_when_malformed_chunk_after_valid_text_then_throws_invalid_stream() async throws {
        // Given
        let frames = [
            sseFrame("{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"valid\"}}]}"),
            "data: {\"completely\":\"invalid\"}\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When / Then
        var observed: [ChatStreamEvent] = []
        var caught: AssistantError?
        do {
            for try await event in service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil) {
                observed.append(event)
            }
            Issue.record("Expected malformed chunk after valid text to surface invalid stream error.")
        } catch let error as AssistantError {
            caught = error
        }
        #expect(textDeltas(in: observed) == ["valid"])
        #expect(caught?.kind == .invalidStream)
    }

    @Test
    func test_sendChat_when_finish_only_empty_content_stream_then_completes_without_upstream_error() async throws {
        // Given
        let frames = [
            finishFrame(reason: "stop"),
            "data: [DONE]\n\n"
        ]
        let transport = ScriptedProxyTransport(scenarios: [.successChunks([Data(frames.joined().utf8)])])
        let service = makeService(transport: transport)

        // When
        let events = try await collect(service.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        #expect(textDeltas(in: events).isEmpty)
        #expect(toolCalls(in: events).isEmpty)
        if case .completed(let reason) = events.last {
            #expect(reason == .stop)
        } else {
            Issue.record("Expected a finish-only stream to complete without an upstream error.")
        }
    }

    // MARK: - Helpers

    private var testEndpoint: URL {
        URL(string: "https://test.example/wpcom/v2/woo-mobile-ai/chat/completions")!
    }

    private var noOpSleep: AIApiProxyChatService.Sleep {
        { _ in }
    }

    private func makeService(transport: ScriptedProxyTransport,
                             token: String = "stub-token") -> AIApiProxyChatService {
        AIApiProxyChatService(tokenProvider: ConstantWPCOMTokenProvider(value: token),
                              endpoint: testEndpoint,
                              streamingTransport: transport.handler,
                              sleep: noOpSleep)
    }

    private func userMessage() -> OpenAIChat.Message {
        .init(role: .user, content: "ping")
    }

    private func collect(_ stream: AsyncThrowingStream<ChatStreamEvent, Error>) async throws -> [ChatStreamEvent] {
        var events: [ChatStreamEvent] = []
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    private func textDeltas(in events: [ChatStreamEvent]) -> [String] {
        events.compactMap {
            if case .textDelta(let text) = $0 { return text }
            return nil
        }
    }

    private func toolCalls(in events: [ChatStreamEvent]) -> [OpenAIChat.ToolCall] {
        events.compactMap {
            if case .toolCall(let call) = $0 { return call }
            return nil
        }
    }

    private func sseFrame(_ payload: String) -> String {
        "data: \(payload)\n\n"
    }

    private func singleTextChunk(text: String = "ok") -> Data {
        let payload = "{\"choices\":[{\"index\":0,\"delta\":{\"content\":\"\(text)\"},\"finish_reason\":\"stop\"}]}"
        return Data(("data: \(payload)\n\ndata: [DONE]\n\n").utf8)
    }

    private func toolCallSkeletonFrame(index: Int, id: String, name: String) -> String {
        let payload = "{\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[" +
            "{\"index\":\(index),\"id\":\"\(id)\",\"type\":\"function\"," +
            "\"function\":{\"name\":\"\(name)\",\"arguments\":\"\"}}]}}]}"
        return "data: \(payload)\n\n"
    }

    private func toolCallArgsFrame(index: Int, args: String) -> String {
        let escaped = args.replacingOccurrences(of: "\"", with: "\\\"")
        let payload = "{\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[" +
            "{\"index\":\(index),\"function\":{\"arguments\":\"\(escaped)\"}}]}}]}"
        return "data: \(payload)\n\n"
    }

    private func finishFrame(reason: String) -> String {
        "data: {\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"\(reason)\"}]}\n\n"
    }

    private func proxyEnvelopeBody(code: String, message: String, status: Int) -> Data {
        Data("{\"code\":\"\(code)\",\"message\":\"\(message)\",\"data\":{\"status\":\(status)}}".utf8)
    }
}

private enum ProxyTransportScenario {
    case successChunks([Data])
    case errorBody(status: Int, body: Data)
    case partialChunksThenError(chunks: [Data], error: Error)
    // Yields chunks then leaves the SSE stream open until the consumer terminates it, so a
    // cancellation can be observed without a real completion ever arriving.
    case chunksThenHangUntilCancelled([Data])
}

private actor ScriptedProxyTransport {
    private var scenarios: [ProxyTransportScenario]
    private(set) var callCount = 0
    private(set) var lastRequest: URLRequest?

    init(scenarios: [ProxyTransportScenario]) {
        self.scenarios = scenarios
    }

    nonisolated var handler: StreamingHTTPTransport {
        { @Sendable [self] request in
            try await self.handle(request: request)
        }
    }

    private func handle(request: URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, HTTPURLResponse) {
        callCount += 1
        lastRequest = request
        guard !scenarios.isEmpty else {
            throw AssistantError(kind: .network, message: "scripted transport exhausted")
        }
        let url = request.url ?? URL(string: "https://test.invalid")!
        let scenario = scenarios.removeFirst()
        switch scenario {
        case .successChunks(let chunks):
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                for chunk in chunks { continuation.yield(chunk) }
                continuation.finish()
            }
            let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (stream, http)
        case .errorBody(let status, let body):
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                continuation.yield(body)
                continuation.finish()
            }
            let http = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (stream, http)
        case .partialChunksThenError(let chunks, let error):
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                for chunk in chunks { continuation.yield(chunk) }
                continuation.finish(throwing: error)
            }
            let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (stream, http)
        case .chunksThenHangUntilCancelled(let chunks):
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                for chunk in chunks { continuation.yield(chunk) }
                continuation.onTermination = { _ in continuation.finish() }
            }
            let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (stream, http)
        }
    }
}

private actor SleepDelayRecorder {
    private(set) var delays: [UInt64] = []

    private func record(_ nanoseconds: UInt64) {
        delays.append(nanoseconds)
    }

    nonisolated var handler: AIApiProxyChatService.Sleep {
        { [self] nanoseconds in
            await self.record(nanoseconds)
        }
    }
}

import Foundation
import Testing
@testable import WooAIAssistant

struct JetpackAIQueryClientTests {

    @Test
    func test_streamTurn_when_streaming_with_split_chunks_then_assembles_text_in_order() async throws {
        // Given
        let frames = [
            "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Hel\"}}]}\n\n",
            "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"lo, w\"}}]}\n\n",
            "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"orld!\"}}]}\n\n",
            "data: {\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        let chunks = chunkifyAwkwardly(frames.joined())
        let client = makeClient(streamingResult: .successChunks(chunks))

        // When
        let events = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let textDeltas = events.compactMap { event -> String? in
            if case .textDelta(let text) = event { return text }
            return nil
        }
        #expect(textDeltas.joined() == "Hello, world!")
        if case .completed(let reason) = events.last {
            #expect(reason == .stop)
        } else {
            Issue.record("Expected last event to be completed.")
        }
    }

    @Test
    func test_streamTurn_when_429_then_retries_with_backoff() async throws {
        // Given
        let successFrames = "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"ok\"},\"finish_reason\":\"stop\"}]}\n\ndata: [DONE]\n\n"
        let scenarios: [TransportScenario] = [
            .errorBody(status: 429, body: rateLimitedBody()),
            .errorBody(status: 429, body: rateLimitedBody()),
            .successChunks([Data(successFrames.utf8)])
        ]
        let transport = ScriptedTransport(scenarios: scenarios)
        let sleepRecorder = SleepRecorder()
        let client = JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                          streamingTransport: transport.handler,
                                          sleep: sleepRecorder.handler)

        // When
        let events = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        #expect(await transport.callCount == 3)
        let textDeltas = events.compactMap { event -> String? in
            if case .textDelta(let text) = event { return text }
            return nil
        }
        #expect(textDeltas.joined() == "ok")
        let recordedDelays = await sleepRecorder.delays
        #expect(recordedDelays == [2_000_000_000, 4_000_000_000])
    }

    @Test
    func test_streamTurn_when_wrapped_error_envelope_then_throws_typed_AssistantError() async throws {
        // Given
        let envelope = #"{"code":"context_too_long","message":"Conversation exceeded the model context.","data":{"status":413}}"#
        let frame = "data: \(envelope)\n\n"
        let transport = ScriptedTransport(scenarios: [.successChunks([Data(frame.utf8)])])
        let client = JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                          streamingTransport: transport.handler,
                                          sleep: noOpSleep)

        // When / Then
        do {
            _ = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected wrapped envelope to surface as AssistantError.")
        } catch let error as AssistantError {
            #expect(error.code == "413")
            #expect(error.message.contains("context_too_long"))
        }
    }

    @Test
    func test_streamTurn_when_assistant_message_carries_tool_calls_then_encodes_empty_content_string() async throws {
        // Given
        let toolCall = OpenAIChat.ToolCall(id: "call_1", function: .init(name: "orders_get", arguments: "{}"))
        let assistantMessage = OpenAIChat.Message(role: .assistant, content: nil, toolCalls: [toolCall])
        let toolMessage = OpenAIChat.Message(role: .tool, content: "{}", toolCalls: nil, toolCallID: "call_1")
        let frame = "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"done\"},\"finish_reason\":\"stop\"}]}\n\ndata: [DONE]\n\n"
        let transport = ScriptedTransport(scenarios: [.successChunks([Data(frame.utf8)])])
        let client = JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                          streamingTransport: transport.handler,
                                          sleep: noOpSleep)

        // When
        _ = try await collect(client.streamTurn(messages: [userMessage(), assistantMessage, toolMessage],
                                                tools: nil,
                                                toolChoice: nil))

        // Then
        let captured = try #require(await transport.lastRequest)
        let body = try #require(captured.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let messages = try #require(json["messages"] as? [[String: Any]])
        let assistantOnWire = try #require(messages.first(where: { $0["role"] as? String == "assistant" }))
        let content = try #require(assistantOnWire["content"] as? String)
        #expect(content.isEmpty)
        #expect(assistantOnWire["tool_calls"] != nil)
    }

    @Test
    func test_streamTurn_when_utf8_boundary_split_then_recovers_full_character() async throws {
        // Given
        // Rocket emoji U+1F680 is 4 bytes (F0 9F 9A 80); the chunk break splits it 2/2.
        let prefix = "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Hi "
        let suffix = "!\"},\"finish_reason\":\"stop\"}]}\n\ndata: [DONE]\n\n"
        let emojiBytes: [UInt8] = [0xF0, 0x9F, 0x9A, 0x80]
        var firstChunk = Data(prefix.utf8)
        firstChunk.append(contentsOf: emojiBytes.prefix(2))
        var secondChunk = Data()
        secondChunk.append(contentsOf: emojiBytes.suffix(2))
        secondChunk.append(Data(suffix.utf8))
        let transport = ScriptedTransport(scenarios: [.successChunks([firstChunk, secondChunk])])
        let client = JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                          streamingTransport: transport.handler,
                                          sleep: noOpSleep)

        // When
        let events = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        let textDeltas = events.compactMap { event -> String? in
            if case .textDelta(let text) = event { return text }
            return nil
        }
        #expect(textDeltas.joined() == "Hi \u{1F680}!")
    }

    @Test
    func test_streamTurn_when_401_pre_data_then_invalidates_jwt_and_retries_once() async throws {
        // Given
        let successFrames = "data: {\"choices\":[{\"index\":0,\"delta\":{\"content\":\"after refresh\"},\"finish_reason\":\"stop\"}]}\n\ndata: [DONE]\n\n"
        let jwtProvider = ScriptedJWTProvider(tokens: ["stale-token", "fresh-token"])
        let transport = ScriptedTransport(scenarios: [
            .errorBody(status: 401, body: Data(#"{"code":"jetpack_ai_unauthorized","message":"unauthorized"}"#.utf8)),
            .successChunks([Data(successFrames.utf8)])
        ])
        let client = JetpackAIQueryClient(jwtProvider: jwtProvider,
                                          streamingTransport: transport.handler,
                                          sleep: noOpSleep)

        // When
        let events = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))

        // Then
        #expect(await transport.callCount == 2)
        #expect(await jwtProvider.invalidateCount == 1)
        #expect(await jwtProvider.handedOut == ["stale-token", "fresh-token"])
        let textDeltas = events.compactMap { event -> String? in
            if case .textDelta(let text) = event { return text }
            return nil
        }
        #expect(textDeltas.joined() == "after refresh")
    }

    @Test
    func test_streamTurn_when_401_repeats_then_surfaces_error_after_one_retry() async throws {
        // Given
        let unauthorizedBody = Data(#"{"code":"jetpack_ai_unauthorized","message":"unauthorized"}"#.utf8)
        let jwtProvider = ScriptedJWTProvider(tokens: ["t1", "t2", "t3"])
        let transport = ScriptedTransport(scenarios: [
            .errorBody(status: 401, body: unauthorizedBody),
            .errorBody(status: 401, body: unauthorizedBody)
        ])
        let client = JetpackAIQueryClient(jwtProvider: jwtProvider,
                                          streamingTransport: transport.handler,
                                          sleep: noOpSleep)

        // When / Then
        do {
            _ = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected the second 401 to surface.")
        } catch let error as AssistantError {
            #expect(error.code == "401")
        }
        #expect(await transport.callCount == 2)
        #expect(await jwtProvider.invalidateCount == 1)
    }

    @Test
    func test_streamTurn_when_429_repeats_three_times_then_surfaces_after_two_retries() async throws {
        // Given
        let scenarios: [TransportScenario] = (0..<3).map { _ in
            .errorBody(status: 429, body: rateLimitedBody())
        }
        let transport = ScriptedTransport(scenarios: scenarios)
        let sleepRecorder = SleepRecorder()
        let client = JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                          streamingTransport: transport.handler,
                                          sleep: sleepRecorder.handler)

        // When / Then
        do {
            _ = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected the third 429 to surface.")
        } catch let error as AssistantError {
            #expect(error.code == "429")
        }
        #expect(await transport.callCount == 3)
        #expect(await sleepRecorder.delays == [2_000_000_000, 4_000_000_000])
    }

    @Test
    func test_streamTurn_when_503_then_surfaces_without_retry() async throws {
        // Given
        let body = Data("upstream is down".utf8)
        let transport = ScriptedTransport(scenarios: [.errorBody(status: 503, body: body)])
        let client = JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                          streamingTransport: transport.handler,
                                          sleep: noOpSleep)

        // When / Then
        do {
            _ = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected 503 to surface.")
        } catch let error as AssistantError {
            #expect(error.code == "503")
            #expect(error.kind == .upstreamFailure)
        }
        #expect(await transport.callCount == 1)
    }

    @Test
    func test_streamTurn_when_wrapped_envelope_arrives_after_keepalive_then_throws_typed_AssistantError() async throws {
        // Given
        let envelope = #"{"code":"context_too_long","message":"context overflow","data":{"status":413}}"#
        let frames = ":\n\n:\n\ndata: \(envelope)\n\n"
        let transport = ScriptedTransport(scenarios: [.successChunks([Data(frames.utf8)])])
        let client = JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                          streamingTransport: transport.handler,
                                          sleep: noOpSleep)

        // When / Then
        do {
            _ = try await collect(client.streamTurn(messages: [userMessage()], tools: nil, toolChoice: nil))
            Issue.record("Expected wrapped envelope to surface even after keepalive comments.")
        } catch let error as AssistantError {
            #expect(error.code == "413")
            #expect(error.message.contains("context_too_long"))
        }
    }

    private func makeClient(streamingResult: TransportScenario) -> JetpackAIQueryClient {
        let transport = ScriptedTransport(scenarios: [streamingResult])
        return JetpackAIQueryClient(jwtProvider: stubJWTProvider(),
                                    streamingTransport: transport.handler,
                                    sleep: noOpSleep)
    }

    private func userMessage() -> OpenAIChat.Message {
        OpenAIChat.Message(role: .user, content: "ping")
    }

    private func collect(_ stream: AsyncThrowingStream<ChatStreamEvent, Error>) async throws -> [ChatStreamEvent] {
        var events: [ChatStreamEvent] = []
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    private func chunkifyAwkwardly(_ string: String) -> [Data] {
        let bytes = Array(string.utf8)
        var chunks: [Data] = []
        var index = 0
        let breakpoints = [7, 19, 47, 83]
        for breakpoint in breakpoints where breakpoint < bytes.count {
            chunks.append(Data(bytes[index..<breakpoint]))
            index = breakpoint
        }
        if index < bytes.count {
            chunks.append(Data(bytes[index..<bytes.count]))
        }
        return chunks
    }

    private func rateLimitedBody() -> Data {
        Data(#"{"code":"jetpack_ai_rate_limited","message":"too many requests","data":{"status":429}}"#.utf8)
    }

    private func stubJWTProvider() -> AssistantJWTProviding {
        FixedJWTProvider(token: "stub-token")
    }

    private var noOpSleep: JetpackAIQueryClient.Sleep {
        { _ in }
    }
}

private actor SleepRecorder {
    private(set) var delays: [UInt64] = []

    nonisolated var handler: JetpackAIQueryClient.Sleep {
        { @Sendable nanoseconds in
            await self.record(nanoseconds)
        }
    }

    private func record(_ nanoseconds: UInt64) {
        delays.append(nanoseconds)
    }
}

private struct FixedJWTProvider: AssistantJWTProviding {
    let token: String
    func currentJWT() async throws -> String { token }
}

private actor ScriptedJWTProvider: AssistantJWTProviding {
    private var tokens: [String]
    private(set) var invalidateCount = 0
    private(set) var handedOut: [String] = []

    init(tokens: [String]) {
        self.tokens = tokens
    }

    func currentJWT() async throws -> String {
        guard !tokens.isEmpty else {
            throw AssistantError(kind: .auth, message: "scripted provider exhausted")
        }
        let next = tokens.removeFirst()
        handedOut.append(next)
        return next
    }

    func invalidate() async {
        invalidateCount += 1
    }
}

private enum TransportScenario {
    case successChunks([Data])
    case errorBody(status: Int, body: Data)
}

private actor ScriptedTransport {
    private var scenarios: [TransportScenario]
    private(set) var callCount = 0
    private(set) var lastRequest: URLRequest?

    init(scenarios: [TransportScenario]) {
        self.scenarios = scenarios
    }

    nonisolated var handler: StreamingHTTPTransport {
        { @Sendable request in
            try await self.handle(request: request)
        }
    }

    private func handle(request: URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, HTTPURLResponse) {
        callCount += 1
        lastRequest = request
        guard !scenarios.isEmpty else {
            throw AssistantError(kind: .network, message: "scripted transport exhausted")
        }
        let scenario = scenarios.removeFirst()
        switch scenario {
        case .successChunks(let chunks):
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                for chunk in chunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
            let http = HTTPURLResponse(url: request.url ?? URL(string: "https://test.invalid")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
            return (stream, http)
        case .errorBody(let status, let body):
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                continuation.yield(body)
                continuation.finish()
            }
            let http = HTTPURLResponse(url: request.url ?? URL(string: "https://test.invalid")!,
                                       statusCode: status,
                                       httpVersion: nil,
                                       headerFields: nil)!
            return (stream, http)
        }
    }
}

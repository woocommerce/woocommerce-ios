import Foundation
import CocoaLumberjackSwift
import NetworkingCore

public struct AIApiProxyChatService: AIChatService {

    public typealias Sleep = @Sendable (UInt64) async throws -> Void

    private let endpoint: URL
    private let tokenProvider: WPCOMTokenProviding
    private let streamingTransport: StreamingHTTPTransport
    private let sleep: Sleep

    public init(tokenProvider: WPCOMTokenProviding,
                endpointOverride: URL? = nil,
                sleep: @escaping Sleep = { try await Task.sleep(nanoseconds: $0) }) {
        self.init(tokenProvider: tokenProvider,
                  endpoint: endpointOverride,
                  streamingTransport: nil,
                  sleep: sleep)
    }

    init(tokenProvider: WPCOMTokenProviding,
         endpoint: URL? = nil,
         streamingTransport: StreamingHTTPTransport? = nil,
         sleep: @escaping Sleep) {
        self.tokenProvider = tokenProvider
        self.endpoint = endpoint ?? Self.defaultEndpoint()
        self.streamingTransport = streamingTransport ?? AIChatTransport().stream
        self.sleep = sleep
    }

    private static let endpointPath = "wpcom/v2/woo-mobile-ai/chat/completions"

    // Compose against `Settings.wordpressApiBaseURL` so launch-arg overrides
    // (`mocked-wpcom-api`, `wpcom-api-base-url=...`) reroute the chat traffic too.
    private static func defaultEndpoint() -> URL {
        if let base = URL(string: Settings.wordpressApiBaseURL),
           let composed = URL(string: endpointPath, relativeTo: base)?.absoluteURL {
            return composed
        }
        DDLogError("⛔️ Settings.wordpressApiBaseURL malformed: \(Settings.wordpressApiBaseURL); falling back.")
        return URL(string: "https://public-api.wordpress.com/\(endpointPath)") ?? URL(fileURLWithPath: "/")
    }

    public func streamTurn(messages: [OpenAIChat.Message],
                           tools: [OpenAIChat.ToolDefinition]?,
                           toolChoice: OpenAIChat.ToolChoice?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.runWithRateLimitRetry(messages: messages,
                                                         tools: tools,
                                                         toolChoice: toolChoice,
                                                         continuation: continuation)
                    continuation.finish()
                } catch let envelope as WrappedEnvelopeError {
                    continuation.finish(throwing: envelope.assistantError)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func runWithRateLimitRetry(messages: [OpenAIChat.Message],
                                       tools: [OpenAIChat.ToolDefinition]?,
                                       toolChoice: OpenAIChat.ToolChoice?,
                                       continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation) async throws {
        var attempt = 0
        while true {
            let bridge = StreamBridge()
            do {
                try await sendStreaming(messages: messages,
                                        tools: tools,
                                        toolChoice: toolChoice,
                                        bridge: bridge,
                                        continuation: continuation)
                return
            } catch let error as AssistantError {
                if await shouldRetryRateLimit(error: error, bridge: bridge, attempt: attempt) {
                    try await backOff(attempt: attempt)
                    attempt += 1
                    continue
                }
                throw error
            } catch let wrapped as WrappedEnvelopeError {
                // A rate limit can also arrive as an HTTP-200 SSE error envelope, not just a real 429.
                if await shouldRetryRateLimit(error: wrapped.assistantError, bridge: bridge, attempt: attempt) {
                    try await backOff(attempt: attempt)
                    attempt += 1
                    continue
                }
                throw wrapped
            }
        }
    }

    private func backOff(attempt: Int) async throws {
        let delaySeconds: UInt64 = attempt == 0 ? 2 : 4
        try await sleep(delaySeconds * 1_000_000_000)
    }

    private func shouldRetryRateLimit(error: AssistantError, bridge: StreamBridge, attempt: Int) async -> Bool {
        guard attempt < 2 else { return false }
        guard await bridge.didEmitAnyEvent == false else { return false }
        return error.code == "429"
    }

    private func sendStreaming(messages: [OpenAIChat.Message],
                               tools: [OpenAIChat.ToolDefinition]?,
                               toolChoice: OpenAIChat.ToolChoice?,
                               bridge: StreamBridge,
                               continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation) async throws {
        let token = try await tokenProvider.token()
        let request = try buildRequest(messages: messages,
                                       tools: tools,
                                       toolChoice: toolChoice,
                                       token: token)
        let (byteStream, http) = try await streamingTransport(request)

        guard (200..<300).contains(http.statusCode) else {
            throw try await failedResponseError(status: http.statusCode, from: byteStream)
        }

        var parser = SSEParser()
        var state = StreamDecodeState()
        var utf8 = UTF8StreamDecoder()

        for try await rawChunk in byteStream {
            if let text = utf8.decode(rawChunk), !text.isEmpty {
                try await process(parser.feed(text), bridge: bridge, continuation: continuation, state: &state)
            }
        }
        if let tail = utf8.flush(), !tail.isEmpty {
            try await process(parser.feed(tail), bridge: bridge, continuation: continuation, state: &state)
        }
        try await process(parser.finish(), bridge: bridge, continuation: continuation, state: &state)

        for toolCall in state.completedToolCalls() {
            await bridge.markEmitted()
            continuation.yield(.toolCall(toolCall))
        }

        // The wpcom streaming path closes upstream errors as HTTP 200 with zero SSE frames; a
        // framed-but-content-less turn is a legitimate empty turn the orchestrator handles.
        guard state.receivedAnyChunk else {
            throw AssistantError(kind: .upstreamFailure, code: "200", message: Localization.emptyStream)
        }
        continuation.yield(.completed(state.finishReason))
    }

    private func failedResponseError(status: Int, from byteStream: AsyncThrowingStream<Data, Error>) async throws -> AssistantError {
        var buffer = Data()
        for try await chunk in byteStream {
            buffer.append(chunk)
        }
        return errorFromFailedResponse(status: status, body: buffer)
    }

    private func process(_ events: [SSEParser.Event],
                         bridge: StreamBridge,
                         continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation,
                         state: inout StreamDecodeState) async throws {
        for event in events {
            try await handle(event: event, bridge: bridge, continuation: continuation, state: &state)
        }
    }

    private func handle(event: SSEParser.Event,
                        bridge: StreamBridge,
                        continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation,
                        state: inout StreamDecodeState) async throws {
        let trimmed = event.data.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed == "[DONE]" { return }
        guard let data = trimmed.data(using: .utf8) else { return }

        // Soft errors can ship as 200 + envelope; surface as a typed error before any event lands.
        if await bridge.didEmitAnyEvent == false, let envelope = decodeProxyEnvelopeError(from: data) {
            throw WrappedEnvelopeError(assistantError: envelope)
        }

        let chunk: OpenAIChat.Chunk
        do {
            chunk = try JSONDecoder().decode(OpenAIChat.Chunk.self, from: data)
        } catch {
            DDLogError("⛔️ Malformed SSE chunk dropped: \(error.localizedDescription)")
            throw AssistantError(kind: .invalidStream, message: Localization.invalidStreamPayload)
        }

        for event in state.ingest(chunk) {
            if case .textDelta = event {
                await bridge.markEmitted()
            }
            continuation.yield(event)
        }
    }

    private func buildRequest(messages: [OpenAIChat.Message],
                              tools: [OpenAIChat.ToolDefinition]?,
                              toolChoice: OpenAIChat.ToolChoice?,
                              token: String) throws -> URLRequest {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let body = OpenAIChat.Request(messages: messages,
                                      tools: tools,
                                      toolChoice: toolChoice,
                                      model: AssistantConfiguration.chatModel,
                                      stream: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        urlRequest.httpBody = try encoder.encode(body)
        return urlRequest
    }

    private actor StreamBridge {
        private(set) var didEmitAnyEvent = false
        func markEmitted() { didEmitAnyEvent = true }
    }

    private struct WrappedEnvelopeError: Error {
        let assistantError: AssistantError
    }

    private struct ProxyError: Decodable {
        let code: String
        let message: String
        let data: ErrorData?

        struct ErrorData: Decodable {
            let status: Int?
            let reason: String?
        }
    }

    private struct StreamDecodeState {
        private var toolCallBuffers: [Int: ToolCallAssembly] = [:]
        private var toolCallOrder: [Int] = []
        private(set) var finishReason: OpenAIChat.FinishReason?
        private(set) var receivedAnyChunk = false

        mutating func ingest(_ chunk: OpenAIChat.Chunk) -> [ChatStreamEvent] {
            // Any decodable chunk (including finish-only and usage-only frames) proves the stream
            // wasn't the frameless wpcom-gap signature, distinct from emitting user-visible content.
            receivedAnyChunk = true
            guard let choice = chunk.choices.first else { return [] }

            var events: [ChatStreamEvent] = []
            if let text = choice.delta.content, !text.isEmpty {
                events.append(.textDelta(text))
            }
            if let deltaCalls = choice.delta.toolCalls {
                for delta in deltaCalls {
                    apply(delta)
                }
            }
            if let reason = choice.finishReason {
                finishReason = reason
            }
            return events
        }

        private mutating func apply(_ delta: OpenAIChat.ToolCallDelta) {
            var asm = toolCallBuffers[delta.index] ?? ToolCallAssembly()
            if asm.id == nil, let id = delta.id { asm.id = id }
            if asm.name == nil, let name = delta.function?.name { asm.name = name }
            if let args = delta.function?.arguments { asm.arguments.append(args) }
            toolCallBuffers[delta.index] = asm
            if !toolCallOrder.contains(delta.index) { toolCallOrder.append(delta.index) }
        }

        func completedToolCalls() -> [OpenAIChat.ToolCall] {
            var calls: [OpenAIChat.ToolCall] = []
            for index in toolCallOrder {
                guard let asm = toolCallBuffers[index], let id = asm.id, let name = asm.name else {
                    DDLogError("⛔️ Skipping tool call at index \(index): id or name absent.")
                    continue
                }
                calls.append(OpenAIChat.ToolCall(id: id, function: .init(name: name, arguments: asm.arguments)))
            }
            return calls
        }
    }

    private func errorFromFailedResponse(status: Int, body: Data) -> AssistantError {
        if let envelope = decodeProxyEnvelopeError(from: body) {
            return envelope
        }
        let fallback = String.localizedStringWithFormat(Localization.httpFailureFallback, status)
        return AssistantError(kind: HTTPStatusClassification.errorKind(forStatusCode: status),
                              code: String(status),
                              message: fallback)
    }

    private func decodeProxyEnvelopeError(from data: Data) -> AssistantError? {
        let envelope: ProxyError
        do {
            envelope = try JSONDecoder().decode(ProxyError.self, from: data)
        } catch {
            return nil
        }
        guard !envelope.code.isEmpty, !envelope.message.isEmpty else { return nil }
        return mapEnvelope(envelope)
    }

    // Route on `code`: `data.reason` is informational and not stable enough for branching.
    private func mapEnvelope(_ envelope: ProxyError) -> AssistantError {
        let httpStatus = envelope.data?.status
        let codeString = httpStatus.map(String.init) ?? envelope.code
        switch envelope.code {
        case "rest_unauthorized", "oauth2_invalid_token":
            return AssistantError(kind: .auth, code: codeString, message: Localization.unauthorized)
        case "rest_forbidden":
            return AssistantError(kind: .auth, code: codeString, message: envelope.message)
        case "woo_mobile_ai_user_rate_limit":
            // Server message distinguishes minute vs month; pass it through verbatim.
            return AssistantError(kind: .rateLimit, code: codeString, message: envelope.message)
        default:
            let kind = httpStatus.map(HTTPStatusClassification.errorKind(forStatusCode:)) ?? .upstreamFailure
            return AssistantError(kind: kind,
                                  code: codeString,
                                  message: "[\(envelope.code)] \(envelope.message)")
        }
    }
}

extension AIApiProxyChatService {
    enum Localization {
        static let httpFailureFallback = NSLocalizedString(
            "ai.assistant.networking.proxy.http_failure",
            value: "The assistant returned an error (HTTP %1$d).",
            comment: "Fallback shown when the proxy chat transport hits a non-2xx status without a structured error envelope. %1$d is the HTTP status code."
        )
        static let invalidStreamPayload = NSLocalizedString(
            "ai.assistant.networking.proxy.invalid_stream_payload",
            value: "The assistant returned an unexpected stream payload.",
            comment: "Surfaced when an SSE data frame from the proxy fails to decode as a chat chunk or known error envelope."
        )
        static let unauthorized = NSLocalizedString(
            "ai.assistant.networking.proxy.unauthorized",
            value: "WPCOM credentials missing or expired.",
            comment: "Surfaced when the AI proxy rejects the request with rest_unauthorized or oauth2_invalid_token."
        )
        static let emptyStream = NSLocalizedString(
            "ai.assistant.networking.proxy.empty_stream",
            value: "The AI service returned an empty response. Please try again.",
            comment: "Surfaced when the proxy closes a streaming response with HTTP 200 but no assistant text or tool calls."
        )
    }
}

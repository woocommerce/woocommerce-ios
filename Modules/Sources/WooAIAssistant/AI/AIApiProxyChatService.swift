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
                sleep: @escaping Sleep) {
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
        self.streamingTransport = streamingTransport ?? AIChatTransport.urlSessionStreamingTransport(AIChatTransport.sharedLLMSession)
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
                    let delaySeconds: UInt64 = attempt == 0 ? 2 : 4
                    try await sleep(delaySeconds * 1_000_000_000)
                    attempt += 1
                    continue
                }
                throw error
            }
        }
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

        if !(200..<300).contains(http.statusCode) {
            var buffer = Data()
            for try await chunk in byteStream {
                buffer.append(chunk)
            }
            throw Self.errorFromFailedResponse(status: http.statusCode, body: buffer)
        }

        var parser = SSEParser()
        var toolCallBuffers: [Int: ToolCallAssembly] = [:]
        var toolCallOrder: [Int] = []
        var finishReason: OpenAIChat.FinishReason?
        var pendingBytes = Data()

        for try await rawChunk in byteStream {
            pendingBytes.append(rawChunk)
            let (decoded, remainder) = decodeUTF8WithBoundaryCarry(pendingBytes)
            pendingBytes = remainder
            guard let text = decoded, !text.isEmpty else { continue }
            for event in parser.feed(text) {
                try await handle(event: event,
                                 bridge: bridge,
                                 continuation: continuation,
                                 buffers: &toolCallBuffers,
                                 order: &toolCallOrder,
                                 finishReason: &finishReason)
            }
        }
        if !pendingBytes.isEmpty,
           let tail = String(data: pendingBytes, encoding: .utf8),
           !tail.isEmpty {
            for event in parser.feed(tail) {
                try await handle(event: event,
                                 bridge: bridge,
                                 continuation: continuation,
                                 buffers: &toolCallBuffers,
                                 order: &toolCallOrder,
                                 finishReason: &finishReason)
            }
        }
        for event in parser.finish() {
            try await handle(event: event,
                             bridge: bridge,
                             continuation: continuation,
                             buffers: &toolCallBuffers,
                             order: &toolCallOrder,
                             finishReason: &finishReason)
        }

        for index in toolCallOrder {
            guard let asm = toolCallBuffers[index], let id = asm.id, let name = asm.name else {
                DDLogError("⛔️ Skipping tool call at index \(index): id or name absent.")
                continue
            }
            await bridge.markEmitted()
            continuation.yield(.toolCall(OpenAIChat.ToolCall(id: id,
                                                             function: .init(name: name,
                                                                             arguments: asm.arguments))))
        }
        continuation.yield(.completed(finishReason))
    }

    private func handle(event: SSEParser.Event,
                        bridge: StreamBridge,
                        continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation,
                        buffers: inout [Int: ToolCallAssembly],
                        order: inout [Int],
                        finishReason: inout OpenAIChat.FinishReason?) async throws {
        let trimmed = event.data.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed == "[DONE]" { return }
        guard let data = trimmed.data(using: .utf8) else { return }

        // Soft errors can ship as 200 + envelope; surface as a typed error before any event lands.
        if await bridge.didEmitAnyEvent == false, let envelope = Self.decodeProxyEnvelopeError(from: data) {
            throw WrappedEnvelopeError(assistantError: envelope)
        }

        let chunk: OpenAIChat.Chunk
        do {
            chunk = try JSONDecoder().decode(OpenAIChat.Chunk.self, from: data)
        } catch {
            DDLogError("⛔️ Malformed SSE chunk dropped: \(error.localizedDescription)")
            throw AssistantError(kind: .invalidStream, message: Localization.invalidStreamPayload)
        }
        guard let choice = chunk.choices.first else { return }

        if let text = choice.delta.content, !text.isEmpty {
            await bridge.markEmitted()
            continuation.yield(.textDelta(text))
        }
        if let deltaCalls = choice.delta.toolCalls {
            for delta in deltaCalls {
                applyToolCallDelta(delta, to: &buffers, order: &order)
            }
        }
        if let reason = choice.finishReason {
            finishReason = reason
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

        // include_usage adds a trailing SSE chunk with prompt-cache + token counts so
        // the wpcom proxy can populate per-feature openai-tokens MC stats.
        let body = OpenAIChat.Request(messages: messages,
                                      tools: tools,
                                      toolChoice: toolChoice,
                                      model: AssistantConfiguration.chatModel,
                                      stream: true,
                                      streamOptions: .init(includeUsage: true))
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

    static func errorFromFailedResponse(status: Int, body: Data) -> AssistantError {
        if let envelope = decodeProxyEnvelopeError(from: body) {
            return envelope
        }
        let fallback = String.localizedStringWithFormat(Localization.httpFailureFallback, status)
        return AssistantError(kind: HTTPStatusClassification.errorKind(forStatusCode: status),
                              code: String(status),
                              message: fallback)
    }

    static func decodeProxyEnvelopeError(from data: Data) -> AssistantError? {
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
    private static func mapEnvelope(_ envelope: ProxyError) -> AssistantError {
        let httpStatus = envelope.data?.status
        let codeString = httpStatus.map(String.init) ?? envelope.code
        switch envelope.code {
        case "rest_unauthorized":
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

public func makeAIApiProxyChatService(tokenProvider: WPCOMTokenProviding,
                                       endpointOverride: URL? = nil,
                                       sleep: @escaping AIApiProxyChatService.Sleep) -> some AIChatService {
    AIApiProxyChatService(tokenProvider: tokenProvider,
                          endpointOverride: endpointOverride,
                          sleep: sleep)
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
            comment: "Surfaced when the AI proxy rejects the request with rest_unauthorized."
        )
    }
}

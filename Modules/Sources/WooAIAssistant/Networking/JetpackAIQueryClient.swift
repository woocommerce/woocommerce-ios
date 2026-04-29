import Foundation
import NetworkingCore

typealias StreamingHTTPTransport = @Sendable (URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, HTTPURLResponse)

struct JetpackAIQueryClient: AIChatService {

    typealias Sleep = @Sendable (UInt64) async throws -> Void

    private let endpoint: URL
    private let jwtProvider: AssistantJWTProviding
    private let streamingTransport: StreamingHTTPTransport
    private let sleep: Sleep

    init(jwtProvider: AssistantJWTProviding,
         endpoint: URL = URL(string: Settings.wordpressApiBaseURL + "wpcom/v2/jetpack-ai-query")!,
         streamingTransport: StreamingHTTPTransport? = nil,
         sleep: Sleep? = nil) {
        self.jwtProvider = jwtProvider
        self.endpoint = endpoint
        self.streamingTransport = streamingTransport ?? Self.urlSessionStreamingTransport(Self.sharedLLMSession)
        self.sleep = sleep ?? { nanoseconds in try await Task.sleep(nanoseconds: nanoseconds) }
    }

    // httpMaximumConnectionsPerHost overrides URLSession.shared's 6-conn cap.
    private static let sharedLLMSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 64
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    private static func urlSessionStreamingTransport(_ session: URLSession) -> StreamingHTTPTransport {
        return { request in
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AssistantError(kind: .network, message: "Non-HTTP response.")
            }
            // Cancelling only the wrapping Swift Task leaves the URL loader holding the
            // socket; an idle SSE connection never produces a cancellation through the
            // byte iterator. Cancel the URL task too.
            let urlSessionTask = bytes.task
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                let task = Task {
                    var buffer = Data()
                    do {
                        for try await byte in bytes {
                            buffer.append(byte)
                            if buffer.count >= 4096 {
                                continuation.yield(buffer)
                                buffer.removeAll(keepingCapacity: true)
                            }
                        }
                        if !buffer.isEmpty {
                            continuation.yield(buffer)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { _ in
                    task.cancel()
                    urlSessionTask.cancel()
                }
            }
            return (stream, http)
        }
    }

    func streamTurn(messages: [OpenAIChat.Message],
                    tools: [OpenAIChat.ToolDefinition]?,
                    toolChoice: OpenAIChat.ToolChoice?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.runWithAuthRetry(messages: messages,
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

    // 401 before any event lands → invalidate JWT + retry once. Replaying after an event
    // crosses the seam would emit a duplicate prefix or a torn tool call. Android applies
    // the same gate for 401 only; 403 is treated as terminal.
    private func runWithAuthRetry(messages: [OpenAIChat.Message],
                                  tools: [OpenAIChat.ToolDefinition]?,
                                  toolChoice: OpenAIChat.ToolChoice?,
                                  continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation) async throws {
        var authAttempt = 0
        while true {
            let bridge = StreamBridge()
            do {
                try await runWithRateLimitRetry(messages: messages,
                                                tools: tools,
                                                toolChoice: toolChoice,
                                                bridge: bridge,
                                                continuation: continuation)
                return
            } catch let error as AssistantError {
                if await shouldRetryAuth(error: error, bridge: bridge, attempt: authAttempt) {
                    authAttempt += 1
                    await jwtProvider.invalidate()
                    continue
                }
                throw error
            }
        }
    }

    private func shouldRetryAuth(error: AssistantError, bridge: StreamBridge, attempt: Int) async -> Bool {
        guard attempt == 0 else { return false }
        guard await bridge.didEmitAnyEvent == false else { return false }
        return error.code == "401"
    }

    // 429 retries (3 attempts, 2s + 4s) only run before any event crosses the seam.
    private func runWithRateLimitRetry(messages: [OpenAIChat.Message],
                                       tools: [OpenAIChat.ToolDefinition]?,
                                       toolChoice: OpenAIChat.ToolChoice?,
                                       bridge: StreamBridge,
                                       continuation: AsyncThrowingStream<ChatStreamEvent, Error>.Continuation) async throws {
        var attempt = 0
        while true {
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
        let jwt = try await jwtProvider.currentJWT()
        let request = try buildRequest(messages: messages,
                                       tools: tools,
                                       toolChoice: toolChoice,
                                       jwt: jwt)
        let (byteStream, http) = try await streamingTransport(request)

        // jetpack-ai-query validates before opening the stream, so a non-2xx body is
        // a single JSON error payload (the proxy uses the same wrapped shape for HTTP
        // failures and soft failures). The HTTP status drives retry classification;
        // the envelope's text just enriches the message for the consumer.
        if !(200..<300).contains(http.statusCode) {
            var buffer = Data()
            for try await chunk in byteStream {
                buffer.append(chunk)
            }
            let reason = Self.envelopeReason(from: buffer) ?? "jetpack-ai-query returned HTTP \(http.statusCode)."
            throw AssistantError(kind: HTTPStatusClassification.errorKind(forStatusCode: http.statusCode),
                                 code: String(http.statusCode),
                                 message: reason)
        }

        var parser = SSEParser()
        var toolCallBuffers: [Int: ToolCallAssembly] = [:]
        var toolCallOrder: [Int] = []
        var finishReason: OpenAIChat.FinishReason?
        // Multi-byte UTF-8 chars that straddle a chunk boundary fail `String(data:encoding:)`
        // and the chunk would be dropped wholesale. Carry up to 3 trailing bytes forward.
        var pendingBytes = Data()

        for try await rawChunk in byteStream {
            pendingBytes.append(rawChunk)
            let (decoded, remainder) = Self.decodeUTF8WithBoundaryCarry(pendingBytes)
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
            _ = parser.feed(tail)
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
            guard let asm = toolCallBuffers[index], let id = asm.id, let name = asm.name else { continue }
            await bridge.markEmitted()
            continuation.yield(.toolCall(OpenAIChat.ToolCall(id: id,
                                                             function: .init(name: name,
                                                                             arguments: asm.arguments))))
        }
        await bridge.markEmitted()
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

        // Some soft errors come back as 200 + a wrapped envelope (no `choices`). Surface
        // as a typed error as long as nothing has crossed the seam yet.
        if await bridge.didEmitAnyEvent == false, let envelope = Self.decodeWrappedError(from: data) {
            throw WrappedEnvelopeError(assistantError: envelope)
        }

        guard let chunk = try? JSONDecoder().decode(OpenAIChat.Chunk.self, from: data) else { return }
        guard let choice = chunk.choices.first else { return }

        if let text = choice.delta.content, !text.isEmpty {
            await bridge.markEmitted()
            continuation.yield(.textDelta(text))
        }
        if let deltaCalls = choice.delta.toolCalls {
            for delta in deltaCalls {
                apply(delta: delta, to: &buffers, order: &order)
            }
        }
        if let reason = choice.finishReason {
            finishReason = reason
        }
    }

    private func buildRequest(messages: [OpenAIChat.Message],
                              tools: [OpenAIChat.ToolDefinition]?,
                              toolChoice: OpenAIChat.ToolChoice?,
                              jwt: String) throws -> URLRequest {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let body = OpenAIChat.Request(messages: messages,
                                      tools: tools,
                                      toolChoice: toolChoice,
                                      model: AssistantConfiguration.chatModel,
                                      stream: true,
                                      feature: AssistantConfiguration.featureName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        urlRequest.httpBody = try encoder.encode(body)
        return urlRequest
    }

    private struct ToolCallAssembly {
        var id: String?
        var name: String?
        var arguments: String = ""
    }

    private actor StreamBridge {
        private(set) var didEmitAnyEvent = false
        func markEmitted() { didEmitAnyEvent = true }
    }

    // Source-tagging wrapper: envelope-derived AssistantErrors travel inside this so the
    // HTTP retry guards (which key on `error.code`) skip them. `streamTurn` unwraps it
    // before yielding the inner AssistantError to the consumer.
    private struct WrappedEnvelopeError: Error {
        let assistantError: AssistantError
    }

    static func decodeUTF8WithBoundaryCarry(_ buffer: Data) -> (decoded: String?, remainder: Data) {
        if let full = String(data: buffer, encoding: .utf8) {
            return (full, Data())
        }
        for backoff in 1...min(3, buffer.count) {
            let split = buffer.count - backoff
            let prefix = buffer.prefix(split)
            if let decoded = String(data: prefix, encoding: .utf8) {
                return (decoded, buffer.suffix(from: split))
            }
        }
        return (nil, buffer)
    }

    private func apply(delta: OpenAIChat.ToolCallDelta,
                       to buffers: inout [Int: ToolCallAssembly],
                       order: inout [Int]) {
        var asm = buffers[delta.index] ?? ToolCallAssembly()
        if asm.id == nil, let id = delta.id { asm.id = id }
        if asm.name == nil, let name = delta.function?.name { asm.name = name }
        if let args = delta.function?.arguments { asm.arguments.append(args) }
        buffers[delta.index] = asm
        if !order.contains(delta.index) { order.append(delta.index) }
    }

    private struct WrappedError: Decodable {
        let code: String
        let message: String
        let data: ErrorData?

        struct ErrorData: Decodable {
            let status: Int?
        }
    }

    static func decodeWrappedError(from data: Data) -> AssistantError? {
        guard let envelope = decodeEnvelope(from: data) else { return nil }
        let httpStatus = envelope.data?.status
        let codeString = httpStatus.map(String.init)
        let kind = httpStatus.map(HTTPStatusClassification.errorKind(forStatusCode:)) ?? .upstreamFailure
        return AssistantError(kind: kind,
                              code: codeString,
                              message: "[\(envelope.code)] \(envelope.message)")
    }

    static func envelopeReason(from data: Data) -> String? {
        decodeEnvelope(from: data).map { "[\($0.code)] \($0.message)" }
    }

    private static func decodeEnvelope(from data: Data) -> WrappedError? {
        let envelope: WrappedError
        do {
            envelope = try JSONDecoder().decode(WrappedError.self, from: data)
        } catch {
            return nil
        }
        guard !envelope.code.isEmpty, !envelope.message.isEmpty else { return nil }
        return envelope
    }
}

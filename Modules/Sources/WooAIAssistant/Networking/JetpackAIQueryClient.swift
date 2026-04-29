import Foundation

typealias StreamingHTTPTransport = @Sendable (URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, HTTPURLResponse)

struct JetpackAIQueryClient: AIChatService {

    typealias Sleep = @Sendable (UInt64) async throws -> Void

    private let endpoint: URL
    private let jwtProvider: AssistantJWTProviding
    private let streamingTransport: StreamingHTTPTransport
    private let sleep: Sleep

    init(jwtProvider: AssistantJWTProviding,
         endpoint: URL = URL(string: "https://public-api.wordpress.com/wpcom/v2/jetpack-ai-query")!,
         streamingTransport: StreamingHTTPTransport? = nil,
         sleep: Sleep? = nil) {
        self.jwtProvider = jwtProvider
        self.endpoint = endpoint
        self.streamingTransport = streamingTransport ?? Self.urlSessionStreamingTransport(Self.sharedLLMSession)
        self.sleep = sleep ?? { nanoseconds in try await Task.sleep(nanoseconds: nanoseconds) }
    }

    // 64 conns/host (URLSession.shared caps at 6) + long timeouts cover the
    // long tail of model thinking before any byte is delivered.
    private static let sharedLLMSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 64
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    static func urlSessionStreamingTransport(_ session: URLSession) -> StreamingHTTPTransport {
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
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // 401/403 before any event lands → invalidate JWT + retry once. Once an event
    // crosses the seam, retrying would emit a duplicate prefix or torn tool call.
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
        guard attempt < 1 else { return false }
        guard await bridge.didEmitAnyEvent == false else { return false }
        guard let code = error.code, code == "401" || code == "403" else { return false }
        return true
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
        // a single JSON error payload, not SSE frames.
        if !(200..<300).contains(http.statusCode) {
            var buffer = Data()
            for try await chunk in byteStream {
                buffer.append(chunk)
            }
            try Self.validate(http: http, body: buffer)
            if let envelope = Self.decodeWrappedError(from: buffer) {
                throw envelope
            }
            throw AssistantError(kind: Self.errorKind(forStatus: http.statusCode),
                                 code: String(http.statusCode),
                                 message: "jetpack-ai-query returned HTTP \(http.statusCode).")
        }

        var parser = SSEParser()
        var firstDecodedChunkSeen = false
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
            let events = parser.feed(text)
            for event in events {
                let trimmed = event.data.trimmingCharacters(in: .whitespaces)
                if trimmed == "[DONE]" { continue }
                guard let data = trimmed.data(using: .utf8) else { continue }

                // Some soft errors come back as 200 + a wrapped envelope (no `choices`).
                // Surface as a typed error before attempting the chunk decode.
                if !firstDecodedChunkSeen, let envelope = Self.decodeWrappedError(from: data) {
                    throw envelope
                }
                firstDecodedChunkSeen = true

                guard let chunk = try? JSONDecoder().decode(OpenAIChat.Chunk.self, from: data) else { continue }
                guard let choice = chunk.choices.first else { continue }

                if let text = choice.delta.content, !text.isEmpty {
                    await bridge.markEmitted()
                    continuation.yield(.textDelta(text))
                }
                if let deltaCalls = choice.delta.toolCalls {
                    for delta in deltaCalls {
                        apply(delta: delta, to: &toolCallBuffers, order: &toolCallOrder)
                    }
                }
                if let reason = choice.finishReason {
                    finishReason = reason
                }
            }
        }
        if !pendingBytes.isEmpty,
           let tail = String(data: pendingBytes, encoding: .utf8),
           !tail.isEmpty {
            _ = parser.feed(tail)
        }
        for event in parser.finish() {
            let trimmed = event.data.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed == "[DONE]" { continue }
            if let data = trimmed.data(using: .utf8),
               let chunk = try? JSONDecoder().decode(OpenAIChat.Chunk.self, from: data),
               let choice = chunk.choices.first {
                if let text = choice.delta.content, !text.isEmpty {
                    await bridge.markEmitted()
                    continuation.yield(.textDelta(text))
                }
                if let deltaCalls = choice.delta.toolCalls {
                    for delta in deltaCalls {
                        apply(delta: delta, to: &toolCallBuffers, order: &toolCallOrder)
                    }
                }
                if let reason = choice.finishReason {
                    finishReason = reason
                }
            }
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

    private func buildRequest(messages: [OpenAIChat.Message],
                              tools: [OpenAIChat.ToolDefinition]?,
                              toolChoice: OpenAIChat.ToolChoice?,
                              jwt: String) throws -> URLRequest {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")

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
        var type: String?
        var name: String?
        var arguments: String = ""
    }

    private actor StreamBridge {
        private(set) var didEmitAnyEvent = false
        func markEmitted() { didEmitAnyEvent = true }
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
        if asm.type == nil, let type = delta.type { asm.type = type }
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

    // jetpack-ai-query wraps soft failures (context overflow, moderation, schema
    // rejection) as `{code, message, data:{status}}` over HTTP 200. Both fields
    // must be populated so a successful chat response (no top-level `code`)
    // doesn't get misclassified.
    static func decodeWrappedError(from data: Data) -> AssistantError? {
        let envelope: WrappedError
        do {
            envelope = try JSONDecoder().decode(WrappedError.self, from: data)
        } catch {
            return nil
        }
        guard !envelope.code.isEmpty, !envelope.message.isEmpty else {
            return nil
        }
        let httpStatus = envelope.data?.status
        let codeString = httpStatus.map(String.init)
        let kind = httpStatus.map(errorKind(forStatus:)) ?? .upstreamFailure
        return AssistantError(kind: kind,
                              code: codeString,
                              message: "[\(envelope.code)] \(envelope.message)")
    }

    static func validate(http: HTTPURLResponse, body: Data) throws {
        if http.statusCode == 401 || http.statusCode == 403 {
            throw AssistantError(kind: .auth,
                                 code: String(http.statusCode),
                                 message: "Authentication to jetpack-ai-query failed (HTTP \(http.statusCode)).")
        }
        if http.statusCode == 429 {
            throw AssistantError(kind: .rateLimit,
                                 code: "429",
                                 message: "Rate-limited by jetpack-ai-query. Please try again shortly.")
        }
        if !(200..<300).contains(http.statusCode) {
            let snippet = String(data: body.prefix(300), encoding: .utf8) ?? ""
            throw AssistantError(kind: errorKind(forStatus: http.statusCode),
                                 code: String(http.statusCode),
                                 message: "jetpack-ai-query returned HTTP \(http.statusCode): \(snippet)")
        }
    }

    private static func errorKind(forStatus status: Int) -> AssistantErrorKind {
        switch status {
        case 401, 403: return .auth
        case 429: return .rateLimit
        case 408: return .timeout
        case 400..<500: return .upstreamFailure
        case 500..<600: return .upstreamFailure
        default: return .unknown
        }
    }
}

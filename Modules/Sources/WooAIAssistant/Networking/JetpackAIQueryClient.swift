import Foundation

/// Streaming HTTP transport. Returns a byte stream alongside the status response
/// so the caller can parse SSE frames incrementally on 2xx, or drain the (small)
/// JSON error body on non-2xx. Production uses URLSession; tests pass a closure
/// that records the request and returns canned bytes.
typealias StreamingHTTPTransport = @Sendable (URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, HTTPURLResponse)

/// Calls `POST /wpcom/v2/jetpack-ai-query` with an OpenAI-shape body.
///
/// Auth: `Authorization: Bearer <Jetpack AI JWT>`. The JWT is minted per
/// site by `AssistantJWTProviding` and rotated on expiry; this client just
/// asks for one before each call and asks the provider to invalidate when
/// the upstream rejects it.
///
/// Streaming-only: the `feature` / `model` / `stream=true` parameters are
/// pinned at construction from `AssistantConfiguration` so callers can't
/// accidentally drift the wire shape per call.
struct JetpackAIQueryClient: AIChatService {

    /// Sleep hook so the 429-backoff branch is testable without `Task.sleep`
    /// burning real wall-clock seconds. Production uses `Task.sleep(nanoseconds:)`.
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

    /// One URLSession per process for all LLM calls. Dedicated so we can raise the
    /// per-host connection cap (URLSession.shared caps at 6/host) without affecting
    /// other Networking-module call paths. 64 matches what URLSession itself uses
    /// on iOS when explicitly raised; 120s/180s timeouts cover the long tail of
    /// model thinking before any byte is delivered.
    private static let sharedLLMSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 64
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    /// Streaming transport backed by URLSession's AsyncBytes. Yields 4 KB `Data`
    /// chunks so the SSE parser can drain frames as soon as they arrive.
    static func urlSessionStreamingTransport(_ session: URLSession) -> StreamingHTTPTransport {
        return { request in
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AssistantError(kind: .network, message: "Non-HTTP response.")
            }
            // Cancelling just the wrapping Swift Task isn't enough - URLSession keeps the
            // socket open waiting for data, and an idle SSE connection never produces a
            // cancellation error through `for try await byte in bytes`. Cancel the URL
            // task too so the socket closes and resources release.
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

    /// Outer envelope. Wraps the inner streaming call so a 401/403 error received before
    /// any chunk is yielded triggers exactly one JWT-invalidate-and-retry. After the first
    /// `ChatStreamEvent` is delivered to the consumer we never retry - that would emit a
    /// duplicate prefix or a torn tool call. The 429 backoff lives one layer in
    /// (`runWithRateLimitRetry`) so the two retries nest cleanly.
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

    /// Inner envelope. 429 retries (3 attempts, 2s + 4s backoff) only run before any event
    /// has been yielded - once the consumer has seen a delta we cannot replay safely. The
    /// rate-limit ceiling exists because jetpack-ai-query throttles aggressively under
    /// parallel smoke load and a brief wait usually clears it.
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

        // Non-2xx: jetpack-ai-query validates BEFORE opening the stream, so the body is
        // a single JSON error payload (no SSE frames). Drain it fully and run through
        // the standard validate + wrapped-envelope decoder.
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
        // and the entire chunk is dropped, manifesting as "the assistant skips characters"
        // on emoji / non-ASCII content. Carry up to 3 trailing bytes forward.
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

                // Some soft errors come back as HTTP 200 with a wrapped JSON envelope that
                // looks NOTHING like an SSE chunk (no `choices` field). Surface as typed
                // error before we waste a JSON decode against the chunk shape.
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
        // Flush any trailing event the buffer held onto. If the stream cut mid-multibyte
        // we just drop the partial tail (no valid codepoint to emit).
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

    /// Accumulator for streaming tool-call fragments. OpenAI streams the skeleton
    /// (`id` / `type` / `function.name`) in the first delta and the arguments as
    /// string chunks across subsequent deltas, keyed by `tool_calls[<index>]`.
    private struct ToolCallAssembly {
        var id: String?
        var type: String?
        var name: String?
        var arguments: String = ""
    }

    /// Tracks whether the consumer has observed any event, so retry envelopes
    /// can short-circuit once a partial response has crossed the seam.
    private actor StreamBridge {
        private(set) var didEmitAnyEvent = false
        func markEmitted() { didEmitAnyEvent = true }
    }

    /// Try to decode `buffer` as UTF-8 in one shot. If that fails, back off by up
    /// to 3 bytes (max length of a UTF-8 sequence minus 1) searching for a valid
    /// prefix - those last bytes are the start of a codepoint that'll complete on
    /// the next network chunk.
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

    /// Wrapped-error envelope returned by jetpack-ai-query for soft failures
    /// (context overflow, moderation, downstream JSON-schema rejection). HTTP
    /// status is usually 200 - the real error lives in the body.
    private struct WrappedError: Decodable {
        let code: String
        let message: String
        let data: ErrorData?

        struct ErrorData: Decodable {
            let status: Int?
        }
    }

    /// Returns an `AssistantError` if the body decodes as a wrapped error envelope.
    /// Returns nil when both `code` and `message` are not populated, which keeps
    /// successful chat-completion responses (no top-level `code`) from being
    /// misclassified.
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

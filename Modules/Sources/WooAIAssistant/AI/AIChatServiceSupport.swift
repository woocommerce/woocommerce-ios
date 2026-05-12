import Foundation
import NetworkingCore

/// Shared transport, UTF-8 boundary carry, and tool-call assembly for both chat clients.

typealias StreamingHTTPTransport = @Sendable (URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, HTTPURLResponse)

public enum AIChatTransport {

    /// Shared retry-backoff sleep used by both `AIApiProxyChatService` and the app-target adaptor.
    public static let defaultRetrySleep: @Sendable (UInt64) async throws -> Void = { nanoseconds in
        try await Task.sleep(nanoseconds: nanoseconds)
    }

    static let sharedLLMSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 64
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    static func urlSessionStreamingTransport(_ session: URLSession) -> StreamingHTTPTransport {
        return { request in
            let bytes: URLSession.AsyncBytes
            let response: URLResponse
            do {
                (bytes, response) = try await session.bytes(for: request)
            } catch let urlError as URLError {
                throw mapURLError(urlError)
            }
            guard let http = response as? HTTPURLResponse else {
                throw AssistantError(kind: .network,
                                     message: AIChatTransport.nonHTTPResponseMessage)
            }
            // Cancelling only the Swift Task leaves the URL loader holding the socket;
            // an idle SSE connection never throws via the byte iterator.
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
                    } catch let urlError as URLError {
                        continuation.finish(throwing: mapURLError(urlError))
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

    static func mapURLError(_ error: URLError) -> AssistantError {
        let kind: AssistantErrorKind
        switch error.code {
        case .timedOut:
            kind = .timeout
        case .cancelled:
            kind = .cancelled
        default:
            // Catch-all to .network mirrors Android's IOException -> NETWORK mapping; the orchestrator
            // would otherwise collapse these to .unknown via the AssistantError-typed catch only.
            kind = .network
        }
        return AssistantError(kind: kind,
                              code: String(error.code.rawValue),
                              message: error.localizedDescription)
    }

    private static let nonHTTPResponseMessage = NSLocalizedString(
        "ai.assistant.networking.shared.non_http_response",
        value: "The assistant returned an unexpected response.",
        comment: "Surfaced when the chat transport receives a non-HTTP URLResponse from the WPCOM proxy."
    )
}

// Carry up to 3 trailing bytes when a multi-byte UTF-8 char straddles a chunk;
// otherwise `String(data:encoding:)` drops the whole chunk.
func decodeUTF8WithBoundaryCarry(_ buffer: Data) -> (decoded: String?, remainder: Data) {
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

struct ToolCallAssembly {
    var id: String?
    var name: String?
    var arguments: String = ""
}

func applyToolCallDelta(_ delta: OpenAIChat.ToolCallDelta,
                        to buffers: inout [Int: ToolCallAssembly],
                        order: inout [Int]) {
    var asm = buffers[delta.index] ?? ToolCallAssembly()
    if asm.id == nil, let id = delta.id { asm.id = id }
    if asm.name == nil, let name = delta.function?.name { asm.name = name }
    if let args = delta.function?.arguments { asm.arguments.append(args) }
    buffers[delta.index] = asm
    if !order.contains(delta.index) { order.append(delta.index) }
}

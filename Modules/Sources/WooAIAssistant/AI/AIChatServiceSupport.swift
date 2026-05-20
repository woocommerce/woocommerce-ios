import Foundation
import NetworkingCore

/// Shared transport, UTF-8 boundary carry, and tool-call assembly for both chat clients.

typealias StreamingHTTPTransport = @Sendable (URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, HTTPURLResponse)

public enum AIChatTransport {

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

struct UTF8StreamDecoder {
    private var pending = Data()

    /// Appends bytes and returns the longest decodable UTF-8 prefix, carrying any
    /// trailing partial multi-byte sequence (up to 3 bytes) to the next call.
    mutating func decode(_ data: Data) -> String? {
        pending.append(data)
        if let full = String(data: pending, encoding: .utf8) {
            pending = Data()
            return full
        }
        for backoff in 1...min(3, pending.count) {
            let split = pending.count - backoff
            let prefix = pending.prefix(split)
            if let decoded = String(data: prefix, encoding: .utf8) {
                pending = pending.suffix(from: split)
                return decoded
            }
        }
        return nil
    }

    /// Returns whatever remains once the stream ends (nil if the tail is an
    /// incomplete sequence).
    mutating func flush() -> String? {
        defer { pending = Data() }
        return String(data: pending, encoding: .utf8)
    }
}

struct ToolCallAssembly {
    var id: String?
    var name: String?
    var arguments: String = ""
}

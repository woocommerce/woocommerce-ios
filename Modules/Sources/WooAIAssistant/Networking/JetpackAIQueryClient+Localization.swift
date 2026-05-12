import Foundation

@available(*, deprecated)
extension JetpackAIQueryClient {
    enum Localization {
        static let httpFailureFallback = NSLocalizedString(
            "ai.assistant.networking.http_failure",
            value: "The assistant returned an error (HTTP %1$d).",
            comment: "Fallback shown when the chat transport hits a non-2xx status without a structured error envelope. %1$d is the HTTP status code."
        )
        static let invalidStreamPayload = NSLocalizedString(
            "ai.assistant.networking.invalid_stream_payload",
            value: "The assistant returned an unexpected stream payload.",
            comment: "Surfaced when an SSE data frame fails to decode as a chat chunk or known error envelope."
        )
    }
}

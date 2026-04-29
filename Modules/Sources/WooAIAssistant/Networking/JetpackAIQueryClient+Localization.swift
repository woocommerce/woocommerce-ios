import Foundation

extension JetpackAIQueryClient {
    enum Localization {
        static let nonHTTPResponse = NSLocalizedString(
            "ai.assistant.networking.non_http_response",
            value: "The assistant returned an unexpected response.",
            comment: "Surfaced when the chat transport receives a non-HTTP URLResponse from the WPCOM proxy."
        )
        static let httpFailureFallback = NSLocalizedString(
            "ai.assistant.networking.http_failure",
            value: "The assistant returned an error (HTTP %1$d).",
            comment: "Fallback shown when the chat transport hits a non-2xx status without a structured error envelope. %1$d is the HTTP status code."
        )
    }
}

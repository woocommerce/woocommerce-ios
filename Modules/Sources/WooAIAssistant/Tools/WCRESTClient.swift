import Foundation

/// Transport surface every REST tool calls into. Deliberately thin so the
/// production adaptor can sit on the existing Networking module (app password,
/// WPCOM bearer, Jetpack tunnel) and the headless harness can swap in a
/// `URLSession`-only implementation without dragging dependencies into the
/// assistant module.
///
/// Non-2xx responses are returned, not thrown, so retry policy and error
/// classification stay in one place rather than spread across `do/catch`.
public protocol WCRESTClient: Sendable {
    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?,
                 headers: [String: String]?) async -> WCRESTResponse
}

public struct WCRESTResponse: Sendable, Equatable {
    public let data: Data
    /// `0` is reserved for transport failures (no HTTP response: dropped
    /// connection, DNS, timeout) so executors and retry policy treat them
    /// like 5xx without a separate throwing path.
    public let statusCode: Int
    public let headers: [String: String]

    public init(data: Data, statusCode: Int, headers: [String: String] = [:]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
}

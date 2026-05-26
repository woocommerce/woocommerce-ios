import Foundation

/// Non-2xx responses return as `WCRESTResponse`, never throw.
public protocol WCRESTClient: Sendable {
    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse
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

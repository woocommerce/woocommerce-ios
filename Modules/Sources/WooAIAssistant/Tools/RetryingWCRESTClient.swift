import Foundation

public struct RetryingWCRESTClient: WCRESTClient {
    private let inner: WCRESTClient
    private let policy: RESTRetryPolicy
    private let sleep: @Sendable (TimeInterval) async -> Void

    public init(inner: WCRESTClient,
                policy: RESTRetryPolicy = .default,
                sleep: @escaping @Sendable (TimeInterval) async -> Void = Self.realSleep) {
        self.inner = inner
        self.policy = policy
        self.sleep = sleep
    }

    public func request(method: String,
                        path: String,
                        query: [String: String]?,
                        body: Data?,
                        headers: [String: String]?) async -> WCRESTResponse {
        var attempt = 0
        while true {
            let response = await inner.request(method: method,
                                               path: path,
                                               query: query,
                                               body: body,
                                               headers: headers)
            if HTTPStatusClassification.isSuccess(response.statusCode) {
                return response
            }
            guard policy.shouldRetry(method: method,
                                     statusCode: response.statusCode,
                                     attempt: attempt) else {
                return response
            }
            await sleep(policy.delay(forAttempt: attempt))
            attempt += 1
        }
    }

    public static let realSleep: @Sendable (TimeInterval) async -> Void = { interval in
        let nanoseconds = UInt64(max(0, interval) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}

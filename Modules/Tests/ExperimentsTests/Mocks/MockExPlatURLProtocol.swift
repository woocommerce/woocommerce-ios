import Foundation
import Synchronization

// Keep URLSession's background callback to reproduce the isolation crash.
final class MockExPlatURLProtocol: URLProtocol {
    static let requestCount = Mutex(0)

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "public-api.wordpress.com" && request.url?.path.contains("/experiments/") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requestCount.withLock { $0 += 1 }
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}

import Foundation

// Keep URLSession's background callback to reproduce the isolation crash.
final class MockExPlatURLProtocol: URLProtocol {
    static let requests = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "public-api.wordpress.com" && request.url?.path.contains("/experiments/") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requests.continuation.yield(())
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}

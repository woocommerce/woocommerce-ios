import Foundation

/// Test-only `URLProtocol` that stubs HTTP responses for the QR-login Remote
/// tests.
///
/// Each test sets up a stub keyed by URL absolute string (which the test
/// builds via the same URL-construction helpers the Remote uses), then runs
/// its `URLSession` request. The protocol intercepts the request before it
/// hits the network and produces the configured response: any status code,
/// any body, or a transport-style failure (`URLError`).
///
/// Distinct from the existing `MockURLProtocol` because we need:
///   - Raw `Data` bodies (some QR error responses are non-JSON, and we want
///     to assert behaviour for malformed bodies).
///   - Transport-failure simulation (the 4-strike polling threshold has to
///     be testable).
final class QRLoginStubURLProtocol: URLProtocol {

    /// Response the stub should serve for a request to `url`.
    enum Stub {
        case response(statusCode: Int, body: Data)
        case failure(URLError)
    }

    /// Test entry point. Register the stub *before* sending the request.
    static func stub(_ stub: Stub, for url: URL) {
        stubsByURL[url.absoluteString] = stub
    }

    /// Counts how many times each URL was requested (across all stubs).
    static func requestCount(for url: URL) -> Int {
        requestCountsByURL[url.absoluteString] ?? 0
    }

    /// Captures the HTTP body sent on the most recent request to `url`.
    static func capturedBody(for url: URL) -> Data? {
        capturedBodies[url.absoluteString]
    }

    /// Clears all configuration & captured state. Call at the start of every
    /// test to keep tests independent.
    static func reset() {
        stubsByURL.removeAll()
        requestCountsByURL.removeAll()
        capturedBodies.removeAll()
    }

    /// `URLSessionConfiguration.ephemeral` with this stub installed as the
    /// only protocol. Pass the resulting `URLSession` to the Remote under test.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [QRLoginStubURLProtocol.self]
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }

    // MARK: - URLProtocol overrides

    override class func canInit(with request: URLRequest) -> Bool {
        request.url.flatMap { stubsByURL[$0.absoluteString] != nil } ?? false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let stub = QRLoginStubURLProtocol.stubsByURL[url.absoluteString] else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        QRLoginStubURLProtocol.requestCountsByURL[url.absoluteString, default: 0] += 1
        QRLoginStubURLProtocol.capturedBodies[url.absoluteString] = bodyData(for: request)

        switch stub {
        case let .response(statusCode, body):
            let response = HTTPURLResponse(url: url,
                                           statusCode: statusCode,
                                           httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    // MARK: - State

    private static var stubsByURL: [String: Stub] = [:]
    private static var requestCountsByURL: [String: Int] = [:]
    private static var capturedBodies: [String: Data] = [:]

    /// `URLSession` strips httpBody from URLRequests for some upload methods
    /// before they reach the protocol. We fall back to `httpBodyStream` when
    /// `httpBody` is unset so tests that POST JSON can still assert the body.
    private func bodyData(for request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

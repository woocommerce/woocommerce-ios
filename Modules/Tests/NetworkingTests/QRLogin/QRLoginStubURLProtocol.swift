import Foundation

/// Test-only `URLProtocol` that stubs HTTP responses for the QR-login Remote
/// tests.
///
/// `canInit` always returns `true`, so a request made on a session built by
/// `makeSession()` can **never** escape to the real network — a missing stub
/// fails the request with a distinctive `URLError.resourceUnavailable` rather
/// than silently hitting a live server.
///
/// State is global (a `URLProtocol` is instantiated by `URLSession`, so
/// there's no per-instance injection point) but lock-guarded and **host-
/// scoped**: `reset(host:)` only clears entries for one host. Swift Testing
/// runs tests in parallel, so the two Remote test suites use disjoint hosts
/// (`shop.example` vs `public-api.wordpress.com`) and each is marked
/// `@Suite(.serialized)` — together that keeps the shared store collision-free.
final class QRLoginStubURLProtocol: URLProtocol {

    /// Response the stub should serve for a request to `url`.
    enum Stub {
        case response(statusCode: Int, body: Data)
        case failure(URLError)
    }

    /// Test entry point. Register the stub *before* sending the request.
    static func stub(_ stub: Stub, for url: URL) {
        lock.withLock { _ = stubsByURL.updateValue(stub, forKey: url.absoluteString) }
    }

    /// Counts how many times each URL was requested.
    static func requestCount(for url: URL) -> Int {
        lock.withLock { requestCountsByURL[url.absoluteString] ?? 0 }
    }

    /// Captures the HTTP body sent on the most recent request to `url`.
    static func capturedBody(for url: URL) -> Data? {
        lock.withLock { capturedBodies[url.absoluteString] }
    }

    /// Clears all stub state for a single host. Host-scoped so two parallel
    /// suites targeting different hosts never wipe each other.
    static func reset(host: String) {
        lock.withLock {
            stubsByURL = stubsByURL.filter { URL(string: $0.key)?.host != host }
            requestCountsByURL = requestCountsByURL.filter { URL(string: $0.key)?.host != host }
            capturedBodies = capturedBodies.filter { URL(string: $0.key)?.host != host }
        }
    }

    /// A `URLSession` with this stub installed as the only protocol. Pass the
    /// resulting session to the Remote under test.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [QRLoginStubURLProtocol.self]
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }

    // MARK: - URLProtocol overrides

    override class func canInit(with request: URLRequest) -> Bool {
        // Always intercept — a request on a stub session must never reach the
        // real network, even if its URL wasn't stubbed.
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let body = bodyData(for: request)
        let stub: Stub? = Self.lock.withLock {
            Self.requestCountsByURL[url.absoluteString, default: 0] += 1
            if let body {
                Self.capturedBodies[url.absoluteString] = body
            }
            return Self.stubsByURL[url.absoluteString]
        }

        guard let stub else {
            // No stub registered — fail loudly instead of escaping to the
            // network, so the test reports a clear "stub missing" error.
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }

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

    private static let lock = NSLock()
    private static var stubsByURL: [String: Stub] = [:]
    private static var requestCountsByURL: [String: Int] = [:]
    private static var capturedBodies: [String: Data] = [:]

    /// `URLSession` moves an upload request's body into `httpBodyStream`
    /// before it reaches the protocol, so we read the stream when `httpBody`
    /// is unset.
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

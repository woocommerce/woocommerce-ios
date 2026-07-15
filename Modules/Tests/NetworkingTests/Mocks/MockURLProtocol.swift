import Alamofire
import Networking
import XCTest

extension MockURLProtocol {
    /// Stores the mocks for `URLRequest`s in memory to be used in `MockURLProtocol`.
    final class Mocks {
        private static let lock = NSLock()
        private static var responsesByRequestURL: [String: (response: AnyCodable, statusCode: Int)] = [:]
        private static var recordedRequests: [URLRequest] = []
        private static var requestReceivedHandler: ((URLRequest) -> Void)?

        static var requests: [URLRequest] {
            lock.lock()
            defer { lock.unlock() }
            return recordedRequests
        }

        static func reset() {
            lock.lock()
            defer { lock.unlock() }
            responsesByRequestURL.removeAll()
            recordedRequests.removeAll()
            requestReceivedHandler = nil
        }

        /// Installs a hook invoked after a request is recorded and before its mocked response is delivered.
        static func whenRequestIsReceived(_ handler: @escaping (URLRequest) -> Void) {
            lock.lock()
            defer { lock.unlock() }
            requestReceivedHandler = handler
        }

        /// Mocks the response of a given request.
        static func mockResponse(_ response: AnyCodable, statusCode: Int, for request: URLRequest) {
            guard let url = request.url?.absoluteString else {
                return
            }
            lock.lock()
            defer { lock.unlock() }
            responsesByRequestURL[url] = (response: response, statusCode: statusCode)
        }

        /// Returns the response for a request if it has been mocked.
        static func response(for request: URLRequest) -> (response: Data?, statusCode: Int)? {
            guard let url = request.url?.absoluteString else {
                return nil
            }
            let result: (response: (response: AnyCodable, statusCode: Int)?, handler: ((URLRequest) -> Void)?) = {
                lock.lock()
                defer { lock.unlock() }
                recordedRequests.append(request)
                return (responsesByRequestURL[url], requestReceivedHandler)
            }()
            result.handler?(request)
            guard let response = result.response else { return nil }

            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(response.response)
                return (response: data, statusCode: response.statusCode)
            }
            catch {
                XCTFail("Couldn't convert response to Data: \(response)")
                return (response: nil, statusCode: response.statusCode)
            }
        }
    }
}

/// Allows mocking for the response of a `URLRequest` in Alamofire.
final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        guard let headers = request.allHTTPHeaderFields else { return request }
        do {
            return try URLEncoding.default.encode(request, with: headers)
        } catch {
            return request
        }
    }

    override func startLoading() {
        defer {
            client?.urlProtocolDidFinishLoading(self)
        }

        guard let url = request.url,
              let response = Mocks.response(for: request) else {
            return
        }

        guard let urlResponse = HTTPURLResponse(url: url, statusCode: response.statusCode, httpVersion: nil, headerFields: [:]) else {
            return
        }

        client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)

        client?.urlProtocol(self, didLoad: response.response ?? .init())
    }

    override func stopLoading() {}
}

import Alamofire
import Networking
import Synchronization
import XCTest

extension MockURLProtocol {
    /// Stores the mocks for `URLRequest`s in memory to be used in `MockURLProtocol`.
    ///
    /// Tests write the mocks on the test thread and `startLoading()` reads them on the URL loading
    /// thread, so the store is guarded by a lock.
    ///
    final class Mocks {
        private static let responsesByRequestURL = Mutex<[String: (response: AnyCodable, statusCode: Int)]>([:])

        /// Mocks the response of a given request.
        static func mockResponse(_ response: AnyCodable, statusCode: Int, for request: URLRequest) {
            guard let url = request.url?.absoluteString else {
                return
            }
            responsesByRequestURL.withLock { $0[url] = (response: response, statusCode: statusCode) }
        }

        /// Removes every mocked response. Call from `tearDown` so mocks do not leak between tests.
        static func reset() {
            responsesByRequestURL.withLock { $0.removeAll() }
        }

        /// Returns the response for a request if it has been mocked.
        static func response(for request: URLRequest) -> (response: Data?, statusCode: Int)? {
            guard let url = request.url?.absoluteString else {
                return nil
            }

            let encoded: (data: Data?, statusCode: Int, encodingFailure: String?)? = responsesByRequestURL.withLock { store in
                guard let response = store[url] else {
                    return nil
                }
                do {
                    return (data: try JSONEncoder().encode(response.response), statusCode: response.statusCode, encodingFailure: nil)
                } catch {
                    return (data: nil, statusCode: response.statusCode, encodingFailure: "\(response)")
                }
            }

            guard let encoded else {
                return nil
            }
            if let encodingFailure = encoded.encodingFailure {
                XCTFail("Couldn't convert response to Data: \(encodingFailure)")
            }
            return (response: encoded.data, statusCode: encoded.statusCode)
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

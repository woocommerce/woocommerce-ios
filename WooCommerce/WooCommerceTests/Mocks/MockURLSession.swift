import Foundation
@testable import WooCommerce
import NetworkingCore

final class MockURLSession: URLSessionProtocol {
    var responses: [String: (Data, URLResponse)] = [:]
    var errors: [String: Error] = [:]

    private(set) var lastRequest: URLRequest?
    private(set) var requestCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        requestCount += 1

        let key = request.url?.absoluteString ?? ""

        if let error = errors[key] {
            throw error
        }

        if let response = responses[key] {
            return response
        }

        // Default success response
        let data = Data()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    func simulateResponse(for url: String, data: Data = Data(), statusCode: Int = 200, headerFields: [String: String]? = nil) {
        let response = HTTPURLResponse(
            url: URL(string: url)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headerFields
        )!
        responses[url] = (data, response)
    }

    func simulateError(for url: String, error: Error) {
        errors[url] = error
    }
}

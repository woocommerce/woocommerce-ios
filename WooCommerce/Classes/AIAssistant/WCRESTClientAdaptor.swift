import Foundation
import Networking
import struct NetworkingCore.JetpackRequest
import enum NetworkingCore.NetworkError
import enum NetworkingCore.WooAPIVersion
import protocol NetworkingCore.Network
import struct Alamofire.HTTPMethod
import enum WooAIAssistant.HTTPStatusClassification
import struct WooAIAssistant.WCRESTResponse
import protocol WooAIAssistant.WCRESTClient

/// `JetpackRequest(availableAsRESTRequest: true)` routes the same way other
/// remotes do: WPCOM-tunneled with the bearer token, or upgraded to a direct
/// app-password REST call when the site supports it.
///
/// `Network` isn't declared `Sendable`, but the production instance is
/// constructed once at launch and treated as thread-safe across the app.
struct WCRESTClientAdaptor: @unchecked Sendable, WCRESTClient {
    private let network: Network
    private let siteID: Int64

    init(network: Network, siteID: Int64) {
        self.network = network
        self.siteID = siteID
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?,
                 headers: [String: String]?) async -> WCRESTResponse {
        let httpMethod = HTTPMethod(rawValue: method.uppercased())
        let (apiVersion, subpath) = Self.splitAPIVersion(from: path)
        let parameters = Self.parameters(forMethod: httpMethod, query: query, body: body)
        // `JetpackRequest` has no header slot; caller-supplied headers
        // (e.g. `Idempotency-Key`) are dropped at this boundary.
        _ = headers

        let jetpackRequest = JetpackRequest(wooApiVersion: apiVersion,
                                            method: httpMethod,
                                            siteID: siteID,
                                            path: subpath,
                                            parameters: parameters,
                                            availableAsRESTRequest: true)

        do {
            let (data, _) = try await network.responseDataAndHeaders(for: jetpackRequest)
            return WCRESTResponse(data: data, statusCode: 200)
        } catch let error as NetworkError {
            return WCRESTResponse(data: error.responseData ?? Data(),
                                  statusCode: error.responseCode ?? HTTPStatusClassification.transportFailure)
        } catch {
            return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
        }
    }

    private static func splitAPIVersion(from path: String) -> (apiVersion: WooAPIVersion, subpath: String) {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let prefixes: [(String, WooAPIVersion)] = [
            ("wc-analytics/", .wcAnalytics),
            ("wc/v4/", .mark4),
            ("wc/v3/", .mark3),
            ("wc/v2/", .mark2),
            ("wc/v1/", .mark1)
        ]
        for (prefix, version) in prefixes where trimmed.hasPrefix(prefix) {
            return (version, String(trimmed.dropFirst(prefix.count)))
        }
        return (.mark3, trimmed)
    }

    private static func parameters(forMethod method: HTTPMethod,
                                   query: [String: String]?,
                                   body: Data?) -> [String: Any]? {
        switch method {
        case .post, .put, .patch:
            guard let body, !body.isEmpty else { return nil }
            return (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
        default:
            guard let query, !query.isEmpty else { return nil }
            return query.reduce(into: [String: Any]()) { dict, pair in
                dict[pair.key] = pair.value
            }
        }
    }
}

private extension NetworkError {
    var responseData: Data? {
        switch self {
        case .notFound(let response), .timeout(let response), .unacceptableStatusCode(_, let response):
            return response
        case .invalidURL, .invalidCookieNonce:
            return nil
        }
    }
}

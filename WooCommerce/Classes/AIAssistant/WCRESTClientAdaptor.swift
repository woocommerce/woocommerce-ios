import Foundation
import Networking
import struct NetworkingCore.JetpackRequest
import protocol NetworkingCore.Mapper
import enum NetworkingCore.NetworkError
import enum NetworkingCore.WooAPIVersion
import protocol NetworkingCore.Network
import struct Alamofire.HTTPMethod
import enum WooAIAssistant.HTTPStatusClassification
import struct WooAIAssistant.WCRESTResponse
import protocol WooAIAssistant.WCRESTClient
import CocoaLumberjackSwift

struct WCRESTClientAdaptor: @unchecked Sendable, WCRESTClient {
    private let network: Network
    private let siteID: Int64
    private let responseMapper = AIToolResponseMapper()

    init(network: Network, siteID: Int64) {
        self.network = network
        self.siteID = siteID
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        let httpMethod = HTTPMethod(rawValue: method.uppercased())
        let (apiVersion, subpath) = splitAPIVersion(from: path)
        let parameters = self.parameters(forMethod: httpMethod, query: query, body: body)

        let jetpackRequest = JetpackRequest(wooApiVersion: apiVersion,
                                            method: httpMethod,
                                            siteID: siteID,
                                            path: subpath,
                                            parameters: parameters,
                                            availableAsRESTRequest: true)

        do {
            let (data, headers) = try await network.responseDataAndHeaders(for: jetpackRequest)
            return WCRESTResponse(data: unwrap(data), statusCode: 200, headers: headers ?? [:])
        } catch let error as NetworkError {
            let body = unwrap(error.responseData ?? Data())
            if case .timeout = error {
                return WCRESTResponse(data: body, statusCode: 408)
            }
            return WCRESTResponse(data: body,
                                  statusCode: error.responseCode ?? HTTPStatusClassification.transportFailure)
        } catch let error as URLError where error.code == .timedOut {
            return WCRESTResponse(data: Data(), statusCode: 408)
        } catch {
            return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
        }
    }

    private func unwrap(_ data: Data) -> Data {
        do {
            return try responseMapper.map(response: data)
        } catch {
            DDLogError("⛔️ WCRESTClientAdaptor failed to unwrap response envelope: \(error)")
            return data
        }
    }

    private func splitAPIVersion(from path: String) -> (apiVersion: WooAPIVersion, subpath: String) {
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

    private func parameters(forMethod method: HTTPMethod,
                            query: [String: String]?,
                            body: Data?) -> [String: Any]? {
        switch method {
        case .post, .put, .patch:
            guard let body, !body.isEmpty else { return nil }
            do {
                return try JSONSerialization.jsonObject(with: body) as? [String: Any]
            } catch {
                DDLogError("⛔️ WCRESTClientAdaptor failed to deserialize request body as JSON: \(error)")
                return nil
            }
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

/// Peels the Jetpack tunnel `{"data":<inner>}` wrap so tool responses reach the LLM as native JSON.
struct AIToolResponseMapper: Mapper {
    func map(response: Data) throws -> Data {
        guard !response.isEmpty, hasDataEnvelope(in: response) else { return response }
        guard let json = try JSONSerialization.jsonObject(with: response) as? [String: Any] else { return response }
        // WP REST error envelopes share the wrap shape but mustn't be peeled - the `code` key disambiguates.
        if json["code"] != nil { return response }
        guard let inner = json["data"] else { return response }
        return try JSONSerialization.data(withJSONObject: inner, options: [.fragmentsAllowed])
    }
}

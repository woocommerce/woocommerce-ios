import Foundation
import CocoaLumberjackSwift
import NetworkingCore

/// `WCRESTClient` that talks straight to a WooCommerce store's
/// `/wp-json/...` endpoints over HTTP Basic auth. The harness deliberately
/// avoids the `Networking` module so it can run outside the Jetpack
/// tunnel.
///
/// Two auth identities are supported:
/// - WP user + application password (`.appPassword`). The default for
///   merchants whose hosts let app passwords authenticate WC REST.
/// - WooCommerce REST API consumer key + secret (`.consumerKey`).
///   Required where Basic auth with app passwords returns
///   `woocommerce_rest_cannot_view`. The same pair doubles as the
///   `X-MCP-API-Key` header so a single secret covers REST and (future)
///   MCP transports.
///
/// Both modes encode `username:password` into a Basic header on the wire;
/// only the source pair differs. Non-2xx responses are returned to the
/// caller as `WCRESTResponse(statusCode: ...)` per the protocol contract,
/// not thrown.
public struct URLSessionWCRESTClient: WCRESTClient {

    public enum Auth: Sendable {
        case appPassword(user: String, key: String)
        case consumerKey(key: String, secret: String)
    }

    private let siteURL: URL
    private let basicAuthHeader: String
    private let mcpAPIKeyHeader: String?
    private let session: URLSession

    public init(siteURL: URL,
                auth: Auth,
                session: URLSession = .shared) {
        self.siteURL = siteURL
        self.session = session
        let raw: String
        switch auth {
        case .appPassword(let user, let key):
            // Strip whitespace - Atomic-hosted WC REST rejects spaced app passwords on Basic
            // auth even though wp-admin accepts them.
            let stripped = key.replacingOccurrences(of: " ", with: "")
            raw = "\(user):\(stripped)"
            self.mcpAPIKeyHeader = nil
        case .consumerKey(let key, let secret):
            raw = "\(key):\(secret)"
            self.mcpAPIKeyHeader = "\(key):\(secret)"
        }
        let encoded = Data(raw.utf8).base64EncodedString()
        self.basicAuthHeader = "Basic \(encoded)"
    }

    public func request(method: String,
                        path: String,
                        query: [String: String]?,
                        body: Data?) async -> WCRESTResponse {
        let url: URL
        do {
            url = try buildURL(path: path, query: query)
        } catch {
            DDLogError("URLSessionWCRESTClient buildURL failed: \(error)")
            return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.uppercased()
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        if let mcpAPIKeyHeader {
            request.setValue(mcpAPIKeyHeader, forHTTPHeaderField: "X-MCP-API-Key")
        }
        if let body, !body.isEmpty {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
            }
            return WCRESTResponse(data: data,
                                  statusCode: http.statusCode,
                                  headers: Self.flattenHeaders(http.allHeaderFields))
        } catch {
            DDLogError("URLSessionWCRESTClient transport failed: \(error)")
            return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
        }
    }

    private func buildURL(path: String, query: [String: String]?) throws -> URL {
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let fullPath = "wp-json/\(trimmedPath)"
        guard var components = URLComponents(
            url: siteURL.appendingPathComponent(fullPath),
            resolvingAgainstBaseURL: false
        ) else {
            throw URLSessionWCRESTError.invalidURL
        }
        if let query, !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw URLSessionWCRESTError.invalidURL
        }
        return url
    }

    private static func flattenHeaders(_ raw: [AnyHashable: Any]) -> [String: String] {
        var out: [String: String] = [:]
        for (key, value) in raw {
            if let stringKey = key as? String, let stringValue = value as? String {
                out[stringKey] = stringValue
            }
        }
        return out
    }
}

enum URLSessionWCRESTError: Error {
    case invalidURL
}

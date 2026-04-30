import Foundation
import CocoaLumberjackSwift
import NetworkingCore

/// `WCRESTClient` that talks straight to a WooCommerce store's
/// `/wp-json/...` endpoints. Basic auth with WP user + application password.
/// The harness deliberately avoids the `Networking` module so it can run
/// outside the Jetpack tunnel.
///
/// Non-2xx responses are returned to the caller as
/// `WCRESTResponse(statusCode: ...)` per the protocol contract, not thrown.
public struct URLSessionWCRESTClient: WCRESTClient {

    public enum Auth: Sendable {
        case appPassword(user: String, key: String)
    }

    private let siteURL: URL
    private let basicAuthHeader: String
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

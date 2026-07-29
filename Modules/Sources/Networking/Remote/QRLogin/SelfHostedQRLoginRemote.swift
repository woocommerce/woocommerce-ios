import Foundation
import NetworkingCore

/// Talks to the self-hosted QR-login endpoints exposed by the merchant's
/// WooCommerce plugin under the site's discovered WordPress REST API root.
///
/// These endpoints are unauthenticated — possession of the single-use token
/// (and the matching grant nonce on `/exchange`) is the authorisation — so this
/// type goes through `URLSession` directly, matching the precedent set by
/// `SiteCredentialLoginUseCase` and `OneTimeApplicationPasswordUseCase`. Going
/// through `AlamofireNetwork` is not an option for these endpoints because
/// that abstraction doesn't expose `HTTPURLResponse.statusCode` to the caller,
/// and the QR-login error tables branch on status code.
public protocol SelfHostedQRLoginRemoteProtocol {
    func scan(siteURL: URL,
              token: String,
              device: QRLoginScanDevice) async throws -> SelfHostedQRLoginScanResponse

    func pollSessionStatus(siteURL: URL,
                           sessionID: String,
                           tokenHash: String) async throws -> SelfHostedQRLoginSessionStatus

    func exchange(siteURL: URL,
                  token: String,
                  exchangeGrant: String) async throws -> SelfHostedQRLoginExchangeResponse
}

public final class SelfHostedQRLoginRemote: SelfHostedQRLoginRemoteProtocol {

    private let session: URLSessionProtocol
    private let apiRootCache: RESTAPIRootCaching
    private let discoverRESTAPIRoot: (_ siteURL: String) async -> String?

    public init(session: URLSessionProtocol = URLSession.shared,
                apiRootCache: RESTAPIRootCaching = WordPressRESTAPIRootCache.shared,
                discoverRESTAPIRoot: ((_ siteURL: String) async -> String?)? = nil) {
        self.session = session
        self.apiRootCache = apiRootCache

        if let discoverRESTAPIRoot {
            self.discoverRESTAPIRoot = discoverRESTAPIRoot
        } else {
            let discovery = WordPressAPIDiscovery(session: session)
            self.discoverRESTAPIRoot = {
                await discovery.resolveRESTAPIRootURL(for: $0)
            }
        }
    }

    public func scan(siteURL: URL,
                     token: String,
                     device: QRLoginScanDevice) async throws -> SelfHostedQRLoginScanResponse {
        let request = try makeJSONRequest(
            method: "POST",
            url: try await endpoint(siteURL: siteURL, path: Paths.scan),
            body: [
                "token": token,
                "supports_number_matching": true,
                "device": device.dictionary
            ]
        )
        let (data, statusCode) = try await perform(request)
        if let error = QRLoginHTTPStatusMapper.error(forStatusCode: statusCode, body: data) {
            throw error
        }
        return try QRLoginResponseBody.decode(SelfHostedQRLoginScanResponse.self, from: data)
    }

    public func pollSessionStatus(siteURL: URL,
                                  sessionID: String,
                                  tokenHash: String) async throws -> SelfHostedQRLoginSessionStatus {
        let url = try await endpoint(
            siteURL: siteURL,
            path: Paths.sessionStatus,
            queryItems: [
                URLQueryItem(name: "session_id", value: sessionID),
                URLQueryItem(name: "token_hash", value: tokenHash)
            ]
        )
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("no-cache, no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, statusCode) = try await perform(request)
        if let error = QRLoginHTTPStatusMapper.error(forStatusCode: statusCode, body: data) {
            throw error
        }
        return try QRLoginResponseBody.decode(SelfHostedQRLoginSessionStatus.self, from: data)
    }

    public func exchange(siteURL: URL,
                         token: String,
                         exchangeGrant: String) async throws -> SelfHostedQRLoginExchangeResponse {
        let request = try makeJSONRequest(
            method: "POST",
            url: try await endpoint(siteURL: siteURL, path: Paths.exchange),
            body: [
                "token": token,
                "exchange_grant": exchangeGrant
            ]
        )
        let (data, statusCode) = try await perform(request)
        if let error = QRLoginHTTPStatusMapper.error(forStatusCode: statusCode, body: data) {
            throw error
        }
        return try QRLoginResponseBody.decode(SelfHostedQRLoginExchangeResponse.self, from: data)
    }
}

// MARK: - HTTP helpers

private extension SelfHostedQRLoginRemote {

    func endpoint(siteURL: URL, path: String, queryItems: [URLQueryItem] = []) async throws -> URL {
        let site = siteURL.absoluteString.trimSlashes()
        let root: String = await {
            if let cachedRoot = apiRootCache.root(for: site) {
                return cachedRoot
            } else if let discoveredRoot = await discoverRESTAPIRoot(site) {
                return discoveredRoot
            } else {
                return WordPressAPIDiscovery.defaultRESTAPIRootURL(for: site)
            }
        }()

        let urlString = [
            root,
            Paths.namespace,
            path
        ]
            .map { $0.trimSlashes() }
            .filter { $0.isEmpty == false }
            .joined(separator: "/")

        guard let url = URL(string: urlString) else {
            throw QRLoginNetworkError.malformed
        }

        return try appendingQueryItems(queryItems, to: url)
    }

    func appendingQueryItems(_ queryItems: [URLQueryItem], to url: URL) throws -> URL {
        guard queryItems.isEmpty == false else {
            return url
        }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw QRLoginNetworkError.malformed
        }
        components.queryItems = (components.queryItems ?? []) + queryItems
        guard let url = components.url else {
            throw QRLoginNetworkError.malformed
        }
        return url
    }

    func makeJSONRequest(method: String, url: URL, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            throw QRLoginNetworkError.malformed
        }
        return request
    }

    func perform(_ request: URLRequest) async throws -> (Data, Int) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw QRLoginNetworkError.malformed
            }
            return (data, http.statusCode)
        } catch let error as QRLoginNetworkError {
            throw error
        } catch {
            throw QRLoginNetworkError.network
        }
    }

    enum Paths {
        static let namespace = "wc-admin/mobile-app"
        static let scan = "qr-login-scan"
        static let sessionStatus = "qr-login-session-status"
        static let exchange = "qr-login-exchange"
    }
}

import Foundation

/// Talks to the self-hosted QR-login endpoints exposed by the merchant's
/// WooCommerce plugin under `{siteUrl}/wp-json/wc-admin/mobile-app/qr-login-*`.
///
/// These endpoints are unauthenticated — possession of the single-use token
/// (and the matching grant nonce on `/exchange`) is the authorisation — so this
/// type goes through `URLSession` directly, matching the precedent set by
/// `SiteCredentialLoginUseCase` and `OneTimeApplicationPasswordUseCase`. Going
/// through `AlamofireNetwork` is not an option for these endpoints because
/// that abstraction doesn't expose `HTTPURLResponse.statusCode` to the caller,
/// and the QR-login error tables (spec §5.1) branch on status code.
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

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func scan(siteURL: URL,
                     token: String,
                     device: QRLoginScanDevice) async throws -> SelfHostedQRLoginScanResponse {
        let request = try makeJSONRequest(
            method: "POST",
            url: endpoint(siteURL: siteURL, path: Paths.scan),
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
        var components = endpointComponents(siteURL: siteURL, path: Paths.sessionStatus)
        components.queryItems = [
            URLQueryItem(name: "session_id", value: sessionID),
            URLQueryItem(name: "token_hash", value: tokenHash)
        ]
        guard let url = components.url else {
            throw QRLoginNetworkError.malformed
        }
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
            url: endpoint(siteURL: siteURL, path: Paths.exchange),
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

    func endpoint(siteURL: URL, path: String) -> URL {
        endpointComponents(siteURL: siteURL, path: path).url
            ?? siteURL.appendingPathComponent(Paths.restRoot + path)
    }

    func endpointComponents(siteURL: URL, path: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = siteURL.scheme
        components.host = siteURL.host
        components.port = siteURL.port
        components.path = siteURL.path + Paths.restRoot + path
        return components
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
        static let restRoot = "/wp-json/wc-admin/mobile-app"
        static let scan = "/qr-login-scan"
        static let sessionStatus = "/qr-login-session-status"
        static let exchange = "/qr-login-exchange"
    }
}

import Foundation

/// Talks to the WordPress.com QR-login endpoints at
/// `public-api.wordpress.com/wpcom/v2/auth/qr-code-app/...`.
///
/// Same URLSession-direct rationale as `SelfHostedQRLoginRemote`: the spec
/// error tables branch on HTTP status code and on the body `code` field, and
/// the existing `Network` abstraction can't surface either to the caller.
///
/// The OAuth `client_id` + `client_secret` are injected at construction so
/// this type doesn't reach for the host app's `ApiCredentials` (which lives
/// in the main app target).
public protocol WPComQRLoginRemoteProtocol {
    func scan(token: String,
              encrypted: String,
              device: QRLoginScanDevice) async throws -> QRLoginScanResponse

    func pollSessionStatus(sessionID: String,
                           tokenHash: String) async throws -> QRLoginSessionStatus

    func exchange(token: String,
                  encrypted: String,
                  exchangeGrant: String) async throws -> QRLoginWPComExchangeResponse
}

public final class WPComQRLoginRemote: WPComQRLoginRemoteProtocol {

    private let session: URLSession
    private let clientID: String
    private let clientSecret: String

    public init(clientID: String, clientSecret: String, session: URLSession = .shared) {
        self.session = session
        self.clientID = clientID
        self.clientSecret = clientSecret
    }

    public func scan(token: String,
                     encrypted: String,
                     device: QRLoginScanDevice) async throws -> QRLoginScanResponse {
        let request = try makeJSONRequest(
            method: "POST",
            url: endpoint(Paths.scan),
            body: [
                "client_id": clientID,
                "client_secret": clientSecret,
                "token": token,
                "encrypted": encrypted,
                "supports_number_matching": true,
                "device": device.dictionary
            ]
        )
        let (data, statusCode) = try await perform(request)
        if let error = QRLoginHTTPStatusMapper.error(forStatusCode: statusCode, body: data) {
            throw error
        }
        return try QRLoginResponseDecoder.scan(data: data, includeUserEmail: true)
    }

    public func pollSessionStatus(sessionID: String,
                                  tokenHash: String) async throws -> QRLoginSessionStatus {
        var components = endpointComponents(Paths.sessionStatus)
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
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
            // Spec §5.2.2: wp.com poll 404 is coerced to the `expired` terminal
            // (server keeps terminal records ~2 minutes; once evicted the
            // lookup 404s). The UI shows the timeout copy, not a hard error.
            if case .notFound = error {
                return QRLoginSessionStatus(state: .expired, exchangeGrant: nil)
            }
            throw error
        }
        return try QRLoginResponseDecoder.sessionStatus(data: data)
    }

    public func exchange(token: String,
                         encrypted: String,
                         exchangeGrant: String) async throws -> QRLoginWPComExchangeResponse {
        let request = try makeJSONRequest(
            method: "POST",
            url: endpoint(Paths.exchange),
            body: [
                "client_id": clientID,
                "client_secret": clientSecret,
                "token": token,
                "encrypted": encrypted,
                "exchange_grant": exchangeGrant
            ]
        )
        let (data, statusCode) = try await perform(request)
        if let error = QRLoginHTTPStatusMapper.error(forStatusCode: statusCode, body: data) {
            throw error
        }
        return try QRLoginResponseDecoder.wpComExchange(data: data)
    }
}

// MARK: - HTTP helpers

private extension WPComQRLoginRemote {

    func endpoint(_ path: String) -> URL {
        endpointComponents(path).url ?? URL(string: Settings.wordpressApiBaseURL + "wpcom/v2/auth/qr-code-app" + path)!
    }

    func endpointComponents(_ path: String) -> URLComponents {
        URLComponents(string: Settings.wordpressApiBaseURL + "wpcom/v2/auth/qr-code-app" + path)
            ?? URLComponents()
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
        static let scan = "/scan"
        static let sessionStatus = "/session-status"
        static let exchange = "/exchange"
    }
}

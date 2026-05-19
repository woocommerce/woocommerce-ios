import Foundation

/// JSON decoding helpers for QR-login endpoints. Shared between the
/// self-hosted and wp.com Remotes — the two protocols return the same shapes
/// for `/scan` and `/session-status` (the wp.com `/scan` just carries an extra
/// `user_email` field), and different shapes for `/exchange`.
///
/// Each helper throws `QRLoginNetworkError.malformed` for any body that
/// doesn't decode into the expected shape, or that decodes but is missing a
/// required field. The Remote callers handle this case the same way as an
/// unmapped non-2xx response (spec §5.1.1, §5.2.1: "all fields are required;
/// if any is missing/blank, the response is treated as malformed").
enum QRLoginResponseDecoder {

    static func scan(data: Data, includeUserEmail: Bool) throws -> QRLoginScanResponse {
        guard let wire = try? JSONDecoder().decode(ScanWire.self, from: data) else {
            throw QRLoginNetworkError.malformed
        }
        guard wire.sessionID.isEmpty == false,
              wire.realNumber.isEmpty == false else {
            throw QRLoginNetworkError.malformed
        }
        if includeUserEmail {
            guard let email = wire.userEmail, email.isEmpty == false else {
                throw QRLoginNetworkError.malformed
            }
            return QRLoginScanResponse(sessionID: wire.sessionID,
                                       realNumber: wire.realNumber,
                                       expiresInSeconds: wire.expiresIn,
                                       userEmail: email)
        }
        return QRLoginScanResponse(sessionID: wire.sessionID,
                                   realNumber: wire.realNumber,
                                   expiresInSeconds: wire.expiresIn,
                                   userEmail: nil)
    }

    static func sessionStatus(data: Data) throws -> QRLoginSessionStatus {
        guard let wire = try? JSONDecoder().decode(SessionStatusWire.self, from: data) else {
            throw QRLoginNetworkError.malformed
        }
        let state = QRLoginSessionStatus.State(rawValue: wire.effectiveState) ?? .unknown
        return QRLoginSessionStatus(state: state, exchangeGrant: wire.exchangeGrant)
    }

    static func selfHostedExchange(data: Data) throws -> QRLoginSelfHostedExchangeResponse {
        guard let wire = try? JSONDecoder().decode(SelfHostedExchangeWire.self, from: data),
              wire.userLogin.isEmpty == false,
              wire.siteURL.isEmpty == false,
              wire.applicationPassword.isEmpty == false else {
            throw QRLoginNetworkError.malformed
        }
        return QRLoginSelfHostedExchangeResponse(userLogin: wire.userLogin,
                                                 siteURL: wire.siteURL,
                                                 applicationPassword: wire.applicationPassword)
    }

    static func wpComExchange(data: Data) throws -> QRLoginWPComExchangeResponse {
        guard let wire = try? JSONDecoder().decode(WPComExchangeWire.self, from: data),
              wire.magicLinkURL.isEmpty == false,
              let url = URL(string: wire.magicLinkURL) else {
            throw QRLoginNetworkError.malformed
        }
        return QRLoginWPComExchangeResponse(magicLinkURL: url)
    }

    /// Best-effort extraction of an error `code` field from a non-2xx response
    /// body. WordPress REST endpoints return `{ "code": "...", "message": "...",
    /// "data": { "status": <int> } }`. Returns `nil` if the body isn't
    /// JSON-decodable or doesn't carry a `code` field.
    static func errorCode(in data: Data) -> String? {
        guard let envelope = try? JSONDecoder().decode(ErrorWire.self, from: data) else {
            return nil
        }
        return envelope.code
    }
}

// MARK: - Wire shapes

private struct ScanWire: Decodable {
    let sessionID: String
    let realNumber: String
    let expiresIn: Int
    let userEmail: String?

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case realNumber = "real_number"
        case expiresIn = "expires_in"
        case userEmail = "user_email"
    }
}

private struct SessionStatusWire: Decodable {
    let state: String?
    let status: String?
    let exchangeGrant: String?

    enum CodingKeys: String, CodingKey {
        case state
        case status // wp.com legacy alias for `state` (§5.2.2)
        case exchangeGrant = "exchange_grant"
    }

    /// `state` wins; falls back to `status` for the wp.com legacy shape, then
    /// to an empty string so the consumer maps to `.unknown`.
    var effectiveState: String {
        state ?? status ?? ""
    }
}

private struct SelfHostedExchangeWire: Decodable {
    let userLogin: String
    let siteURL: String
    let applicationPassword: String

    enum CodingKeys: String, CodingKey {
        case userLogin = "user_login"
        case siteURL = "site_url"
        case applicationPassword = "application_password"
    }
}

private struct WPComExchangeWire: Decodable {
    let magicLinkURL: String

    enum CodingKeys: String, CodingKey {
        case magicLinkURL = "magic_link_url"
    }
}

private struct ErrorWire: Decodable {
    let code: String?
}

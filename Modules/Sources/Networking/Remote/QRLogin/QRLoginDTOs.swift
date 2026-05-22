import Foundation

// The QR-login data layer is endpoint-shaped: each `Decodable` struct mirrors
// exactly one endpoint's response contract. The self-hosted endpoints (the
// merchant's WooCommerce plugin) and the wp.com endpoints (public-api.wordpress.com)
// are owned by separate backends, so they get separate types even where the
// shapes currently overlap — a match by convergent design, not a shared contract.
//
// The single exception is `QRLoginScanDevice`: it is request-side data the
// client knows about itself, identical regardless of endpoint.

// MARK: - Self-hosted responses

/// Response of `POST {siteURL}/wp-json/wc-admin/mobile-app/qr-login-scan` (spec §5.1.1).
///
/// All fields are required; a missing or blank value makes the whole response
/// malformed. The self-hosted scan carries no user identity — unlike wp.com,
/// the merchant's own server has no wp.com email to return.
public struct SelfHostedQRLoginScanResponse: Equatable {
    public let sessionID: String
    public let realNumber: String
    public let expiresInSeconds: Int

    public init(sessionID: String, realNumber: String, expiresInSeconds: Int) {
        self.sessionID = sessionID
        self.realNumber = realNumber
        self.expiresInSeconds = expiresInSeconds
    }
}

/// Response of `GET {siteURL}/wp-json/wc-admin/mobile-app/qr-login-session-status` (spec §5.1.2).
public struct SelfHostedQRLoginSessionStatus: Equatable {
    /// The states the self-hosted endpoint can report. It has no `consumed`
    /// state — that "already signed in elsewhere" terminal is wp.com-only.
    public enum State: String, Equatable {
        case scanned
        case approved
        case rejected
        case expired   // terminal "timed out"
        case unknown   // any value the client doesn't recognise — treated defensively as expired
    }

    public let state: State

    /// Only populated when `state == .approved`. A blank/missing value while
    /// `state == .approved` MUST be treated as `expired` ("fail closed") by the
    /// consumer (spec §5.1.2).
    public let exchangeGrant: String?

    public init(state: State, exchangeGrant: String?) {
        self.state = state
        self.exchangeGrant = exchangeGrant
    }
}

/// Response of `POST {siteURL}/wp-json/wc-admin/mobile-app/qr-login-exchange` (spec §5.1.3).
///
/// Carries the freshly minted Application Password. All fields are required.
public struct SelfHostedQRLoginExchangeResponse: Equatable {
    public let userLogin: String
    public let siteURL: String
    public let applicationPassword: String

    public init(userLogin: String, siteURL: String, applicationPassword: String) {
        self.userLogin = userLogin
        self.siteURL = siteURL
        self.applicationPassword = applicationPassword
    }
}

// MARK: - WP.com responses

/// Response of `POST /wpcom/v2/auth/qr-code-app/scan` (spec §5.2.1).
///
/// Unlike the self-hosted scan, the wp.com endpoint also returns the signed-in
/// user's wp.com email for the number-match screen. All fields are required.
public struct WPComQRLoginScanResponse: Equatable {
    public let sessionID: String
    public let realNumber: String
    public let expiresInSeconds: Int
    public let userEmail: String

    public init(sessionID: String, realNumber: String, expiresInSeconds: Int, userEmail: String) {
        self.sessionID = sessionID
        self.realNumber = realNumber
        self.expiresInSeconds = expiresInSeconds
        self.userEmail = userEmail
    }
}

/// Response of `GET /wpcom/v2/auth/qr-code-app/session-status` (spec §5.2.2).
public struct WPComQRLoginSessionStatus: Equatable {
    /// The states the wp.com endpoint can report. `consumed` ("already signed
    /// in elsewhere") is wp.com-only.
    public enum State: String, Equatable {
        case scanned
        case approved
        case rejected
        case expired   // terminal "timed out"
        case consumed  // terminal "already signed in elsewhere"
        case unknown   // any value the client doesn't recognise — treated defensively as expired
    }

    public let state: State

    /// Only populated when `state == .approved`. A blank/missing value while
    /// `state == .approved` MUST be treated as `expired` ("fail closed") by the
    /// consumer (spec §5.2.2).
    public let exchangeGrant: String?

    public init(state: State, exchangeGrant: String?) {
        self.state = state
        self.exchangeGrant = exchangeGrant
    }
}

/// Response of `POST /wpcom/v2/auth/qr-code-app/exchange` (spec §5.2.3).
///
/// Carries a magic-link URL the app opens to finish wp.com sign-in.
public struct WPComQRLoginExchangeResponse: Equatable {
    public let magicLinkURL: URL

    public init(magicLinkURL: URL) {
        self.magicLinkURL = magicLinkURL
    }
}

// MARK: - Shared request payload

/// Device metadata sent on both `/scan` requests (spec §5.1.1 / §5.2.1).
///
/// This is the one QR-login data type genuinely shared by both protocols: it is
/// request-side data the client knows about itself, so it carries the same
/// shape no matter which endpoint receives it. Each field is whitelisted and
/// capped server-side; values outside the whitelist are silently dropped.
public struct QRLoginScanDevice: Equatable {
    public let os: String
    public let osVersion: String
    public let model: String
    public let brand: String
    public let appVersion: String

    public init(os: String, osVersion: String, model: String, brand: String, appVersion: String) {
        self.os = os
        self.osVersion = osVersion
        self.model = model
        self.brand = brand
        self.appVersion = appVersion
    }

    var dictionary: [String: String] {
        [
            "os": os,
            "os_version": osVersion,
            "model": model,
            "brand": brand,
            "app_version": appVersion
        ]
    }
}

// MARK: - Decoding
//
// Each response type decodes itself, the way every other Networking model does.
// Validation lives in `init(from:)`: the QR-login spec treats a blank required
// field as a malformed response (§5.1.1 / §5.2.1), so a blank value fails
// decoding. The Remotes funnel every decoding failure into
// `QRLoginNetworkError.malformed` via `QRLoginResponseBody.decode`.

extension SelfHostedQRLoginScanResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case realNumber = "real_number"
        case expiresInSeconds = "expires_in"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sessionID = try container.decodeNonBlankString(forKey: .sessionID)
        let realNumber = try container.decodeNonBlankString(forKey: .realNumber)
        let expiresInSeconds = try container.decode(Int.self, forKey: .expiresInSeconds)
        self.init(sessionID: sessionID, realNumber: realNumber, expiresInSeconds: expiresInSeconds)
    }
}

extension SelfHostedQRLoginSessionStatus: Decodable {
    private enum CodingKeys: String, CodingKey {
        case state
        case exchangeGrant = "exchange_grant"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decodeIfPresent(String.self, forKey: .state)
        let grant = try container.decodeIfPresent(String.self, forKey: .exchangeGrant)
        self.init(state: State(rawValue: raw ?? "") ?? .unknown, exchangeGrant: grant)
    }
}

extension SelfHostedQRLoginExchangeResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case userLogin = "user_login"
        case siteURL = "site_url"
        case applicationPassword = "application_password"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userLogin = try container.decodeNonBlankString(forKey: .userLogin)
        let siteURL = try container.decodeNonBlankString(forKey: .siteURL)
        let applicationPassword = try container.decodeNonBlankString(forKey: .applicationPassword)
        self.init(userLogin: userLogin, siteURL: siteURL, applicationPassword: applicationPassword)
    }
}

extension WPComQRLoginScanResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case realNumber = "real_number"
        case expiresInSeconds = "expires_in"
        case userEmail = "user_email"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sessionID = try container.decodeNonBlankString(forKey: .sessionID)
        let realNumber = try container.decodeNonBlankString(forKey: .realNumber)
        let expiresInSeconds = try container.decode(Int.self, forKey: .expiresInSeconds)
        let userEmail = try container.decodeNonBlankString(forKey: .userEmail)
        self.init(sessionID: sessionID, realNumber: realNumber, expiresInSeconds: expiresInSeconds, userEmail: userEmail)
    }
}

extension WPComQRLoginSessionStatus: Decodable {
    private enum CodingKeys: String, CodingKey {
        case state
        case status // wp.com legacy alias for `state` (spec §5.2.2)
        case exchangeGrant = "exchange_grant"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // `state` wins; fall back to the legacy `status` alias, then to an empty
        // string so an unrecognised or absent value maps to `.unknown`.
        let raw = try container.decodeIfPresent(String.self, forKey: .state)
            ?? container.decodeIfPresent(String.self, forKey: .status)
        let grant = try container.decodeIfPresent(String.self, forKey: .exchangeGrant)
        self.init(state: State(rawValue: raw ?? "") ?? .unknown, exchangeGrant: grant)
    }
}

extension WPComQRLoginExchangeResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case magicLinkURL = "magic_link_url"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decodeNonBlankString(forKey: .magicLinkURL)
        guard let url = URL(string: raw) else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath,
                                                    debugDescription: "magic_link_url is not a valid URL"))
        }
        self.init(magicLinkURL: url)
    }
}

private extension KeyedDecodingContainer {
    /// Decodes a required `String` that the QR-login spec forbids from being
    /// blank — an empty value fails decoding so the Remote can surface it as a
    /// malformed response.
    func decodeNonBlankString(forKey key: Key) throws -> String {
        let value = try decode(String.self, forKey: key)
        guard value.isEmpty == false else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath,
                                                    debugDescription: "Required QR-login field '\(key.stringValue)' is blank"))
        }
        return value
    }
}

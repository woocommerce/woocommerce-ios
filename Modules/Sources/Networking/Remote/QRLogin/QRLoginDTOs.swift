import Foundation

/// Server response of `POST .../qr-login-scan` and `POST .../wpcom/v2/auth/qr-code-app/scan`.
///
/// `userEmail` is populated only by the wp.com endpoint (§5.2.1). All other
/// fields are required on both protocols (§5.1.1).
public struct QRLoginScanResponse: Equatable {
    public let sessionID: String
    public let realNumber: String
    public let expiresInSeconds: Int
    public let userEmail: String?

    public init(sessionID: String, realNumber: String, expiresInSeconds: Int, userEmail: String?) {
        self.sessionID = sessionID
        self.realNumber = realNumber
        self.expiresInSeconds = expiresInSeconds
        self.userEmail = userEmail
    }
}

/// Server response of `GET .../qr-login-session-status` (§5.1.2, §5.2.2).
public struct QRLoginSessionStatus: Equatable {
    public enum State: String, Equatable {
        case scanned
        case approved
        case rejected
        case expired   // self-hosted terminal "timed out"
        case consumed  // wp.com-only terminal "already signed in elsewhere"
        case unknown   // any value the client doesn't recognise — treated defensively as expired
    }

    public let state: State

    /// Only populated when `state == .approved`. A blank/missing value while
    /// `state == .approved` MUST be treated as `expired` ("fail closed") by
    /// the consumer (§5.1.2, §5.2.2).
    public let exchangeGrant: String?

    public init(state: State, exchangeGrant: String?) {
        self.state = state
        self.exchangeGrant = exchangeGrant
    }
}

/// Server response of `POST .../qr-login-exchange` (§5.1.3).
public struct QRLoginSelfHostedExchangeResponse: Equatable {
    public let userLogin: String
    public let siteURL: String
    public let applicationPassword: String

    public init(userLogin: String, siteURL: String, applicationPassword: String) {
        self.userLogin = userLogin
        self.siteURL = siteURL
        self.applicationPassword = applicationPassword
    }
}

/// Server response of `POST /wpcom/v2/auth/qr-code-app/exchange` (§5.2.3).
public struct QRLoginWPComExchangeResponse: Equatable {
    public let magicLinkURL: URL

    public init(magicLinkURL: URL) {
        self.magicLinkURL = magicLinkURL
    }
}

/// Device metadata sent on `/scan` requests (§5.1.1 / §5.2.1). Each field is
/// whitelisted server-side and capped; values outside the whitelist are
/// silently dropped.
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

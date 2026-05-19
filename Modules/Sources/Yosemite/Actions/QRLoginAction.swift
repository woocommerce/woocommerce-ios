import Foundation
import Networking

/// Actions supported by `QRLoginStore`. One case per (protocol × endpoint)
/// combination — the upper-layer strategies (Layer 3) wrap these into a
/// protocol-agnostic interface.
///
/// Each completion delivers either the decoded response or a
/// `QRLoginNetworkError` carrying enough detail (HTTP status + body code)
/// for the user-facing error mapper.
public enum QRLoginAction: Action {

    // MARK: - Self-hosted (wp-admin)

    case selfHostedScan(siteURL: URL,
                        token: String,
                        device: QRLoginScanDevice,
                        completion: (Result<QRLoginScanResponse, QRLoginNetworkError>) -> Void)

    case selfHostedPoll(siteURL: URL,
                        sessionID: String,
                        tokenHash: String,
                        completion: (Result<QRLoginSessionStatus, QRLoginNetworkError>) -> Void)

    case selfHostedExchange(siteURL: URL,
                            token: String,
                            exchangeGrant: String,
                            completion: (Result<QRLoginSelfHostedExchangeResponse, QRLoginNetworkError>) -> Void)

    // MARK: - WP.com (public-api.wordpress.com)

    case wpComScan(token: String,
                   encrypted: String,
                   device: QRLoginScanDevice,
                   completion: (Result<QRLoginScanResponse, QRLoginNetworkError>) -> Void)

    case wpComPoll(sessionID: String,
                   tokenHash: String,
                   completion: (Result<QRLoginSessionStatus, QRLoginNetworkError>) -> Void)

    case wpComExchange(token: String,
                       encrypted: String,
                       exchangeGrant: String,
                       completion: (Result<QRLoginWPComExchangeResponse, QRLoginNetworkError>) -> Void)
}

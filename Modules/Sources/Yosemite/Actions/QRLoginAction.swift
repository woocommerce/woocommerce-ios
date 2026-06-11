import Foundation

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
                        completion: (Result<SelfHostedQRLoginScanResponse, QRLoginNetworkError>) -> Void)

    case selfHostedPoll(siteURL: URL,
                        sessionID: String,
                        tokenHash: String,
                        completion: (Result<SelfHostedQRLoginSessionStatus, QRLoginNetworkError>) -> Void)

    case selfHostedExchange(siteURL: URL,
                            token: String,
                            exchangeGrant: String,
                            completion: (Result<SelfHostedQRLoginExchangeResponse, QRLoginNetworkError>) -> Void)

    // MARK: - WP.com (public-api.wordpress.com)

    case wpComScan(token: String,
                   encrypted: String,
                   device: QRLoginScanDevice,
                   completion: (Result<WPComQRLoginScanResponse, QRLoginNetworkError>) -> Void)

    case wpComPoll(sessionID: String,
                   tokenHash: String,
                   completion: (Result<WPComQRLoginSessionStatus, QRLoginNetworkError>) -> Void)

    case wpComExchange(token: String,
                       encrypted: String,
                       exchangeGrant: String,
                       completion: (Result<WPComQRLoginExchangeResponse, QRLoginNetworkError>) -> Void)
}

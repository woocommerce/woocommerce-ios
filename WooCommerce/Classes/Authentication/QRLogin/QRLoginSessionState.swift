import Foundation
import Yosemite

/// Behaviour-layer view of a QR-login session's state during polling.
///
/// The data layer has one session-status struct per endpoint
/// (`SelfHostedQRLoginSessionStatus` / `WPComQRLoginSessionStatus`); this is the
/// shared concept they both map into, so `QRLoginPollingLoop` and
/// `QRLoginErrorMapper` stay protocol-agnostic. The grant rides on `.approved`
/// because it only ever exists for that state.
enum QRLoginSessionState: Equatable {
    case scanned
    case approved(exchangeGrant: String?)
    case rejected
    case expired
    /// "Already signed in elsewhere" — only the wp.com endpoint reports this.
    case consumed
    /// Any state value the client doesn't recognise — treated defensively as a
    /// timeout by the consumer.
    case unknown
}

extension SelfHostedQRLoginSessionStatus {
    /// Behaviour-layer view of this poll result. The self-hosted endpoint never
    /// reports `consumed`, so that case is unreachable here.
    var sessionState: QRLoginSessionState {
        switch state {
        case .scanned: return .scanned
        case .approved: return .approved(exchangeGrant: exchangeGrant)
        case .rejected: return .rejected
        case .expired: return .expired
        case .unknown: return .unknown
        }
    }
}

extension WPComQRLoginSessionStatus {
    /// Behaviour-layer view of this poll result.
    var sessionState: QRLoginSessionState {
        switch state {
        case .scanned: return .scanned
        case .approved: return .approved(exchangeGrant: exchangeGrant)
        case .rejected: return .rejected
        case .expired: return .expired
        case .consumed: return .consumed
        case .unknown: return .unknown
        }
    }
}

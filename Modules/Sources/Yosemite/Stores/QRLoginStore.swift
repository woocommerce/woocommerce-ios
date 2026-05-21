import Foundation
import Networking

/// Yosemite store fronting the QR-login Remotes.
///
/// Subclasses `DeauthenticatedStore` because QR-login is a logged-out flow —
/// the merchant has not yet authenticated, so we run alongside
/// `AccountCreationStore`, `WordPressSiteStore`, etc. in
/// `DeauthenticatedState`.
///
/// Both Remotes are injected so tests can substitute mock implementations
/// without touching `URLSession`. The default convenience init wires up the
/// real Remotes with the WP.com OAuth credentials passed from
/// `DeauthenticatedState` (host app target) — keeping `ApiCredentials` out of
/// this module.
public final class QRLoginStore: DeauthenticatedStore {

    private let selfHostedRemote: SelfHostedQRLoginRemoteProtocol
    private let wpComRemote: WPComQRLoginRemoteProtocol

    public init(dispatcher: Dispatcher,
                selfHostedRemote: SelfHostedQRLoginRemoteProtocol,
                wpComRemote: WPComQRLoginRemoteProtocol) {
        self.selfHostedRemote = selfHostedRemote
        self.wpComRemote = wpComRemote
        super.init(dispatcher: dispatcher)
    }

    public convenience init(dispatcher: Dispatcher,
                            wpComClientID: String,
                            wpComClientSecret: String) {
        self.init(dispatcher: dispatcher,
                  selfHostedRemote: SelfHostedQRLoginRemote(),
                  wpComRemote: WPComQRLoginRemote(clientID: wpComClientID,
                                                  clientSecret: wpComClientSecret))
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: QRLoginAction.self)
    }

    public override func onAction(_ action: Action) {
        guard let action = action as? QRLoginAction else {
            assertionFailure("QRLoginStore received an unsupported action: \(action)")
            return
        }

        switch action {
        case let .selfHostedScan(siteURL, token, device, completion):
            selfHostedScan(siteURL: siteURL, token: token, device: device, completion: completion)
        case let .selfHostedPoll(siteURL, sessionID, tokenHash, completion):
            selfHostedPoll(siteURL: siteURL, sessionID: sessionID, tokenHash: tokenHash, completion: completion)
        case let .selfHostedExchange(siteURL, token, exchangeGrant, completion):
            selfHostedExchange(siteURL: siteURL, token: token, exchangeGrant: exchangeGrant, completion: completion)
        case let .wpComScan(token, encrypted, device, completion):
            wpComScan(token: token, encrypted: encrypted, device: device, completion: completion)
        case let .wpComPoll(sessionID, tokenHash, completion):
            wpComPoll(sessionID: sessionID, tokenHash: tokenHash, completion: completion)
        case let .wpComExchange(token, encrypted, exchangeGrant, completion):
            wpComExchange(token: token, encrypted: encrypted, exchangeGrant: exchangeGrant, completion: completion)
        }
    }
}

// MARK: - Self-hosted dispatch

private extension QRLoginStore {

    func selfHostedScan(siteURL: URL,
                        token: String,
                        device: QRLoginScanDevice,
                        completion: @escaping (Result<SelfHostedQRLoginScanResponse, QRLoginNetworkError>) -> Void) {
        Task {
            do {
                let response = try await selfHostedRemote.scan(siteURL: siteURL, token: token, device: device)
                completion(.success(response))
            } catch {
                completion(.failure(normalize(error)))
            }
        }
    }

    func selfHostedPoll(siteURL: URL,
                        sessionID: String,
                        tokenHash: String,
                        completion: @escaping (Result<SelfHostedQRLoginSessionStatus, QRLoginNetworkError>) -> Void) {
        Task {
            do {
                let status = try await selfHostedRemote.pollSessionStatus(siteURL: siteURL,
                                                                          sessionID: sessionID,
                                                                          tokenHash: tokenHash)
                completion(.success(status))
            } catch {
                completion(.failure(normalize(error)))
            }
        }
    }

    func selfHostedExchange(siteURL: URL,
                            token: String,
                            exchangeGrant: String,
                            completion: @escaping (Result<SelfHostedQRLoginExchangeResponse, QRLoginNetworkError>) -> Void) {
        Task {
            do {
                let response = try await selfHostedRemote.exchange(siteURL: siteURL,
                                                                   token: token,
                                                                   exchangeGrant: exchangeGrant)
                completion(.success(response))
            } catch {
                completion(.failure(normalize(error)))
            }
        }
    }
}

// MARK: - WP.com dispatch

private extension QRLoginStore {

    func wpComScan(token: String,
                   encrypted: String,
                   device: QRLoginScanDevice,
                   completion: @escaping (Result<WPComQRLoginScanResponse, QRLoginNetworkError>) -> Void) {
        Task {
            do {
                let response = try await wpComRemote.scan(token: token, encrypted: encrypted, device: device)
                completion(.success(response))
            } catch {
                completion(.failure(normalize(error)))
            }
        }
    }

    func wpComPoll(sessionID: String,
                   tokenHash: String,
                   completion: @escaping (Result<WPComQRLoginSessionStatus, QRLoginNetworkError>) -> Void) {
        Task {
            do {
                let status = try await wpComRemote.pollSessionStatus(sessionID: sessionID, tokenHash: tokenHash)
                completion(.success(status))
            } catch {
                completion(.failure(normalize(error)))
            }
        }
    }

    func wpComExchange(token: String,
                       encrypted: String,
                       exchangeGrant: String,
                       completion: @escaping (Result<WPComQRLoginExchangeResponse, QRLoginNetworkError>) -> Void) {
        Task {
            do {
                let response = try await wpComRemote.exchange(token: token,
                                                              encrypted: encrypted,
                                                              exchangeGrant: exchangeGrant)
                completion(.success(response))
            } catch {
                completion(.failure(normalize(error)))
            }
        }
    }
}

// MARK: - Helpers

private extension QRLoginStore {

    /// Coerces any thrown error into a `QRLoginNetworkError`. The Remotes
    /// only throw `QRLoginNetworkError`, but the `throws` signature is
    /// untyped — this keeps the contract explicit.
    func normalize(_ error: Error) -> QRLoginNetworkError {
        (error as? QRLoginNetworkError) ?? .network
    }
}

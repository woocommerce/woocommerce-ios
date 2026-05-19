import Foundation
import Networking
import Yosemite

/// Self-hosted (wp-admin) QR-login strategy. Wraps `QRLoginAction.selfHosted*`
/// dispatches and translates `QRLoginNetworkError` into user-facing variants
/// via `QRLoginErrorMapper`.
///
/// `completeAfterExchange` is intentionally a stub in this layer — Layer 4
/// will plug in the post-exchange site-setup (fetch SiteModel, save AP,
/// eligibility, store switch, AP revoke on failure).
@MainActor
final class SelfHostedQRLoginStrategy: QRLoginStrategy {

    let protocol_: QRLoginErrorMapper.Protocol_ = .selfHosted

    private let token: String
    private let siteURL: URL
    private let stores: StoresManager
    private let deviceInfoProvider: QRLoginDeviceInfoProvider

    /// Set once `/scan` succeeds. Reused across poll attempts.
    private var sessionID: String?
    private var tokenHash: String?

    /// Set once `/exchange` succeeds. Held so the post-exchange step (Layer 4)
    /// can use the credentials, and so that an exchange-retry doesn't re-run
    /// scan or poll.
    private var exchangeResponse: QRLoginSelfHostedExchangeResponse?

    init(token: String,
         siteURL: URL,
         stores: StoresManager = ServiceLocator.stores,
         deviceInfoProvider: QRLoginDeviceInfoProvider = DefaultQRLoginDeviceInfoProvider()) {
        self.token = token
        self.siteURL = siteURL
        self.stores = stores
        self.deviceInfoProvider = deviceInfoProvider
    }

    func scan() async -> Result<QRLoginScanResult, QRLoginUserFacingError> {
        let device = deviceInfoProvider.device
        let response = await dispatch(scanWith: device)
        switch response {
        case .success(let scan):
            let hash = QRLoginTokenHash.make(for: token)
            sessionID = scan.sessionID
            tokenHash = hash
            return .success(QRLoginScanResult(
                sessionID: scan.sessionID,
                realNumber: scan.realNumber,
                expiresInSeconds: scan.expiresInSeconds,
                tokenHash: hash,
                subtitle: .host(siteURL.host ?? siteURL.absoluteString)
            ))
        case .failure(let error):
            return .failure(QRLoginErrorMapper.userFacingError(forScan: error, protocol_: protocol_))
        }
    }

    func makePollAttempt() -> QRLoginPollingLoop.PollAttempt {
        let siteURL = self.siteURL
        let stores = self.stores
        let sessionID = self.sessionID
        let tokenHash = self.tokenHash
        return {
            guard let sessionID, let tokenHash else {
                // Programming error: poll without prior successful scan.
                throw QRLoginNetworkError.malformed
            }
            return try await Self.dispatch(stores: stores) { completion in
                QRLoginAction.selfHostedPoll(siteURL: siteURL,
                                             sessionID: sessionID,
                                             tokenHash: tokenHash,
                                             completion: completion)
            }
        }
    }

    func exchange(grant: String) async -> Result<Void, QRLoginUserFacingError> {
        // Reuse a previously-retained successful exchange (retry path).
        if let exchangeResponse {
            return await completeAfterExchange(exchangeResponse)
        }

        let result: Result<QRLoginSelfHostedExchangeResponse, QRLoginNetworkError>
        do {
            result = .success(try await Self.dispatch(stores: stores) { completion in
                QRLoginAction.selfHostedExchange(siteURL: siteURL,
                                                 token: token,
                                                 exchangeGrant: grant,
                                                 completion: completion)
            })
        } catch let error as QRLoginNetworkError {
            result = .failure(error)
        } catch {
            result = .failure(.network)
        }

        switch result {
        case .success(let response):
            exchangeResponse = response
            return await completeAfterExchange(response)
        case .failure(let error):
            return .failure(QRLoginErrorMapper.userFacingError(forExchange: error, protocol_: protocol_))
        }
    }

    /// Post-exchange site setup. Stubbed in Layer 3 — Layer 4 wires the
    /// SiteModel fetch, AP storage, eligibility check, store switch.
    private func completeAfterExchange(_ response: QRLoginSelfHostedExchangeResponse) async -> Result<Void, QRLoginUserFacingError> {
        // TODO: Layer 4 — implement spec §5.1.4 here.
        .success(())
    }
}

// MARK: - Dispatch helpers

private extension SelfHostedQRLoginStrategy {

    func dispatch(scanWith device: QRLoginScanDevice) async -> Result<QRLoginScanResponse, QRLoginNetworkError> {
        do {
            let response = try await Self.dispatch(stores: stores) { completion in
                QRLoginAction.selfHostedScan(siteURL: siteURL,
                                             token: token,
                                             device: device,
                                             completion: completion)
            }
            return .success(response)
        } catch let error as QRLoginNetworkError {
            return .failure(error)
        } catch {
            return .failure(.network)
        }
    }

    /// Bridges an `Action` whose completion delivers
    /// `Result<T, QRLoginNetworkError>` into Swift Concurrency.
    static func dispatch<T>(stores: StoresManager,
                             _ build: (@escaping (Result<T, QRLoginNetworkError>) -> Void) -> Action) async throws -> T {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            let action = build { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }
}

import Foundation
import Yosemite

/// Self-hosted (wp-admin) QR-login strategy. Wraps `QRLoginAction.selfHosted*`
/// dispatches and translates `QRLoginNetworkError` into user-facing variants
/// via `QRLoginErrorMapper`. After a successful `/exchange` it hands the minted
/// Application Password to `QRLoginPostExchangeService` for site setup.
@MainActor
final class SelfHostedQRLoginStrategy: QRLoginStrategy {

    let protocol_: QRLoginErrorMapper.Protocol_ = .selfHosted

    private let token: String
    private let siteURL: URL
    private let stores: StoresManager
    private let deviceInfoProvider: QRLoginDeviceInfoProvider
    private let postExchangeService: QRLoginPostExchangeServicing

    /// Set once `/scan` succeeds. Reused across poll attempts.
    private var sessionID: String?
    private var tokenHash: String?

    /// Set once `/exchange` succeeds and post-exchange site setup completes.
    /// Retry-after-success short-circuits to a no-op success rather than
    /// minting a fresh AP, in case the user taps "Try again" on a transient
    /// downstream failure.
    private var exchangeResponse: SelfHostedQRLoginExchangeResponse?
    private var postExchangeCompleted = false

    init(token: String,
         siteURL: URL,
         stores: StoresManager = ServiceLocator.stores,
         deviceInfoProvider: QRLoginDeviceInfoProvider = DefaultQRLoginDeviceInfoProvider(),
         postExchangeService: QRLoginPostExchangeServicing? = nil) {
        self.token = token
        self.siteURL = siteURL
        self.stores = stores
        self.deviceInfoProvider = deviceInfoProvider
        // `QRLoginPostExchangeService()` is @MainActor-isolated, so it can't be
        // a default parameter expression (those are evaluated in the caller's
        // context, which the compiler can't always prove is MainActor). The
        // strategy itself is @MainActor, so constructing the service in the
        // body is allowed.
        self.postExchangeService = postExchangeService ?? QRLoginPostExchangeService()
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
            let status = try await Self.dispatch(stores: stores) { completion in
                QRLoginAction.selfHostedPoll(siteURL: siteURL,
                                             sessionID: sessionID,
                                             tokenHash: tokenHash,
                                             completion: completion)
            }
            return status.sessionState
        }
    }

    func exchange(grant: String) async -> Result<QRLoginExchangeOutcome, QRLoginUserFacingError> {
        // If post-exchange already completed in a prior retry, no work to do.
        if postExchangeCompleted {
            return .success(.authenticated)
        }

        let response: SelfHostedQRLoginExchangeResponse
        if let cached = exchangeResponse {
            // Retry path: exchange already succeeded server-side, but the
            // post-exchange site setup failed. Don't mint a new AP — re-run
            // post-exchange against the cached response.
            response = cached
        } else {
            do {
                response = try await Self.dispatch(stores: stores) { completion in
                    QRLoginAction.selfHostedExchange(siteURL: siteURL,
                                                     token: token,
                                                     exchangeGrant: grant,
                                                     completion: completion)
                }
                exchangeResponse = response
            } catch let error as QRLoginNetworkError {
                return .failure(QRLoginErrorMapper.userFacingError(forExchange: error, protocol_: protocol_))
            } catch {
                return .failure(QRLoginErrorMapper.userFacingError(forExchange: .network, protocol_: protocol_))
            }
        }

        switch await postExchangeService.complete(response) {
        case .success:
            postExchangeCompleted = true
            return .success(.authenticated)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Dispatch helpers

private extension SelfHostedQRLoginStrategy {

    func dispatch(scanWith device: QRLoginScanDevice) async -> Result<SelfHostedQRLoginScanResponse, QRLoginNetworkError> {
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

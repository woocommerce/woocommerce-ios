import Foundation
import Networking
import Yosemite

/// Closure that opens a magic-link URL in an in-app browser. Injected by the
/// coordinator (Layer 6) — Layer 3 only declares the seam so the strategy is
/// testable without a `UIApplication`.
typealias QRLoginMagicLinkOpener = @MainActor (URL) async -> Void

/// WP.com QR-login strategy. Wraps `QRLoginAction.wpCom*` dispatches and
/// translates `QRLoginNetworkError` into user-facing variants via
/// `QRLoginErrorMapper`.
///
/// `exchange` opens the returned magic-link URL through the injected opener;
/// the existing magic-link intercept (`AuthenticationManager.handleAuthenticationUrl`
/// for `WordPressAuthenticator.isWordPressAuthUrl`) completes wp.com OAuth.
@MainActor
final class WPComQRLoginStrategy: QRLoginStrategy {

    let protocol_: QRLoginErrorMapper.Protocol_ = .wpCom

    private let token: String
    private let encrypted: String
    private let stores: StoresManager
    private let deviceInfoProvider: QRLoginDeviceInfoProvider
    private let magicLinkOpener: QRLoginMagicLinkOpener

    private var sessionID: String?
    private var tokenHash: String?
    private var exchangeResponse: QRLoginWPComExchangeResponse?

    init(token: String,
         encrypted: String,
         stores: StoresManager = ServiceLocator.stores,
         deviceInfoProvider: QRLoginDeviceInfoProvider = DefaultQRLoginDeviceInfoProvider(),
         magicLinkOpener: @escaping QRLoginMagicLinkOpener = WPComQRLoginStrategy.defaultMagicLinkOpener) {
        self.token = token
        self.encrypted = encrypted
        self.stores = stores
        self.deviceInfoProvider = deviceInfoProvider
        self.magicLinkOpener = magicLinkOpener
    }

    func scan() async -> Result<QRLoginScanResult, QRLoginUserFacingError> {
        let device = deviceInfoProvider.device
        do {
            let response = try await Self.dispatch(stores: stores) { completion in
                QRLoginAction.wpComScan(token: token,
                                        encrypted: encrypted,
                                        device: device,
                                        completion: completion)
            }
            let hash = QRLoginTokenHash.make(for: token)
            sessionID = response.sessionID
            tokenHash = hash
            return .success(QRLoginScanResult(
                sessionID: response.sessionID,
                realNumber: response.realNumber,
                expiresInSeconds: response.expiresInSeconds,
                tokenHash: hash,
                subtitle: .email(response.userEmail ?? "")
            ))
        } catch let error as QRLoginNetworkError {
            return .failure(QRLoginErrorMapper.userFacingError(forScan: error, protocol_: protocol_))
        } catch {
            return .failure(QRLoginErrorMapper.userFacingError(forScan: .network, protocol_: protocol_))
        }
    }

    func makePollAttempt() -> QRLoginPollingLoop.PollAttempt {
        let stores = self.stores
        let sessionID = self.sessionID
        let tokenHash = self.tokenHash
        return {
            guard let sessionID, let tokenHash else {
                throw QRLoginNetworkError.malformed
            }
            return try await Self.dispatch(stores: stores) { completion in
                QRLoginAction.wpComPoll(sessionID: sessionID,
                                        tokenHash: tokenHash,
                                        completion: completion)
            }
        }
    }

    func exchange(grant: String) async -> Result<Void, QRLoginUserFacingError> {
        if let exchangeResponse {
            await magicLinkOpener(exchangeResponse.magicLinkURL)
            return .success(())
        }
        do {
            let response = try await Self.dispatch(stores: stores) { completion in
                QRLoginAction.wpComExchange(token: token,
                                            encrypted: encrypted,
                                            exchangeGrant: grant,
                                            completion: completion)
            }
            exchangeResponse = response
            await magicLinkOpener(response.magicLinkURL)
            return .success(())
        } catch let error as QRLoginNetworkError {
            return .failure(QRLoginErrorMapper.userFacingError(forExchange: error, protocol_: protocol_))
        } catch {
            return .failure(QRLoginErrorMapper.userFacingError(forExchange: .network, protocol_: protocol_))
        }
    }

    /// Default opener used outside tests. The coordinator (Layer 6) provides
    /// the real implementation; until then we just log so the seam exists.
    static let defaultMagicLinkOpener: QRLoginMagicLinkOpener = { url in
        DDLogInfo("QR-login: ready to open magic link \(url.host ?? "<unknown host>")")
    }
}

// MARK: - Dispatch helpers

private extension WPComQRLoginStrategy {
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

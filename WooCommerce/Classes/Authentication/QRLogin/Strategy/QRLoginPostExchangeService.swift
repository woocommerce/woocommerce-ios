import Foundation
import WooFoundation
import Yosemite
import struct NetworkingCore.ApplicationPassword
import protocol NetworkingCore.ApplicationPasswordUseCase
import class NetworkingCore.OneTimeApplicationPasswordUseCase
import enum NetworkingCore.Credentials
import struct NetworkingCore.Secret

/// Runs the self-hosted post-exchange sequence once the QR
/// `/exchange` call has minted an Application Password:
///
///   1. Build `Credentials.applicationPassword` and authenticate the stores
///      manager. Persists the AP to keychain via
///      `OneTimeApplicationPasswordUseCase` so subsequent app-target REST
///      calls can use it.
///   2. Fetch the site via `WordPressSiteAction.fetchSiteInfo` (unauthenticated
///      — `wp-json` root endpoint).
///   3. If the site does not advertise WooCommerce → revoke the AP server-side
///      (DELETE on the AP endpoint), deauthenticate the stores manager, and
///      surface `.notAWooSite`.
///   4. Run `RoleEligibilityUseCase` with `placeholderStoreID`. On
///      `insufficientRole` → revoke + deauthenticate + `.userNotEligible`. On
///      any other failure → revoke + deauthenticate + `.siteAuthFailure`.
///   5. On full success: track `.signedIn` and return `.success(())`.
///
/// Failure paths always call `deletePassword(locally: true)`, which both
/// revokes the AP server-side and removes it from local storage. The revoke
/// is wrapped in `try?` so the user sees the original error even if the
/// revoke itself fails — an orphan AP on the merchant's site is recoverable;
/// a confusing UI state is not.
@MainActor
protocol QRLoginPostExchangeServicing {
    /// - Parameters:
    ///   - response: the `/exchange` response (its `site_url` is server-controlled).
    ///   - scannedSiteURL: the https-validated URL the merchant scanned and
    ///     confirmed on the number-match screen. Used to validate `response.siteURL`.
    func complete(_ response: SelfHostedQRLoginExchangeResponse,
                  scannedSiteURL: URL) async -> Result<Void, QRLoginUserFacingError>
}

@MainActor
final class QRLoginPostExchangeService: QRLoginPostExchangeServicing {

    /// Factory for the AP use case so tests can plug in a mock that doesn't
    /// touch keychain or the network.
    typealias ApplicationPasswordUseCaseFactory =
        @MainActor (ApplicationPassword, String) -> ApplicationPasswordUseCase

    private let stores: StoresManager
    private let roleEligibilityUseCase: RoleEligibilityUseCaseProtocol
    private let applicationPasswordUseCaseFactory: ApplicationPasswordUseCaseFactory
    private let analytics: Analytics

    init(stores: StoresManager = ServiceLocator.stores,
         roleEligibilityUseCase: RoleEligibilityUseCaseProtocol? = nil,
         applicationPasswordUseCaseFactory: ApplicationPasswordUseCaseFactory? = nil,
         analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.roleEligibilityUseCase = roleEligibilityUseCase ?? RoleEligibilityUseCase(stores: stores)
        self.analytics = analytics
        self.applicationPasswordUseCaseFactory = applicationPasswordUseCaseFactory ?? Self.defaultApplicationPasswordUseCaseFactory
    }

    func complete(_ response: SelfHostedQRLoginExchangeResponse,
                  scannedSiteURL: URL) async -> Result<Void, QRLoginUserFacingError> {
        let applicationPassword = ApplicationPassword(
            wpOrgUsername: response.userLogin,
            password: Secret(response.applicationPassword),
            // The exchange response doesn't carry the AP UUID. OneTimeApplicationPasswordUseCase
            // looks up the real one on delete via /wp/v2/users/me/application-passwords/introspect,
            // so a placeholder is fine here.
            uuid: UUID().uuidString
        )

        // The exchange response's `site_url` is server-controlled. Trusting it
        // blindly would let a malicious/compromised server bind the minted
        // credentials to a different host or downgrade the scheme to http,
        // bypassing both the scan-time https rule and the host the merchant
        // confirmed on the number-match screen. Require it to match the scanned
        // URL (exact host, same scheme) before authenticating against it.
        guard let siteURL = Self.validatedSiteURL(from: response, scannedSiteURL: scannedSiteURL) else {
            // The `/exchange` call already minted an AP on the scanned site, so
            // revoke it (using the trusted scanned URL — the response URL is what
            // we're rejecting) rather than leaving an orphan, then surface a
            // sign-in failure. No credentials were authenticated yet.
            let useCase = applicationPasswordUseCaseFactory(applicationPassword, scannedSiteURL.absoluteString)
            return await fail(.siteAuthFailure, useCase: useCase)
        }

        let useCase = applicationPasswordUseCaseFactory(applicationPassword, siteURL)

        let credentials = Credentials.applicationPassword(username: response.userLogin,
                                                          password: response.applicationPassword,
                                                          siteAddress: siteURL)
        _ = stores.authenticate(credentials: credentials)

        let siteResult = await fetchSiteInfo(siteURL: siteURL)
        let site: Site
        switch siteResult {
        case .success(let value):
            site = value
        case .failure:
            return await fail(.siteAuthFailure, useCase: useCase)
        }

        guard site.isWooCommerceActive else {
            return await fail(.notAWooSite, useCase: useCase)
        }

        switch await checkRoleEligibility() {
        case .success:
            analytics.track(.signedIn)
            return .success(())
        case .failure(.insufficientRole):
            return await fail(.userNotEligible, useCase: useCase)
        case .failure:
            return await fail(.siteAuthFailure, useCase: useCase)
        }
    }
}

// MARK: - Helpers

private extension QRLoginPostExchangeService {

    func fetchSiteInfo(siteURL: String) async -> Result<Site, Error> {
        await withCheckedContinuation { continuation in
            let action = WordPressSiteAction.fetchSiteInfo(siteURL: siteURL) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
    }

    func checkRoleEligibility() async -> Result<Void, RoleEligibilityError> {
        await withCheckedContinuation { continuation in
            roleEligibilityUseCase.checkEligibility(for: WooConstants.placeholderStoreID) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func fail(_ kind: QRLoginUserFacingError.Kind,
              useCase: ApplicationPasswordUseCase) async -> Result<Void, QRLoginUserFacingError> {
        // Best-effort revoke. We swallow errors here: the AP
        // must be revoked, but if the revoke fails we still need to surface
        // the original user-facing error rather than masking it with a
        // network failure on revoke.
        try? await useCase.deletePassword(locally: true)
        _ = stores.deauthenticate()
        return .failure(.init(kind: kind, phase: .postExchange, primaryAction: .scanAgain))
    }

    static let defaultApplicationPasswordUseCaseFactory: ApplicationPasswordUseCaseFactory = { ap, siteAddress in
        OneTimeApplicationPasswordUseCase(applicationPassword: ap, siteAddress: siteAddress)
    }

    /// Returns the server-returned `site_url` only when it matches the scanned,
    /// confirmed URL — exact host (case-insensitive) and the same scheme. Matching
    /// the scanned scheme inherits the parser's policy (https-only in release,
    /// http allowed in DEBUG), so no separate scheme list is duplicated here.
    /// Returns `nil` when the response URL is malformed or doesn't match, which the
    /// caller treats as a sign-in failure. On match the response value is used
    /// verbatim so a legitimate canonical path (e.g. a subdirectory install) is
    /// preserved.
    static func validatedSiteURL(from response: SelfHostedQRLoginExchangeResponse,
                                 scannedSiteURL: URL) -> String? {
        guard let responseURL = URL(string: response.siteURL),
              let responseHost = responseURL.host?.lowercased(),
              let scannedHost = scannedSiteURL.host?.lowercased(),
              responseHost == scannedHost,
              responseURL.scheme?.lowercased() == scannedSiteURL.scheme?.lowercased() else {
            return nil
        }
        return response.siteURL
    }
}

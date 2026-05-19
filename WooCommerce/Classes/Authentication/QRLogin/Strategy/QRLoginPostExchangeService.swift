import Foundation
import Yosemite
import protocol WooFoundation.Analytics
import struct NetworkingCore.ApplicationPassword
import protocol NetworkingCore.ApplicationPasswordUseCase
import class NetworkingCore.OneTimeApplicationPasswordUseCase
import enum NetworkingCore.Credentials
import struct WordPressShared.Secret

/// Runs the self-hosted post-exchange sequence from spec §5.1.4 once the QR
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
    func complete(_ response: QRLoginSelfHostedExchangeResponse) async -> Result<Void, QRLoginUserFacingError>
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

    func complete(_ response: QRLoginSelfHostedExchangeResponse) async -> Result<Void, QRLoginUserFacingError> {
        let applicationPassword = ApplicationPassword(
            wpOrgUsername: response.userLogin,
            password: Secret(response.applicationPassword),
            // The exchange response doesn't carry the AP UUID. OneTimeApplicationPasswordUseCase
            // looks up the real one on delete via /wp/v2/users/me/application-passwords/introspect,
            // so a placeholder is fine here.
            uuid: UUID().uuidString
        )
        let useCase = applicationPasswordUseCaseFactory(applicationPassword, response.siteURL)

        let credentials = Credentials.applicationPassword(username: response.userLogin,
                                                          password: response.applicationPassword,
                                                          siteAddress: response.siteURL)
        stores.authenticate(credentials: credentials)

        let siteResult = await fetchSiteInfo(siteURL: response.siteURL)
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
        // Best-effort revoke. We swallow errors here: spec §5.1.4 says the AP
        // must be revoked, but if the revoke fails we still need to surface
        // the original user-facing error rather than masking it with a
        // network failure on revoke.
        try? await useCase.deletePassword(locally: true)
        stores.deauthenticate()
        return .failure(.init(kind: kind, phase: .postExchange, primaryAction: .scanAgain))
    }

    static let defaultApplicationPasswordUseCaseFactory: ApplicationPasswordUseCaseFactory = { ap, siteAddress in
        OneTimeApplicationPasswordUseCase(applicationPassword: ap, siteAddress: siteAddress)
    }
}

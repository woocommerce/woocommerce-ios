import Foundation
import Yosemite

@MainActor
struct ProductPreviewAuthenticationAvailability {
    private let currentSite: Site?
    private let wpcomCredentialsAvailable: Bool
    private let wporgCredentialsAvailable: Bool

    init(sessionManager: SessionManagerProtocol) {
        let currentCredentials = sessionManager.defaultCredentials
        currentSite = sessionManager.defaultSite
        wporgCredentialsAvailable = AuthenticatedWebViewController.resolveWPOrgAuthentication(
            extraCredentials: nil,
            currentCredentials: currentCredentials,
            authenticationEndpointLookup: sessionManager.cookieNonceAuthenticationEndpoints(for:)
        ) != nil

        if case .wpcom = currentCredentials {
            wpcomCredentialsAvailable = true
        } else {
            wpcomCredentialsAvailable = false
        }
    }

    func canAuthenticate(for url: URL?) -> Bool {
        guard let currentSite, let url else {
            return false
        }

        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: url)
        let authenticationFlow = viewModel.authenticationFlow(currentSite: currentSite,
                                                               wpcomCredentialsAvailable: wpcomCredentialsAvailable,
                                                               wporgCredentialsAvailable: wporgCredentialsAvailable)
        return authenticationFlow != .none
    }
}

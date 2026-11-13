import Foundation
import Yosemite

/// View model for `ApplicationPasswordAuthorizationWebViewController`.
///
final class ApplicationPasswordAuthorizationViewModel {
    static let successURL = "woocommerce://application-password"

    enum SiteMismatchStep: String {
        case beforeApproval = "before_approval"
        case duringApproval = "during_approval"
        case afterApproval = "after_approval"
    }

    enum NavigationDecision: Equatable {
        case allow
        case siteMismatch(SiteMismatchStep)
        case rejected
        case missingCredentials
        case approved(username: String, password: String)
    }

    let siteURL: String
    private let stores: StoresManager
    private(set) var authorization: ApplicationPasswordAuthorization?

    init(siteURL: String,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.stores = stores
    }

    @MainActor
    func fetchAuthURL() async throws -> ApplicationPasswordAuthorization? {
        let authorization: ApplicationPasswordAuthorization? = try await withCheckedThrowingContinuation { continuation in
            let action = WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: siteURL, detectUnexpectedResponses: true) { result in
                switch result {
                case .success(let authorization):
                    continuation.resume(returning: authorization)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
        self.authorization = authorization
        return authorization
    }

    /// `site_url` is checked before the credentials, so an approval on another site is a mismatch, not a generic error.
    func decision(for url: URL) -> NavigationDecision {
        guard url.absoluteString.hasPrefix(Self.successURL) else {
            return isForeignApprovalPage(url) ? .siteMismatch(.duringApproval) : .allow
        }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        func value(_ name: String) -> String? {
            queryItems.last(where: { $0.name == name })?.value
        }
        if let success = value(Constants.success), success.lowercased() != "true" {
            return .rejected
        }
        let redirectSiteURL = value(Constants.siteURL)
        guard ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: redirectSiteURL) ||
                ApplicationPasswordSiteMatcher.isWithinSite(siteURL: authorization?.approvalSiteURL, candidateURL: redirectSiteURL) else {
            return .siteMismatch(.afterApproval)
        }
        guard let username = value(Constants.username), !username.isEmpty,
              let password = value(Constants.password), !password.isEmpty else {
            return .missingCredentials
        }
        return .approved(username: username, password: password)
    }
}

private extension ApplicationPasswordAuthorizationViewModel {
    /// Logins may pass through other hosts (SSO, hosted 2FA). Only the approval page, which creates the password
    /// and hands it to the redirect, has to stay within the WordPress the app already checked.
    func isForeignApprovalPage(_ url: URL) -> Bool {
        guard ApplicationPasswordSiteMatcher.isApprovalPage(url.absoluteString) else {
            return false
        }
        let approvalSite = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorization?.url.absoluteString)
        return !ApplicationPasswordSiteMatcher.isWithinSite(siteURL: approvalSite, candidateURL: url.absoluteString)
    }

    enum Constants {
        static let success = "success"
        static let siteURL = "site_url"
        static let username = "user_login"
        static let password = "password"
    }
}

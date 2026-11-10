import Foundation
import Networking

/// Handles `WordPressSiteAction`
///
public final class WordPressSiteStore: DeauthenticatedStore {
    // Keeps a strong reference to remote to keep requests alive.
    private let remote: WordPressSiteRemote

    public init(remote: WordPressSiteRemote, dispatcher: Dispatcher) {
        self.remote = remote
        super.init(dispatcher: dispatcher)
    }

    public convenience init(network: Network, dispatcher: Dispatcher) {
        let remote = WordPressSiteRemote(network: network)
        self.init(remote: remote, dispatcher: dispatcher)
    }

    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: WordPressSiteAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? WordPressSiteAction else {
            assertionFailure("WordPressSiteStore received an unsupported action: \(action)")
            return
        }
        switch action {
        case let .fetchSiteInfo(siteURL, detectUnexpectedResponses, completion):
            fetchSiteInfo(for: siteURL, detectUnexpectedResponses: detectUnexpectedResponses, completion: completion)
        case let .fetchApplicationPasswordAuthorizationURL(siteURL, detectUnexpectedResponses, completion):
            fetchApplicationPasswordAuthorizationURL(for: siteURL, detectUnexpectedResponses: detectUnexpectedResponses, completion: completion)
        case let .fetchPageList(siteURL, completion):
            fetchPageList(siteURL: siteURL, completion: completion)
        }
    }
}

private extension WordPressSiteStore {
    func fetchSiteInfo(for siteURL: String, detectUnexpectedResponses: Bool, completion: @escaping @Sendable (Result<Site, Error>) -> Void) {
        let remote = remote
        Task { @MainActor in
            do {
                let wpSite = try await remote.fetchSiteInfo(for: siteURL, detectUnexpectedResponses: detectUnexpectedResponses)
                let site = wpSite.asSite
                completion(.success(site))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchApplicationPasswordAuthorizationURL(for siteURL: String,
                                                  detectUnexpectedResponses: Bool,
                                                  completion: @escaping @Sendable (Result<ApplicationPasswordAuthorization?, Error>) -> Void) {
        let remote = remote
        Task { @MainActor in
            do {
                let wpSite = try await remote.fetchSiteInfo(for: siteURL, detectUnexpectedResponses: detectUnexpectedResponses)
                guard let path = wpSite.applicationPasswordAuthorizationURL,
                      let url = URL(string: path) else {
                    completion(.success(nil))
                    return
                }
                let authorization = try await checkedAuthorization(url: url, siteURL: siteURL, remote: remote)
                completion(.success(authorization))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// The store's REST index picks the approval page, so a lookalike store could list another site's page.
    /// A page on another host is accepted only when that host's WordPress reports the store as its home.
    func checkedAuthorization(url: URL, siteURL: String, remote: WordPressSiteRemote) async throws -> ApplicationPasswordAuthorization {
        guard let approvalSiteURL = ApplicationPasswordSiteMatcher.approvalSiteURL(for: url.absoluteString) else {
            throw ApplicationPasswordAuthorizationError.siteMismatch
        }
        if ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: approvalSiteURL) {
            return ApplicationPasswordAuthorization(url: url, approvalSiteURL: nil)
        }
        let approvalSiteHome = try await remote.fetchSiteInfo(for: approvalSiteURL).home
        guard ApplicationPasswordSiteMatcher.isSameSiteAddress(siteURL, approvalSiteHome) else {
            throw ApplicationPasswordAuthorizationError.siteMismatch
        }
        return ApplicationPasswordAuthorization(url: url, approvalSiteURL: approvalSiteURL)
    }

    func fetchPageList(siteURL: String, completion: @escaping @Sendable (Result<[WordPressPage], Error>) -> Void) {
        let remote = remote
        Task { @MainActor in
            do {
                let pageList = try await remote.fetchSitePages(for: siteURL)
                completion(.success(pageList))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

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

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: WordPressSiteAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? WordPressSiteAction else {
            assertionFailure("WordPressSiteStore received an unsupported action: \(action)")
            return
        }
        switch action {
        case let .fetchSiteInfo(siteURL, completion):
            fetchSiteInfo(for: siteURL, completion: completion)
        }
    }
}

private extension WordPressSiteStore {
    func fetchSiteInfo(for siteURL: String, completion: @escaping (Result<Site, Error>) -> Void) {
        Task { @MainActor in
            do {
                let wpSite = try await remote.fetchSiteInfo(for: siteURL)
                let site = wpSite.asSite
                completion(.success(site))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

import Foundation
import Networking

/// Handles `JetpackConnectionAction`
///
public final class JetpackConnectionStore: DeauthenticatedStore {

    // Keep a strong reference to remote to keep requests alive
    private var remote: JetpackConnectionRemote?

    public override init(dispatcher: Dispatcher) {
        super.init(dispatcher: dispatcher)
    }

    public convenience init(dispatcher: Dispatcher, network: Network, siteURL: String) {
        self.init(dispatcher: dispatcher)
        updateRemote(with: siteURL, network: network)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: JetpackConnectionAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? JetpackConnectionAction else {
            assertionFailure("JetpackConnectionStore received an unsupported action")
            return
        }
        switch action {
        case .authenticate(let siteURL, let network):
            updateRemote(with: siteURL, network: network)
        case .retrieveJetpackPluginDetails(let completion):
            retrieveJetpackPluginDetails(completion: completion)
        case .installJetpackPlugin(let completion):
            installJetpackPlugin(completion: completion)
        case .activateJetpackPlugin(let completion):
            activateJetpackPlugin(completion: completion)
        case .fetchJetpackConnectionURL(let completion):
            fetchJetpackConnectionURL(completion: completion)
        case .fetchJetpackUser(let completion):
            fetchJetpackUser(completion: completion)
        }
    }
}

private extension JetpackConnectionStore {
    func updateRemote(with siteURL: String, network: Network) {
        self.remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
    }

    func retrieveJetpackPluginDetails(completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        remote?.retrieveJetpackPluginDetails(completion: completion)
    }

    func installJetpackPlugin(completion: @escaping (Result<Void, Error>) -> Void) {
        remote?.installJetpackPlugin(completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func activateJetpackPlugin(completion: @escaping (Result<Void, Error>) -> Void) {
        remote?.activateJetpackPlugin(completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func fetchJetpackConnectionURL(completion: @escaping (Result<URL, Error>) -> Void) {
        remote?.fetchJetpackConnectionURL { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let url):
                // If we get the account connection URL, return it immediately.
                if url.absoluteString.hasPrefix(Constants.jetpackAccountConnectionURL) {
                    return completion(.success(url))
                }
                // Otherwise, request the url with redirection disabled and retrieve the URL in LOCATION header
                self.remote?.registerJetpackSiteConnection(with: url, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchJetpackUser(completion: @escaping (Result<JetpackUser, Error>) -> Void) {
        remote?.fetchJetpackUser(completion: completion)
    }
}

// MARK: - Enums
//
private extension JetpackConnectionStore {
    enum Constants {
        static let jetpackAccountConnectionURL = "https://jetpack.wordpress.com/jetpack.authorize"
    }
}

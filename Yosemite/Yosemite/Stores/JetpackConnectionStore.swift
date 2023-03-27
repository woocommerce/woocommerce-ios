import Foundation
import Networking

/// Handles `JetpackConnectionAction`
///
public final class JetpackConnectionStore: DeauthenticatedStore {

    // Keep strong references to remotes to keep requests alive
    private var jetpackConnectionRemote: JetpackConnectionRemote?
    private var accountRemote: AccountRemote?

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
        case .loadWPComAccount(let network, let onCompletion):
            loadWPComAccount(network: network, onCompletion: onCompletion)
        }
    }
}

private extension JetpackConnectionStore {
    func updateRemote(with siteURL: String, network: Network) {
        self.jetpackConnectionRemote = JetpackConnectionRemote(siteURL: siteURL, network: network)
    }

    func retrieveJetpackPluginDetails(completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        jetpackConnectionRemote?.retrieveJetpackPluginDetails(completion: completion)
    }

    func installJetpackPlugin(completion: @escaping (Result<Void, Error>) -> Void) {
        jetpackConnectionRemote?.installJetpackPlugin(completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func activateJetpackPlugin(completion: @escaping (Result<Void, Error>) -> Void) {
        jetpackConnectionRemote?.activateJetpackPlugin(completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func fetchJetpackConnectionURL(completion: @escaping (Result<URL, Error>) -> Void) {
        jetpackConnectionRemote?.fetchJetpackConnectionURL(completion: completion)
    }

    func fetchJetpackUser(completion: @escaping (Result<JetpackUser, Error>) -> Void) {
        jetpackConnectionRemote?.fetchJetpackUser(completion: completion)
    }

    func loadWPComAccount(network: Network, onCompletion: @escaping (Account?) -> Void) {
        let remote = AccountRemote(network: network)
        remote.loadAccount { result in
            switch result {
            case .success(let account):
                onCompletion(account)
            case .failure:
                onCompletion(nil)
            }
        }
        self.accountRemote = remote
    }
}

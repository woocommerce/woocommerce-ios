import Foundation
import Networking

/// Handles `JetpackConnectionAction`
///
public final class JetpackConnectionStore: DeauthenticatedStore {

    // Keep strong references to remotes to keep requests alive
    private var jetpackConnectionRemote: JetpackConnectionRemote?
    private var accountRemote: AccountRemote?
    private var siteRemote: SiteRemote?

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
        case .fetchJetpackConnectionData(let completion):
            fetchJetpackConnectionData(completion: completion)
        case .registerSite(let completion):
            registerSite(completion: completion)
        case .provisionConnection(let completion):
            provisionConnection(completion: completion)
        case .finalizeConnection(let siteID, let siteURL, let provisionResponse, let network, let completion):
            finalizeConnection(siteID: siteID, siteURL: siteURL, provisionResponse: provisionResponse, network: network, completion: completion)
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

    func fetchJetpackConnectionData(completion: @escaping (Result<JetpackConnectionData, Error>) -> Void) {
        jetpackConnectionRemote?.fetchJetpackConnectionData(completion: completion)
    }

    func registerSite(completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let jetpackConnectionRemote else { return }
        Task { @MainActor in
            do {
                let blogID = try await jetpackConnectionRemote.registerSite()
                completion(.success(blogID))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func provisionConnection(completion: @escaping (Result<JetpackConnectionProvisionResponse, Error>) -> Void) {
        guard let jetpackConnectionRemote else { return }
        Task { @MainActor in
            do {
                let response = try await jetpackConnectionRemote.provisionConnection()
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func finalizeConnection(siteID: Int64,
                            siteURL: String,
                            provisionResponse: JetpackConnectionProvisionResponse,
                            network: Network,
                            completion: @escaping (Result<Void, Error>) -> Void) {
        let remote = SiteRemote(network: network, dotcomClientID: "", dotcomClientSecret: "")
        Task { @MainActor in
            do {
                try await remote.finalizeJetpackConnection(siteID: siteID, siteURL: siteURL, provisionResponse: provisionResponse)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
        self.siteRemote = remote
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

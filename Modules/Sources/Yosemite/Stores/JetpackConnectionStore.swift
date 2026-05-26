import Foundation
import Networking

/// Handles `JetpackConnectionAction`
///
public final class JetpackConnectionStore: DeauthenticatedStore {

    // Keep strong references to remotes to keep requests alive
    private var jetpackConnectionRemote: JetpackConnectionRemote?
    private var accountRemote: AccountRemote?

    /// periphery: ignore - kept with strong reference to keep network requests alive.
    private var siteRemote: SiteRemote?

    override public init(dispatcher: Dispatcher) {
        super.init(dispatcher: dispatcher)
    }

    public convenience init(dispatcher: Dispatcher, network: Network, siteURL: String) {
        self.init(dispatcher: dispatcher)
        updateRemote(with: siteURL, network: network)
    }

    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: JetpackConnectionAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? JetpackConnectionAction else {
            assertionFailure("JetpackConnectionStore received an unsupported action")
            return
        }
        switch action {
        case .authenticate(let siteURL, let network):
            updateRemote(with: siteURL, network: network)
        case .retrieveJetpackPluginDetails(let siteID, let completion):
            retrieveJetpackPluginDetails(siteID: siteID, completion: completion)
        case .installJetpackPlugin(let siteID, let completion):
            installJetpackPlugin(siteID: siteID, completion: completion)
        case .activateJetpackPlugin(let siteID, let completion):
            activateJetpackPlugin(siteID: siteID, completion: completion)
        case let .fetchJetpackConnectionURL(authenticatedWithWPCom, completion):
            fetchJetpackConnectionURL(authenticatedWithWPCom: authenticatedWithWPCom,
                                      completion: completion)
        case .fetchJetpackConnectionData(let siteID, let completion):
            fetchJetpackConnectionData(siteID: siteID, completion: completion)
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

    func retrieveJetpackPluginDetails(siteID: Int64, completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        guard let jetpackConnectionRemote else {
            completion(.failure(JetpackConnectionStoreError.remoteNotConfigured))
            return
        }
        jetpackConnectionRemote.retrieveJetpackPluginDetails(siteID: siteID, completion: completion)
    }

    func installJetpackPlugin(siteID: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let jetpackConnectionRemote else {
            completion(.failure(JetpackConnectionStoreError.remoteNotConfigured))
            return
        }
        jetpackConnectionRemote.installJetpackPlugin(siteID: siteID, completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func activateJetpackPlugin(siteID: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let jetpackConnectionRemote else {
            completion(.failure(JetpackConnectionStoreError.remoteNotConfigured))
            return
        }
        jetpackConnectionRemote.activateJetpackPlugin(siteID: siteID, completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func fetchJetpackConnectionURL(authenticatedWithWPCom: Bool,
                                   completion: @escaping (Result<URL, Error>) -> Void) {
        guard let jetpackConnectionRemote else {
            completion(.failure(JetpackConnectionStoreError.remoteNotConfigured))
            return
        }
        guard authenticatedWithWPCom else {
            jetpackConnectionRemote.fetchJetpackConnectionURL(completion: completion)
            return
        }
        jetpackConnectionRemote.fetchJetpackConnectionURL { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let url):
                // If we get the account connection URL, return it immediately.
                if url.absoluteString.hasPrefix(Constants.jetpackAccountConnectionURL) {
                    return completion(.success(url))
                }
                // Otherwise, request the url with redirection disabled and retrieve the URL in LOCATION header
                self.jetpackConnectionRemote?.registerJetpackSiteConnection(with: url, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchJetpackConnectionData(siteID: Int64, completion: @escaping (Result<JetpackConnectionData, Error>) -> Void) {
        guard let jetpackConnectionRemote else {
            completion(.failure(JetpackConnectionStoreError.remoteNotConfigured))
            return
        }
        jetpackConnectionRemote.fetchJetpackConnectionData(siteID: siteID, completion: completion)
    }

    func registerSite(completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let jetpackConnectionRemote else {
            completion(.failure(JetpackConnectionStoreError.remoteNotConfigured))
            return
        }
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
        guard let jetpackConnectionRemote else {
            completion(.failure(JetpackConnectionStoreError.remoteNotConfigured))
            return
        }
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
        /// Intentionally leaving `dotcomClientID` and `dotcomClientSecret` empty
        /// as these are not needed for the `finalizeJetpackConnection` method we're using here.
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

private extension JetpackConnectionStore {
    enum Constants {
        static let jetpackAccountConnectionURL = "https://jetpack.wordpress.com/jetpack.authorize"
    }

    enum JetpackConnectionStoreError: Error {
        case remoteNotConfigured
    }
}

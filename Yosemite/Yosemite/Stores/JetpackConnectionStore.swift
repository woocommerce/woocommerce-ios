import Foundation
import Networking
import WordPressKit

/// Handles `JetpackConnectionAction`
///
public final class JetpackConnectionStore: DeauthenticatedStore {

    // Keep a strong reference to network to keep requests alive
    private var network: WordPressOrgNetwork?

    // Keep a strong reference to remote to keep requests alive
    private var remote: JetpackConnectionRemote?

    public override init(dispatcher: Dispatcher) {
        super.init(dispatcher: dispatcher)
    }

    override public func registerSupportedActions(in dispatcher: Dispatcher) {
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
        case let .fetchJetpackConnectionURL(siteURL, authenticator, completion):
            fetchJetpackConnectionURL(siteURL: siteURL, with: authenticator, completion: completion)
        }
    }
}

private extension JetpackConnectionStore {
    func fetchJetpackConnectionURL(siteURL: String, with authenticator: Authenticator, completion: @escaping (Result<URL, Error>) -> Void) {
        let network = WordPressOrgNetwork(authenticator: authenticator, userAgent: UserAgent.defaultUserAgent)
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)

        // hold strong references
        self.network = network
        self.remote = remote

        remote.fetchJetpackConnectionURL(completion: completion)
    }
}

import Foundation
import Networking
import WordPressKit

/// Handles `JetpackConnectionAction`
///
public final class JetpackConnectionStore: DeauthenticatedStore {

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
    func fetchJetpackConnectionURL(siteURL: String, with authenticator: Authenticator, completion: @escaping (Result<URL?, Error>) -> Void) {
        let remote = JetpackConnectionRemote(siteURL: siteURL, authenticator: authenticator)
        Task {
            do {
                let url = try await remote?.fetchJetpackConnectionURL()
                await MainActor.run {
                    completion(.success(url))
                }
            } catch let error {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}

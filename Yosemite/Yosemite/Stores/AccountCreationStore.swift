import Foundation
import Networking

/// Handles `AccountCreationAction`
///
public final class AccountCreationStore: DeauthenticatedStore {
    // Keeps a strong reference to remote to keep requests alive.
    private let remote: AccountRemoteProtocol

    private let dotcomClientID: String
    private let dotcomClientSecret: String

    public init(dotcomClientID: String, dotcomClientSecret: String, remote: AccountRemoteProtocol, dispatcher: Dispatcher) {
        self.remote = remote
        self.dotcomClientID = dotcomClientID
        self.dotcomClientSecret = dotcomClientSecret
        super.init(dispatcher: dispatcher)
    }

    public convenience init(dotcomClientID: String, dotcomClientSecret: String, network: Network, dispatcher: Dispatcher) {
        let remote = AccountRemote(network: network)
        self.init(dotcomClientID: dotcomClientID, dotcomClientSecret: dotcomClientSecret, remote: remote, dispatcher: dispatcher)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AccountCreationAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? AccountCreationAction else {
            assertionFailure("AccountCreationStore received an unsupported action: \(action)")
            return
        }
        switch action {
        case .createAccount(let email, let password, let completion):
            createAccount(email: email, password: password, completion: completion)
        }
    }
}

private extension AccountCreationStore {
    func createAccount(email: String, password: String, completion: @escaping (Result<CreateAccountResult, CreateAccountError>) -> Void) {
        Task { @MainActor in
            // Auto-generates a username based on the email.
            let usernameSuggestionsResult = await remote.loadUsernameSuggestions(from: email)
            guard case let .success(usernameSuggestions) = usernameSuggestionsResult,
            let username = usernameSuggestions.first else {
                return completion(.failure(.invalidUsername))
            }
            // Creates a WPCOM account.
            let result = await remote.createAccount(email: email,
                                                    username: username,
                                                    password: password,
                                                    clientID: dotcomClientID,
                                                    clientSecret: dotcomClientSecret)
            completion(result)
        }
    }
}

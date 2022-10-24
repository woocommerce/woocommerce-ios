import Foundation

/// Defines actions supported by `AccountCreationStore`.
public enum AccountCreationAction: Action {
    /// Creates a WPCOM account given an email and password. Returns an auth token and username on success.
    case createAccount(email: String, password: String, completion: (Result<CreateAccountResult, CreateAccountError>) -> Void)
}

#if !targetEnvironment(macCatalyst)
import StripeTerminal

/// Implementation of the ConnectionTokenProvider protocol that
/// uses the networking adapter provided by clients of Hardware
/// to fetch a connection token
final class DefaultConnectionTokenProvider: ConnectionTokenProvider {
    private let provider: ReaderTokenProvider

    init(provider: ReaderTokenProvider) {
        self.provider = provider
    }

    public func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        provider.fetchToken() { result in
            switch result {
            case .success(let token):
                completion(token, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
#endif

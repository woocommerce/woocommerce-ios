import StripeTerminal

/// Implementation of the ConnectionTokenProvider protocol that
/// uses the networking adapter provided by clients of Hardware
/// to fetch a connection token
final class DefaultConnectionTokenProvider: ConnectionTokenProvider {
    private let adapter: CardReaderNetworkingAdapter

    init(adapter: CardReaderNetworkingAdapter) {
        self.adapter = adapter
    }

    public func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        adapter.fetchToken(completion: completion)
    }
}

import StripeTerminal

/// Implementation of the ConnectionTokenProvider protocol that
/// attacks WCPay to get a token.
/// Tokens can be "live" or "test", depending on wheter WCPay
/// is set for live or test mode.
public final class WCPayTokenProvider: ConnectionTokenProvider {
    private let mockToken = "get a token from your test site"

    public init() { }

    public func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        // For this first implementation we just want to have something up quickly.
        // So, for now, we will return a hardcoded string, and no error.
        // This will be removed later, and will be implemented properly.
        completion(mockToken, nil)
    }
}

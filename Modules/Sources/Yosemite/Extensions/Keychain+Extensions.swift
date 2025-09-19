import KeychainAccess
import NetworkingCore

extension Keychain {
    /// AI key provided by the merchant
    ///
    var merchantAIProviderKey: String? {
        get { self[WooConstants.merchantAIProviderKey] }
        set { self[WooConstants.merchantAIProviderKey] = newValue }
    }
}

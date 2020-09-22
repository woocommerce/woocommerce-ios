import KeychainAccess

extension Keychain {
    /// The Apple ID that the user signed in to the WooCommerce app via SIWA.
    var wooAppleID: String? {
        get { self[WooConstants.keychainAppleIDKey] }
        set { self[WooConstants.keychainAppleIDKey] = newValue }
    }
}

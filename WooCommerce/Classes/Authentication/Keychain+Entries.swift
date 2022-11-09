import KeychainAccess

extension Keychain {
    /// The Apple ID that the user signed in to the WooCommerce app via SIWA.
    var wooAppleID: String? {
        get { self[WooConstants.keychainAppleIDKey] }
        set { self[WooConstants.keychainAppleIDKey] = newValue }
    }

    /// The anonymous ID used to identify a logged-out user potentially across installs in analytics and A/B experiments.
    var anonymousID: String? {
        get { self[WooConstants.anonymousIDKey] }
        set { self[WooConstants.anonymousIDKey] = newValue }
    }

    /// Auth token for the current selected store
    ///
    var currentAuthToken: String? {
        get { self[WooConstants.authToken] }
        set { self[WooConstants.authToken] = newValue }
    }
}

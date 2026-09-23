extension WooAnalyticsEvent {
    enum Authentication {
        private enum Key {
            static let reason = "reason"
        }

        /// Reasons the app signs the merchant out without them asking.
        ///
        /// Values match the ones tracked on WooCommerce Android for cross-platform parity
        /// (see the Login Health monitoring work).
        ///
        enum InvoluntaryLogoutReason: String {
            /// WordPress.com reports the access token as invalid.
            case invalidToken = "invalid_token"

            /// The stored application password stopped working and could not be recovered,
            /// i.e. the site credentials are no longer valid.
            case applicationPasswordUnauthorized = "application_password_unauthorized"

            /// The Sign in with Apple credential was revoked. This is an iOS-only sign-out
            /// path that has no equivalent on WooCommerce Android.
            case appleIDCredentialRevoked = "apple_id_credential_revoked"
        }

        /// Tracks when the app signs the merchant out on its own, fired right before the logout.
        ///
        static func involuntaryLogout(reason: InvoluntaryLogoutReason) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .involuntaryLogout,
                              properties: [Key.reason: reason.rawValue])
        }
    }
}

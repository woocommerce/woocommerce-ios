import WordPressAuthenticator

extension WordPressComSiteInfo {

    /// Encapsulates the rules that declare a WordPress site as having a valid
    /// Jetpack installation
    var hasValidJetpack: Bool {
        return hasJetpack &&
            isJetpackConnected &&
            isJetpackActive
    }
}

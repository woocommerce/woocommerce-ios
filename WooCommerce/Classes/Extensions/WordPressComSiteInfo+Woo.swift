import WordPressAuthenticator

extension WordPressComSiteInfo {

    /// Encapsulates the rules that declare a WordPress site as having a valid
    /// Jetpack installation
    var hasValidJetpack: Bool {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.jetpackConnectionPackageSupport) {
            return isJetpackConnected
        } else {
            return hasJetpack &&
                isJetpackConnected &&
                isJetpackActive
        }
    }
}

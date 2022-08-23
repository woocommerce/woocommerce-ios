import WordPressAuthenticator

extension WordPressSupportSourceTag {
    /// Returns the custom help content web page's URL if the screen.
    /// Returns `nil` if the screen with the current `sourceTag` doesn't have custom help content available.
    ///
    /// The `sourceTag` is set for login related screens in WordPressAuthenticator library.
    ///
    var customHelpCenterURL: URL? {
        switch self {
        case .loginSiteAddress:
            return WooConstants.URLs.helpCenterForEnterStoreAddress.asURL()
        default:
            return nil
        }
    }
}

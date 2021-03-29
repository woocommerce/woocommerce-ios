import Foundation

// MARK: - Named Assets
//
extension UIImage {
    /// Returns the Link Image.
    ///
    static var linkFieldImage: UIImage {
        return UIImage(named: "icon-url-field", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Default Magic Link Image.
    ///
    static var magicLinkImage: UIImage {
        return UIImage(named: "login-magic-link", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Default Site Icon Placeholder Image.
    ///
    @objc
    public static var siteAddressModalPlaceholder: UIImage {
        return UIImage(named: "site-address", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Default Gravatar Placeholder Image.
    ///
    @objc
    public static var onePasswordImage: UIImage {
        return UIImage(named: "onepassword-button", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns the Link Image.
    ///
    @objc
    public static var googleIcon: UIImage {
        return UIImage(named: "google", in: bundle, compatibleWith: nil) ?? UIImage()
    }

    /// Returns WordPressAuthenticator's Bundle
    ///
    private static var bundle: Bundle {
        return WordPressAuthenticator.bundle
    }
}
